use strict;
use warnings;

package App::Rssfilter::Group::Test::AddedFeed;

use Test::Routine;
use Test::More;
use Method::Signatures;
use namespace::autoclean;

requires 'group';
requires 'mock_feed';

has 'feed_id' => (
    is => 'rw',
    default => sub { 0 },
);

method advance_feed_id() {
    return $self->feed_id( $self->feed_id + 1 );
}

test added_feed => method {
    my $pre_add_mock_feed_count =
        grep { $self->mock_feed eq $_ } @{ $self->group->feeds };

    $self->group->add_feed( $self->mock_feed );

    my $mock_feed_count =
        grep { $self->mock_feed eq $_ } @{ $self->group->feeds };
    is(
        $mock_feed_count - $pre_add_mock_feed_count,
        1,
        q{feed has been added to the group's list of feeds}
    );
};

test created_and_added_feed => method {
    my $id = $self->advance_feed_id;
    my ( $name, $url ) = map { $self->mock_feed->$_() . $id } qw< name url >;
    $self->group->add_feed( name => $name, url => $url );
    my $created_feed = $self->group->feeds->[-1];
    is( $created_feed->name, $name,  'add_feed passed options ...' );
    is( $created_feed->url,  $url,   '... to App::Rssfilter::Feed->new()' );
};

1;
