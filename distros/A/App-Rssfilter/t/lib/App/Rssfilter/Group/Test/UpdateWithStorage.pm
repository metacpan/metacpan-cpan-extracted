use strict;
use warnings;

package App::Rssfilter::Group::Test::UpdateWithStorage;

use Test::Routine;
use Test::Exception;
use Test::More;
use namespace::autoclean;
use Method::Signatures;

requires 'group';
requires 'group_name';
requires 'mock_storage';
requires 'rules_for_update';

method do_update( $group ) {
    $self->mock_storage->set_always( path_push => $self->path_pushed_storage );
    $group->update( rules => $self->rules_for_update, storage => $self->mock_storage );
}

test update_with_storage => method {

    $self->do_update( $self->group );

    $self->mock_storage->called_ok( 'path_push', 'called path_push on mock storage...');

    $self->mock_storage->called_args_pos_is(
        0,
        2,
        $self->group_name,
        '... with the name of the group'
    );

    ok(
        ! $self->group->storage->called( 'path_push' ),
        q{object's storage was not touched}
    );
};

1;
