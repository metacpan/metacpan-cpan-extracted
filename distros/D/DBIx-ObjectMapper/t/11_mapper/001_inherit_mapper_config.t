use strict;
use warnings;
use Test::More;

use DBIx::ObjectMapper::Mapper;
use DBIx::ObjectMapper::Metadata;
use DBIx::ObjectMapper::Metadata::Sugar qw(:all);

{
    package MyTest001::Player;
    use strict;
    use warnings;

    sub new {
        my ( $class, $id, $name, $play ) = @_;
        bless{ id => $id, name => $name, play => $play }, $class;
    }

    sub id {
        my $self = shift;
        $self->{id} = shift if @_;
        return $self->{id};
    }

    sub name {
        my $self = shift;
        $self->{name} = shift if @_;
        return $self->{name};
    }

    sub play {
        my $self = shift;
        $self->{play} = shift if @_;
        return $self->{play};
    }

    1;
};

{
    package MyTest001::FootballPlayer;
    use base qw(MyTest001::Player);

    1;
};

my $meta = DBIx::ObjectMapper::Metadata->new;
my $player = $meta->table(
    'player' => [
        Col( id => Int(), PrimaryKey ),
        Col( name => Text(), NotNull ),
        Col( play => String(128) ),
    ]
);

ok my $player_mapper = DBIx::ObjectMapper::Mapper->new(
    $player => 'MyTest001::Player',
    constructor => { arg_type => 'ARRAY' },
    attributes => {
        properties => [
            { isa => $player->c('id') },
            { isa => $player->c('name') },
            { isa => $player->c('play') },
        ]
    }
);

ok( DBIx::ObjectMapper::Mapper->is_initialized('MyTest001::Player') );

ok my $inherit_mapper = DBIx::ObjectMapper::Mapper->new(
    $player => 'MyTest001::FootballPlayer',
    inherits => 'MyTest001::Player',
    default_condition => [ $player->c('play') == 'football' ],
    default_value => { $player->c('play') => 'football' },
);

is $inherit_mapper->table, $player_mapper->table;
#is_deeply $inherit_mapper->attributes, $player_mapper->attributes;
is_deeply $inherit_mapper->accessors, $player_mapper->accessors;
is_deeply $inherit_mapper->constructor, $player_mapper->constructor;

isnt $inherit_mapper->attributes, $player_mapper->attributes;
isnt $inherit_mapper->accessors, $player_mapper->accessors;
isnt $inherit_mapper->constructor, $player_mapper->constructor;

done_testing;
