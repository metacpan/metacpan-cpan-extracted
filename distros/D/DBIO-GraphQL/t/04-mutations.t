use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use My::Schema;
use My::Test qw(deploy_schema);
use DBIO::GraphQL;

sub fresh {
  my $db = My::Schema->connect('dbi:SQLite:dbname=:memory:');
  deploy_schema($db);
  $db->resultset('Author')->create({
    id    => 1,
    name  => 'Seed Author',
    email => 'seed@example.com',
  });
  my $r = DBIO::GraphQL->to_graphql($db, mutations => 1);
  return ($db, $r->{execute}, $r->{context});
}

sub gql {
  my ($exec, $ctx, $query, $vars) = @_;
  return $exec->($query, undef, $ctx, $vars // {});
}

# createAuthor - happy path
{
  my ($db, $exec, $ctx) = fresh();
  my $res = gql($exec, $ctx, 'mutation {
    createAuthor(name: "New Author", email: "new@example.com", rating: 7.5) {
      id name email rating
    }
  }');

  ok(!$res->{errors}, 'createAuthor: no errors')
    or diag explain $res->{errors};
  my $a = $res->{data}{createAuthor};
  ok($a->{id},                       'createAuthor returns an id' );
  is($a->{name},   'New Author',     'createAuthor name correct'  );
  is($a->{email},  'new@example.com','createAuthor email correct' );
  is($a->{rating}, 7.5,              'createAuthor rating correct');
  is($db->resultset('Author')->count, 2, 'Author count incremented');
}

# createAuthor — required field missing
{
  my ($db, $exec, $ctx) = fresh();
  my $res = gql($exec, $ctx,
    'mutation { createAuthor(email: "noname@example.com") { id } }');

  ok($res->{errors} && @{$res->{errors}},
    'createAuthor with missing NonNull field populates errors array');
}

# updateAuthor — by PK
{
  my ($db, $exec, $ctx) = fresh();
  my $res = gql($exec, $ctx, 'mutation {
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
  my ($db, $exec, $ctx) = fresh();
  my $res = gql($exec, $ctx, 'mutation {
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
  my ($db, $exec, $ctx) = fresh();
  my $res = gql($exec, $ctx, 'mutation {
    updateAuthor(id: 9999, name: "Ghost", email: "ghost@example.com") { id }
  }');

  ok(($res->{errors} && @{$res->{errors}}) || !defined $res->{data}{updateAuthor},
    'updateAuthor with unknown id returns null data or populates errors');
}

# updateAuthor — a complete primary key alone names the row. The email of
# another row is a data argument here, not a second way to find a target:
# an unknown id must fail and leave that other row untouched (karr k7).
{
  my ($db, $exec, $ctx) = fresh();
  $db->resultset('Author')->create({
    id    => 2,
    name  => 'Bystander',
    email => 'bystander@example.com',
  });

  my $res = gql($exec, $ctx, 'mutation {
    updateAuthor(id: 999, email: "bystander@example.com", name: "HIJACKED") {
      id name
    }
  }');

  like(($res->{errors} // [])->[0]{message} // '', qr/No Author row found/,
    'updateAuthor with unknown PK reports the row as not found');
  is($res->{data}{updateAuthor}, undef,
    'updateAuthor with unknown PK returns no row');
  is($db->resultset('Author')->find(2)->name, 'Bystander',
    'row owning the supplied unique value is not updated');
  is($db->resultset('Author')->find(1)->name, 'Seed Author',
    'seed row is not updated either');
}

# createBook — with FK, verify nested author resolve
{
  my ($db, $exec, $ctx) = fresh();
  my $res = gql($exec, $ctx, 'mutation {
    createBook(title: "Dune", author_id: 1, price: 12.99) {
      id title price author { id }
    }
  }');

  ok(!$res->{errors}, 'createBook: no errors')
    or diag explain $res->{errors};
  my $book = $res->{data}{createBook};
  is($book->{title},      'Dune', 'createBook title correct'        );
  is($book->{price},      12.99,  'createBook price (Float) correct');
  is($book->{author}{id}, 1,      'createBook nested author id'     );
}

# deleteAuthor — by PK
{
  my ($db, $exec, $ctx) = fresh();
  $db->resultset('Author')->create({
    id    => 99,
    name  => 'To Delete',
    email => 'del@example.com'
  });

  is($db->resultset('Author')->count, 2, 'pre-delete count is 2');

  my $res = gql($exec, $ctx, 'mutation { deleteAuthor(id: 99) }');
  ok(!$res->{errors}, 'deleteAuthor: no errors')
    or diag explain $res->{errors};
  is($res->{data}{deleteAuthor}, 1, 'deleteAuthor returns true'        );
  is($db->resultset('Author')->count, 1, 'count back to 1 after delete');
}

# deleteAuthor — row not found returns false
{
  my ($db, $exec, $ctx) = fresh();
  my $res = gql($exec, $ctx, 'mutation { deleteAuthor(id: 9999) }');

  ok(!$res->{errors}, 'deleteAuthor (not found): no errors');
  is($res->{data}{deleteAuthor}, 0, 'deleteAuthor returns false for missing row');
}

# deleteAuthor — by unique constraint
{
  my ($db, $exec, $ctx) = fresh();
  my $res = gql($exec, $ctx,
    'mutation { deleteAuthor(email: "seed@example.com") }');

  ok(!$res->{errors}, 'deleteAuthor by unique constraint: no errors');
  is($res->{data}{deleteAuthor}, 1, 'deleteAuthor by UQ returns true');
  ok(!$db->resultset('Author')->find({ email => 'seed@example.com' }),
    'row is gone from DB');
}

# deleteAuthor — a complete primary key alone names the row: an unknown id
# returns false and must not delete the row that owns the supplied unique
# value (karr k7).
{
  my ($db, $exec, $ctx) = fresh();
  $db->resultset('Author')->create({
    id    => 3,
    name  => 'Bystander',
    email => 'bystander@example.com',
  });

  my $res = gql($exec, $ctx,
    'mutation { deleteAuthor(id: 999, email: "bystander@example.com") }');

  ok(!$res->{errors}, 'deleteAuthor with unknown PK: no errors')
    or diag explain $res->{errors};
  is($res->{data}{deleteAuthor}, 0, 'deleteAuthor with unknown PK returns false');
  ok($db->resultset('Author')->find(3),
    'row owning the supplied unique value is still there');
  is($db->resultset('Author')->count, 2, 'no row was deleted');
}

# deleteAuthor — a failing DELETE (FK violation) surfaces in errors;
# false means "row not found" (karr k8).
{
  my ($db, $exec, $ctx) = fresh();
  $db->storage->dbh->do('PRAGMA foreign_keys = ON');
  $db->resultset('Book')->create({ id => 1, title => 'Held', author_id => 1 });

  # SQLite reports no SQLSTATE, so the envelope cannot classify the refusal:
  # it is an internal error, its text goes to the warning, not to the client.
  my @warnings;
  my $res = do {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    gql($exec, $ctx, 'mutation { deleteAuthor(id: 1) }');
  };

  ok($res->{errors} && @{$res->{errors}},
    'deleteAuthor with an FK-violating DELETE populates errors');
  is($res->{errors}[0]{message}, 'internal error',
    'the client gets "internal error", not the database message');
  is($res->{errors}[0]{extensions}{code}, 'INTERNAL_ERROR', 'with the code INTERNAL_ERROR');
  like(join('', @warnings), qr/FOREIGN KEY constraint failed/,
    'the database message goes to the warning');
  ok(!defined $res->{data}{deleteAuthor},
    'data for the failed deleteAuthor is null');
  is($db->resultset('Author')->count, 1, 'author row is still there');
}

done_testing;
