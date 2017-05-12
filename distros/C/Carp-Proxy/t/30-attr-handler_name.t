# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

use Carp::Proxy fatal => { disposition => \&disp };

main();
done_testing();

#----------------------------------------------------------------------

sub handler1 {}
sub handler2 {}

sub disp { return $_[0]->handler_name }

sub main {

    foreach my $handler (qw( handler1 handler2 )) {

        my $capture;

        lives_ok{ $capture = fatal $handler }
            "fatal returns to caller for $handler";

        is
            $capture,
            $handler,
            "$handler matches";
    }

    return;
}
