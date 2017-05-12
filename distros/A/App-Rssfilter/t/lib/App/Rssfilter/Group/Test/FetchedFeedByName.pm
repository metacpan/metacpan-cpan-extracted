use strict;
use warnings;

package App::Rssfilter::Group::Test::FetchedFeedByName;

use Test::Routine;
use Test::More;
use Method::Signatures;
use namespace::autoclean;

requires 'group';

test fetched_feed_by_name => method {
    my $feed_name = 'needle';
    my $feed = App::Rssfilter::Feed->new( $feed_name => 'http://example.org/' );
    $self->group->add_feed( $feed->name => 'http://example.net/' );
    $self->group->add_feed( $feed );
    is(
        $self->group->feed( $feed->name ),
        $feed,
        'returned most recently added feed with matching name ...'
    );

    is(
        $self->group->feed( q{\0} ),
        undef,
        '... and returned undef when no feed matched'
    );
};

1;
