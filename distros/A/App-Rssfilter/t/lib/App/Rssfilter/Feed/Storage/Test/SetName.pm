use strict;
use warnings;

package App::Rssfilter::Feed::Storage::Test::SetName;

use Test::Routine;
use Test::More;
use namespace::autoclean;
use Method::Signatures;

requires 'feed_storage';
requires 'feed_name';

test set_name => method {
    my $name_set = $self->feed_storage->set_name( 'reef knot' );
    is(
        $name_set->name,
        'reef knot',
        'set_name returns an object with its name set to the argument passed ...'
    );

    is(
        $self->feed_storage->name,
        $self->feed_name,
        '... and does not change name of original object'
    );
};

test set_name_to_existing_name => method {
    my $name_set = $self->feed_storage->set_name( $self->feed_name );
    is(
        $name_set,
        $self->feed_storage,
        'set_name returns original object if new name is same as old'
    );

};

1;
