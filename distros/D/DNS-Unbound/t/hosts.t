#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use File::Temp;

use_ok('DNS::Unbound');

my ($fh, $fpath) = File::Temp::tempfile( CLEANUP => 1 );

print $fh "127.0.0.1  myhost.local$/";
close $fh;

my $dns = DNS::Unbound->new()->hosts($fpath);

my $result = $dns->resolve( 'myhost.local', 'A' );

is(
    "@{$result->data()}",
    pack( 'C*', 127, 0, 0, 1 ),
    'query returns as expected',
);

done_testing();
