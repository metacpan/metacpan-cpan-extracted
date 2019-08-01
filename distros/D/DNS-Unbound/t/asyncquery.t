#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use DNS::Unbound::AsyncQuery;

{
    my @cancel_args;
    local $DNS::Unbound::AsyncQuery::CANCEL_CR = sub {
        @cancel_args = @_;
    };

    my ($res, $rej);

    my $query_resolved;

    my $query = DNS::Unbound::AsyncQuery->new( sub {
        ($res, $rej) = @_;
    } );

    isa_ok( $query, 'Promise::ES6', 'new() return' );

    $query->_set_dns( { ctx => 'some_ctx', id => 'some_id' } );

    $query = $query->then( sub { $query_resolved = shift() } );

    $query->cancel();

    is_deeply(
        \@cancel_args,
        [ 'some_ctx', 'some_id' ],
        'cancel(): $CANCEL_CR coderef called as expected',
    );
}

{
    my $query = DNS::Unbound::AsyncQuery->new( sub {} );
    $query->_set_dns( { ctx => 'some_ctx', id => 'some_id' } );
    $query->_forget_dns();

    is( $query->_get_dns(), undef, '_forget_dns()' );
}

done_testing;
