# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;
use warnings;
# use Test::More qw(no_plan);
use Test::More;
BEGIN {
	eval { use Cv -nomore };
	eval { require XSLoader; XSLoader::load('Cv::t', $Cv::VERSION) };
	plan skip_all => "no Cv/t.so" if $@;
	plan tests => 6;
}
use Test::Exception;
BEGIN { use_ok('Cv', -nomore) }

my @intPtr = map { int rand 65536 } 1 .. 100;

if (1) {
	{
		my $intPtr = Cv::intPtr(\@intPtr);
		is_deeply($intPtr, \@intPtr);
	}

	throws_ok { Cv::intPtr({}) } qr/values is not of type int \* in Cv::intPtr at $0/;

	{
		use warnings FATAL => qw(all);
		throws_ok { Cv::intPtr(['1x']) } qr/Argument \"1x\" isn't numeric in subroutine entry at $0/;
	}

	{
		no warnings 'numeric';
		my $x; lives_ok { $x = Cv::intPtr([1, '2x', 3]) };
		is_deeply($x, [1, 2, 3]);
	}
}
