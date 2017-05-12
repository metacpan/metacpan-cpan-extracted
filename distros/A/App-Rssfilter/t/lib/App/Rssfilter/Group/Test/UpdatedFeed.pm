use strict;
use warnings;

package App::Rssfilter::Group::Test::UpdatedFeed;

use Test::Routine;
use Test::More;
use namespace::autoclean;
use Method::Signatures;

requires 'do_update';
requires 'mock_feed';
requires 'path_pushed_storage';
requires 'rules_for_update';

before 'do_update' => method( $group ) {
    $group->add_feed( $self->mock_feed );
};

test updated_feed => method {
    $self->mock_feed->called_ok( 'update', 'called update on nested feed ...');

    my (undef, %feed_update_args) = $self->mock_feed->call_args(0);

    is_deeply(
           $feed_update_args{storage},
           $self->path_pushed_storage,
           '... and passed path_push storage to nested feed when updating'
    );

    my @rules_to_check = map { @{ $_ } } $self->rules_for_update, $self->group->rules;
    is_deeply(
           $feed_update_args{rules},
           \@rules_to_check,
           '... and passed its rules to nested feed when updating'
    );
};

1;
