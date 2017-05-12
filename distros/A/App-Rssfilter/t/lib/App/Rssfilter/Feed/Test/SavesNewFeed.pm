use strict;
use warnings;

package App::Rssfilter::Feed::Test::SavesNewFeed;

use Test::Routine;
use Test::More;
use namespace::autoclean;
use Method::Signatures;

requires 'mock_storage';
requires 'new_feed';

test saves_new_feed => method {
    my ( $name, $args ) = $self->mock_storage->next_call;
    is( $name, 'save_feed',          'attempted to save ...' );
    is( $args->[1], $self->new_feed, '... the new feed' );
};

1;
