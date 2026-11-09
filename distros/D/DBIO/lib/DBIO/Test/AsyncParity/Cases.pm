package DBIO::Test::AsyncParity::Cases;
# ABSTRACT: The case table of DBIO::Test::AsyncParity: ResultSet operations, once synchronous and once asynchronous

use strict;
use warnings;

our $VERSION = '0.900004';

use Scalar::Util ();
use DBIO::Exception ();


sub fixture {
  return {
    artists => [
      [ 'Caterwauler McCrae' => 10 ],
      [ 'Random Boy Band'    => 20 ],
      [ 'We Are Goth'        => 30 ],
    ],
    cds => [
      [ 'Caterwauler McCrae', 'Spoonful of bees',             1999 ],
      [ 'Caterwauler McCrae', 'Forkful of chips',             2001 ],
      [ 'Random Boy Band',    "Caterwaulin' Blues",           1997 ],
      [ 'We Are Goth',        'Generic Manufactured Singles', 2001 ],
    ],
    tracks => [
      [ 'Spoonful of bees', 1, 'Boring Name' ],
      [ 'Spoonful of bees', 2, 'Boring Song' ],
      [ 'Spoonful of bees', 3, 'No More Ideas' ],
      [ 'Forkful of chips', 1, 'Stripy' ],
    ],
  };
}


# --------------------------------------------------------------- the helpers

my $FIRST  = 'Caterwauler McCrae';
my $SECOND = 'Random Boy Band';

sub _rs { return $_[0]->resultset($_[1]) }

# A seeded artist, found by name through the synchronous path. Reads are the
# same on both ways: a case's own subject is what differs.
sub _artist {
  my ($schema, $name) = @_;
  my $row = _rs($schema, 'Artist')->search({ name => $name })->single;
  DBIO::Exception->throw("the fixture artist '$name' is not there -- was it seeded?")
    unless $row;
  return $row;
}

sub _cd {
  my ($schema, $title) = @_;
  my $row = _rs($schema, 'CD')->search({ title => $title })->single;
  DBIO::Exception->throw("the fixture CD '$title' is not there -- was it seeded?")
    unless $row;
  return $row;
}

sub _pick {
  my ($row, @cols) = @_;
  return undef unless defined $row;
  return { map { $_ => $row->get_column($_) } @cols };
}

sub _picks {
  my @cols = @_;
  return sub { [ map { _pick($_, @cols) } @_ ] };
}

sub _count_named {
  my ($source, $col, $value) = @_;
  return sub { _rs($_[0], $source)->search({ $col => $value })->count };
}

# The storage-level insert both ways of the transaction cases use.
sub _insert_args {
  my ($schema, $name) = @_;
  return ($schema->source('Artist'), { name => $name, rank => 5 });
}

# Chain a list of async steps one after the other, resolving with $last->().
sub _sequence {
  my ($fc, $steps, $last) = @_;
  my $f = $fc->done;
  for my $step (@$steps) {
    my $s = $step;
    $f = $f->then(sub { $s->() });
  }
  return $f->then(sub { $last->() });
}

# --------------------------------------------------------------------- cases


