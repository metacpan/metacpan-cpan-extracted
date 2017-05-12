#!/usr/bin/perl

use lib 't';
use Test::More tests => 17;
use strict;
use warnings;

# Tests for DBIx::Mint::Table -- Multiple conections

BEGIN {
    use_ok 'DBIx::Mint';
    use_ok 'Test::DB';
    use_ok 'Test::DB2';
    use_ok 'Bloodbowl::Coach';
}

# Connect to the first database
Test::DB->connect_db;
my $mint = DBIx::Mint->instance;
isa_ok( $mint, 'DBIx::Mint');

my $schema = $mint->schema;
isa_ok( $schema, 'DBIx::Mint::Schema');

$schema->add_class(
    class    => 'Bloodbowl::Coach',
    table    => 'coaches',
    pk       => 'id',
    auto_pk  => 1
);
$schema->add_class(
    class    => 'Bloodbowl::Skill',
    table    => 'skills',
    pk       => 'name',
);


# Connect to the second database
Test::DB2->connect_db();
my $mint2 = DBIx::Mint->instance('BB2');
isa_ok( $mint2, 'DBIx::Mint');

my $schema2 = $mint2->schema;
isa_ok( $schema2, 'DBIx::Mint::Schema');

$schema2->add_class(
    class    => 'Bloodbowl::Coach',
    table    => 'coaches',
    pk       => 'id',
    auto_pk  => 1
);
$schema2->add_class(
    class    => 'Bloodbowl::Skill',
    table    => 'skills',
    pk       => 'name',
);

{
    eval {
        my $mint3 = DBIx::Mint->new(name => 'BB2');
    };
    like $@, qr{DBIx::Mint object BB2 exists already},
        'You cannot create two Mint objects with the same name';
}

# Test ResultSet objects
my $rs1 = DBIx::Mint::ResultSet->new( table => 'coaches' );
isa_ok $rs1, 'DBIx::Mint::ResultSet';

my $rs2 = DBIx::Mint::ResultSet->new( table => 'coaches', instance => 'BB2' );
isa_ok $rs2, 'DBIx::Mint::ResultSet';

my $coach_1 = $rs1->search({ name => 'user_a'})->single;
is $coach_1->{password}, 'wwww', 'User fetched correctly from default database';

my $coach_2 = $rs2->search({ name => 'bb2_a'})->single;
is $coach_2->{password}, 'aaaa', 'User fetched correctly from second database';

# Test class-based access
$coach_1 = $rs1->set_target_class('Bloodbowl::Coach')->search({ name => 'user_a'})->single;
isa_ok $coach_1,       'Bloodbowl::Coach';
is $coach_1->password, 'wwww',       'User fetched correctly from default database by RS';
is $coach_1->_name,    '_DEFAULT',   'Object fetched contains its Mint instance name';
$coach_1->password('new');

# Copy coach_1 to second database
my %copy = %$coach_1;
delete $copy{id};
my $id   = Bloodbowl::Coach->insert( $mint2, \%copy );
$coach_2 = Bloodbowl::Coach->find_or_create($mint2, { name => 'user_a' });
is $coach_2->password, 'new', 'Copied object correctly from default database to another';

done_testing();
