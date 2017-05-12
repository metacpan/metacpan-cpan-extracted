#!/usr/bin/env perl
use strict;
use warnings;
use feature ':5.10';

use Test::More tests => 2;
use DataExtract::FixedWidth;

{
	eval {
		my $de = DataExtract::FixedWidth->new({
			cols => [qw/foo bar baz/]
		});
	};
	like ( $@, qr/You must.*header_row/, 'cols only');
	undef $@;
}

{
	eval {
		my $de = DataExtract::FixedWidth->new;
	};
	say "bar $@";
	like ( $@, qr/You must/, 'nothing only');
}

