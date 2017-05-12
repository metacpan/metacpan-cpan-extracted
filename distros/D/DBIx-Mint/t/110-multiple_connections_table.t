#!/usr/bin/perl

use lib 't';
use Test::More tests => 17;
use strict;
use warnings;

# Tests for DBIx::Mint::Table with a connection other than default

BEGIN {
    use_ok 'DBIx::Mint';
    use_ok 'Test::DB2';
    use_ok 'Bloodbowl::Coach';
}

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

# Create
my @to_verify;
{
    # This test exercises both create and insert with a named connection
    my $coach = Bloodbowl::Coach->create( $mint2,
        { name => 'testing0', email => 'testing0@coaches.net', password => 'weak0' });
    isa_ok $coach, 'Bloodbowl::Coach';
    like $coach->id, qr/^\d+$/, 'Created object has expected auto-generated primary key';
    push @to_verify, $coach->id;
}
{
    # Excercise find, result_set and update. Update uses the instance variant
    my $coach = Bloodbowl::Coach->find( $mint2, $to_verify[0] );
    isa_ok $coach, 'Bloodbowl::Coach';
    is $coach->name, 'testing0', 'Object retrieved correctly using named Mint object';

    # Because the object was fetched, it contains the name of the Mint to use
    $coach->name('updated');
    $coach->update;

    my $rs = Bloodbowl::Coach->result_set( $mint2 )
        ->search({ name => 'updated' })
        ->set_target_class('Bloodbowl::Coach');
    my $found = $rs->single;
    is $found->id, $coach->id, 'Update as instance method works';
}
{
    # Excercise insert with a Mint object
    my @ids = Bloodbowl::Coach->insert( $mint2,
        { name => 'testing1', email => 'testing1@coaches.net', password => 'weak1' },
        { name => 'testing2', email => 'testing2@coaches.net', password => 'weak2' },
        { name => 'testing3', email => 'testing3@coaches.net', password => 'weak3' });
    is scalar @ids, 3, 'Received ids from inserted records, using named Mint';
    push @to_verify, @ids;
    my $are_digits;
    foreach (@ids) {
        $are_digits++ if $_->[0] =~ /^\d+$/;
    }
    is $are_digits, 3, 'The returned ids are digits, as expected';
}
{
    # Excercise update as class method with a Mint object
    Bloodbowl::Coach->update( $mint2, { name => 'updated' }, { password => { LIKE => 'weak%' }} );
}
{
    # Let's verify that we inserted and updated all the records we wanted.
    my @all = Bloodbowl::Coach->result_set( $mint2 )
        ->search({ name => 'updated' })
        ->set_target_class('Bloodbowl::Coach')
        ->all;
    is scalar @all, 4, 'The inserts and updates to the non-default database have been verified';
    my $is_correct = 0;
    foreach my $coach (@all) {
        $is_correct++ if $coach->password eq "weak$is_correct";
    }
    is $is_correct, 4, 'The data inserted/updated during these tests have been verified';
}
{
    # Excercise delete as instance method and then as a class method
    my $coach = Bloodbowl::Coach->find( $mint2, $to_verify[0]);
    $coach->delete;
    is scalar %$coach, 0,  'When deleted, object is emptied';
    my $coach2 = Bloodbowl::Coach->find( $mint2, $to_verify[0]);
    is $coach2, undef,     "Object was indeed deleted from the database";
    shift @to_verify;

    Bloodbowl::Coach->delete( $mint2, { password => { LIKE => 'weak%' }} );
    my @all = Bloodbowl::Coach->result_set( $mint2 )
        ->search({ name => 'updated' })
        ->set_target_class('Bloodbowl::Coach')
        ->all;
    is scalar @all, 0,      "Objects were indeed deleted from the database";
}

done_testing();
