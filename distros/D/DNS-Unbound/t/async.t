#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use_ok('DNS::Unbound');

diag( "libunbound " . DNS::Unbound::unbound_version() );

use Data::Dumper;
$Data::Dumper::Useqq = 1;

for my $use_threads_yn ( 0, 1 ) {
    my $dns = DNS::Unbound->new();

    diag "########### Use threads? $use_threads_yn";

    $dns->enable_threads() if $use_threads_yn;

    {
        my $name = 'usa.gov';
        #$name = 'cannot.exist.invalid';

        my $query = $dns->resolve_async( $name, 'NS' )->then(
            sub {
                my ($result) = @_;

                isa_ok( $result, 'DNS::Unbound::Result', 'promise resolution' );

                my $rrs_ar = $result->to_net_dns_rrs();
                cmp_deeply(
                    $rrs_ar,
                    array_each(
                        Isa('Net::DNS::RR'),
                    ),
                    'to_net_dns_rrs() - DEPRECATED',
                );

                diag explain [ passed => $result ];
            },
            sub { diag explain [ failed => @_ ] },
        );

        my $fd = $dns->fd();

        vec( my $rin = q<>, $fd, 1 ) = 1;
        select( my $rout = $rin, undef, undef, undef );

        diag "Ready vvvvvvvvvvvvv";
        $dns->process();
    }

    #----------------------------------------------------------------------

    {
        my @tlds = qw( example.com in-addr.arpa ip6.arpa com org );

        my $done_count = 0;

        my @queries = map {
            $dns->resolve_async( $_, 'NS' )->then(
                sub { diag explain [ passed => @_ ] },
                sub { diag explain [ failed => @_ ] },
            )->then( sub {
                $done_count++;

                is(
                    $dns->count_pending_queries(),
                    @tlds - $done_count,
                    "count_pending_queries() ($done_count finished)",
                );
            } );
        } @tlds;

        $dns->wait() while $done_count < @tlds;
    }
}

{
    my $dns = DNS::Unbound->new();
    my $done;

    $dns->resolve_async( '....', 'NS' )->catch(
        sub {
            my $err = shift;

            isa_ok( $err, 'DNS::Unbound::X::ResolveError', 'exception' );

            is($err->get('number'), DNS::Unbound::UB_SYNTAX(), 'number');

            like( $err->get('string'), qr<.>, 'string' );
        }
    )->then( sub { die 'badbad' } )->finally( sub { $done = 1 } );

    $dns->wait() while !$done;
}

done_testing();
