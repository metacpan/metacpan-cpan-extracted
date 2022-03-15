#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;
use Test::Deep;

use File::Temp;

use DNS::Unbound;

my $dns = DNS::Unbound->new();

$dns->resolve('localhost', 'A');

my @methods_to_check = grep { DNS::Unbound->can($_) } (
    'trustedkeys',
    'add_ta_file',
    'add_ta_autr',
);

for my $method ( @methods_to_check ) {
    dies_ok(
        sub { $dns->$method('////////qqqq' . rand) },
        "$method after finalization",
    );

    my $err = $@;

    cmp_deeply(
        $err,
        all(
            Isa('DNS::Unbound::X::Unbound'),
            methods(
                [ get => 'number' ] => DNS::Unbound::UB_AFTERFINAL,
                [ get => 'string' ] => re(qr<final>i),
            ),
        ),
        "$method: error thrown",
    ) or diag explain $err;
}

{
    dies_ok(
        sub { $dns->add_ta('////////qqqq' . rand) },
        "add_ta() after finalization",
    );

    my $err = $@;

    cmp_deeply(
        $err,
        all(
            Isa('DNS::Unbound::X::Unbound'),
            methods(
                [ get => 'number' ] => DNS::Unbound::UB_AFTERFINAL,
                [ get => 'string' ] => re(qr<final>i),
            ),
        ),
        "add_ta: error thrown",
    ) or diag explain $err;
}

done_testing();
