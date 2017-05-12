#!perl
use strict;
use Test::More (tests => 4);
use Data::FormValidator;

BEGIN
{
    use_ok("Data::FormValidator::Constraints::Japanese");
}

my $dfv = Data::FormValidator->new('t/profile.pl');

my @inputs = (
    { text => "ほげほげほげ",     ok => 1 },
    { text => "ほげほげほげほげ", ok => 0 },
    { text => "げほげ",           ok => 0 },
);

for (@inputs) {
    my $rv = $dfv->check({ text => $_->{text} }, 'length');

    if ($_->{ok}) {
        ok(! $rv->has_invalid && ! $rv->has_missing && ! $rv->has_unknown, "$_->{text} should pass");
    } else {
        ok($rv->has_invalid && ! $rv->has_missing && ! $rv->has_unknown, "$_->{text} should fail");
    }
}

1;