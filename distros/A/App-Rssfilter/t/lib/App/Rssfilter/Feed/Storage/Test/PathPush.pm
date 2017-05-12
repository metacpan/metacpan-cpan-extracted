use strict;
use warnings;

package App::Rssfilter::Feed::Storage::Test::PathPush;

use Test::Routine;
use Test::More;
use namespace::autoclean;
use Method::Signatures;
use Path::Class::Dir;

requires 'feed_storage';

test path_push => method {
    my $path_pushed = $self->feed_storage->path_push( 'cool crocodile' );
    is(
        $path_pushed->path->relative( $self->feed_storage->path ),
        'cool crocodile',
        'path_push adds passed argument to end of path'
    );
};

1;
