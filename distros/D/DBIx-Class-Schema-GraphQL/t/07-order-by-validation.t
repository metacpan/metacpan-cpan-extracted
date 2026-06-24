#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan skip_all => "Test requires DBIx::Class and GraphQL"
  unless eval "use DBIx::Class::Schema; use GraphQL::Execution qw(execute); 1;";

use DBIx::Class::Schema::GraphQL;

{
    package Test::Schema::Result::Book;
    use base qw(DBIx::Class::Core);
    __PACKAGE__->table('books');
    __PACKAGE__->add_columns(
        id    => { data_type => 'integer', is_auto_increment => 1 },
        title => { data_type => 'varchar', size => 255 },
    );
    __PACKAGE__->set_primary_key('id');

    package Test::Schema;
    use base qw(DBIx::Class::Schema);
    __PACKAGE__->register_class('Book', 'Test::Schema::Result::Book');
}

my $db = Test::Schema->connect('dbi:SQLite:dbname=:memory:');
$db->deploy;

my $result  = DBIx::Class::Schema::GraphQL->to_graphql($db);
my $schema  = $result->{schema};
my $context = $result->{context};

subtest 'Valid column sorting passes' => sub {
    my $query = '
        query {
            allBooks(orderBy: { field: "title", direction: DESC }) {
                nodes { id title }
            }
        }
    ';

    my $res = execute($schema, $query, undef, $context);

    is_deeply($res->{errors}, undef, 'No errors thrown for a valid column name');
};

subtest 'SQL injection payload throws an error' => sub {
    my $injection = '(CASE WHEN (SELECT 1)=1 THEN title ELSE id END)';
    my $query = sprintf('
        query {
            allBooks(orderBy: { field: "%s", direction: ASC }) {
                nodes { id title }
            }
        }
    ', $injection);

    my $res = execute($schema, $query, undef, $context);

    ok(exists $res->{errors}, 'GraphQL execution returned an error array');
    like(
        $res->{errors}[0]{message},
        qr/Invalid field '.*' provided for orderBy/,
        'Correctly caught our custom validation failure message'
    );
};

subtest 'Non-existent column throws an error' => sub {
    my $query = '
        query {
            allBooks(orderBy: { field: "fake_column_name", direction: ASC }) {
                nodes { id title }
            }
        }
    ';

    my $res = execute($schema, $query, undef, $context);

    ok(exists $res->{errors}, 'GraphQL execution returned an error array');
    like(
        $res->{errors}[0]{message},
        qr/Invalid field 'fake_column_name' provided for orderBy/,
        'Correctly rejected an ordinary missing column name'
    );
};

done_testing;
