# -*- perl -*-

require 5.008;
use strict;
require ExtUtils::MakeMaker;

eval { require 5.008; } or die << 'EOD';
#######################################
#	This module requires a minimum Perl version of 5.8.0
#	Please upgrade!
#######################################
EOD

print "\nConfiguring DBIx::Threaded ...\n
>>>\tRemember to actually *READ* the README file!
   \tAnd re-read it if you have any problems.\n
";

my %prereq;
my %opts =
    ('NAME' => 'DBIx::Threaded',
     'VERSION_FROM' => 'lib/DBIx/Threaded.pm',
     'dist'         => { 
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf' }
     );

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'AUTHOR'} = 'Presicient Corp. (info@presicient.com)';
    $opts{'ABSTRACT'} = 'DBI subclass to share DBI objects between threads';
    $opts{'PREREQ_PM'} = \%prereq;
}

my $ok = 1;
$ok &= CheckModule('DBI', '1.48');
$ok &= CheckModule('Thread::Queue::Duplex', '0.12');

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
    "\nREADME: lib/DBIx/Threaded.pm" .
    "\n\tperldoc -t lib/DBIx/Threaded.pm >README\n\n"
}

sub libscan {
    my($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
}
