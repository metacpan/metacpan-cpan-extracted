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

use App::plockf;

my $plockf = "$FindBin::RealBin/../blib/script/plockf";
unless (-f $plockf) {
    # blib version not available, use ../bin source version
    $plockf = "$FindBin::RealBin/../bin/plockf";
}

my($script_version) = `$plockf --version` =~ m{version\s+(\S+)};

is $script_version, $App::plockf::VERSION, 'Script and module version are the same';

__END__
