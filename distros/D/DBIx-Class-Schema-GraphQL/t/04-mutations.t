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

# patchAuthor — change one column, verify the other is untouched
{
    my ($db, $schema, $ctx) = fresh();
    my $res = gql($schema, $ctx, 'mutation {
        patchAuthor(id: 1, name: "Patched Name") {
            id name email
        }
    }');

    ok(!$res->{errors}, 'patchAuthor single column: no errors')
        or diag explain $res->{errors};
    my $a = $res->{data}{patchAuthor};
    is($a->{name},  'Patched Name',      'patchAuthor: name was updated'   );
    is($a->{email}, 'seed@example.com',  'patchAuthor: email was untouched');

    my $row = $db->resultset('Author')->find(1);
    is($row->name,  'Patched Name',     'DB: name reflects patch'          );
    is($row->email, 'seed@example.com', 'DB: email unchanged after patch'  );
}

# patchAuthor — change a different column, verify the first is still intact
{
    my ($db, $schema, $ctx) = fresh();
    my $res = gql($schema, $ctx, 'mutation {
        patchAuthor(id: 1, email: "patched@example.com") {
            id name email
        }
    }');

    ok(!$res->{errors}, 'patchAuthor email only: no errors')
        or diag explain $res->{errors};
    my $a = $res->{data}{patchAuthor};
    is($a->{email}, 'patched@example.com', 'patchAuthor: email was updated' );
    is($a->{name},  'Seed Author',         'patchAuthor: name was untouched');

    my $row = $db->resultset('Author')->find(1);
    is($row->email, 'patched@example.com', 'DB: email reflects patch'       );
    is($row->name,  'Seed Author',         'DB: name unchanged after patch' );
}

# patchAuthor — by unique constraint
{
    my ($db, $schema, $ctx) = fresh();
    my $res = gql($schema, $ctx, 'mutation {
        patchAuthor(email: "seed@example.com", name: "UQ Patched") {
            id name email
        }
    }');

    ok(!$res->{errors}, 'patchAuthor by unique constraint: no errors')
        or diag explain $res->{errors};
    is($res->{data}{patchAuthor}{name},  'UQ Patched',         'name updated via UQ lookup');
    is($res->{data}{patchAuthor}{email}, 'seed@example.com',   'email untouched via UQ patch');
}

# patchAuthor — row not found surfaces in errors array
{
    my ($db, $schema, $ctx) = fresh();
    my $res = gql($schema, $ctx, 'mutation {
        patchAuthor(id: 9999, name: "Ghost") { id }
    }');

    ok(($res->{errors} && @{$res->{errors}}) || !defined $res->{data}{patchAuthor},
        'patchAuthor with unknown id returns null data or populates errors');
}

# patchAuthor — no non-key columns supplied is an error
{
    my ($db, $schema, $ctx) = fresh();
    my $res = gql($schema, $ctx, 'mutation {
        patchAuthor(id: 1) { id name }
    }');

    ok($res->{errors} && @{$res->{errors}},
        'patchAuthor with only PK and no data columns populates errors array');
    my $row = $db->resultset('Author')->find(1);
    is($row->name, 'Seed Author', 'DB: row is untouched after no-op patch attempt');
}

# patchBook — patch only price, title untouched
{
    my ($db, $schema, $ctx) = fresh();
    $db->resultset('Book')->create({
        id        => 1,
        title     => 'Original Title',
        author_id => 1,
        price     => 9.99,
    });

    my $res = gql($schema, $ctx, 'mutation {
        patchBook(id: 1, price: 19.99) {
            id title price
        }
    }');

    ok(!$res->{errors}, 'patchBook price only: no errors')
        or diag explain $res->{errors};
    my $b = $res->{data}{patchBook};
    is($b->{price}, 19.99,            'patchBook: price was updated'   );
    is($b->{title}, 'Original Title', 'patchBook: title was untouched' );

    my $row = $db->resultset('Book')->find(1);
    is($row->price, 19.99,            'DB: price reflects patch'       );
    is($row->title, 'Original Title', 'DB: title unchanged after patch');
}

done_testing;
