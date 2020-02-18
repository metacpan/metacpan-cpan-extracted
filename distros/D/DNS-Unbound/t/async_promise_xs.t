#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

for my $mod ( qw( Promise::XS ) ) {
    eval "require $mod" or plan skip_all => "No $mod: $@";
}

$ENV{'DNS_UNBOUND_PROMISE_ENGINE'} = 'Promise::XS';

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
            )->then( sub { $done_count++ } );
        } @tlds;

        $dns->wait() while $done_count < @tlds;
    }
}

done_testing();
