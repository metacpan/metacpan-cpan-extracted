#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use My::Schema;
use DBIx::Class::Schema::GraphQL;
use GraphQL::Execution qw(execute);

sub fresh {
    my $db = My::Schema->connect('dbi:SQLite:dbname=:memory:');
    $db->deploy;
    $db->resultset('Author')->create({
        id    => 1,
        name  => 'Seed Author',
        email => 'seed@example.com',
    });
    my $r = DBIx::Class::Schema::GraphQL->to_graphql($db);
    return ($db, $r->{schema}, $r->{context});
}

sub gql {
    my ($schema, $ctx, $query, $vars) = @_;
    return execute($schema, $query, undef, $ctx, $vars // {});
}

# createAuthor - happy path
{
    my ($db, $schema, $ctx) = fresh();
    my $res = gql($schema, $ctx, 'mutation {
        createAuthor(name: "New Author", email: "new@example.com", rating: 7.5) {
            id name email rating
        }
    }');

    ok(!$res->{errors}, 'createAuthor: no errors')
       or diag explain $res->{errors};
    my $a = $res->{data}{createAuthor};
    ok($a->{id},                        'createAuthor returns an id' );
    is($a->{name},   'New Author',      'createAuthor name correct'  );
    is($a->{email},  'new@example.com', 'createAuthor email correct' );
    is($a->{rating}, 7.5,               'createAuthor rating correct');
    is($db->resultset('Author')->count, 2, 'Author count incremented');
}

# createAuthor — required field missing
{
    my ($db, $schema, $ctx) = fresh();
    my $res = gql($schema, $ctx,
        'mutation { createAuthor(email: "noname@example.com") { id } }');

    ok($res->{errors} && @{$res->{errors}},
       'createAuthor with missing NonNull field populates errors array');
}

# updateAuthor — by PK
{
    my ($db, $schema, $ctx) = fresh();
    my $res = gql($schema, $ctx, 'mutation {
        updateAuthor(id: 1, name: "Updated Name", email: "seed@example.com") {
            id name
        }
    }');

    ok(!$res->{errors}, 'updateAuthor by PK: no errors')
       or diag explain $res->{errors};
    is($res->{data}{updateAuthor}{name}, 'Updated Name', 'name updated via PK');
    is($db->resultset('Author')->find(1)->name, 'Updated Name',
       'DB reflects the update');
}

# updateAuthor — by unique constraint
{
    my ($db, $schema, $ctx) = fresh();
    my $res = gql($schema, $ctx, 'mutation {
        updateAuthor(email: "seed@example.com", name: "UQ Updated") {
            id name
        }
    }');

    ok(!$res->{errors}, 'updateAuthor by unique constraint: no errors')
        or diag explain $res->{errors};
    is($res->{data}{updateAuthor}{name}, 'UQ Updated',
        'name updated via unique constraint lookup');
}

# updateAuthor — row not found surfaces in errors array
{
    my ($db, $schema, $ctx) = fresh();
    my $res = gql($schema, $ctx, 'mutation {
        updateAuthor(id: 9999, name: "Ghost", email: "ghost@example.com") { id }
    }');

    ok(($res->{errors} && @{$res->{errors}}) || !defined $res->{data}{updateAuthor},
       'updateAuthor with unknown id returns null data or populates errors');
}

# createBook — with FK, verify nested author resolve
{
    my ($db, $schema, $ctx) = fresh();
    my $res = gql($schema, $ctx, 'mutation {
        createBook(title: "Dune", author_id: 1, price: 12.99) {
            id title price author { id }
        }
    }');

    ok(!$res->{errors}, 'createBook: no errors')
       or diag explain $res->{errors};
    my $book = $res->{data}{createBook};
    is($book->{title},      'Dune',  'createBook title correct'        );
    is($book->{price},      12.99,   'createBook price (Float) correct');
    is($book->{author}{id}, 1,       'createBook nested author id'     );
}

# deleteAuthor — by PK
{
    my ($db, $schema, $ctx) = fresh();
    $db->resultset('Author')->create({
        id    => 99,
        name  => 'To Delete',
        email => 'del@example.com'
    });

    is($db->resultset('Author')->count, 2, 'pre-delete count is 2');

    my $res = gql($schema, $ctx, 'mutation { deleteAuthor(id: 99) }');
    ok(!$res->{errors}, 'deleteAuthor: no errors')
       or diag explain $res->{errors};
    is($res->{data}{deleteAuthor}, 1, 'deleteAuthor returns true'        );
    is($db->resultset('Author')->count, 1, 'count back to 1 after delete');
}

# deleteAuthor — row not found returns false
{
    my ($db, $schema, $ctx) = fresh();
    my $res = gql($schema, $ctx, 'mutation { deleteAuthor(id: 9999) }');

    ok(!$res->{errors}, 'deleteAuthor (not found): no errors');
    is($res->{data}{deleteAuthor}, 0, 'deleteAuthor returns false for missing row');
}

# deleteAuthor — by unique constraint
{
    my ($db, $schema, $ctx) = fresh();
    my $res = gql($schema, $ctx,
        'mutation { deleteAuthor(email: "seed@example.com") }');

    ok(!$res->{errors}, 'deleteAuthor by unique constraint: no errors');
    is($res->{data}{deleteAuthor}, 1, 'deleteAuthor by UQ returns true');
    ok(!$db->resultset('Author')->find({ email => 'seed@example.com' }),
       'row is gone from DB' );
}

done_testing;
