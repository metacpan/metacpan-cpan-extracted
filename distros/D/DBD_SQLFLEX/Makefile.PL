#!/usr/bin/perl -sw
#
# @(#)$Id: Makefile.PL,v 58.16 1998/01/15 19:53:07 johnl Exp $ 
#
# Portions Copyright (c) 1996-98 Jonathan Leffler
# Portions Copyright (c) 1996    Alligator Descartes
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

#TABSTOP=4

# A sufficiently recent version of Perl and DBI must be installed before we
# can build the DBD module.  The code in DBD::Sqlflex needs the features
# present in Perl 5.004 and DBI 0.90.
use 5.004;
use ExtUtils::MakeMaker qw(&WriteMakefile $Verbose);
use Config;
use strict;
use DBI 0.90;
use DBI::DBD;

# Configure for Unix vs Windows 95/NT
my $objext = $Config{obj_ext};
my $split = $Config{path_sep};
my $NTConfiguration = $Config{archname} eq 'MSWin32';

if ($NTConfiguration)
{
	# NT configuration...
	print q[
	This is a semi-experimental version of Makefile.PL with Win32 (NT)
	support.  This version has been tested on NT, but there could still
	be bugs in it.  Please help save the world by trying to debug the
	NT code and report the results back to the DBI Users mail list.

	Thanks!
	]
}

$| = 1;     # Ensure that Perl output is interleaved with test output.

my %opts = (
    NAME         => 'DBD::Sqlflex',
    VERSION_FROM => 'Sqlflex.pm',
    clean        => { FILES        => 'Sqlflex.xsi' },
    dist         => { DIST_DEFAULT => 'clean distcheck disttest tardist',
                      PREOP        => '$(MAKE) -f Makefile.old distdir',
                      COMPRESS     => 'gzip',
                      SUFFIX       => 'gz'
                    }
           );

$opts{PM}->{"$ENV{SQLDIR}/src/misc/sqlmsg.flx"} = '$(INST_LIBDIR)/sqlmsg.flx';
$opts{PM}->{"Sqlflex.pm"} = '$(INST_LIBDIR)/Sqlflex.pm';
$opts{PM}->{"SqlflexTest.pm"} = '$(INST_LIBDIR)/SqlflexTest.pm';

my $dbd_ix = &version_info($opts{VERSION_FROM});
print "\nConfiguring $opts{NAME} version $dbd_ix...\n";
print "\tYou are using DBI version $DBI::VERSION and Perl version $]\n";
print "Remember to actually read the README file!\n\n";

did_not_read("Perl is out of date") unless ($] >= 5.004);
did_not_read("DBI is out of date") unless ($DBI::VERSION >= 0.90);

# Compare installed version of DBI with version which DBD::Sqlflex was
# last tested with.
# The required and reference versions are different for this release.

my $dbi_ref_ver = "0.91";
warn "*** Ideally, you should upgrade to DBI version $dbi_ref_ver.\n\n"
	unless ($DBI::VERSION >= $dbi_ref_ver);

my ($ID) = find_sqldir();

# --- Check whether Sqlflex is installed OK for us.
my $warning = qq{
  Beware: $opts{NAME} is not yet aware of the new IUS data types.
  It will work with traditional data types, but will fail badly
  on any data types which were not in earlier versions of OnLine.
};

my $multiconn = 1;
$multiconn = 0;
if ($NTConfiguration)
{
   $opts{DEFINE} .= " -DWINNT -Dfar=";
}

# -- Configure the make process

$opts{INC} = " ";

# Add extra definitions to compile the code under GCC if DBD_GCC_DEBUG set.
# Perl configuration headers contain lots of /* inside comments (-Wno-comment)

#$opts{DEFINE} .= ' -Wall -pedantic -Wno-comment -Wpointer-arith -Wcast-align'
#           . ' -Wconversion -Wtraditional -Wcast-qual'
$opts{DEFINE} .= ' -Wall -pedantic -Wno-comment'
        if $Config{cc} eq 'gcc' and $ENV{DBD_GCC_DEBUG};

# Ensure that __STDC__ is defined under CenterLine CC
$opts{DEFINE} .= ' -Xa'
        if $Config{cc} eq 'clcc';

# We need to add -Ae on HP-UX to ensure that prototypes are accepted,
# but only if using the native HP-UX compiler (GCC does not accept -Ae,
# for example).
$opts{DEFINE} .= " -Ae"
        if $Config{osname} eq "hpux" and $Config{ccflags} !~ /-A[ea]/ and
                $Config{cc} eq 'cc';

# Extra definitions under Alpha cc to get __STDC__ defined
$opts{DEFINE} .= ' -std1'
        if (($Config{cc} eq 'cc') && ($Config{osname} eq 'dec_osf'));

# Ensure that __STDC__ is defined for SUNWspro compilers on Solaris.
$opts{DEFINE} .= ' -Xa'
        if ($Config{osname} eq 'solaris' and &which($Config{cc}) =~ m%/SUNWspro/%);

