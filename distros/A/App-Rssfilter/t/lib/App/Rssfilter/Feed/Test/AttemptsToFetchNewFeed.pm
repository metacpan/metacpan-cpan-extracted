use strict;
use warnings;

package App::Rssfilter::Feed::Test::AttemptsToFetchNewFeed;

use Test::Routine;
use Test::More;
use namespace::autoclean;
use Method::Signatures;

requires 'feed';
requires 'feed_url';
requires 'mock_ua';
requires 'last_modified';
requires 'mock_storage';
requires 'feed_name';

test attempts_to_fetch_new_feed => method {
    $self->feed->update;
    my ( $name, $args ) = $self->mock_ua->next_call;
    is( $name, 'get',                'attempted to fetch ... ' );
    is( $args->[1], $self->feed_url, ' ... the new feed' );

    if ( defined( $self->last_modified ) ) {
        is(
            $args->[2]->{ 'If-Modified-Since' },
            $self->last_modified,
            'and indicated the last time we fetched the feed' 
        );
    }
};

test updates_storage_with_name => method {
    my ( $name, $args ) = $self->mock_storage->next_call;
    is( $name, 'set_name',            'attempts to set the name of its storage ... ' );
    is( $args->[1], $self->feed_name, ' ... to the name of feed' );
};

1;
