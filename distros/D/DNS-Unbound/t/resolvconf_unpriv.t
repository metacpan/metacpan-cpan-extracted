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

lives_ok(
    sub { $dns->resolvconf() },
    'no arg given',
);

eval { $dns->resolvconf('////////qqqq' . rand) };

my $err = $@;

SKIP: {
    if (!$err) {
        my $is_ok = !DNS::Unbound->can('unbound_version');

        my $full_version;

        $is_ok ||= do {
            $full_version = DNS::Unbound::unbound_version();
            my $version = $full_version;
            $version =~ s<\..*?\z><>;
            $version < 1.13;
        };

        if ($is_ok) {
            $full_version ||= '?';

            skip "resolvconf() didn’t throw on a nonexistent path, but your libunbound ($full_version) may just be too old to report that.", 1;
        }
    }

    cmp_deeply(
        $err,
        all(
            Isa('DNS::Unbound::X::Unbound'),
            methods(
                [ get => 'number' ] => DNS::Unbound::UB_READFILE,
                [ get => 'string' ] => re(qr<file>i),
            ),
        ),
        'error thrown',
    ) or diag explain $err;
}

done_testing();
