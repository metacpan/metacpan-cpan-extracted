use strict;
use warnings;

package App::Rssfilter::Group::Test::FetchedSubgroupByName;

use Test::Routine;
use Test::More;
use Method::Signatures;
use namespace::autoclean;

requires 'group';

test fetched_subgroup_by_name => method {
    my $subgroup_name = 'needle';
    my $subgroup = App::Rssfilter::Group->new( $subgroup_name );
    $self->group->add_group( $subgroup->name );
    $self->group->add_group( $subgroup );
    is(
        $self->group->group( $subgroup->name ),
        $subgroup,
        'returned most recently added group with matching name ...'
    );

    is(
        $self->group->group( q{\0} ),
        undef,
        '... and returned undef when no group matched'
    );
};

1;
