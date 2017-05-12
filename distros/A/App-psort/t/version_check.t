#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip no Test::More module\n";
	exit;
    }
}

plan tests => 1;

use App::psort;

my $use_blib = 1;
my $psort = "$FindBin::RealBin/../blib/script/psort";
unless (-f $psort) {
    # blib version not available, use ../bin source version
    $psort = "$FindBin::RealBin/../bin/psort";
    $use_blib = 0;
}

my($script_version) = `$psort --version` =~ m{version\s+(\S+)};

is $script_version, $App::psort::VERSION, 'Script and module version are the same';

__END__
