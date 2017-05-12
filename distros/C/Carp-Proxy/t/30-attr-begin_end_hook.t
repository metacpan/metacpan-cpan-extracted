# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

BEGIN {

    use_ok 'Carp::Proxy',
        (
         fatal    => {
                      disposition => 'return'
                     },

         fatal_b  => {
                      disposition => 'return',
                      begin_hook  => \&begin_hook,
                     },

         fatal_e  => {
                      disposition => 'return',
                      end_hook    => \&end_hook,
                     },

         fatal_be => {
                      disposition => 'return',
                      begin_hook  => \&begin_hook,
                      end_hook    => \&end_hook,
                     },
        );
}

main();
done_testing();

#----------------------------------------------------------------------

my $begin_called;
my $end_called;

sub begin_hook { $begin_called = 1 }
sub end_hook   { $end_called   = 1 }

#-----
# The begin_hook should have already been called before the handler gets
# control.  Also, the end_hook should not have run yet.
#-----
sub handler {
    my( $cp, $expected_begin, $title ) = @_;

    is
        $begin_called,
        $expected_begin,
        "$title begin called before handler";

    is
        $end_called,
        0,
        "$title end value unmolested before handler";

    return;
}

sub test_accessor {
    my( $cp, $hook, $setting ) = @_;

    $cp->$hook( $setting );
    return;
}

sub hook_test {
    my( $proxy, $expected_begin, $expected_end, $title ) = @_;

    #-----
    # The hook routines set these globals when they run.  We clear them
    # here before each test.
    #-----
    $begin_called = 0;
    $end_called   = 0;

    #-----
    # All of our proxys (fatal, fatal_b, fatal_e and fatal_be) have their
    # disposition set to 'return', no none of them should throw.
    #-----
    {
        no strict 'refs';
        lives_ok{ $proxy->('handler', $expected_begin, $title ) }
            "$title throws instead of returns";
    }

    #----- Now examine both globals

    is
        $begin_called,
        $expected_begin,
        "$title matching begin value";

    is
        $end_called,
        $expected_end,
        "$title matching end value";

    return;
}

sub main {

    #-----
    # The proxy for which neither hook is set (fatal) should not run
    # either hook.  Hence the expected values for the globals will be
    # 0,0.
    #-----
    foreach my $tuple ([ 'fatal',    0, 0, 'no-hook proxy'    ],
                       [ 'fatal_b',  1, 0, 'begin-only proxy' ],
                       [ 'fatal_e',  0, 1, 'end-only proxy'   ],
                       [ 'fatal_be', 1, 1, 'both-hook proxy'  ],
                      ) {

        hook_test( @{ $tuple } );
    }

    #-----
    # Here we want to verify that we can modify the hooks from the return
    # value (hashref) of the builtin '*configuration*' handler.  A similar
    # set of tests, from above, is now repeated.
    #-----
    my $conf = fatal '*configuration*';

    $conf->{ begin_hook } = \&begin_hook;
    hook_test 'fatal', 1, 0, 'reconfigured begin';

    $conf->{ end_hook } = \&end_hook;
    hook_test 'fatal', 1, 1, 'reconfigured begin-end';

    $conf->{ begin_hook } = undef;
    hook_test 'fatal', 0, 1, 'reconfigured undef-begin';

    $conf->{ end_hook } = undef;
    hook_test 'fatal', 0, 0, 'reconfigured begin-end';

    return;
}
