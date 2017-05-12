use strict;
use warnings;

use DBICx::TestDatabase;
use Test::More;
use lib 't/lib';

eval "use DBIx::Class::ResultSet::RecursiveUpdate";
if ($@) {
    plan skip_all =>
        'DBIx::Class::ResultSet::RecursiveUpdate is required to run this test';
}
else {
    plan
        tests => 7,
        ;
}

my $schema = DBICx::TestDatabase->new('AuditTestRU::Schema');

isa_ok($schema, 'DBIx::Class::Schema::AuditLog');

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;
my $changesets = $al_schema->resultset('AuditLogChangeset');

my $books_rs = $schema->resultset('Book');

isa_ok($books_rs, 'DBIx::Class::ResultSet::RecursiveUpdate');
isa_ok($books_rs, 'DBIx::Class::ResultSet::AuditLog');

my $book_data = {
    isbn    => '112233',
    authors => [
        {   id   => 1,
            name => 'FooAuthor',
        },
        {   id   => 2,
            name => 'BarAuthor',
        },
    ],
    title => { name => 'NiceTitle', }
};


$schema->txn_do(
    sub {
        $books_rs->recursive_update($book_data);
    },
);


subtest 'validate changeset after create with ru' => sub {
    is( $changesets->count, 1, 'one changeset in log' );
    my $cset = $changesets->find(1);
    is( $cset->Action->count, 6, 'six actions in changeset' );
    foreach ( $cset->Action->all ) {
        is( $_->action_type, 'insert', 'all actions are inserts' );
    }
};

$book_data = {
    id      => 1,
    authors => [ { id => 3, name => 'FooBarAuthor' } ],
    title => { name => 'AnotherTitle' },
};

$schema->txn_do(
    sub {
        $books_rs->recursive_update($book_data);
    },
);

subtest 'validate changeset after first update with ru' => sub{
    is( $changesets->count, 2, 'two changesets in log');

    my $cset = $changesets->find(2);
    is($cset->Action->count, 5, 'five actions in changeset');
    is($cset->Action->search({action_type => 'delete'})->count, 2, 'two delete actions');
    is($cset->Action->search({action_type => 'insert'})->count, 2, 'two insert actions');
    is($cset->Action->search({action_type => 'update'})->count, 1, 'one update action');
};

$book_data = {
    id       => 1,
    title_id => 2,
    isbn     => '11111',
    authors  => [
        { id => 3, name => 'FooBarAuthor' },
        { id => 1, name => 'FooAuthor' }
    ],
    title => { name => 'NiceTitle' },
};

$schema->txn_do(
    sub {
        $books_rs->recursive_update($book_data);
    },
);


subtest 'validate changeset after first update with ru' => sub{
    is( $changesets->count, 3, 'three changesets in log');

    my $cset = $changesets->find(3);
    is($cset->Action->count, 5, 'five actions in changeset');
    is($cset->Action->search({action_type => 'delete'})->count, 1, 'one delete action');
    is($cset->Action->search({action_type => 'insert'})->count, 3, 'three insert actions');
    is($cset->Action->search({action_type => 'update'})->count, 1, 'one update action');
};

$book_data = {
    id      => 1,
    authors => [
        { id => 3, name => 'FooBar-Author' },
        { id => 1, name => 'Foo-Author' }
    ],
    title => { name => 'NiceTitle' },
};

$schema->txn_do(
    sub {
        $books_rs->recursive_update($book_data);
    },
);

subtest 'validate changeset after second update with ru' => sub{
    is( $changesets->count, 4, 'four changesets in log');

    my $cset = $changesets->find(4);
    is($cset->Action->count, 6, 'six actions in changeset');
    is($cset->Action->search({action_type => 'update'})->count, 2, 'two update action');
    is($cset->Action->search({action_type => 'delete'})->count, 2, 'two delete action');
    is($cset->Action->search({action_type => 'insert'})->count, 2, 'two insert action');
};

