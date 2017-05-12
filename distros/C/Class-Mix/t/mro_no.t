use warnings;
use strict;

BEGIN {
	if("$]" >= 5.009005) {
		require Test::More;
		Test::More::plan(skip_all => "MRO available on this Perl");
	}
}

use Test::More tests => 18;

BEGIN { use_ok "Class::Mix", qw(mix_class); }

{ package Foo; }
{ package Bar; }
{ package Baz; }

# error cases
foreach(
	{mro=>[]},
	{mro=>undef},
	{mro=>"wibble"},
	{mro=>"c3"},
) {
	eval { mix_class($_) };
	isnt $@, "";
	eval { mix_class("Foo", $_) };
	isnt $@, "";
	eval { mix_class("Foo", "Bar", $_) };
	isnt $@, "";
}

# OK cases
no strict "refs";
is mix_class({mro=>"dfs"}), "UNIVERSAL";
is mix_class("Foo", {mro=>"dfs"}), "Foo";
my $foobar = mix_class("Foo", "Bar", {mro=>"dfs"});
is_deeply(\@{$foobar."::ISA"}, ["Foo", "Bar"]);
is mix_class({mro=>"dfs"}, "Foo", "Bar"), $foobar;
is mix_class("Foo", "Bar"), $foobar;

1;
