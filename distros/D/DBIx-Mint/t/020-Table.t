#!/usr/bin/perl

use lib 't';
use Test::DB;
use Test::More tests => 33;
use strict;
use warnings;

# Tests for DBIx::Mint::Table

BEGIN {
    use_ok 'DBIx::Mint';
    use_ok 'DBIx::Mint::Table';
    use_ok 'DBIx::Mint::Schema';
}

Test::DB->connect_db;
isa_ok( DBIx::Mint->instance, 'DBIx::Mint');

{
    package Bloodbowl::Coach;
    use Moo;
    with 'DBIx::Mint::Table';
    
    has id           => ( is => 'rw', predicate => 1 );
    has name         => ( is => 'rw' );
    has email        => ( is => 'rw' );
    has password     => ( is => 'rw' );
}
{
    package Bloodbowl::Skill;
    use Moo;
    with 'DBIx::Mint::Table';
    
    has name         => ( is => 'rw' );
    has category     => ( is => 'rw' );
}

{
    # These should croak
    eval {
        my $rs = Bloodbowl::Coach->result_set;
    };
    like $@, qr{result_set: The schema for [\w:]+ is undefined},
        'result_set croaks when the schema is not defined';
}

my $schema = DBIx::Mint::Schema->instance;
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

isa_ok( $schema, 'DBIx::Mint::Schema');

# Tests for Find
{
    my $user = Bloodbowl::Coach->find({ name => 'user_a' });
    isa_ok($user, 'Bloodbowl::Coach');
    is($user->{id},    2,                   'Record fetched correctly by find, with where clause');
    eval {
        $user->find(4);
    };
    like $@, qr{find must be called as a class method},
        'Find must be called as a class method';
}
{
    my $user = Bloodbowl::Coach->find(3);
    isa_ok($user, 'Bloodbowl::Coach');
    is($user->{id},    3,                   'Record fetched correctly by find');
}
{
    my $user = Bloodbowl::Coach->find('a');
    ok !defined $user,                      'Retreiving a non-existent record returns undef';
}

# Tests for insert
{
    my $user  = Bloodbowl::Coach->new(name => 'user d', email => 'd@blah.com', password => 'xxx');
    my @ids   = Bloodbowl::Coach->insert(
        $user,
        {name => 'user e', email => 'e@blah.com', password => 'xxx'}, 
        {name => 'user f', email => 'f@blah.com', password => 'xxx'}, 
    );
    ok defined $user->id,     'Inserted object has the auto-generated id field';
    is $user->id, $ids[0][0], 'Auto-generated id field is the same as the one returned';
}
{
    my $user  = Bloodbowl::Coach->new(name => 'user h', email => 'h@blah.com', password => 'xxx');
    my $id    = $user->insert;
    ok defined $user->id,  'Inserted object has the auto-generated id field';
    is $user->id, $id,     'Auto-generated id field is the same as the one returned';
}
{
    my $id   = Bloodbowl::Coach->insert(name => 'user g', email => 'g@blah.com', password => 'xxxx');
    my $user = Bloodbowl::Coach->find($id);
    is $user->name, 'user g', 'Inserted and then retrieved a hash correctly'; 
}
{
    my $id   = Bloodbowl::Skill->insert(name => 'skill x', category => 'category x');
    my $test = Bloodbowl::Skill->find($id);
    is $test->name, $id,      'Inserted and then retrieved a simple hash in a non-auto pk table';
}    
    
# Tests for create
{
    my $user = Bloodbowl::Coach->create(name => 'user i', email => 'i@blah.com', password => 'xxxx');
    is $user->name, 'user i', 'Created a user correctly';
    my $tst  = Bloodbowl::Coach->find($user->id);
    is $tst->name, 'user i',  'User just created was retrieved from database correctly';
}    

# Tests for find or create
{
    my $user = Bloodbowl::Coach->find_or_create(2);
    is $user->name, 'user_a', 'Found existing user with find_or_create';
    my $test = Bloodbowl::Coach->find_or_create( name => 'user j', email => 'j@blah.com', password => 'xxx');
    ok $test->has_id,         'Created an object with find_or_create';
    $user    = Bloodbowl::Coach->find( $test->id );
    is $user->name, 'user j', 'Retrieved user created with find_or_create';
}

# Tests for update
{
    Bloodbowl::Coach->update({password => '222'}, {});
    my $user = Bloodbowl::Coach->find(2);
    is $user->password, '222', 'Update works fine as a class method';
}
{
    my $user = Bloodbowl::Coach->find(2);
    $user->password('678');
    $user->update;
    my $test = Bloodbowl::Coach->find(2);
    is $test->password, 678,  'Update works fine as an instance method';
    $test    = Bloodbowl::Coach->find(3);
    is $test->password, 222,  'As an instance method, not all records were modified';
}
{
    eval {
        Bloodbowl::Coach->update({password => '222'}, { please => 'croak' }, {});
    };
    like $@, qr{DBIx::Mint::Table update: Expected the first argument to be a DBIx::Mint object},
        'Three args form of update should receive a Mint as first arg';
}
{
    eval {
        Bloodbowl::Coach->update({ please => 'croak' }, 'Yay');
    };
    like $@, qr{DBIx::Mint::Table update: called with incorrect arguments},
        'update checks that its set and where args are references';
}

# Tests for delete
{
    Bloodbowl::Coach->delete({password => 678});
    my $user = Bloodbowl::Coach->find(2);
    ok !defined $user,   'Delete at class level works';
    $user    = Bloodbowl::Coach->find(4);
    is $user->id, 4,     'And not all the records where deleted';
    $user->delete;
    is_deeply $user, {}, 'Delete at the object level undefs the deleted object';
    my $test = Bloodbowl::Coach->find(4);
    ok !defined $test,   'Deleted object could not be found';
}
{
    Bloodbowl::Coach->delete( name => { LIKE => 'user%' } );
    my @all = Bloodbowl::Coach->result_set->all;
    is scalar @all, 1,    'Deletion using a simple hash as input works fine';
}

done_testing();

