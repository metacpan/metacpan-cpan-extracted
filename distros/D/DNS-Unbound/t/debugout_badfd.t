#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;
use Test::Exception;

use File::Temp;

use_ok('DNS::Unbound');

my $fd;

my $dns = DNS::Unbound->new();

do {
    my $fh = File::Temp::tempfile();
    $fd = fileno $fh;
    close $fh;
};

throws_ok(
    sub { $dns->debugout($fd) },
    'DNS::Unbound::X::BadDebugFD',
    'error when bad FD given to debugout()',
);

my $err = $@;

cmp_ok( 0 + $err->get('error'), '>', 0, '“error” as num' );
like( q<> . $err->get('error'), qr<. .>, '“error” as string' );

is( $err->get('fd'), $fd, '“fd”' );

done_testing();
