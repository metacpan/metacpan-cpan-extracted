#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use My::Schema;
use DBIx::Class::Schema::GraphQL;
use GraphQL::Execution qw(execute);

my $db = My::Schema->connect('dbi:SQLite:dbname=:memory:');
$db->deploy;

$db->resultset('Author')->create({
    id     => 1,
    name   => 'J.R.R. Tolkien',
    email  => 'jrrt@example.com',
    rating => 9.8,
    active => 1,
});
$db->resultset('Author')->create({
    id     => 2,
    name   => 'Isaac Asimov',
    email  => 'asimov@example.com',
    rating => 9.5,
    active => 1,
});
$db->resultset('Book')->create({ id => 1, title => 'The Hobbit', author_id => 1, price => 9.99  });
$db->resultset('Book')->create({ id => 2, title => 'The LOTR',   author_id => 1, price => 29.99 });
$db->resultset('Book')->create({ id => 3, title => 'Foundation', author_id => 2, price => 8.99  });

my $result = DBIx::Class::Schema::GraphQL->to_graphql($db);
my ($schema, $ctx) = @{$result}{qw(schema context)};

sub gql {
    my ($query, $vars) = @_;
    return execute($schema, $query, undef, $ctx, $vars // {});
}

# Singular query
{
    my $res = gql('{ author(id: 1) { id name rating } }');
    ok(!$res->{errors}, 'singular author query has no errors')
       or diag explain $res->{errors};
    is($res->{data}{author}{id},     1,                'author id'    );
    is($res->{data}{author}{name},   'J.R.R. Tolkien', 'author name'  );
    is($res->{data}{author}{rating}, 9.8,              'author rating');
}

# Singular query - NOT FOUND
{
    my $res = gql('{ author(id: 999) { id } }');
    ok(!$res->{errors}, 'no errors for missing author');
    ok(!defined $res->{data}{author}, 'missing author returns null');
}

# Plural query
{
    my $res = gql('{ allAuthors { total nodes { id name } } }');
    ok(!$res->{errors}, 'allAuthors has no errors');
    is($res->{data}{allAuthors}{total},              2, 'allAuthors total is 2'    );
    is(scalar @{ $res->{data}{allAuthors}{nodes} },  2, 'allAuthors returns 2 rows');
}

# Nested has_many relationship
{
    my $res = gql('{ author(id: 1) { name books { title } } }');
    ok(!$res->{errors}, 'nested books query has no errors')
       or diag explain $res->{errors};
    my @titles = map { $_->{title} } @{ $res->{data}{author}{books} };
    is(scalar @titles, 2, 'Tolkien has 2 books');
    ok((grep { $_ eq 'The Hobbit' } @titles), 'The Hobbit is present');
}

# Nested belongs_to relationship
{
    my $res = gql('{ book(id: 3) { title author { name } } }');
    ok(!$res->{errors}, 'nested author on book has no errors')
       or diag explain $res->{errors};
    is($res->{data}{book}{title},        'Foundation',   'book title' );
    is($res->{data}{book}{author}{name}, 'Isaac Asimov', 'book author');
}

# Variables
{
    my $res = gql('query GetBook($bid: Int) { book(id: $bid) { title } }',
                  { bid => 1 });
    ok(!$res->{errors}, 'query with variable has no errors');
    is($res->{data}{book}{title}, 'The Hobbit', 'variable passed correctly');
}

done_testing;
