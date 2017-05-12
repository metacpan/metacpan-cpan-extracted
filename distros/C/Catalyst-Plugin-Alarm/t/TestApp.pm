package TestApp;
use strict;
use warnings;
use Test::More;    # for diag()

use Catalyst qw[ Alarm];
__PACKAGE__->config(
    alarm => {
        timeout => 3,
        handler => sub {
            if ( ref $_[1] ) {
                diag(" .... local alarm went off!!");
                $_[1]->[0] = 1;
                $_[0]->alarm->on(0);
            }
            else {
                diag(" .... global alarm went off");

                #$_[0]->alarm->on(0);   # leave it on to test
            }
        },
        global             => 5,
        use_native_signals => $ENV{USE_NATIVE_SIGNALS},
    },
);

TestApp->setup();

1;
