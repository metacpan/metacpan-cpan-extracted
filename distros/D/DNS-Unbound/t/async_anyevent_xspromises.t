#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

# This leaks.
#use Test::FailWarnings;

for my $mod ( qw( AnyEvent  AnyEvent::XSPromises ) ) {
    eval "require $mod" or plan skip_all => "No $mod: $@";
}

use Data::Dumper;
$Data::Dumper::Useqq = 1;

$ENV{'DNS_UNBOUND_PROMISE_ENGINE'} = 'AnyEvent::XSPromises';

use_ok('DNS::Unbound');

for my $use_threads_yn ( 0, 1 ) {
    my $dns = DNS::Unbound->new();

    my $watch = AnyEvent->io(
        fh => $dns->fd(),
        poll => 'r',
        cb => sub { $dns->process() },
    );

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

        my $cv = AnyEvent->condvar();
        $query->then($cv);
        $cv->recv();
    }

    #----------------------------------------------------------------------

    {
        my @tlds = qw( example.com in-addr.arpa ip6.arpa com org );

        my @queries = map {
            $dns->resolve_async( $_, 'NS' )->then(
                sub { diag explain [ passed => @_ ] },
                sub { diag explain [ failed => @_ ] },
            );
        } @tlds;

        my $cv = AnyEvent->condvar();
        AnyEvent::XSPromises::collect(@queries)->then($cv);
        $cv->recv();
    }
}

done_testing();
