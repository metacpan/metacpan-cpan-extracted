#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use DNS::Unbound::AsyncQuery::PromiseES6;

{
    my @cancel_args;
    local $DNS::Unbound::AsyncQuery::CANCEL_CR = sub {
        @cancel_args = @_;
    };

    my ($res, $rej);

    my $query_resolved;

    my $query = DNS::Unbound::AsyncQuery::PromiseES6->new( sub {
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
    my $query = DNS::Unbound::AsyncQuery::PromiseES6->new( sub {} );
    my $faux = { ctx => 'some_ctx', id => 'some_id' };

    $query->_set_dns( $faux );

    is( $query->_get_dns(), $faux, '_set_dns() and _get_dns()' );
}

done_testing;
