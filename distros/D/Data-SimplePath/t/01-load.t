#!/usr/bin/perl -T

use strict;
use warnings;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	plan ('tests' => 3);
}

BEGIN {
	use_ok ('Data::SimplePath', '0.005');
}

is   ($Data::SimplePath::VERSION, '0.005', '$Data::SimplePath::VERSION ok');
diag ("Testing Data::SimplePath $Data::SimplePath::VERSION, Perl $], $^X");
