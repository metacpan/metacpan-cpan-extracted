#!/usr/local/bin/perl -sw
# $Id: Makefile.PL,v 1.27 1995/08/26 17:39:01 timbo Rel $

use ExtUtils::MakeMaker qw(&WriteMakefile $Verbose %att);
use Getopt::Std;
use Config;
require 'flush.pl';

use DBI;	# The DBI must be installed before we can build a DBD

%opts = (
    'NAME'    => 'DBD::QBase',
    'VERSION' => '0.03',
);

# --- Introduction

print "\nConfiguring DBD::QBase version $opts{VERSION}...\n";
print "Remember to actually read the README file!\n\n";

# --- Where is Oracle installed...
unless ($ENV{QBase_HOME}){
    warn "\$QBase_HOME not defined. Searching for QBase...\n";
    foreach(qw(/LocalLibrary/QuickBase)){
	$ENV{QBase_HOME}=$_,last if -d "$_/Headers";
    }
    die "Unable to determine QBase_HOME" unless $ENV{QBase_HOME};
}
my $OH = $ENV{QBase_HOME};

print "Using QuickBase in $OH\n";


# --- What Oracle is installed...

die "Error: Can't determine QuickBase header.\n"
	unless -f "$OH/Headers/QuickBase.h";
die "Error: Can't determine QuickBase Library (assuming version 5.1)\n"
	 unless -f "$OH/lib/libQBSQL5_1.a";

# read list of libs that QuickBase require
$sysliblist ="-lMedia_s -lNeXT_s -lQBSQL5_1";
print "Oracle sysliblist: $sysliblist\n";

# Make sure that QuickBase setups up some flags
$MK{CFLAGS}   = "-ObjC";
$MK{LDFLAGS}  = "-ObjC";

$OCIINCLUDE = $MK{INCLUDE} || '';
$opts{LIBS} = [ $sysliblist ];
$opts{INC}  = "$OCIINCLUDE -I$Config{archlib}/DBI";
$opts{dynamic_lib} = { OTHERLDFLAGS => '-L$(LIBHOME) $(COMPOBJS) '.$linkwith };
$opts{OBJECT} = '$(O_FILES)';

# --- Handle special cases ---

$opts{DEFINE} = '-ObjC';


# Set some private WriteMakefile options if this is 'me' :-)
if ($ENV{LOGNAME} eq 'timbo' and $ENV{S_ARCH_SW}){  # a reasonable guess
    $Verbose = 1;
    $opts{INST_LIB}     = $Config{installprivlib};
    $opts{INST_ARCHLIB} = $Config{installarchlib};
}

# log key platform information to help me help you quickly
print "System: perl$] @Config{qw(myuname archname dlsrc)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";
print "  CC:        $MK{CC}\n"		if $MK{CC};
print "  CFLAGS:    $MK{CFLAGS}\n"	if $MK{CFLAGS};
print "  LDFLAGS:   $MK{LDFLAGS}\n"	if $MK{LDFLAGS};
print "  LDSTRING:  $MK{LDSTRING}\n"	if $MK{LDSTRING};

# Assorted hints - these should be move to a hints subdirectory

WriteMakefile(%opts);

exit 0;


sub MY::post_initialize{

    # Ensure Oraperl.pm is installed into the top lib dir
    $att{PM}->{'QBase.pm'} = '$(INST_LIB)/QBase.pm';

    # Add $linkwith to EXTRALIBS for those doing static linking
     $att{EXTRALIBS} .= " -L\$(LIBHOME) $linkwith";

	# default target for make's which don't understand '.SUFFIXES:'
	# (which appears as the first target).
    '
default_target: all
';
}


sub MY::post_constants{

    # Oracle Definitions, based on $(ORACLE_HOME)/proc/lib/proc.mk
    # for Oracle 7.0.x for SunOS 4 (Solaris 1)
    # Please let me know if this does, or does not, work for you.
    '
###################################################################
#
ORACLE_HOME = '.$ENV{ORACLE_HOME}.'

# The following text has been extracted from '.$oraclemk.'
#
'.$MK.'
#
# End of extract from '.$oraclemk.'
#
###################################################################
';
}