sub cases {
  my @case;

  # ------------------------------------------------------------------ reads
  push @case, {
    no => 1, name => 'find-pk', kind => 'direct',
    doc  => 'find by primary key',
    sync => sub {
      my ($s) = @_;
      my $id = _artist($s, $FIRST)->artistid;
      return _rs($s, 'Artist')->find($id);
    },
    async => sub {
      my ($s) = @_;
      my $id = _artist($s, $FIRST)->artistid;
      return _rs($s, 'Artist')->find_async($id);
    },
    norm => _picks(qw(name rank)),
  };

  push @case, {
    no => 2, name => 'find-unique', kind => 'direct',
    doc  => 'find by a named unique constraint (ADR 0034)',
    sync => sub {
      return _rs($_[0], 'Artist')->find({ name => $SECOND }, { key => 'artist_name' });
    },
    async => sub {
      return _rs($_[0], 'Artist')->find_async({ name => $SECOND }, { key => 'artist_name' });
    },
    norm => _picks(qw(name rank)),
  };

  push @case, {
    no => 3, name => 'find-miss', kind => 'direct',
    doc  => 'find that matches nothing answers undef, not an error',
    sync => sub {
      return _rs($_[0], 'Artist')->find({ name => 'No Such Artist' }, { key => 'artist_name' });
    },
    async => sub {
      return _rs($_[0], 'Artist')->find_async({ name => 'No Such Artist' }, { key => 'artist_name' });
    },
    norm => sub { [ map { defined $_ ? 'row' : undef } @_ ] },
  };

  push @case, {
    no => 4, name => 'find-rel-key', kind => 'direct',
    doc  => 'find whose key holds a relationship value (ResultSet find, ADR 0034)',
    sync => sub {
      my ($s) = @_;
      return _rs($s, 'CD')->find({ artist => _artist($s, $FIRST), title => 'Spoonful of bees' });
    },
    async => sub {
      my ($s) = @_;
      return _rs($s, 'CD')->find_async({ artist => _artist($s, $FIRST), title => 'Spoonful of bees' });
    },
    norm => _picks(qw(title year)),
  };

  push @case, {
    no => 5, name => 'search-all', kind => 'direct',
    doc  => 'search with a condition, all rows',
    sync => sub {
      return _rs($_[0], 'Artist')->search({ rank => { '>=' => 10 } }, { order_by => 'name' })->all;
    },
    async => sub {
      return _rs($_[0], 'Artist')->search({ rank => { '>=' => 10 } }, { order_by => 'name' })->all_async;
    },
    norm => _picks(qw(name rank)),
  };

  push @case, {
    no => 6, name => 'order-rows-offset', kind => 'direct',
    doc  => 'order_by with rows and offset',
    sync => sub {
      return _rs($_[0], 'Artist')
        ->search({}, { order_by => { -desc => 'name' }, rows => 2, offset => 1 })->all;
    },
    async => sub {
      return _rs($_[0], 'Artist')
        ->search({}, { order_by => { -desc => 'name' }, rows => 2, offset => 1 })->all_async;
    },
    norm => _picks(qw(name rank)),
  };

  push @case, {
    no => 7, name => 'group-by', kind => 'direct',
    doc  => 'group_by over a column subset',
    sync => sub {
      return _rs($_[0], 'CD')
        ->search({}, { columns => ['year'], group_by => ['year'], order_by => 'year' })->all;
    },
    async => sub {
      return _rs($_[0], 'CD')
        ->search({}, { columns => ['year'], group_by => ['year'], order_by => 'year' })->all_async;
    },
    norm => _picks('year'),
  };

  push @case, {
    no => 8, name => 'prefetch', kind => 'direct',
    doc  => 'prefetch of a has_many, collapsed',
    sync => sub {
      return _rs($_[0], 'Artist')
        ->search({ 'me.name' => $FIRST }, { prefetch => 'cds', order_by => 'cds.year' })->all;
    },
    async => sub {
      return _rs($_[0], 'Artist')
        ->search({ 'me.name' => $FIRST }, { prefetch => 'cds', order_by => 'cds.year' })->all_async;
    },
    norm => sub {
      [ map { { name => $_->name, cds => [ map { $_->title } $_->cds->all ] } } @_ ];
    },
  };

  push @case, {
    no => 9, name => 'join', kind => 'direct',
    doc  => 'join on a relationship, columns of the base table only',
    sync => sub {
      return _rs($_[0], 'Artist')->search(
        { 'cds.year' => 2001 },
        { join => 'cds', columns => ['name'], distinct => 1, order_by => 'name' },
      )->all;
    },
    async => sub {
      return _rs($_[0], 'Artist')->search(
        { 'cds.year' => 2001 },
        { join => 'cds', columns => ['name'], distinct => 1, order_by => 'name' },
      )->all_async;
    },
    norm => _picks('name'),
  };

  push @case, {
    no => 10, name => 'search-related', kind => 'composed',
    doc  => 'a related resultset of a row; the chain has no async method of its own',
    sync => sub {
      my ($s) = @_;
      return _artist($s, $FIRST)->search_related('cds', {}, { order_by => 'year' })->all;
    },
    async => sub {
      my ($s) = @_;
      return _artist($s, $FIRST)->search_related('cds', {}, { order_by => 'year' })->all_async;
    },
    norm => _picks(qw(title year)),
  };

  push @case, {
    no => 11, name => 'first', kind => 'direct',
    doc  => 'first row of an ordered set',
    sync => sub {
      return _rs($_[0], 'Artist')->search({}, { order_by => 'name' })->first;
    },
    async => sub {
      return _rs($_[0], 'Artist')->search({}, { order_by => 'name' })->first_async;
    },
    norm => _picks(qw(name rank)),
  };

  push @case, {
    no => 12, name => 'single', kind => 'direct',
    doc  => 'single row by a condition',
    sync => sub {
      return _rs($_[0], 'Artist')->search({ name => $SECOND })->single;
    },
    async => sub {
      return _rs($_[0], 'Artist')->search({ name => $SECOND })->single_async;
    },
    norm => _picks(qw(name rank)),
  };

  push @case, {
    no => 13, name => 'count', kind => 'direct',
    doc  => 'count of a condition',
    sync => sub {
      return _rs($_[0], 'CD')->search({ year => 2001 })->count;
    },
    async => sub {
      return _rs($_[0], 'CD')->search({ year => 2001 })->count_async;
    },
    norm => sub { [ @_ ] },
  };

  push @case, {
    no => 14, name => 'count-literal', kind => 'direct',
    doc  => 'count with a literal SQL condition and a bind value',
    sync => sub {
      return _rs($_[0], 'Artist')->count_literal($_[0]->storage->sql_maker->_quote('rank') . ' > ?', 15);
    },
    async => sub {
      return _rs($_[0], 'Artist')->count_literal_async($_[0]->storage->sql_maker->_quote('rank') . ' > ?', 15);
    },
    norm => sub { [ @_ ] },
  };

  push @case, {
    no => 15, name => 'results-exist', kind => 'direct',
    doc  => 'the EXISTS question, for a hit and a miss',
    sync => sub {
      my ($s) = @_;
      return (
        _rs($s, 'Artist')->search({ name => $FIRST })->results_exist,
        _rs($s, 'Artist')->search({ name => 'No Such Artist' })->results_exist,
      );
    },
    async => sub {
      my ($s) = @_;
      my $hit = _rs($s, 'Artist')->search({ name => $FIRST })->results_exist_async;
      return $hit->then(sub {
        my $first = $_[0];
        return _rs($s, 'Artist')->search({ name => 'No Such Artist' })->results_exist_async
          ->then(sub { [ $first, $_[0] ] });
      });
    },
    norm => sub {
      my @r = ref $_[0] eq 'ARRAY' ? @{ $_[0] } : @_;
      return [ map { $_ ? 1 : 0 } @r ];
    },
  };

  push @case, {
    no => 16, name => 'rsc-all', kind => 'direct',
    doc  => 'all values of one column',
    sync => sub {
      return _rs($_[0], 'Artist')->search({}, { order_by => 'name' })->get_column('name')->all;
    },
    async => sub {
      return _rs($_[0], 'Artist')->search({}, { order_by => 'name' })->get_column('name')->all_async;
    },
    norm => sub { [ @_ ] },
  };

  push @case, {
    no => 17, name => 'rsc-single', kind => 'direct',
    doc  => 'single value of one column',
    sync => sub {
      return _rs($_[0], 'Artist')->search({ name => $FIRST })->get_column('rank')->single;
    },
    async => sub {
      return _rs($_[0], 'Artist')->search({ name => $FIRST })->get_column('rank')->single_async;
    },
    norm => sub { [ @_ ] },
  };

  push @case, {
    no => 18, name => 'rsc-min-max-sum', kind => 'direct',
    doc  => 'min, max and sum of a column',
    sync => sub {
      my $col = _rs($_[0], 'Artist')->get_column('rank');
      return [ scalar $col->min, scalar $col->max, scalar $col->sum ];
    },
    async => sub {
      my $col = _rs($_[0], 'Artist')->get_column('rank');
      return $col->min_async->then(sub {
        my $min = $_[0];
        return $col->max_async->then(sub {
          my $max = $_[0];
          return $col->sum_async->then(sub { [ $min, $max, $_[0] ] });
        });
      });
    },
    norm => sub { $_[0] },
  };

  push @case, {
    no => 19, name => 'rsc-func', kind => 'direct',
    doc  => 'an aggregate function by name',
    sync => sub {
      return scalar _rs($_[0], 'Artist')->get_column('rank')->func('MAX');
    },
    async => sub {
      return _rs($_[0], 'Artist')->get_column('rank')->func_async('MAX');
    },
    norm => sub { [ @_ ] },
  };

  # ----------------------------------------------------------------- writes
  push @case, {
    no => 20, name => 'create', kind => 'direct',
    doc  => 'create a row',
    sync => sub {
      return _rs($_[0], 'Artist')->create({ name => 'Parity Created', rank => 5 });
    },
    async => sub {
      return _rs($_[0], 'Artist')->create_async({ name => 'Parity Created', rank => 5 });
    },
    norm    => _picks(qw(name rank)),
    observe => _count_named('Artist', name => 'Parity Created'),
  };

  my $cascade = sub {
    return {
      artist => { name => 'Parity Cascade Artist', rank => 7 },
      title  => 'Parity Cascade CD',
      year   => 2020,
      tracks => [ { position => 1, title => 'Parity Cascade Track' } ],
    };
  };
  push @case, {
    no => 21, name => 'create-cascade', kind => 'composed',
    doc  => 'create with nested data: related rows in one multi-create',
    sync => sub {
      return _rs($_[0], 'CD')->create($cascade->());
    },
    async => sub {
      return _rs($_[0], 'CD')->create_async($cascade->());
    },
    norm => sub {
      [ map { { title => $_->title, year => $_->year, artist => $_->artist->name } } @_ ];
    },
    observe => _count_named('Artist', name => 'Parity Cascade Artist'),
  };

  push @case, {
    no => 22, name => 'row-insert', kind => 'direct',
    doc  => 'insert a row built with new_result',
    sync => sub {
      return _rs($_[0], 'Artist')->new_result({ name => 'Parity Inserted', rank => 6 })->insert;
    },
    async => sub {
      return _rs($_[0], 'Artist')->new_result({ name => 'Parity Inserted', rank => 6 })->insert_async;
    },
    norm => sub { [ map { { %{ _pick($_, qw(name rank)) }, in_storage => $_->in_storage ? 1 : 0 } } @_ ] },
    observe => _count_named('Artist', name => 'Parity Inserted'),
  };

  push @case, {
    no => 23, name => 'row-update', kind => 'direct',
    doc  => 'update a fetched row',
    sync => sub {
      return _artist($_[0], $SECOND)->update({ rank => 99 });
    },
    async => sub {
      return _artist($_[0], $SECOND)->update_async({ rank => 99 });
    },
    norm    => _picks(qw(name rank)),
    observe => _count_named('Artist', rank => 99),
  };

  push @case, {
    no => 24, name => 'row-update-rs-loop', kind => 'composed',
    doc  => 'update of a set: ResultSet update has no async twin, so row by row',
    sync => sub {
      my @rows = _rs($_[0], 'CD')->search({ year => 2001 }, { order_by => 'title' })->all;
      $_->update({ year => 2002 }) for @rows;
      return scalar @rows;
    },
    async => sub {
      my ($s) = @_;
      my $fc = $s->storage->future_class;
      return _rs($s, 'CD')->search({ year => 2001 }, { order_by => 'title' })->all_async->then(sub {
        my @rows = @_;
        return _sequence(
          $fc,
          [ map { my $r = $_; sub { $r->update_async({ year => 2002 }) } } @rows ],
          sub { scalar @rows },
        );
      });
    },
    norm    => sub { [ @_ ] },
    observe => _count_named('CD', year => 2002),
  };

  push @case, {
    no => 25, name => 'row-delete', kind => 'direct',
    doc  => 'delete a fetched row (OneKey: a source with nothing to cascade into)',
    sync => sub {
      my $row = _rs($_[0], 'OneKey')->create({ artist => 4242, cd => 1 });
      return $row->delete;
    },
    async => sub {
      my $row = _rs($_[0], 'OneKey')->create({ artist => 4242, cd => 1 });
      return $row->delete_async;
    },
    norm    => sub { [ map { $_->in_storage ? 1 : 0 } @_ ] },
    observe => _count_named('OneKey', artist => 4242),
  };

  push @case, {
    no => 26, name => 'row-delete-rs-loop', kind => 'composed',
    doc  => 'delete of a set: ResultSet delete has no async twin, so row by row',
    sync => sub {
      my ($s) = @_;
      _rs($s, 'Artist')->create({ name => "Parity Doomed $_", rank => 1 }) for qw(A B);
      my @rows = _rs($s, 'Artist')->search({ name => { -like => 'Parity Doomed %' } })->all;
      $_->delete for @rows;
      return scalar @rows;
    },
    async => sub {
      my ($s) = @_;
      my $fc = $s->storage->future_class;
      _rs($s, 'Artist')->create({ name => "Parity Doomed $_", rank => 1 }) for qw(A B);
      return _rs($s, 'Artist')->search({ name => { -like => 'Parity Doomed %' } })->all_async->then(sub {
        my @rows = @_;
        return _sequence(
          $fc,
          [ map { my $r = $_; sub { $r->delete_async } } @rows ],
          sub { scalar @rows },
        );
      });
    },
    norm    => sub { [ @_ ] },
    observe => sub {
      _rs($_[0], 'Artist')->search({ name => { -like => 'Parity Doomed %' } })->count;
    },
  };

  push @case, {
    no => 27, name => 'row-copy', kind => 'direct',
    doc  => 'copy a row with new values (OneKey: no cascade_copy relationship)',
    sync => sub {
      my $row = _rs($_[0], 'OneKey')->create({ artist => 4243, cd => 1 });
      return $row->copy({ cd => 2 });
    },
    async => sub {
      my $row = _rs($_[0], 'OneKey')->create({ artist => 4243, cd => 1 });
      return $row->copy_async({ cd => 2 });
    },
    norm    => _picks(qw(artist cd)),
    observe => _count_named('OneKey', artist => 4243),
  };

  push @case, {
    no => 28, name => 'row-reload', kind => 'direct',
    doc  => 'get_from_storage and discard_changes',
    sync => sub {
      my $row = _artist($_[0], $FIRST);
      $row->rank(1234);
      my $fresh = $row->get_from_storage;
      $row->discard_changes;
      return [ _pick($fresh, qw(name rank)), _pick($row, qw(name rank)) ];
    },
    async => sub {
      my $row = _artist($_[0], $FIRST);
      $row->rank(1234);
      return $row->get_from_storage_async->then(sub {
        my $fresh = $_[0];
        return $row->discard_changes_async->then(sub {
          return [ _pick($fresh, qw(name rank)), _pick($row, qw(name rank)) ];
        });
      });
    },
    norm => sub { $_[0] },
  };

  push @case, {
    no => 29, name => 'update-or-insert', kind => 'direct',
    doc  => 'update_or_insert of a row not in storage inserts it',
    sync => sub {
      return _rs($_[0], 'Artist')->new_result({ name => 'Parity Uoi', rank => 3 })->update_or_insert;
    },
    async => sub {
      return _rs($_[0], 'Artist')->new_result({ name => 'Parity Uoi', rank => 3 })->update_or_insert_async;
    },
    norm    => sub { [ map { { %{ _pick($_, qw(name rank)) }, in_storage => $_->in_storage ? 1 : 0 } } @_ ] },
    observe => _count_named('Artist', name => 'Parity Uoi'),
  };

  push @case, {
    no => 30, name => 'find-or-create', kind => 'direct',
    doc  => 'find_or_create of a row that is not there creates it',
    sync => sub {
      return _rs($_[0], 'Artist')->find_or_create({ name => 'Parity Foc', rank => 4 });
    },
    async => sub {
      return _rs($_[0], 'Artist')->find_or_create_async({ name => 'Parity Foc', rank => 4 });
    },
    norm    => _picks(qw(name rank)),
    observe => _count_named('Artist', name => 'Parity Foc'),
  };

  push @case, {
    no => 31, name => 'find-or-new', kind => 'direct',
    doc  => 'find_or_new of a row that is not there builds it, unstored',
    sync => sub {
      return _rs($_[0], 'Artist')->find_or_new({ name => 'Parity For New', rank => 4 });
    },
    async => sub {
      return _rs($_[0], 'Artist')->find_or_new_async({ name => 'Parity For New', rank => 4 });
    },
    norm => sub { [ map { { %{ _pick($_, qw(name rank)) }, in_storage => $_->in_storage ? 1 : 0 } } @_ ] },
  };

  push @case, {
    no => 32, name => 'update-or-create', kind => 'direct',
    doc  => 'update_or_create of a row that is there updates it',
    sync => sub {
      return _rs($_[0], 'Artist')->update_or_create({ name => $SECOND, rank => 77 });
    },
    async => sub {
      return _rs($_[0], 'Artist')->update_or_create_async({ name => $SECOND, rank => 77 });
    },
    norm    => _picks(qw(name rank)),
    observe => _count_named('Artist', rank => 77),
  };

  push @case, {
    no => 33, name => 'update-or-new', kind => 'direct',
    doc  => 'update_or_new of a row that is there updates it',
    sync => sub {
      return _rs($_[0], 'Artist')->update_or_new({ name => $SECOND, rank => 88 });
    },
    async => sub {
      return _rs($_[0], 'Artist')->update_or_new_async({ name => $SECOND, rank => 88 });
    },
    norm => sub { [ map { { %{ _pick($_, qw(name rank)) }, in_storage => $_->in_storage ? 1 : 0 } } @_ ] },
  };

  push @case, {
    no => 34, name => 'upsert', kind => 'direct',
    doc  => 'single-statement upsert (needs the supports_upsert capability, ADR 0036)',
    sync => sub {
      return _rs($_[0], 'Artist')->upsert({ name => 'Parity Upsert', rank => 9 }, { conflict_target => ['name'] });
    },
    async => sub {
      return _rs($_[0], 'Artist')->upsert_async({ name => 'Parity Upsert', rank => 9 }, { conflict_target => ['name'] });
    },
    norm    => _picks(qw(name rank)),
    observe => _count_named('Artist', name => 'Parity Upsert'),
  };

  # ----------------------------------------------- transactions and context
  push @case, {
    no => 35, name => 'txn-commit', kind => 'direct',
    doc  => 'a transaction that commits: txn_do and txn_do_async',
    sync => sub {
      my ($s) = @_;
      my $st = $s->storage;
      return $st->txn_do(sub {
        $st->insert(_insert_args($s, 'Parity Txn Commit'));
        return 'committed';
      });
    },
    async => sub {
      my ($s) = @_;
      return $s->storage->txn_do_async(sub {
        my ($ctx) = @_;
        return $ctx->insert_async(_insert_args($s, 'Parity Txn Commit'))
          ->then(sub { 'committed' });
      });
    },
    norm    => sub { [ @_ ] },
    observe => _count_named('Artist', name => 'Parity Txn Commit'),
  };

  push @case, {
    no => 36, name => 'txn-rollback', kind => 'direct',
    doc  => 'a transaction that fails rolls back and rethrows',
    sync => sub {
      my ($s) = @_;
      my $st = $s->storage;
      return $st->txn_do(sub {
        $st->insert(_insert_args($s, 'Parity Txn Rollback'));
        DBIO::Exception->throw('parity rollback');
      });
    },
    async => sub {
      my ($s) = @_;
      my $fc = $s->storage->future_class;
      return $s->storage->txn_do_async(sub {
        my ($ctx) = @_;
        return $ctx->insert_async(_insert_args($s, 'Parity Txn Rollback'))->then(sub {
          eval { DBIO::Exception->throw('parity rollback') };
          return $fc->fail($@);
        });
      });
    },
    expect_error => qr/parity rollback/,
    norm         => sub { [ @_ ] },
    observe      => _count_named('Artist', name => 'Parity Txn Rollback'),
  };

  push @case, {
    no => 37, name => 'txn-with-context', kind => 'composed',
    doc  => 'a ResultSet bound to the transaction context writes inside it (with_context)',
    sync => sub {
      my ($s) = @_;
      return $s->storage->txn_do(sub {
        return _rs($s, 'Artist')->create({ name => 'Parity Txn Context', rank => 8 });
      });
    },
    async => sub {
      my ($s) = @_;
      return $s->storage->txn_do_async(sub {
        my ($ctx) = @_;
        return _rs($s, 'Artist')->with_context($ctx)
          ->create_async({ name => 'Parity Txn Context', rank => 8 });
      });
    },
    norm    => _picks(qw(name rank)),
    observe => _count_named('Artist', name => 'Parity Txn Context'),
  };

  push @case, {
    no => 38, name => 'txn-adopts-future', kind => 'async-only',
    doc  => 'the Future a txn_do_async coderef returns is adopted: its value is the result',
    async => sub {
      my ($s) = @_;
      return $s->storage->txn_do_async(sub {
        my ($ctx) = @_;
        return $ctx->insert_async(_insert_args($s, 'Parity Txn Adopt'))
          ->then(sub { 'adopted' });
      });
    },
    expect  => [ 'adopted' ],
    norm    => sub { [ @_ ] },
    observe => _count_named('Artist', name => 'Parity Txn Adopt'),
  };

  # ----------------------------------------------------------------- errors
  push @case, {
    no => 39, name => 'err-unique', kind => 'direct',
    doc  => 'a unique violation is the same exception class on both ways',
    sync => sub {
      return _rs($_[0], 'Artist')->create({ name => $FIRST, rank => 1 });
    },
    async => sub {
      return _rs($_[0], 'Artist')->create_async({ name => $FIRST, rank => 1 });
    },
    expect_error => 1,
    norm         => sub { [ @_ ] },
  };

  push @case, {
    no => 40, name => 'async-on-sync-connection', kind => 'async-only',
    doc  => 'an *_async call on a connection without an async mode croaks, it does not degrade',
    async => sub {
      my ($s, $env) = @_;
      return _rs($env->{sync_schema}->(), 'Artist')->all_async;
    },
    expect_error => qr/not an async connection/,
    norm         => sub { [ @_ ] },
  };

  # ---------------------------------------------------- no async twin: named
  push @case, {
    no => 41, name => 'populate', kind => 'composed',
    doc  => 'populate has no async twin (ResultSet, section ASYNC); stated, not invented',
    sync => sub {
      my @rows = _rs($_[0], 'Artist')->populate([
        { name => 'Parity Populate 1', rank => 1 },
        { name => 'Parity Populate 2', rank => 2 },
      ]);
      return scalar @rows;
    },
    async => sub {
      my $rs = _rs($_[0], 'Artist');
      DBIO::Exception->throw('ResultSet populate has no async twin: there is no populate_async')
        unless $rs->can('populate_async');
      return $rs->populate_async([
        { name => 'Parity Populate 1', rank => 1 },
        { name => 'Parity Populate 2', rank => 2 },
      ])->then(sub { scalar @_ == 1 && ref $_[0] eq 'ARRAY' ? scalar @{ $_[0] } : scalar @_ });
    },
    absent  => qr/populate has no async twin/,
    norm    => sub { [ @_ ] },
    observe => sub {
      _rs($_[0], 'Artist')->search({ name => { -like => 'Parity Populate %' } })->count;
    },
  };

  push @case, _bracket_cases();
  push @case, _failure_cases();
  push @case, _pool_cases();
  push @case, _transport_cases();

  return \@case;
}

