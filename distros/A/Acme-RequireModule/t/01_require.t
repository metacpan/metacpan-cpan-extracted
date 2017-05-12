#!perl -w

use strict;
use Test::More tests => 5;

{
	use Acme::RequireModule;

	my $mod = 'integer';

	require $mod;

	ok $INC{'integer.pm'}, 'inside the scope';

	is $mod, 'integer';

	require 'Text::Abbrev';
	ok($INC{'Text/Abbrev.pm'});

	eval{
		require 'Yes::We::Can';
	};
	ok $@;
}

eval{
	require 'Math::Trig';
};
ok $@, 'outside the scope';