#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;

use File::Temp;

use_ok('DNS::Unbound');

my ($fh, $fpath) = File::Temp::tempfile( CLEANUP => 1 );

print $fh "127.0.0.1  myhost.local$/";
close $fh;

my $dns = DNS::Unbound->new();

throws_ok(
    sub { $dns->hosts('/hahaha/haha/qweqwe' . rand) },
    qr<file>i,
    'error when hosts() path doesn’t exist',
);

$dns->hosts($fpath);

my $result = $dns->resolve( 'myhost.local', 'A' );

is(
    "@{$result->data()}",
    pack( 'C*', 127, 0, 0, 1 ),
    'query returns as expected',
);

done_testing();