# ------------------------------------------------------------ the helpers (2)

sub _async { return $_[0]->storage->async }
sub _fc    { return $_[0]->storage->future_class }

# The number of artists with a name, asked on a connection of its own: the
# follow-up every case ends with, which shows the pool still serves.
sub _count_async {
  my ($s, $name) = @_;
  my $rs = _rs($s, 'Artist');
  $rs = $rs->search({ name => $name }) if defined $name;
  return $rs->count_async;
}

# The connections of the pool, all of them, held: a Future of the list.
sub _hold_all {
  my ($s, $leave) = @_;
  my $pool = _async($s)->pool;
  my $n    = $pool->max_size - ($leave // 0);
  return _fc($s)->done if $n < 1;
  return _fc($s)->needs_all(map { $pool->acquire } 1 .. $n);
}

sub _release_all {
  my ($s, @conn) = @_;
  my $pool = _async($s)->pool;
  $pool->release($_) for @conn;
  return;
}

# ---------------------------- pipeline, cancel (karr k396, k274, k232)

sub _bracket_cases {
  my @case;

  push @case, {
    no => 42, name => 'pipeline-commit', kind => 'async-only',
    requires => ['pipeline'],
    doc  => 'a pipeline of two inserts is sent as one batch and both rows are there',
    async => sub {
      my ($s) = @_;
      my $fc = _fc($s);
      return _async($s)->pipeline(sub {
        my ($p) = @_;
        return $fc->needs_all(
          $p->insert_async(_insert_args($s, 'Parity Pipe 1')),
          $p->insert_async(_insert_args($s, 'Parity Pipe 2')),
        );
      })->then(sub { $fc->done('piped') });
    },
    expect  => [ 'piped' ],
    norm    => sub { [ @_ ] },
    observe => sub {
      _rs($_[0], 'Artist')->search({ name => { -like => 'Parity Pipe %' } })->count;
    },
  };

  # The batch fails on its second statement. The connection is retired, the
  # open statements fail with the batch's error, and the pool serves the next
  # caller (karr core k396).
  push @case, {
    no => 43, name => 'pipeline-fail', kind => 'async-only',
    requires => ['pipeline'],
    doc  => 'a pipeline with a failing statement fails; the storage serves the next statement',
    async => sub {
      my ($s) = @_;
      my $fc = _fc($s);
      return _async($s)->pipeline(sub {
        my ($p) = @_;
        return $fc->needs_all(
          $p->insert_async(_insert_args($s, 'Parity Pipe Fail')),
          $p->insert_async($s->source('Artist'), { name => $FIRST, rank => 1 }),
        );
      })->then(
        sub { _count_async($s)->then(sub { $fc->done('batch succeeded') }) },
        sub { _count_async($s)->then(sub { $fc->done('batch failed', 'pool serves') }) },
      );
    },
    expect => [ 'batch failed', 'pool serves' ],
    norm   => sub { [ @_ ] },
  };

  push @case, {
    no => 44, name => 'cancel-txn', kind => 'async-only',
    requires => ['cancel'],
    doc  => 'a cancelled transaction rolls back; its row is not there and the pool serves',
    async => sub {
      my ($s) = @_;
      my $fc  = _fc($s);
      my $txn = $s->storage->txn_do_async(sub {
        my ($ctx) = @_;
        $ctx->insert_async(_insert_args($s, 'Parity Cancel Txn'));
        return $fc->new;
      });
      $txn->cancel;
      return _count_async($s, 'Parity Cancel Txn');
    },
    expect => [ 0 ],
    norm   => sub { [ @_ ] },
  };

  push @case, {
    no => 45, name => 'cancel-statement', kind => 'async-only',
    requires => ['cancel'],
    doc  => 'a cancelled statement gives its connection back; the pool serves',
    async => sub {
      my ($s) = @_;
      _rs($s, 'Artist')->all_async->cancel;
      return _count_async($s);
    },
    expect => [ 3 ],
    norm   => sub { [ @_ ] },
  };

  push @case, {
    no => 46, name => 'cancel-batch', kind => 'async-only',
    requires => [ 'pipeline', 'cancel' ],
    doc  => 'a cancelled pipeline retires its connection; the pool serves',
    async => sub {
      my ($s) = @_;
      my $fc    = _fc($s);
      my $batch = _async($s)->pipeline(sub {
        my ($p) = @_;
        $p->insert_async(_insert_args($s, 'Parity Cancel Batch'));
        return $fc->new;
      });
      $batch->cancel;
      return _count_async($s)->then(sub { $fc->done('pool serves') });
    },
    expect => [ 'pool serves' ],
    norm   => sub { [ @_ ] },
  };

  return @case;
}

# ------------------- ROLLBACK, statements in flight, disconnect (karr k395, k236)

sub _failure_cases {
  my @case;

  push @case, {
    no => 47, name => 'rollback-failed', kind => 'async-only',
    requires => ['fault:rollback_fails'],
    doc  => 'a ROLLBACK the server does not confirm: the transaction fails, the connection is retired, the pool serves',
    async => sub {
      my ($s, $env) = @_;
      my $fc    = _fc($s);
      my $guard = $env->{fault}->('rollback_fails');
      return $s->storage->txn_do_async(sub {
        my ($ctx) = @_;
        return $ctx->insert_async(_insert_args($s, 'Parity Rollback Failed'))->then(sub {
          eval { DBIO::Exception->throw('parity rollback failed') };
          return $fc->fail($@);
        });
      })->then(
        sub { undef $guard; return $fc->done('committed') },
        sub {
          my ($error) = @_;
          undef $guard;
          return $fc->done("$error" =~ /parity rollback failed/ ? 'failed' : 'failed other');
        },
      )->then(sub {
        my ($state) = @_;
        return _count_async($s, 'Parity Rollback Failed')->then(sub { $fc->done($state, $_[0]) });
      });
    },
    expect => [ 'failed', 0 ],
    norm   => sub { [ @_ ] },
  };

  # The context counts every statement it hands out; COMMIT waits for them.
  push @case, {
    no => 48, name => 'txn-statement-in-flight', kind => 'async-only',
    doc  => 'a statement still running when the coderef returns is awaited before COMMIT',
    async => sub {
      my ($s) = @_;
      return $s->storage->txn_do_async(sub {
        my ($ctx) = @_;
        $ctx->insert_async(_insert_args($s, 'Parity In Flight'));
        return 'returned at once';
      });
    },
    expect  => [ 'returned at once' ],
    norm    => sub { [ @_ ] },
    observe => _count_named('Artist', name => 'Parity In Flight'),
  };

  push @case, {
    no => 49, name => 'txn-statement-in-flight-fails', kind => 'async-only',
    doc  => 'a dropped statement that fails fails the transaction; nothing of it is kept',
    async => sub {
      my ($s) = @_;
      return $s->storage->txn_do_async(sub {
        my ($ctx) = @_;
        $ctx->insert_async(_insert_args($s, 'Parity In Flight Fails'));
        $ctx->insert_async($s->source('Artist'), { name => $FIRST, rank => 1 });
        return 'returned at once';
      });
    },
    expect_error => 1,
    norm         => sub { [ @_ ] },
    observe      => _count_named('Artist', name => 'Parity In Flight Fails'),
  };

  push @case, {
    no => 50, name => 'disconnect-in-txn', kind => 'async-only',
    requires => ['fault:disconnect'],
    doc  => 'the connection is lost in the middle of a transaction: it fails, nothing is kept, the pool serves',
    async => sub {
      my ($s, $env) = @_;
      my $fc = _fc($s);
      return $s->storage->txn_do_async(sub {
        my ($ctx) = @_;
        return $ctx->insert_async(_insert_args($s, 'Parity Disconnect'))->then(sub {
          $env->{fault}->('disconnect', $ctx);
          return $ctx->insert_async(_insert_args($s, 'Parity Disconnect 2'));
        });
      })->then(
        sub { return $fc->done('committed') },
        sub { return $fc->done('failed') },
      )->then(sub {
        my ($state) = @_;
        return _count_async($s, 'Parity Disconnect')->then(sub { $fc->done($state, $_[0]) });
      });
    },
    expect => [ 'failed', 0 ],
    norm   => sub { [ @_ ] },
  };

  return @case;
}

# ----------------------- the limits of the pool, session state (karr k397, k398)

sub _pool_cases {
  my @case;

  # A transaction holds a connection; the Future its coderef returns is a call
  # on the storage, which has to queue for a connection of the same pool.
  push @case, {
    no => 51, name => 'pool-self-deadlock', kind => 'async-only',
    requires => ['pool_queue'],
    doc  => 'a transaction whose coderef returns a call queued for its own pool fails at once',
    async => sub {
      my ($s) = @_;
      my $fc = _fc($s);
      my @held;
      return _hold_all($s, 1)->then(sub {
        @held = @_;
        return $s->storage->txn_do_async(sub {
          return _rs($s, 'Artist')->search({ name => 'Parity Never' })->all_async;
        });
      })->then(
        sub { _release_all($s, @held); return $fc->done('not refused') },
        sub {
          my ($error) = @_;
          _release_all($s, @held);
          my $state = "$error" =~ /queued for this transaction.s own pool/ ? "refused" : "refused otherwise";
          return _count_async($s)->then(sub { $fc->done($state, 'pool serves') });
        },
      );
    },
    expect => [ 'refused', 'pool serves' ],
    norm   => sub { [ @_ ] },
  };

  push @case, {
    no => 52, name => 'pool-max-waiters', kind => 'async-only',
    requires => ['pool_queue'],
    doc  => 'with the pool taken, max_waiters callers queue and the next one is refused at once',
    async => sub {
      my ($s) = @_;
      my $fc   = _fc($s);
      my $pool = _async($s)->pool;
      my @held;
      my $old = $pool->{max_waiters};
      return _hold_all($s)->then(sub {
        @held = @_;
        $pool->{max_waiters} = 1;
        my $queued  = $pool->acquire;
        my $refused = $pool->acquire;
        $pool->{max_waiters} = $old;
        my $state = $refused->is_failed && $refused->failure =~ /pool exhausted: 1 callers waiting/
          ? 'refused' : 'not refused';
        _release_all($s, @held);
        return $queued->then(sub {
          my ($conn) = @_;
          $pool->release($conn);
          return $fc->done('queued', $state);
        });
      });
    },
    expect => [ 'queued', 'refused' ],
    norm   => sub { [ @_ ] },
  };

  push @case, {
    no => 53, name => 'pool-acquire-timeout', kind => 'async-only',
    requires => ['pool_queue'],
    doc  => 'with the pool taken, a caller that waits longer than acquire_timeout fails',
    async => sub {
      my ($s) = @_;
      my $fc   = _fc($s);
      my $pool = _async($s)->pool;
      my @held;
      my $old = $pool->{acquire_timeout};
      return _hold_all($s)->then(sub {
        @held = @_;
        $pool->{acquire_timeout} = 0.2;
        my $waiter = $pool->acquire;
        $pool->{acquire_timeout} = $old;
        return $waiter->then(
          sub { $pool->release($_[0]); return $fc->done('served') },
          sub { return $fc->done("$_[0]" =~ /no pool connection within/ ? 'timed out' : 'failed otherwise') },
        );
      })->then(sub {
        my ($state) = @_;
        _release_all($s, @held);
        return $fc->done($state);
      });
    },
    expect => [ 'timed out' ],
    norm   => sub { [ @_ ] },
  };

  # Session state of one borrower never reaches the next (ADR 0079). A
  # temporary table is session state; every connection of the pool gets one and
  # is given back, then every connection is asked for it.
  push @case, {
    no => 54, name => 'session-reset', kind => 'async-only',
    requires => ['pool_queue'],
    doc  => 'a connection given back is reset: the session state of its last borrower is gone',
    async => sub {
      my ($s, $env) = @_;
      my $fc    = _fc($s);
      my $async = _async($s);
      my ($set, $probe) = @{ $env->{session_sql} };
      my @held;
      return _hold_all($s)->then(sub {
        @held = @_;
        return $fc->needs_all(map { $async->_query_async_pinned($_, $set, []) } @held);
      })->then(sub {
        _release_all($s, @held);
        return _hold_all($s);
      })->then(sub {
        @held = @_;
        return $fc->needs_all(map {
          $async->_query_async_pinned($_, $probe, [])->then(
            sub { $fc->done('seen') },
            sub { $fc->done('gone') },
          );
        } @held);
      })->then(sub {
        my @seen = @_;
        _release_all($s, @held);
        return $fc->done((grep { $_ ne 'gone' } @seen) ? 'leaked' : 'reset');
      });
    },
    expect => [ 'reset' ],
    norm   => sub { [ @_ ] },
  };

  return @case;
}

# ----------------------------- LISTEN/NOTIFY, a connection that cannot come up

sub _transport_cases {
  my @case;

  push @case, {
    no => 55, name => 'listen-notify', kind => 'async-only',
    requires => [ 'listen', 'notify' ],
    doc  => 'a notification sent on one connection arrives at the listener, with its payload',
    async => sub {
      my ($s) = @_;
      my $fc    = _fc($s);
      my $async = _async($s);
      my $got   = $fc->new;
      my $channel = 'parity_listen';
      return $async->listen($channel, sub {
        my ($chan, $payload) = @_;
        $got->done($chan, $payload) unless $got->is_ready;
      })->then(sub {
        return $async->notify($channel, 'parity payload');
      })->then(sub {
        return $got;
      })->then(sub {
        my @answer = @_;
        return $async->unlisten($channel)->then(sub { $fc->done(@answer) });
      });
    },
    expect => [ 'parity_listen', 'parity payload' ],
    norm   => sub { [ @_ ] },
  };

  # The error of a connection that cannot come up reaches the caller without
  # the password the connection was made with (karr k305, k400).
  push @case, {
    no => 56, name => 'connect-error-masked', kind => 'async-only',
    requires => ['unreachable_connection'],
    doc  => 'the error of a connection that cannot be made never carries the connection\'s password',
    async => sub {
      my ($s, $env) = @_;
      my $fc = _fc($s);
      my ($schema, $secret) = $env->{unreachable}->();
      # the failure arrives as a failed Future; an exception out of the call
      # itself is a deviation and counts as a failure of the case
      my $future = eval { _rs($schema, 'Artist')->count_async };
      return $fc->done('thrown') if !$future;
      return $future->then(
        sub { return $fc->done('connected') },
        sub {
          my ($error) = @_;
          return $fc->done(index("$error", $secret) < 0 ? 'masked' : 'leaked');
        },
      );
    },
    expect => [ 'masked' ],
    norm   => sub { [ @_ ] },
  };

  return @case;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::AsyncParity::Cases - The case table of DBIO::Test::AsyncParity: ResultSet operations, once synchronous and once asynchronous

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The list L<DBIO::Test::AsyncParity> runs. A case is a hash:

  {
    no           => 7,                       # the number the run reports
    name         => 'group-by',              # what a transport declares against
    kind         => 'direct',                # direct | composed | async-only
    doc          => 'one line, what it shows',
    sync         => sub { my ($schema, $env) = @_; ... },   # the blocking way
    async        => sub { my ($schema, $env) = @_; ... },   # returns a Future
    norm         => sub { ... },             # raw result -> plain data
    observe      => sub { my ($schema) = @_; ... },         # optional
    expect_error => 1 | qr/.../,             # optional
    expect       => [ ... ],                 # async-only cases
    absent       => qr/.../,                 # optional
    requires     => [ 'pipeline', ... ],     # optional
  }

=over 4

=item kind

C<direct>: the synchronous method has an C<*_async> twin and the case calls
that twin. C<composed>: core has no single async method for the operation and
the case composes it from the ones it has (a loop over rows, a related
resultset, a transaction with a bound context). C<async-only>: the case has no
synchronous way to compare against and states what the asynchronous way must
answer.

=item sync, async

Both receive the connected schema and C<$env>, a hash with C<harness> and
C<sync_schema> (a coderef returning a second, purely synchronous connection to
the same database). C<async> returns a L<DBIO::Future>; the runner awaits it
through the harness. The two ways run against the B<same> schema instance and
the same database, each after the same reset and seed.

=item norm

Turns what a way returned into plain data, the same code for both ways.
Auto-increment keys are left out of it: the two ways run one after the other
and the server hands out different ones.

=item observe

Reads the state the case left behind, through the synchronous path, after the
way has run. Compared like a result.

=item expect_error

Both ways must throw, with the same exception class; a regex also has to match
the message of each. Without this key a way that throws is a failure.

=item absent

The case documents an operation core has no asynchronous twin for. The regex is
what the asynchronous way's failure must match. It is a declared absence that
belongs to the table, not to a transport; when core grows the twin the case
passes, the declaration is stale and the run fails until the key is removed.

=item requires

The capabilities of the transport the case needs: names from
L<DBIO::Test::AsyncParity/parity_capabilities> (C<pipeline>, C<cancel>,
C<pool_queue>, C<listen>, C<notify>, C<fault:rollback_fails>,
C<fault:disconnect>, C<unreachable_connection>). A transport without one of
them does not run the case: it is reported C<skipped>, naming what is missing
(L<DBIO::Test::AsyncParity/Capabilities>). The cases that need a fault of the
transport read it from C<< $env->{fault}->($name, @args) >>; C<session-reset>
reads its two statements from C<< $env->{session_sql} >>, and
C<connect-error-masked> gets its schema from C<< $env->{unreachable}->() >>.

=back

The fixture every case runs on is L</fixture>: three artists, four CDs and
four tracks, named, never addressed by key (a live database hands out its own).
The cases that write a row of their own use C<OneKey>, a source with no
relationships, where the thing under test is the write and not a cascade.

=head1 METHODS

=head2 fixture

  my $data = DBIO::Test::AsyncParity::Cases->fixture;

The seed data as C<< { artists => [ [ name, rank ] ], cds => [ [ artist name,
title, year ] ], tracks => [ [ cd title, position, title ] ] } >>.

=head2 cases

  my $cases = DBIO::Test::AsyncParity::Cases->cases;

The arrayref of cases, in number order, a fresh copy.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
