#!perl
use strict;
use Test::More (tests => 8);
use Data::FormValidator;

BEGIN
{
    use_ok("Data::FormValidator::Constraints::Japanese");
}

my $dfv = Data::FormValidator->new('t/profile.pl');

my @ok = qw(
    123-4567
    1234567
);
my @bad = qw(
    1234
    fdsavae432-123
    12-4gasd
    12-34567
    123-abcd
);

for (@ok) {
    my $rv = $dfv->check({ zip => $_ }, 'zip');
    ok(! $rv->has_invalid && ! $rv->has_missing && ! $rv->has_unknown);
}

for (@bad) {
    my $rv = $dfv->check({ zip => $_ }, 'zip');
    ok($rv->has_invalid && ! $rv->has_missing && ! $rv->has_unknown);
}

1;