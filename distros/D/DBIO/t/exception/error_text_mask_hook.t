# ABSTRACT: the engine text of an error goes through _mask_error_values
use strict;
use warnings;

use Test::More;

use DBIO::Test;

# ADR 0075. What this file claims:
#   1. a statement refused through _dbh_execute hands the engine text, the
#      plain bound values (undef and references dropped) and the statement
#      to the hook _mask_error_values, and throws the text it answers; the
#      base hook takes the values out, in the form they were written and in
#      the form the handle quotes them;
#   2. a statement of _do_query hands its binds to the hook;
#   3. NoBindVars: the text names the statement in placeholder form and the
#      number of values -- the values are not in the statement -- and the
#      hook gets the values that were interpolated;
#   4. a populate refused by the engine names the row (counted from 1) and
#      the columns, never a value, and masks the engine text with the values
#      of that row; a failure no row is named for masks with every row;
#   5. a bad slice names row and columns, never a value.
#
# THE SUBSTITUTION: the mock runs no statement, so a stub statement handle
# fails through $storage->_dbi_handle_error with a text the way an engine
# writes it, the values inside.

my @calls;

{
  package T::Sth;
  sub new { bless { storage => $_[1], text => $_[2] }, $_[0] }
  sub bind_param { 1 }
  sub errstr { '' }
  sub err { 0 }
  sub finish { 1 }
  sub execute {
    $_[0]{storage}->_dbi_handle_error($_[0]{text}, { Statement => 'x', NUM_OF_PARAMS => 0 });
  }

  package T::Dbh;
  sub new { bless { storage => $_[1], text => $_[2] }, $_[0] }
  sub prepare_cached { T::Sth->new(@{$_[0]}{qw(storage text)}) }
  sub prepare        { T::Sth->new(@{$_[0]}{qw(storage text)}) }
  sub errstr { '' }

  package T::QuoteDbh;
  sub quote { my $v = $_[1]; $v =~ s/'/''/g; "'$v'" }

  package T::Storage;
  use mro 'c3';
  our @ISA = ('DBIO::Test::Storage');
  sub _prepare_sth { my ($self, $dbh, $sql) = @_; $dbh->prepare($sql) }
  sub _adjust_bind_values { $_[2] }
  sub _mask_error_values {
    my ($self, @args) = @_;
    push @calls, [ @args ];
    return $self->next::method(@args);
  }
}

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;
bless $storage, 'T::Storage';
$storage->disable_sth_caching(1);

# 1. _dbh_execute
{
  my $sql  = 'INSERT INTO artist (name, rank, note) VALUES (?, ?, ?)';
  my $text = q{duplicate key: Key (name)=(geheim-pk) exists, rank 'a'', 2=''b'};
  my $dbh  = T::Dbh->new($storage, $text);
  $storage->{_fake_dbh} = bless {}, 'T::QuoteDbh';   # the handle quotes as the engine does
  my $bind = [ map { [ {}, $_ ] } ('geheim-pk', q{a', 2='b}, undef, [ 'ref' ]) ];

  @calls = ();
  eval { $storage->_dbh_execute($dbh, $sql, $bind, [ (undef) x 4 ]) };
  my $err = "$@";

  is scalar @calls, 1, 'the hook is asked once';
  like $calls[0][0], qr/duplicate key/, '... with the text of the engine';
  is_deeply $calls[0][1], [ 'geheim-pk', q{a', 2='b} ],
    '... the plain values (undef and the reference dropped)';
  is $calls[0][2], $sql, '... and the statement';
  like $err, qr/duplicate key: Key \(name\)=\(\*\*\*\) exists/,
    'the value is masked in the text';
  unlike $err, qr/geheim-pk|2=''b/, 'no value is in the text';
  delete $storage->{_fake_dbh};
  like $err, qr/\Q[for Statement "$sql" with 4 bind values]\E/,
    'the statement and the number of values are named';
}

# the hook decides: what it answers is what is thrown
{
  no warnings 'redefine';
  local *T::Storage::_mask_error_values = sub { 'hook-answer' };
  my $dbh = T::Dbh->new($storage, 'engine says geheim-pk');
  eval { $storage->_dbh_execute($dbh, 'SELECT ?', [ [ {}, 'geheim-pk' ] ], [ undef ]) };
  like "$@", qr/DBI Exception: hook-answer /, 'the text the hook answers is thrown';
  unlike "$@", qr/geheim-pk/, '... without the engine text';
}

# 2. _do_query
{
  @calls = ();
  $storage->{_pool_connect_runner} = sub {
    $storage->_dbi_handle_error('failed for geheim-do', {});
  };
  eval { $storage->_do_query([ 'UPDATE t SET a = ?', undef, 'geheim-do', undef ]) };
  my $err = "$@";
  delete $storage->{_pool_connect_runner};

  is_deeply $calls[0][1], ['geheim-do'], '_do_query hands its binds to the hook';
  unlike $err, qr/geheim-do/, '... and its error does not carry them';
}

# 4. populate, refused by the engine
{
  package T::BulkSth;
  sub new { bless { text => $_[1], failed => $_[2] }, $_[0] }
  sub bind_param { 1 }
  sub errstr { '' }
  sub err { 0 }
  sub finish { 1 }
  sub execute_for_fetch {
    my ($self, $fetch, $status) = @_;
    while (my $row = $fetch->()) { push @$status, -1 }
    @$status = map { $_ == $self->{failed} ? [ 1, $self->{text} ] : -1 } 0 .. $#$status
      if defined $self->{failed};
    die $self->{text};
  }
}

{
  my $source = $schema->source('Artist');
  my @cols   = qw(name rank);
  my @data   = ([ 'first-row', 1 ], [ 'second-row-secret', 2 ], [ 'third-row', 3 ]);
  my $proto  = [
    [ { dbic_colname => 'name', _bind_data_slice_idx => 0 }, 'x' ],
    [ { dbic_colname => 'rank', _bind_data_slice_idx => 1 }, 1 ],
  ];

  @calls = ();
  my $sth = T::BulkSth->new(q{duplicate key 'second-row-secret' exists}, 1);
  eval { $storage->_dbh_execute_for_fetch($source, $sth, $proto, \@cols, \@data) };
  my $err = "$@";

  like $err, qr/aborted with 'duplicate key '\*\*\*' exists'/, 'the engine text is masked';
  like $err, qr/row 2 of the populate data/, 'the row is named, counted from 1';
  like $err, qr/columns: name, rank/, 'the columns are named';
  unlike $err, qr/second-row-secret|first-row|third-row/, 'no value is in the text';
  is_deeply +($calls[-1] || [])->[1], [ 'second-row-secret', 2 ], 'the hook gets the values of that row';

  # no row named
  @calls = ();
  $sth = T::BulkSth->new(q{connection lost near 'third-row'}, undef);
  eval { $storage->_dbh_execute_for_fetch($source, $sth, $proto, \@cols, \@data) };
  $err = "$@";
  like $err, qr/Unexpected populate error: connection lost near '\*\*\*'/,
    'a failure without a row masks with the values of every row';
  unlike $err, qr/first-row|second-row-secret|third-row/, '... and holds none';
  is_deeply [ sort @{ ($calls[-1] || [])->[1] || [] } ], [ sort qw(first-row second-row-secret third-row 1 2 3) ],
    '... the hook gets every row';
}

# 5. a bad slice
{
  my $source = $schema->source('Artist');
  eval {
    DBIO::Storage::DBI::_insert_bulk(
      $storage, $source, [qw(name rank)],
      [ [ 'good-value-1', 1 ], [ \'NOW()', 2 ], ],
    );
  };
  my $err = "$@";
  like $err, qr/for column 'name' in row 2 of the populate data \(columns: name, rank\)/,
    'a bad slice names column, row and columns';
  unlike $err, qr/good-value-1/, '... and no value';
}

# the base hook quotes through the handle when there is one, and never
# connects or throws
{
  my $s = DBIO::Test->init_schema(no_deploy => 1)->storage;
  my $quoting = bless {}, 'T::BackslashDbh';
  { package T::BackslashDbh; sub quote { my $v = $_[1]; $v =~ s/'/\\'/g; "'$v'" } }
  $s->{_fake_dbh} = $quoting;
  is $s->_mask_error_values(q{bad 'it\\'s secret' here}, [ q{it's secret} ], undef),
    'bad *** here', 'the form the handle quotes is found';
  delete $s->{_fake_dbh};
  is $s->_mask_error_values('bad geheim-1', [ 'geheim-1' ], undef),
    'bad ***', 'without a handle the written form is masked';
  is $s->_mask_error_values('bad geheim-1', [], undef), 'bad geheim-1',
    'no values, no change';
}

done_testing;