if ($Config{"prototype"} ne 'define')
{
	print "\nGosh!  Perl doesn't think your compiler handles prototypes.\n";
	print "Well, even though I don't believe it, we'll take Perl's word\n";
	print "for it and we won't try to force them into use.\n";
	print "Don't you need to upgrade your compiler?\n";
}

my $objects = "Sqlflex.o dbdimp.o dbdattr.o sqltype.o odbctype.o decsci.o link.o";
# Map object file names on non-Unix platforms
$objects =~ s/\.o\w/$objext/g if ($objext ne ".o");

# Need to pick up the DBI headers.
# Prior to DBI-0.77, the /auto sub-directory in $INC1 was not used.
my $INC1 = "-I\$(INSTALLSITEARCH)/auto/DBI";

$opts{INC} .= " $INC1 ";
$opts{OBJECT} = $objects;

# Default version of $opts{LD}
$opts{LD} = "sqlld \$(LDDLFLAGS)";
$opts{CC} = "sqlcc";

my $esql_nt;
if ($NTConfiguration)
{
	# NT configuration
	$esql_nt = "-cc";	# Not sure what this does; ask Harold.
	my $libs=" ISQLI501.LIB LMCSQLW.LIB ";
	$opts{dynamic_lib} = { OTHERLDFLAGS => "/LIBPATH:$ID/lib $libs"};
}
elsif ($Config{ld} !~ /cc$/ && $Config{ld} ne $Config{cc})
{
	# Unix configuration (awkward squad subset of Unix configurations)
	print qq{
	Uh oh!  We're on a machine which does not use the C compiler to
	create shared libraries.  Please consider recompiling Perl using
	the C compiler to create shared libraries; it makes life easier for
	everyone!
	};
	print "Unfortunately, you are also using a version of ESQL/C which\n";
	print "cannot tell us which libraries it needs.\n";
	print "We'll assume that esqlld can sort things out for you.\n";
	print "Contact the $opts{NAME} maintenance team if it doesn't.\n";
	# Do not override default version of $opts{LD}
	print "\n";
}

# log key platform information to help me help you quickly
print "Perl:     perl$] @Config{qw(archname dlsrc)}\n";
print "System:   @Config{qw(myuname)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";
print "Loader:   $Config{ld}\n"
        if ($Config{ld} !~ /cc$/ && $Config{ld} ne $Config{cc});



# Assorted hints - these should be move to a hints subdirectory.
print "\nSee notes about SPARCompiler on Solaris in hints/solaris\n"
	if ($Config{osname} eq 'solaris' and &which($Config{cc}) =~ m%/SUNWspro/%);
print "\n";

# Probably cause for being thrown out of The Perl Institute, but TMTOWTDI!
system "perl t/dtgen.pl > t/dtgen.sql";
system "perl t/decgen.pl > t/decgen.sql";

WriteMakefile(%opts);

# Cleanly exit from the Makefile-build process

exit 0;

sub find_sqldir
{
	my ($ID);
	if ($NTConfiguration)
	{
		# NT configuration
		print "Using SQLDIR=?????\n";
	}
	else
	{
		# Unix configuration
		$ID = $ENV{SQLDIR};
		did_not_read('$SQLDIR is not set') unless ($ID);
		did_not_read('$SQLDIR/bin is not in $PATH')
			unless ($ENV{PATH} =~ m%:$ID/bin:% ||
					$ENV{PATH} =~ m%^$ID/bin:% ||
					$ENV{PATH} =~ m%:$ID/bin$%);
	}
	return $ID;
}

# Extract the version number from Sqlflex.pm.
# It may need to handle single quotes as well as double quotes around the
# version number to be fully general.  If there's a better way to do this,
# I want to be told, please.
sub version_info
{
	my ($file) = @_;
	open(PMFILE, $file) || die;
	while (<PMFILE>)
	{
		if (/\$VERSION\s*=\s*"([^"]+)"\s*;/)
		{
			close PMFILE;
			return $1;
		}
	}
	close PMFILE;
	return "<<ERROR - no VERSION in $file>>";
}

sub did_not_read
{
	my ($reason) = @_;
	die "\n*** You didn't read the README file!\n$reason\n\n";
}

# which: report the name of an executable command.
sub which
{
	my ($cmd, $path) = @_;
	my ($dir, $name);
	$path = $ENV{PATH} if (!$path);
	my @path = split /$split/, $path;
	for $dir (@path)
	{
		$dir = '.' if (!$dir);
		$name = $dir . "/" . $cmd;
		return $name if -x $name;
	}
	return "";
}

sub MY::postamble 
{
   my ($p1);
   # Standardised code to generate Sqlflex.xs from Sqflex.xsi and the
   # template from DBI (Driver.xst).  dbd_postamble() is defined by DBI::DBD.
   $p1 = dbd_postamble();

   return $p1;
}
__END__
