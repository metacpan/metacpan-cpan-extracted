#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 6;

{
    package BadCompTest;
    use Bolts;

    artifact 'array' => (
        builder => sub { [ 1, 2, 3 ] },
    );

    artifact 'hash' => (
        builder => sub {
            {
                foo => 1,
                bar => 2,
                baz => 3,
            },
        },
    );
}

my $bag = BadCompTest->new;

my $v;
$v = eval { $bag->acquire('array', 'x') };
is($v, undef);
like($@, qr/\bno artifact indexed\b/);

$v = eval { $bag->acquire('array', 3) };
is($v, undef);
like($@, qr/\bno artifact indexed\b/);

$v = eval { $bag->acquire('hash', 'qux') };
is($v, undef);
like($@, qr/\bno artifact keyed\b/);
