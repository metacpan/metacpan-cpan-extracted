#!/usr/bin/perl -w

use strict;

use File::Spec;

use lib '.', File::Spec->catdir( File::Spec->curdir, 't', 'lib' );

use Alzabo::Test::Utils;

use Test::More;

use Alzabo::Create::Schema;

my $config = Alzabo::Test::Utils->test_config_for('pg');

unless ( keys %$config )
{
    plan skip_all => 'no Postgres test config provided';
    exit;
}

{
    package FakeSchema;

    sub new { return bless { name => $_[1] }, $_[0] }

    sub db_schema_name { $_[0]->{name} }
}

require DBD::Pg;
require Alzabo::Driver::PostgreSQL;


plan tests => 29;

Alzabo::Test::Utils->remove_schema('pg');


my $schema_name = delete $config->{schema_name};
delete $config->{rdbms};

{
    # This seems to help avoid those damn 'source database "template1"
    # is being accessed by other users' errors.  Freaking Postgres!
    sleep 1;

    # We create a couple of tables *without* using Alzabo, then see
    # whether it can reverse-engineer them and preserve foreign key
    # relationships.
    my $driver = Alzabo::Driver->new( rdbms  => 'PostgreSQL',
                                      schema => FakeSchema->new('template1'),
                                    );
    $driver->connect( %$config );
    my $dbh = $driver->handle;

    $dbh->do("CREATE DATABASE $schema_name");
    $dbh->disconnect;

    ok( 1, 'drop and create database' );

    $driver = Alzabo::Driver->new( rdbms  => 'PostgreSQL',
                                   schema => FakeSchema->new($schema_name),
                                 );
    $driver->connect( %$config );
    $dbh = $driver->handle;

    $dbh->do( q{CREATE TABLE foo_people  -- one-column primary key
                (
                 id SERIAL PRIMARY KEY,
                 name VARCHAR(30)
                )
               });

    $dbh->do( q{CREATE TABLE foo_dogs  -- two-column primary key
                (
                 id INTEGER NOT NULL,
                 tag_number INTEGER NOT NULL,
                 PRIMARY KEY (id, tag_number)
                )
               });

    $dbh->do( q{CREATE TABLE foo_main
                (
                 id SERIAL PRIMARY KEY,

                 foo_person INTEGER NOT NULL,
                 FOREIGN KEY (foo_person) REFERENCES foo_people(id),

                 foo_dog_id INTEGER NULL,
                 foo_dog_tag INTEGER NULL,
                 FOREIGN KEY (foo_dog_id, foo_dog_tag) REFERENCES foo_dogs(id, tag_number)
                )
               });

    $dbh->do( q{CREATE TABLE foo_cats
                (
                 id SERIAL PRIMARY KEY,
                 name VARCHAR(30)
                )
               });

    $dbh->do( q{CREATE TABLE cat_owner  -- linking table
                (
                 person_id INTEGER NOT NULL,
                 cat_id    INTEGER NOT NULL,
                 has_check CHAR(1)  CHECK (has_check = 'Q'  OR  has_check = 'P'),
                 FOREIGN KEY (person_id) REFERENCES foo_people (id),
                 FOREIGN KEY (cat_id)    REFERENCES foo_cats   (id),
                 PRIMARY KEY (person_id, cat_id)
                )
               });

    $dbh->disconnect;
    ok( 1, 'create tables to be reverse engineered' );
}

my $schema = Alzabo::Create::Schema->reverse_engineer
  ( name  => $schema_name,
    rdbms => 'PostgreSQL',
    %$config,
  );

ok( $schema, 'schema was created via reverse engineering' );

{
    my $t = $schema->table('foo_main');
    ok( $t, 'found foo_main table' );

    my @fk = $t->all_foreign_keys;
    is( scalar @fk, 2, 'found 2 foreign keys' );

    my $people_fk = $t->foreign_keys_by_column( $t->column('foo_person') );
    ok( $people_fk, 'found fk to foo_person' );
    is( $people_fk->table_from->name, 'foo_main', 'fk is from foo_main' );
    is( $people_fk->table_to->name, 'foo_people', 'fk is to foo_people' );
    is( scalar @{[$people_fk->columns_from]}, 1, 'one column is involved in fk' );
    ok( $people_fk->is_many_to_one, 'fk is many to one' );
    ok( $people_fk->from_is_dependent, 'from is dependent' );

    my $dog_fk = $t->foreign_keys_by_column( $t->column('foo_dog_id') );
    ok( $dog_fk, 'found fk to foo_dogs' );
    is( $dog_fk->table_from->name, 'foo_main', 'fk is from foo_main' );
    is( $dog_fk->table_to->name, 'foo_dogs', 'fk is to foo_dogs' );
    is( scalar @{[$dog_fk->columns_from]}, 2, '2 columns are involved in fk' );
    ok( $dog_fk->is_many_to_one, 'fk is many to one' );
    ok( ! $dog_fk->from_is_dependent, 'from is not dependent' );
}

{
    my $att = join '', $schema->table('cat_owner')->column('has_check')->attributes;
    like( $att, qr/CHECK/, 'cat_owner.has_check has a constraint' );
}
{
    my @fk = $schema->table('foo_dogs')->all_foreign_keys;
    @fk = grep $_->from_is_dependent, @fk;
    is( scalar @fk, 0, 'No dependent foreign keys from referenced table' );

    @fk = $schema->table('foo_people')->all_foreign_keys;
    @fk = grep $_->from_is_dependent, @fk;
    is( scalar @fk, 0, 'No dependent foreign keys from referenced table' );

    my $people_t = $schema->table('foo_people');
    @fk = $people_t->foreign_keys_by_column($people_t->column('id'));
    is @fk, 2, 'Table is involved in 2 relationships';
    my ($linking_fk) = grep {$_->table_to->name eq 'cat_owner'} @fk;
    ok $linking_fk, 'foo_people is linked to cat_owner';
    is $linking_fk->to_is_dependent, 1, 'cat_owner depends on foo_people';
}

{
    $schema->save_to_file;
    $schema = 'Alzabo::Runtime::Schema'->load_from_file(name => $schema_name);

    $schema->connect( Alzabo::Test::Utils->connect_params_for('pg') );

    my $p = $schema->table('foo_people');
    is( $p->primary_key->sequenced, 1, 'sequence for primary key was detected' );
    my $person = $p->insert( values => { } );
    ok( $person, 'can insert values using the primary key sequence' );

    my $d = $schema->table('foo_dogs');
    is( $d->primary_key->sequenced, 0, "this PK isn't sequenced" );
    my $dog = $d->insert( values => {id => 1, tag_number => 5} );
    ok( $dog, 'can insert values specifying primary key explicitly' );

    my $m = $schema->table('foo_main');
    is( $m->primary_key->sequenced, 1, 'sequence for primary key was detected' );
    my $main =  $m->insert( values => { foo_person  => $person->select('id'),
					foo_dog_id  => $dog->select('id'),
					foo_dog_tag => $dog->select('tag_number') } );
    ok( $main, 'can insert values using the primary key sequence' );
}
