#!/usr/local/bin/perl -sw
# $Id: //depot/tilpasninger/dbd-ingres/Makefile.PL#6 $

require 5.004;

use ExtUtils::MakeMaker 5.38, qw(&WriteMakefile $Verbose);
use Getopt::Long;
use Config;
use strict;

# Some MakeMaker's forged some FileHandle methods
require FileHandle unless defined(&FileHandle::new);

# This DBI must be installed before we can build a DBD.
# For those not using Dynamic loading this means building a
# new static perl in the DBI directory by saying 'make perl'
# and then using _that_ perl to make this one.
use DBI 1.00;
use DBI::DBD;
my $Is_VMS = $Config{osname} eq 'VMS';
my $Is_NT = $Config{osname} eq 'MSWin32';

my %opts = (
    NAME => 'DBD::Ingres',
    VERSION_FROM => 'Ingres.pm',
    PREREQ_PM => {"DBI"=>1.00, "Getopt::Long"=>0, "Config"=>0},
    dist  => { DIST_DEFAULT=> 'clean distcheck disttest tardist',
               PREOP => '$(MAKE) -f Makefile.old distdir',
	       COMPRESS => 'gzip', SUFFIX => 'gz', },
    LINKTYPE => 'dynamic',
    OPTIMIZE => '-g',
   ($] >= 5.005)
    ? (
     'AUTHOR' => 'Henrik Tougaard (htoug@cpan.org)',
     'ABSTRACT_FROM' => 'Ingres.pm',
    )
    : (),
);
$opts{CAPI} = 'TRUE' if $Config{archname} =~ /-object\b/i;

# Options, typically only used for debugging
$::opt_g = '';		# enable debugging (s/-O/-g/g)
$::opt_v = 0;		# be verbose
$::opt_o = 0;           # OpenIngres or not

GetOptions('v!', 'g!', 'o!') or die "Invalid arguments";

$::opt_g &&= '-g';	# convert to actual string
$Verbose ||= $::opt_v;
my $OpenIngres= $::opt_o;

# --- Introduction

print "\n Configuring DBD::Ingres ...

   \tTry 'perl Makefile.PL -v'
   \t  if you have any problems.


";

# --- Where is Ingres installed...

unless ($ENV{II_SYSTEM}){
    die "\$II_SYSTEM not defined. No Ingres?\n";
}
my $II_SYSTEM = $ENV{II_SYSTEM};

print "Using Ingres in $II_SYSTEM\n";

my $libhome = "";
my $linkwith = "-L$II_SYSTEM/ingres/lib -lingres";  # good (?) guess for 6.4
if (-f "$II_SYSTEM/ingres/files/abflnk.opt") {
    # the option file should give us all the libraries we need
    open(ABFLNK, "$II_SYSTEM/ingres/files/abflnk.opt")
        or die "Can't read the option file ".
               "'$II_SYSTEM/ingres/files/abflnk.opt'\n";
    $linkwith = join(" ", <ABFLNK>);
    close ABFLNK;
    $linkwith =~ s/\n//g;
    $linkwith =~ s/\$II_SYSTEM/$II_SYSTEM/g;
} elsif (-f "$II_SYSTEM/ingres/lib/libcompat.1.so") {
    $linkwith .= " -lcompat.1";   # OpenIngres without ABF.
}
# Adjust linkwith (some 6.4 versions have the name of the library in abfopt.opt
for ($linkwith) {
   s{(/.*)/lib(.*?)\.a}{-L$1 -l$2};
}

# Try to figure out if this is an OpenIngres or not
unless (defined $OpenIngres) {
    $OpenIngres = defined(-f "$II_SYSTEM/ingres/lib/libcompat.1.so");
    print "OpenIngres detected\n" if $OpenIngres;
}


my $linkopt = "";

# --- Handle special cases ---

$opts{DEFINE} = '-Wall -pedantic -Wno-comment -Wtraditional'
    if $Config{cc} eq 'gcc';

$opts{DEFINE} .= '-Xa' if $Config{cc} eq 'clcc';	# CenterLine CC

warn "WARNING: Your GNU C compiler is very old. Please upgrade.\n"
    if ($Config{gccversion} and $Config{gccversion} =~ m/^(1|2\.[1-5])/);

my $ESQLC = $ENV{ESQLC} ||"$II_SYSTEM/ingres/bin/esqlc";

# OpenVMS has specialities:
if ($Is_VMS) {
    $opts{OPTIMIZE} = "/optimize/nowarning";
    $opts{CCCDLFLAGS}="/nowarning";
    $linkopt = "II_SYSTEM:[ingres.files]esql.opt/opt";
    $linkwith = "";
    $libhome = "";
    $ESQLC = "ESQLC";
    $OpenIngres = -r "II_SYSTEM:[INGRES.FILES]CONFIG.DAT";
} elsif ($Is_NT) {
    $ESQLC = $ENV{ESQLC} ||"$II_SYSTEM\\ingres\\bin\\esqlc.exe";
} else {
    # Non-vms checks:
    # See if the ESQL-precompiler exists...
    print "I can't find your Esql/C precompiler: '$ESQLC'\n",
          "Is your Ingres set up correctly??\n"
       unless -x $ESQLC;
}

