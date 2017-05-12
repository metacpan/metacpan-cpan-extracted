# -*- perl -*-

require 5.6.0;
use strict;
use vars qw($DBI_INC_DIR);
require ExtUtils::MakeMaker;

eval { require 5.6.0 } or die << 'EOD';
#######################################
#	This module requires a minimum Perl version of 5.6.0
#	Please upgrade!
#######################################
EOD

print "\nConfiguring DBD::Chart ...\n
>>>\tRemember to actually *READ* the README file!
   \tAnd re-read it if you have any problems.\n
";

my %prereq;
my %opts =
    ('NAME' => 'DBD::Chart',
     'VERSION_FROM' => 'Chart.pm',
     'dist'         => { 
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf' }
     );

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'AUTHOR'} = 'Dean Arnold (darnold@presicient.com)';
    $opts{'ABSTRACT'} = 'Chart driver for DBI module';
    $opts{'PREREQ_PM'} = \%prereq;
}
my $ok = 1;
$ok &&= CheckModule('DBI', '1.13');
$ok &&= CheckModule('GD', '1.13');
$ok &&= CheckModule('GD::Text', '0.80');

if (!$ok) {
    print("\n",
	  "Missing modules are available from any CPAN mirror, for example\n",
	  "\tftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/by-module\n",
	  "\n");
}

&check_DBI();
ExtUtils::MakeMaker::WriteMakefile(%opts);

sub check_DBI {
    my $dir;
    eval { require DBI::DBD };
    foreach $dir (@INC) {
        if (-f "$dir/auto/DBI/DBIXS.h") {
  	    $DBI_INC_DIR = "-I$dir/auto/DBI";
	    last;
        }
     }
    if (!defined($DBI_INC_DIR)) {
        print "Unable to locate auto/DBI/DBIXS.h in the following directories:\n";
        print "\n";
        foreach $dir (@INC) {
    	    print "    $dir\n";
        }
        print "\nDoesn't look like a correct DBI installation.\n";
        $ok = 0;
    }
    if (!$ok) {
        exit(0);
    }
}

sub CheckModule ($$;$) {
    my($module, $version, $package) = @_;
    $package ||= $module;
    $prereq{$module} = $version || 0;
    if ($version) {
		print "Checking for $package, $version or later ... ";
		eval "use $module $version";
		if ($@) {
		    print("\nYou don't have the $package package",
			  " version $version or later, installed.\n");
		    return 0;
		}
    } else {
		print "Checking for $package ... ";
		eval "use $module";
		if ($@) {
		    print("\nYou don't have the $package package installed.\n");
		    return 0;
		}
    }
    print "ok\n";
    return 1;
}

package MY;

sub postamble {
    "\npm_to_blib: README\n" .
    "\nREADME: Chart.pm" .
    "\n\tperldoc -t Chart.pm >README\n\n"
}


sub libscan {
    my($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
}
