# -*- cperl -*-
use 5.010;
use warnings FATAL => qw( all );
use strict;

use English qw( -no_match_vars );
use Test::More;
use Test::Exception;
use Carp::Capture;

main();
done_testing;

#-----

sub main {

    abc();
    return;
}

sub abc {

    my $cc = Carp::Capture->new;

    my $id = $cc->capture;

    my $anno;
    throws_ok{ $anno = $cc->retrieve_annotation( $id ) }
        qr{ \Q<< unannotated capture >>\E }x,
        'unannotated captures throw on attempted retrieval';

    throws_ok{ $anno = $cc->retrieve_annotation( $id + 1 )}
        qr{\Q<< no such id >>\E}x,
        'retrieve_annotation throws for unknown id';

    throws_ok{ $anno = $cc->retrieve_annotation( $cc->uncaptured )}
        qr{\Q<< uncaptured annotation >>\E},
        'retrieve_annotation throws if fed an uncaptured id';
}
