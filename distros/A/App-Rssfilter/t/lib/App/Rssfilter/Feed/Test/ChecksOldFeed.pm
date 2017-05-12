use strict;
use warnings;

package App::Rssfilter::Feed::Test::ChecksOldFeed;

use Test::Routine;
use Test::More;
use namespace::autoclean;
use Method::Signatures;

requires 'mock_storage';

test checks_old_feed => method {
    my ( $name, $args );

    ( $name, $args ) = $self->mock_storage->next_call;
    is( $name, 'load_existing', 'loaded old feed' );

    ( $name, $args ) = $self->mock_storage->next_call;
    is( $name, 'last_modified', 'found last time old feed was modified' );
};

1;
