# -*- perl -*-

require 5.004;
use strict;
use vars qw($DBI_INC_DIR);
require ExtUtils::MakeMaker;
my %prereq;
my %opts =
    ('NAME' => 'DBD::RAM',
     'VERSION_FROM' => 'RAM.pm',
     'dist'         => { 'SUFFIX'       => ".gz",
			 'DIST_DEFAULT' => 'all tardist',
			 'COMPRESS'     => "gzip -9vf" }
     );
if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'AUTHOR'} = 'Jeff Zucker (jeff@vpservices.com)';
    $opts{'PREREQ_PM'} = \%prereq;
}
my $ok = 1;
$ok &&= CheckModule('DBI', '1.00');
$ok &&= CheckModule('DBD::File');
$ok &&= CheckModule('SQL::Statement', '0.1011');
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
	    print("\nYou don't have installed the $package package,",
		  " version $version or later.\n");
	    return 0;
	}
    } else {
	print "Checking for $package ... ";
	eval "use $module";
	if ($@) {
	    print("\nYou don't have installed the $package package.\n");
	    return 0;
	}
    }
    print "ok\n";
    return 1;
}

package MY;

sub postamble {
    "\npm_to_blib: README\n" .
    "\nREADME: RAM.pm" .
    "\n\tperldoc -t RAM.pm >README\n\n"
}

sub libscan {
    my($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
}

=head1 ORIGINAL FROM h2xs

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'DBD::RAM',
    'VERSION_FROM' => 'RAM.pm', # finds $VERSION
);

=cut






