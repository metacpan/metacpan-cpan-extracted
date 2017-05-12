use warnings;
use strict;

use Test::More tests => 50;

BEGIN { use_ok "Class::Mix", qw(mix_class); }

{ package Foo; }
{ package Bar; }
{ package Baz; }
{ package Quux::Wibble; }

# error cases
foreach(
	[],
	{foo=>1},
	{prefix=>"1"},
) {
	eval { mix_class($_) };
	isnt $@, "";
	eval { mix_class("Foo", $_) };
	isnt $@, "";
}

# trivial cases
is(mix_class(), "UNIVERSAL");
is(mix_class("Foo"), "Foo");
is(mix_class("Quux::Wibble"), "Quux::Wibble");

# basic mixing cases
no strict "refs";
my $foobar = mix_class("Foo", "Bar");
is_deeply(\@{$foobar."::ISA"}, ["Foo", "Bar"]);
ok($foobar->isa("Foo"));
ok($foobar->isa("Bar"));
ok(!$foobar->isa("Baz"));
my $barfoo = mix_class("Bar", "Foo");
is_deeply(\@{$barfoo."::ISA"}, ["Bar", "Foo"]);
ok($barfoo->isa("Foo"));
ok($barfoo->isa("Bar"));
ok(!$barfoo->isa("Baz"));

# with blank options
is mix_class({}), "UNIVERSAL";
is mix_class({}, "Foo"), "Foo";
is mix_class("Foo", {}), "Foo";
is mix_class({}, "Foo", "Bar"), $foobar;
is mix_class("Foo", {}, "Bar"), $foobar;
is mix_class("Foo", "Bar", {}), $foobar;

# with blank prefix
my $u_u = mix_class({ prefix=>"" });
is $u_u, "UNIVERSAL";
my $u_foo = mix_class({ prefix=>"" }, "Foo");
is $u_foo, "Foo";
my $u_foobar = mix_class("Foo", "Bar", { prefix=>"" });
like $u_foobar, qr/\A[^:]+\z/;
is_deeply(\@{$u_foobar."::ISA"}, ["Foo", "Bar"]);
my $u_wibble = mix_class("Quux::Wibble", { prefix=>"" });
like $u_wibble, qr/\A[^:]+\z/;
is_deeply(\@{$u_wibble."::ISA"}, ["Quux::Wibble"]);

# with non-blank prefix
my $quux_u = mix_class({ prefix=>"Quux::" });
like $quux_u, qr/\AQuux::[^:]+\z/;
is_deeply(\@{$quux_u."::ISA"}, []);
my $quux_foo = mix_class({ prefix=>"Quux::" }, "Foo");
like $quux_foo, qr/\AQuux::[^:]+\z/;
is_deeply(\@{$quux_foo."::ISA"}, ["Foo"]);
my $quux_foobar = mix_class("Foo", "Bar", { prefix=>"Quux::" });
like $quux_foobar, qr/\AQuux::[^:]+\z/;
is_deeply(\@{$quux_foobar."::ISA"}, ["Foo", "Bar"]);
my $quux_wibble = mix_class("Quux::Wibble", { prefix=>"Quux::" });
is $quux_wibble, "Quux::Wibble";

# consistency of results
is(mix_class(), "UNIVERSAL");
is(mix_class("Foo"), "Foo");
is(mix_class("Quux::Wibble"), "Quux::Wibble");
is(mix_class("Foo", "Bar"), $foobar);
is(mix_class("Bar", "Foo"), $barfoo);
is(mix_class({ prefix=>"" }), $u_u);
is(mix_class("Foo", { prefix=>"" }), $u_foo);
is(mix_class("Foo", { prefix=>"" }, "Bar"), $u_foobar);
is(mix_class("Quux::Wibble", { prefix=>"" }), $u_wibble);
is(mix_class({ prefix=>"Quux::" }), $quux_u);
is(mix_class("Foo", { prefix=>"Quux::" }), $quux_foo);
is(mix_class({ prefix=>"Quux::" }, "Foo", "Bar"), $quux_foobar);
is(mix_class("Quux::Wibble", { prefix=>"Quux::" }), $quux_wibble);

1;
