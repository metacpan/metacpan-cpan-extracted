#!/usr/bin/perl

use Test::More tests => 27;
use strict;
use warnings;

### Tests for adding relationships -- Basic tests

BEGIN {
    use_ok 'DBIx::Mint::Schema';
}

{
    package Bloodbowl::Coach; use Moo;
    has 'id' => ( is => 'rw' );
}
{
    package Bloodbowl::Team; use Moo;
    has 'id' => ( is => 'rw' );
}
{
    package Bloodbowl::Blah; use Moo;
    has 'field1' => ( is => 'ro', default => sub { 'textkey' } );
    has 'field2' => ( is => 'ro', default => sub { 33 } );
}

my $schema = DBIx::Mint::Schema->instance;
isa_ok($schema, 'DBIx::Mint::Schema');

$schema->add_class(
    class      => 'Bloodbowl::Coach',
    table      => 'coaches',
    pk         => 'id',
    auto_pk => 1,
);
is($schema->for_class('Bloodbowl::Coach')->table(), 'coaches',
    'Accessor for the schema of a class works fine (table)');

is_deeply($schema->for_class('Bloodbowl::Coach')->pk(), ['id'],
    'Accessor for the schema of a class works fine (primary key)');

ok($schema->for_class('Bloodbowl::Coach')->auto_pk(),
    'Accessor for the schema of a class works fine (auto_pk)');

$schema->add_class(
    class      => 'Bloodbowl::Team',
    table      => 'teams',
    pk         => 'id',
    auto_pk    => 1,
);

$schema->add_class(
    class      => 'Bloodbowl::Blah',
    table      => 'blah',
    pk         => [qw(field1 field2)],
);

{
    eval {
        $schema->add_class(
            class      => 'Bloodbowl::Bleh',
            table      => 'bleh',
            pk         => [qw(field1 field2)],
            auto_pk    => 1,
        );
    };
    like $@, qr{Only a single primary key is supported},
        'Tables with multiple primary keys cannot be marked auto';
}

{
    my $schema2 = DBIx::Mint::Schema->instance;
    is($schema, $schema2, 'DBIx::Mint::Schema is really a singleton');
}

is_deeply($schema->for_class('Bloodbowl::Blah')->pk(), ['field1', 'field2'],
    'Accessor for the schema of a class works fine (multiple col primary key)');

ok(!$schema->for_class('Bloodbowl::Blah')->auto_pk(),
    'Accessor for the schema of a class works fine (no auto_pk)');


$schema->add_relationship(
    from_class        => 'Bloodbowl::Coach',
    to_class          => 'Bloodbowl::Team',
    to_field          => 'coach',
    method            => 'get_team',
    result_as         => 'resultset',
    inverse_method    => 'get_coach',
    inverse_result_as => 'resultset',
);

can_ok('Bloodbowl::Coach', 'get_team');
can_ok('Bloodbowl::Team',  'get_coach');

my $coach = Bloodbowl::Coach->new;
$coach->id(3);

my $rs = $coach->get_team;
isa_ok($rs, 'DBIx::Mint::ResultSet');

{
    my ($sql,@bind) = $rs->select_sql;
    is($sql, q{SELECT teams.* FROM coaches AS me INNER JOIN teams AS teams ON ( me.id = teams.coach ) WHERE ( me.id = ? )},
        'The returned ResultSet produces correct SQL');
    is($bind[0], 3, 'Bound values for relationship is correct');
}

my $team = Bloodbowl::Team->new( id => 4, coach => 3 );
my $team_rs = $team->get_coach;
isa_ok($team_rs, 'DBIx::Mint::ResultSet');

{
    my ($sql,@bind) = $team_rs->select_sql;
    is($sql, q{SELECT coaches.* FROM teams AS me INNER JOIN coaches AS coaches ON ( me.coach = coaches.id ) WHERE ( me.id = ? )},
        'The reverse ResultSet produces correct SQL');
    is( $bind[0], 4, 'Bound values are correct for reverse method');
}

{
    $schema->add_relationship(
        from_class        => 'Bloodbowl::Coach',
        to_class          => 'Bloodbowl::Blah',
        conditions        => { coach_f1 => 'blah_field1', coach_f2 => 'blah_field2'},
        method            => 'get_blah',
        result_as         => 'as_sql',
        inverse_method    => 'get_coach',
        inverse_result_as => 'resultset',
    );
    my  ($sql, @bind) = $coach->get_blah;
    like $sql, qr{INNER JOIN blah AS blah},         'ResultSet for multi-column primary key test 1';
    like $sql, qr{me\.coach_f1 = blah\.blah_field1},'ResultSet for multi-column primary key test 2';
    like $sql, qr{me\.coach_f2 = blah\.blah_field2},'ResultSet for multi-column primary key test 3';
    like $sql, qr{WHERE \( me\.id = \? \)},         'ResultSet for a multi-column primary key produces correct SQL';
    
    my $blah = Bloodbowl::Blah->new;
    $rs = $blah->get_coach;
    isa_ok( $rs, 'DBIx::Mint::ResultSet');
    ($sql, @bind) = $rs->select_sql;
    like($sql, qr{INNER JOIN coaches AS coaches},      'Inverse ResultSet for multi-column primary key test 1'),
    like($sql, qr{me\.blah_field1 = coaches\.coach_f1},'Inverse ResultSet for multi-column primary key test 2'),
    like($sql, qr{me\.blah_field2 = coaches\.coach_f2},'Inverse ResultSet for multi-column primary key test 3'),
    like($sql, qr{me\.field1 = \? AND me\.field2 = \?},
        'Inverse ResultSet for a multi-column primary key produces correct SQL');    
}
{
    # This should croak
    eval {
        $schema->add_relationship(
            from_class        => 'Bloodbowl::Coach',
            to_class          => 'Bloodbowl::Blah',
            conditions        => { coach_f1 => 'blah_field1', coach_f2 => 'blah_field2'},
            method            => 'get_bleh',
            result_as         => 'please_croak',
        );
    };
    like $@, qr{result_as option not recognized},      'Invalid argument to result_as is discovered';
}

done_testing();