# Solaris needs the elf-library
if ($Config{osname} eq 'solaris') {
    $linkwith .= " -lelf";
}

# HP-UX cannot link a non-PIC object file into a shared library.
if ($Config{osname} eq 'hpux') {
    print "Warning: forced to build static not dynamic on $Config{osname} $Config{osvers}\n";
    print "         See README for more information.\n";
    $opts{LINKTYPE} = 'static';
}

# log key platform information to help me help you quickly
print "System: perl$] @Config{qw(myuname)}\n",
      "Compiler: @Config{qw(cc optimize ccflags)}\n",
      "SQL-precompiler: $ESQLC\n",
      "II_SYSTEM: $II_SYSTEM",
	  ($OpenIngres ? ", OpenIngres\n" : "Ingres 6.4\n"),
      "Linkwith: '$linkwith'\n" if $Verbose;

print "\n";

$opts{LIBS} = [ "$libhome $linkwith" ];

# compute path to DBI include files
my $INSTALLSITEARCH = $INC{'DBI.pm'};
$INSTALLSITEARCH =~ s{/DBI.pm$}{};
my $DBIXS_INSTALL_DIR;
foreach my $guess ("$INSTALLSITEARCH/" . $Config::Config{archname},
		$Config::Config{'installsitearch'},
		"$INSTALLSITEARCH/") {
    if (-f "$guess/auto/DBI/DBIXS.h") {
        $DBIXS_INSTALL_DIR = "$guess/auto/DBI";
        $opts{'INC'} = "-I$DBIXS_INSTALL_DIR";
        last;
    }
}
if (!$DBIXS_INSTALL_DIR) {
    die "Unable to find header file DBIXS.h; you seem to have an"
	. " interesting Perl setup ...\n";
}

$opts{dynamic_lib} = { OTHERLDFLAGS => " $linkwith \$(COMPOBJS)" };
$opts{OBJECT} = 'Ingres$(OBJ_EXT) dbdimp$(OBJ_EXT)';
$opts{depend} = { "dbdimp\$(OBJ_EXT)" => "dbdimp.c Ingres.h",
		  "Ingres\$(OBJ_EXT)" => "Ingres.h",
                };
$opts{clean} = { FILES => "dbdimp.c dbdimp.sc Ingres.h Ingres.sc Ingres.xsi" };
$opts{macro} = { ESQLC => $ESQLC, ESQLCOPT => "-o.h -w -p" };
$opts{DEFINE} = '-DOPENINGRES' if $OpenIngres;
WriteMakefile(%opts);

sub MY::post_initialize {
    my $self = shift;
    # Ensure Ingperl.pm and ingperl.pl are installed into top lib dir
    $self->{PM}->{'Ingperl.pm'} = '$(INST_LIB)/Ingperl.pm';
    $self->{PM}->{'ingperl.pl'} = '$(INST_LIB)/ingperl.pl';
    '';
}

sub MY::postamble {
    # Note this is not quite in accordance with the DBD-writer specs.
    # Mainly due to attempts to cater for 'wierd' DBI locations.
    my $subst = $OpenIngres ?
		    's!/\\*OI\\*!!' :    # Turn on OpenIngres or 
		    's!/\\*64\\*!!';     # Ingres 6.4 parts of dbdimp.psc

    my $driver_xst_path = $DBIXS_INSTALL_DIR."/Driver.xst";
    if ($Is_VMS) {
        require VMS::Filespec;
        $driver_xst_path = VMS::Filespec::vmsify($driver_xst_path);
    }

    q[
dbdimp.c Ingres.h : dbdimp.sc Ingres.sh
	$(ESQLC) $(ESQLCOPT) dbdimp.sc 

dbdimp.sc: dbdimp.psc
	$(PERL) -p -e "].$subst.q[" dbdimp.psc > dbdimp.sc

$(BASEEXT).xs: $(BASEEXT).xsi].($Is_VMS ? "\n\tcontinue" : "").q[

$(BASEEXT).c: $(BASEEXT).xsi

DBI_DRIVER_XST = ].$driver_xst_path.q[

$(BASEEXT).xsi: $(DBI_DRIVER_XST)
	$(PERL) -p -e "s/~DRIVER~/$(BASEEXT)/g" <$(DBI_DRIVER_XST) >$(BASEEXT).xsi
];
}


{   # If perl Makefile.PL *-g* then switch on debugging
    package MY; # SUPER needs package context, $self is not sufficient
    sub const_cccmd {
        my($self) = shift;
        local($_) = $self->SUPER::const_cccmd(@_);
        return $_ unless $::opt_g;
        if ($Is_VMS) {
            s!/[Oo][Pp][Tt][Ii]?[a-zA-Z]*!/NOOPTIMIZE/DEBUG!;
        } else {
            s/\s-O\d?\b/ -g/g;
        }
        $_;
    }
    sub dynamic_lib { # This affects only VMS
        my ($self) = shift;
        local($_) = $self->SUPER::dynamic_lib(@_);
        return $_ unless $Is_VMS;
        s!perlshr_attr.opt/Option!perlshr_attr.opt/Option,$linkopt!;
        $_;
    };

}

1;

