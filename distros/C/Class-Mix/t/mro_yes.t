use warnings;
use strict;

BEGIN {
	if("$]" < 5.009005) {
		require Test::More;
		Test::More::plan(skip_all => "MRO not available on this Perl");
	}
}

use Test::More tests => 35;

BEGIN { use_ok "Class::Mix", qw(mix_class); }

{ package Foo; }
{ package Bar; use mro "dfs"; }
{ package Baz; use mro "c3"; }

# error cases
foreach(
	{mro=>[]},
	{mro=>undef},
	{mro=>"wibble"},
) {
	eval { mix_class($_) };
	isnt $@, "";
	eval { mix_class("Foo", $_) };
	isnt $@, "";
	eval { mix_class("Foo", "Bar", $_) };
	isnt $@, "";
}

# dfs cases
no strict "refs";
my $dfs_u = mix_class({mro=>"dfs"});
is $dfs_u, "UNIVERSAL";
is mro::get_mro($dfs_u), "dfs";
my $dfs_foo = mix_class("Foo", {mro=>"dfs"});
is $dfs_foo, "Foo";
is mro::get_mro($dfs_foo), "dfs";
my $dfs_bar = mix_class("Bar", {mro=>"dfs"});
is $dfs_bar, "Bar";
is mro::get_mro($dfs_bar), "dfs";
my $dfs_baz = mix_class("Baz", {mro=>"dfs"});
is_deeply(\@{$dfs_baz."::ISA"}, ["Baz"]);
is mro::get_mro($dfs_baz), "dfs";
my $dfs_foobar = mix_class("Foo", "Bar", {mro=>"dfs"});
is_deeply(\@{$dfs_foobar."::ISA"}, ["Foo", "Bar"]);
is mro::get_mro($dfs_foobar), "dfs";

# default cases must be consistent with dfs
is mix_class(), $dfs_u;
is mix_class("Foo"), $dfs_foo;
is mix_class("Bar"), $dfs_bar;
is mix_class("Baz"), $dfs_baz;
is mix_class("Foo", "Bar"), $dfs_foobar;

# c3 cases
my $c3_u = mix_class({mro=>"c3"});
is_deeply(\@{$c3_u."::ISA"}, []);
is mro::get_mro($c3_u), "c3";
my $c3_foo = mix_class("Foo", {mro=>"c3"});
is_deeply(\@{$c3_foo."::ISA"}, ["Foo"]);
is mro::get_mro($c3_foo), "c3";
my $c3_bar = mix_class("Bar", {mro=>"c3"});
is_deeply(\@{$c3_bar."::ISA"}, ["Bar"]);
is mro::get_mro($c3_bar), "c3";
my $c3_baz = mix_class("Baz", {mro=>"c3"});
is $c3_baz, "Baz";
is mro::get_mro($c3_baz), "c3";
my $c3_foobar = mix_class("Foo", "Bar", {mro=>"c3"});
is_deeply(\@{$c3_foobar."::ISA"}, ["Foo", "Bar"]);
is mro::get_mro($c3_foobar), "c3";

1;
