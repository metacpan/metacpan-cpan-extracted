#!perl
use strict;
use Test::More (tests => 5);
use Data::FormValidator;

BEGIN
{
    use_ok("Data::FormValidator::Constraints::Japanese", ":closures");
}

my $dfv = Data::FormValidator->new('t/profile.pl');
my $rv  = $dfv->check({ hiragana => "にほんご", katakana => "カタカナ" }, "basic");

ok(! $rv->has_invalid && ! $rv->has_missing && ! $rv->has_unknown, "valid");

$rv = $dfv->check({ hiragana => "にほんごうぃずだっしゅーーー" }, "basic");
ok(! $rv->has_invalid && ! $rv->has_missing && ! $rv->has_unknown, "valid");

$rv = $dfv->check({ hiragana => "日本語" }, "basic");
ok($rv->has_invalid && ! $rv->has_missing && ! $rv->has_unknown, "invalid and no missing");

$rv = $dfv->check({ katakana => "日本語" }, "basic");
ok($rv->has_invalid && ! $rv->has_missing && ! $rv->has_unknown, "invalid and no missing");


1;