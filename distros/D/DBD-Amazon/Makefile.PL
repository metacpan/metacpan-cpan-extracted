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

print "\nConfiguring DBD::Amazon ...\n
>>>\tRemember to actually *READ* the README file!
   \tAnd re-read it if you have any problems.\n
";

my %prereq;
my %opts =
    ('NAME' => 'DBD::Amazon',
     'VERSION_FROM' => 'lib/DBD/Amazon.pm',
     'dist'         => { 
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf' }
     );

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'AUTHOR'} = 'Presicient Corp. (info@presicient.com)';
    $opts{'ABSTRACT'} = 'Perl DBI driver Abstraction for the Amazon E-Commerce Services';
    $opts{'PREREQ_PM'} = \%prereq;
}

my $ok = 1;
$ok &&= CheckModule('DBI', '1.42');
$ok &&= CheckModule('XML::Simple', '1.13');
$ok &&= CheckModule('SQL::Statement', '1.14');
$ok &&= CheckModule('Clone', '0.15');

if (!$ok) {
    print("\n",
	  "Missing modules are available from CPAN (search.cpan.org)\n",
	  "\n");
}

ExtUtils::MakeMaker::WriteMakefile(%opts);

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
    "\nREADME: lib/DBD/Amazon.pm" .
    "\n\tperldoc -t lib/DBD/Amazon.pm >README\n\n"
}

sub libscan {
    my($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
}
