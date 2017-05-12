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

    annotation();

    return;
}

sub annotation {

    my $cc = Carp::Capture->new;

    my $id_undef = $cc->capture( undef );
    my $id_abc   = $cc->capture( 'abc' );
    my $id_aref  = $cc->capture([ 1, 2, 3 ]);

    my $ret_undef = $cc->retrieve_annotation( $id_undef );

    ok not( defined $ret_undef ),
        'retrieve_annotation is able to propagate an undef';

    is
        $cc->retrieve_annotation( $id_abc ),
        'abc',
        'retrieve_annotation is able to propagate a string';

    is_deeply
        $cc->retrieve_annotation( $id_aref ),
        [ 1, 2, 3 ],
        'retrieve_annotation is able to propagate a reference';

    return;
}
