use strict;
use Test::Simple tests => 11;
use Class::Void;

sub is_empty_string($) {
	return 1 if shift eq "";
	return
}

my $null = Class::Void->bla->blub->foo->bar;

ok(is_empty_string($null), "basic tests for empty string behavior");

$null    = Class::Void->new;

ok(is_empty_string($null));

$null   += 14; 

ok(is_empty_string($null));

$null   /= 0;

ok(is_empty_string($null));

$null   = $null * 5 / 6 | 9 ^ 5;

ok(is_empty_string($null));

my $not_null   = "$null not empty";

$null   = ($null * 5 / 6 | 9 ^ 5)->test;

ok(is_empty_string($null)); 

ok($not_null, "concatenation");

$null    = $null->foo->bar;

ok(is_empty_string($null));


ok($null->isa("Class::Void"), "isa");

my $can = $null->can("whatever");

ok($can, "can");
ok(is_empty_string($can->()), "execute can return value");