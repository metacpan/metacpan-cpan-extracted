#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Test::DescribeMe 'author';

use_ok('DNS::Unbound');

diag( "libunbound " . DNS::Unbound::unbound_version() );

my @names = map { 'name-' . substr(rand, 2) . '.example.com' } ( 1 .. 1000 );

my $dns = DNS::Unbound->new();

my $fd = $dns->fd();

vec( my $rin = q<>, $fd, 1 ) = 1;

my @queries = map {
    my $name = $_;
    $dns->resolve_async( $name, 'NS' )->then(
        sub { diag "$name: OK" },
        sub { diag "$name: @_" },
    );
} @names;

while ($dns->count_pending_queries()) {
    diag "Queries pending: " . $dns->count_pending_queries();

    select( my $rout = $rin, undef, undef, undef );

    $dns->process();
}

done_testing;
