# -*- perl -*-

require 5.8.0;
use strict;
use vars qw($DBI_INC_DIR);
require ExtUtils::MakeMaker;

eval { require 5.8.0 } or die << 'EOD';
#######################################
#	This module requires a minimum Perl version of 5.8.0
#	Please upgrade!
#######################################
EOD

print "

 *** Configuring DBD::Teradata (feature-limited free edition)...

";

my ($inc, $libs, $defines) = ('','','');

if ($^O eq 'MSWin32') {
#
#	user must set the TDAT_DBD_CLI_LIB environment variable
#	first time they install on windows (or on re-install)
#	we'll default to common location
#
	$ENV{TDAT_DBD_CLI_LIB} = 'C:\\PROGRA~1\\NCR\\TERADA~1\\cli\\lib'
		unless defined($ENV{TDAT_DBD_CLI_LIB});

	$ENV{TDAT_DBD_CLI_INC} = 'C:\\PROGRA~1\\NCR\\TERADA~1\\cli\\inc'
		unless defined($ENV{TDAT_DBD_CLI_INC});

	$inc = '-I' . $ENV{TDAT_DBD_CLI_INC};
	if ((-e "$ENV{SystemRoot}\\System32\\wincli32.dll") &&
		(-e "$ENV{TDAT_DBD_CLI_LIB}\\wincli32.lib")) {
		$libs .= "-L$ENV{TDAT_DBD_CLI_LIB} -lwincli32";
#		print $libs, "\n";
		foreach ('tdusr32', 'localisation', 'tdgss', 'terasso') {
			$libs .= " -l$_"
				if -e "$ENV{SystemRoot}\\System32\\$_.dll";
		}
	}
}
else {
#
#	how do we pick where the libs are installed ? for now assume /usr/lib
#
	my $libdir = $ENV{TDAT_DBD_CLI_LIB} ||= '/usr/lib';
	$inc = '-I' . $ENV{TDAT_DBD_CLI_INC}
		if defined($ENV{TDAT_DBD_CLI_INC});
	$defines = '-D__error_t_defined=1';
	if (-e "$libdir/libcliv2.so") {
		$libs .= "-L$libdir -lcliv2 -lnet -lsocket -lresolv";

		foreach ('tdusr', 'tdgss') {
			$libs .= " -l$_.so"
				if -e "$libdir/lib$_.so";
		}
	}
}

print "
***************************************************************
*
*	!!!NOTE TO INSTALLERS!!!
*
*	DBD::Teradata will be built using the following
*	directives:
*	Libraries: $libs
*	Include files: $inc
*	Compile flags: $defines
*
*	If your CLI2 libraries and/or include files are in another
*	location, please update the TDAT_DBD_CLI_LIB and
*	TDAT_DBD_CLI_INC environment variables before running
*	Makefile.PL.
*
***************************************************************

";

my %opts = (
	'NAME' => 'DBD::Teradata',
	'VERSION_FROM' => 'lib/DBD/Teradata.pm',
	'dist'         => {
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf'
	 },

    'AUTHOR' => 'Dean Arnold (darnold@presicient.com)',
    'ABSTRACT' => 'Perl DBI driver for Teradata',
    'PREREQ_PM' => {},
    'LIBS' => $libs,
    'INC' => $inc,
    'CCFLAGS' => $defines
);


my $ok = 1;
my $failed = undef;

$ok = undef,
$failed = 1
	unless CheckModule('DBI', '1.40');

$ok = undef,
print '

	DECIMAL values will be converted via floating point arithmetic.
	Math::BigInt may be installed for more accurate conversions.

'
	unless CheckModule('Math::BigInt', '1.73');

print '

	Missing modules are available from any CPAN mirror, e.g.,
	http://search.cpan.org/

'
	unless $ok;

&check_DBI();

exit(0) if $failed;

ExtUtils::MakeMaker::WriteMakefile(%opts);

sub check_DBI {
    eval { require DBI::DBD };
    foreach (@INC) {
  	    $DBI_INC_DIR = "-I$_/auto/DBI",
	    last
        	if -f "$_/auto/DBI/DBIXS.h";
    }
    unless (defined($DBI_INC_DIR)) {
        print "Unable to locate auto/DBI/DBIXS.h in the following directories:\n\n";
   	    print "    $_\n"
        	foreach (@INC);

        print "\nDoesn't look like a correct DBI installation.\n";
        $ok = 0;
    }
	exit(0)
    	unless $ok;
}

sub CheckModule ($$;$) {
    my($module, $version, $package) = @_;
    $package ||= $module;
    if ($version) {
		print "Checking for $package, $version or later ... ";
		eval "use $module $version";
	    print "\nYou don't have the $package package version $version or later, installed.\n" and
	    return 0
			if $@;
    }
    else {
		print "Checking for $package ... ";
		eval "use $module";
		print "\nYou don't have the $package package installed.\n" and
		return 0
			if $@;
    }
    print "ok\n";
    return 1;
}

