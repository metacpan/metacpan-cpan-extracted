use strict;
use warnings;

package App::Rssfilter::Group::Test::AddedGroup;

use Test::Routine;
use Test::More;
use Method::Signatures;
use namespace::autoclean;

requires 'group';
requires 'mock_group';

method count_matches( $needle, ArrayRef $haystack ) {
    return grep { $needle eq $_ } @{ $haystack };
}

method count_mock_group_matches() {
    return $self->count_matches( $self->mock_group, $self->group->groups );
}

test added_group => method {
    my $pre_added_group_count = $self->count_mock_group_matches();

    $self->group->add_group( $self->mock_group );

    my $added_group_count = $self->count_mock_group_matches();

    is(
        $added_group_count - $pre_added_group_count,
        1,
        q{group has been added to group's list of subgroups}
    );
};

test created_and_added_group => method {
    $self->group->add_group( 'gouranga' );
    my $created_group = $self->group->groups->[-1];
    is( $created_group->name, 'gouranga', 'add_group passed options to A::R::G->new()');
};

1;
