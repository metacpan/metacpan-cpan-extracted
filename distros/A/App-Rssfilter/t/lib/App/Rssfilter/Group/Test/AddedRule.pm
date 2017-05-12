use strict;
use warnings;

package App::Rssfilter::Group::Test::AddedRule;

use Test::Routine;
use Test::More;
use namespace::autoclean;
use Method::Signatures;

requires 'group';
requires 'mock_rule';

test added_rule => method {
    my $pre_add_mock_rule_count =
        grep { $self->mock_rule eq $_ } @{ $self->group->rules };

    is(
        $self->group->add_rule( $self->mock_rule ),
        $self->group,
        'adding rule to group returns the group object (for chaining)'
    );

    my $mock_rule_count =
        grep { $self->mock_rule eq $_ } @{ $self->group->rules };
    is(
        $mock_rule_count - $pre_add_mock_rule_count,
        1,
        q{rule has been added to the group's list of rules}
    );
};

test created_and_added_rule => method {
    my $match  = sub {};
    my $filter = sub {};
    $self->group->add_rule( condition => $match, action => $filter );

    my $created_rule = $self->group->rules->[-1];
    is( $created_rule->condition, $match,  'add_rule passed options ...' );
    is( $created_rule->action,    $filter, '... to App::Rssfilter::Rule->new()' );

};

1;
