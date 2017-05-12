# -*- cperl -*-
use 5.010;
use warnings FATAL => qw( all );
use strict;

use English qw( -no_match_vars );
use Test::More;
use Test::Exception;
use Carp::Capture;
use Readonly;

Readonly::Scalar my $UNSIGNED_REX => qr/ \A \d+ \z /x;

main();
done_testing;

#-----

sub main {

    captures_are_unsigneds();

    return;
}

sub captures_are_unsigneds {

    my $cc = Carp::Capture->new;

    my $uncaptured = $cc->uncaptured;

    like
        $uncaptured,
        $UNSIGNED_REX,
        'The uncaptured ID is an unsigned';

    my $initially = $cc->capture;

    like
        $initially,
        $UNSIGNED_REX,
        'The ID captured from a fresh object is an unsigned';

    cmp_ok
        $initially,
        '!=',
        $uncaptured,
        'The initial ID is different from an uncaptured ID';

    $cc->disable;
    my $after_disable = $cc->capture;

    like
        $after_disable,
        $UNSIGNED_REX,
        'The ID supplied from a disabled capture is an unsigned';

    cmp_ok
        $after_disable,
        '==',
        $uncaptured,
        'The ID from a disabled capture matches the uncaptured ID';

    $cc->enable;
    my $after_enable = $cc->capture;

    like
        $after_enable,
        $UNSIGNED_REX,
        'Re-enabling captures provides an unsigned ID';

    cmp_ok
        $after_enable,
        '!=',
        $uncaptured,
        'The re-enabled ID is defferent from the uncaptured ID';

    cmp_ok
        $after_enable,
        '!=',
        $initially,
        'The re-enabled ID appears to be unique';

    $cc->revert;
    my $disable_after_pop = $cc->capture;

    like
        $disable_after_pop,
        $UNSIGNED_REX,
        'Popping back to disabled, still an unsigned';

    cmp_ok
        $disable_after_pop,
        '==',
        $uncaptured,
        'The popped disable is an uncaptured';

    $cc->revert;
    my $enable_after_pop = $cc->capture;

    like
        $enable_after_pop,
        $UNSIGNED_REX,
        'The popped enable is an unsigned';

    cmp_ok
        $enable_after_pop,
        '!=',
        $initially,
        'Two enabled captures from same status stack level differ';

    cmp_ok
        $enable_after_pop,
        '!=',
        $after_enable,
        'Two enabled captures from different status stack levels differ';

    lives_ok{ $cc->revert }
        'We can pop more than we push';

    my $again_from_base = $cc->capture;

    like
        $again_from_base,
        $UNSIGNED_REX,
        'The extra-popped base is still an unsigned';

    cmp_ok
        $again_from_base,
        '!=',
        $uncaptured,
        'Extra-popped base is still enabled';
}