sub fetch_oci_macros {

    my $oraclemk = shift;
    # Read $oraclemk makefile, extract macro definitions from it
    # and store them in $MK, @MK and %MK.

    # Don't include the following definitions in the generated
    # makefile (note that %MK stills gets these values).
    my @edit = qw(SHELL CC CFLAGS ASFLAGS RCC LDFLAGS AR ECHO EXE OBJS);
    my %edit; @edit{@edit} = ('$_ = ""') x @edit;

    $edit{COMPOBJS} = q{
	    # Change the COMPOBJS line. (Some files use LIBHOME not COMPOBJ)
	    # old: $(COMPOBJ)/crti.o $(COMPOBJ)/crt1.o $(COMPOBJ)/__fstd.o
	    # new: $(COMPOBJ)/__fstd.o
	    s:\$\S+?/crt[1in]\.o\b::g;
	} if $Config{osname} eq 'solaris'; # and $Config{gccversion};

    my $mkver = 0;
    my $linkwith = '';
    my $lastline = '';
    open(ORACLEMK,"<$oraclemk") or die "open $oraclemk: $!\n";
    for(1; $_ = <ORACLEMK>; $lastline = $_){
	# Join split lines but retain backwack and newlines:
	$_ .= <ORACLEMK> while(m/\\[\r\n]+$/);
	chomp;
	push(@MK, '') if ($_ eq '' and $lastline ne '');
	next unless $_;
	last if m/^\w+\s*:/;	# gone too far, reached actual targets

	unless($MK{mkver}) {	# still need to get version number
	    # This is tough since some versions of proc.mk split the
	    # RCS header over three lines! Well that's Oracle for you.
	    my $line = $_;
	    $line =~ s/[\\\r\n]/ /g;
	    $MK{mkver} = $mkver = $1
		if $line =~ m/\$Header:.*?\.mk.+(\d+\.\d+)/;
	}

	# We always store values into %MK before checking %edit
	$MK{$1} = $2 if m/^\s*(\w+)\s*=\s*(.*)/;

	next if m/^\s*\.SUFFIXES/;

	if ($1 and exists $edit{$1}) {
	    my $name = $1;
	    eval $edit{$name};	# execute code to edit $_
	    warn "Edit $name ($edit{$name}) failed: $@\n" if $@;
	}

	push(@MK, $_);

	# have we seen enough now?	( this caused problems)
	# last if ($MK{OCILDLIBS} or (int($mkver)==1 and $MK{TTLIBS}));
    }
    close(ORACLEMK);

    if ($MK{OCILDLIBS}) {
	$linkwith = '$(OCILDLIBS)';

    } elsif (int($mkver) == 1) {
	if ($MK{LLIBOCIC}) {
	    $linkwith = '$(LLIBOCIC) $(TTLIBS)';
	} else {
	    $linkwith = '-locic $(TTLIBS)';	# XXX GUESS HACK
	}
    }
    unless ($linkwith){
	warn "ERROR parsing $oraclemk (version '$MK{mkver}'):\n";
	warn "\tUnable to determine what to link with.\n";
    }
    $MK = join("\n", @MK);
    $linkwith;
}


sub ask {
    my($prompt, $default) = @_;
	printflush(STDOUT,"$prompt: ");
	printflush(STDOUT,"[$default] ") if $default;
    my $value = <>;
	chomp $value;
	return $value or $default;
}


# ---------------------------------------------------------------


sub MY::dist {		# new name with 5.001e
    '
DISTFILES=RCS/*

ci:
	-ci -u $(DISTFILES) 2>&1 | grep -v "no lock set by "
	-rcs -q -Nv`echo "$(VERSION)" | tr . _`: $(DISTFILES)

rcsdiff:
	for f in $(DISTFILES); do rcsdiff -r$(V) $$f; done 2>&1 | less

dist:  ci clean
	rcs -q -sRel $(DISTFILES)
	co -q -u     $(DISTFILES)
	rm -f Makefile *~ t/*~
	cd ..; tar cvFf $(DISTNAME)-$(VERSION).tar \
		`sed -e "s:^:$(BASEEXT)/:" < $(BASEEXT)/MANIFEST`
	@cd ..; compress $(DISTNAME)-$(VERSION).tar;
	@chmod -w ../$(DISTNAME)-$(VERSION).tar.Z
	mv ../$(DISTNAME)-$(VERSION).tar.Z $$HOME/perl/db/DBD/QBase/
	cp README $$HOME/perl/db/DBD/QBase/
	@cd $$HOME/perl/db/DBD/QBase; pwd; ls -l *.Z
';
}

*{"MY::distclean"} = \&MY::dist;	# remain compatible with 5.001

__END__
