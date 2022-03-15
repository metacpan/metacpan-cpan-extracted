#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

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

                diag "passed: $name";
            },
            sub { diag explain [ failed => @_ ] },
        );

        my $fd = $dns->fd();

        vec( my $rin = q<>, $fd, 1 ) = 1;
        select( my $rout = $rin, undef, undef, undef );

        diag __FILE__ . ": Waiting on $name: vvvvvvvvvvvvv";
        $dns->process();
    }

    #----------------------------------------------------------------------

    {
        my @tlds = qw( example.com in-addr.arpa ip6.arpa com org );

        my $done_count = 0;

        my @queries = map {
            my $name = $_;

            $dns->resolve_async( $_, 'NS' )->then(
                sub { diag "passed: $name" },
                sub { diag explain [ failed => @_ ] },
            )->then( sub { $done_count++ } );
        } @tlds;

        diag __FILE__ . ": Waiting on: @tlds";
        while ($done_count < @tlds) {
            diag "wait()ing …";
            $dns->wait();
        }
    }
}

done_testing();
