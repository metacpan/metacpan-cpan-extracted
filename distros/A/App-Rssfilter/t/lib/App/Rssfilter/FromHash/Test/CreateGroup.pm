use strict;
use warnings;

package App::Rssfilter::FromHash::Test::CreateGroup;

use Test::Routine;
use Test::Exception;
use Test::More;
use namespace::autoclean;
use Method::Signatures;

requires 'from_hash';

has mock_rule => (
    is => 'ro',
    default => method {
        $self->_make_mock( 'App::Rssfilter::Rule' );
    },
);

has mock_feed => (
    is => 'ro',
    default => method {
        $self->_make_mock( 'App::Rssfilter::Feed' );
    },
);

method _make_mock( $class ) {
    use Test::MockObject;
    my $mock = Test::MockObject->new();
    $mock->set_isa( $class );
    return $mock;
}

test create_simple_group => method {
    my $group;
    lives_ok(
        sub {
            $group = $self->from_hash(
                name  => 'coil',
                feeds => [ $self->mock_feed ],
                rules => [ $self->mock_rule ],
            );
        },
        'can call from_hash without calamity'
    );

    is(
        $group->name,
        'coil',
        'group created with name from hash'
    );

    is_deeply(
        $group->feeds,
        [ $self->mock_feed ],
        'added feeds from the hash to the created group'
    );

    is_deeply(
        $group->rules,
        [ $self->mock_rule ],
        'added rules from the hash to the created group'
    );
};

test create_nested_group => method {
    my $group = $self->from_hash(
        group => 'coil',
        groups => [
            {
                name  => 'turn',
                feeds => [ $self->mock_feed ],
                rules => [ $self->mock_rule ],
            },
        ],
    );

    is(
        $group->groups->[0]->name,
        'turn',
        'set the name of the nested group from the nested hash'
    );

    is_deeply(
        $group->groups->[0]->feeds,
        [ $self->mock_feed ],
        'added feeds from the nested hash to the nested group'
    );

    is_deeply(
        $group->groups->[0]->rules,
        [ $self->mock_rule ],
        'added rules from the nested hash to the nested group'
    );
};

1;
