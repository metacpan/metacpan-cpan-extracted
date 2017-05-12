# -*- cperl -*-
use 5.010;
use warnings FATAL => qw( all );
use strict;

use English qw( -no_match_vars );
use Test::More;
use Carp::Capture;

main();
done_testing;

#-----

sub main {

    disambiguation_1();
    disambiguation_2();
    uncaptured();
    return;
}

#----- The first example in the POD section 'DISAMBIGUATION'
sub disambiguation_1 {

    my $cc = Carp::Capture->new;
    my @ids;

    foreach my $letter (qw( a b c d )) {

        push @ids, $cc->capture;
    }

    # Prints "1 1 1 1"
    # say "@ids";

    is_deeply
        \@ids,
        [ 1, 1, 1, 1 ],
        'Disambiguation example #1 loop captures all return id of 1';

    return;
}

#----- The second example in the POD section 'DISAMBIGUATION'
sub disambiguation_2 {

    my $cc = Carp::Capture->new;
    my @ids;

    foreach my $letter (qw( a b c d )) {

        push @ids, $cc->capture( $letter );
    }

    # Prints "2 3 4 5"
    # say "@ids";

    is_deeply
        \@ids,
        [ 2, 3, 4, 5 ],
        'Disambiguation example #2 Annotations yield distinct ids';

    # Prints "True"
    # say "True"
    #     if $cc->stacktrace( $ids[0] ) eq
    #        $cc->stacktrace( $ids[1] );

    is
        $cc->stacktrace( $ids[0] ),
        $cc->stacktrace( $ids[1] ),
        'Annotated captures in loop yield identical stacktrace strings';

    # Prints "c"
    # say $cc->retrieve_annotation( $ids[2] );

    is
        $cc->retrieve_annotation( $ids[2] ),
        'c',
        'Retrieved annotation matches supplied argument';

    return;
}

sub uncaptured {

    my $cc = Carp::Capture->new;
    my $uncaptured = $cc->uncaptured;

    # Prints "On"
    # say $uncaptured == $cc->capture ? 'Off' : 'On';

    cmp_ok $uncaptured, '!=', $cc->capture,
        'enabled capture id is non-uncaptured';

    $cc->disable;

    # Prints "Off"
    # say $uncaptured == $cc->capture ? 'Off' : 'On';

    cmp_ok $uncaptured, '==', $cc->capture,
        'disabled capture id is uncaptured';

    return;
}
