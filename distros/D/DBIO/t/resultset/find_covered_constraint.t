use strict;
use warnings;

use Test::More;
use Test::Exception;
use SQL::Abstract::Test import => [qw(is_same_sql_bind)];

use DBIO::Test;

# ADR 0070: find looks up exactly the row the caller describes. Every key of
# the condition goes into the query as one AND; the condition has to give every
# column of at least one unique constraint a concrete equality, else find
# throws. The find_or_* / update_or_* helpers look up by the columns of the
# covered constraint only and treat the other values as data.
#
# Query comparison: the SQL find ran (captured on the mock storage, the same
# SQL a real cursor would execute) must equal the SQL of the plain search
# written out by hand.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

# find's SQL + binds, and the same for the search it has to be equal to
sub captured_select {
  my ($code) = @_;
  $storage->clear_mocks;
  $storage->reset_captured;
  $code->();
  my @sel = grep { $_->{op} eq 'select' } $storage->captured_queries;
  return @sel ? [ $sel[-1]{sql}, @{ $sel[-1]{bind} || [] } ] : undef;
}

sub find_matches_search {
  my ($source, $find_args, $search_cond, $name) = @_;
  my $rs = $schema->resultset($source);

  my $got = captured_select(sub { $rs->find(@$find_args) });
  my $exp = captured_select(sub { $rs->search($search_cond)->single });

  ok $got, "$name: find ran a query" or return;
  is_same_sql_bind($got->[0], [ @{$got}[1..$#$got] ], $exp->[0], [ @{$exp}[1..$#$exp] ], $name);
}

# --- every passed key reaches the query ---------------------------------------

find_matches_search(
  Artist => [ { artistid => 1, rank => 999 } ],
  { 'me.artistid' => 1, 'me.rank' => 999 },
  'a key outside the covered constraint stays in the condition',
);

find_matches_search(
  Artist => [ { artistid => 1, name => 'foo' } ],
  { 'me.artistid' => 1, 'me.name' => 'foo' },
  'two covered constraints are ANDed, never ORed',
);

{
  local $SIG{__WARN__} = sub {};   # no constraint warning expected, none relied on
  find_matches_search(
    Artist => [ { name => undef, artistid => 3 } ],
    { 'me.artistid' => 3, 'me.name' => undef },
    'a column given as undef stays as IS NULL',
  );
}

find_matches_search(
  Artist => [ 7 ],
  { 'me.artistid' => 7 },
  'find(@pk) with scalars is the primary key lookup',
);

find_matches_search(
  Artist => [ { name => 'foo', rank => 4 }, { key => 'artist_name' } ],
  { 'me.name' => 'foo', 'me.rank' => 4 },
  'with key the other keys still go into the query',
);

find_matches_search(
  Artist => [ { artistid => { '=' => 5 } } ],
  { 'me.artistid' => { '=' => 5 } },
  '{ col => { "=" => $scalar } } is a concrete equality',
);

# --- what does not cover a constraint -----------------------------------------

for my $case (
  [ 'empty condition'                   => {} ],
  [ 'column outside every constraint'   => { rank => 5 } ],
  [ 'part of a multi-column constraint' => { charfield => 'x' } ],
  [ 'operator'                          => { artistid => { '>' => 0 } } ],
  [ 'value list'                        => { artistid => [ 1, 2 ] } ],
  [ 'undef'                             => { artistid => undef } ],
  [ 'only inside an OR branch'          => { -or => [ { artistid => 1 }, { name => 'x' } ] } ],
) {
  my ($name, $cond) = @$case;
  $storage->reset_captured;
  throws_ok { $schema->resultset('Artist')->find($cond) }
    qr/find\(\) needs a condition that gives every column of one unique constraint/,
    "find throws: $name";
  is scalar(grep { $_->{op} eq 'select' } $storage->captured_queries), 0,
    "$name: no query ran";
}

{
  throws_ok { $schema->resultset('Artist')->find({ rank => 5, charfield => undef }) }
    qr/Columns given: 'charfield', 'rank'\. Unique constraints: .*artist_name \(name\).*primary \(artistid\).*search\(\.\.\.\)->single/s,
    'the message names the given columns, the constraints and search->single';
}

lives_ok { $schema->resultset('Artist')->search({ rank => 5 })->single }
  'search(...)->single is the way for any other condition';

# the scope of a resultset is part of the condition
{
  my $rs = $schema->resultset('Artist')->search({ artistid => 2 });
  lives_ok { $rs->find({ rank => 5 }) } 'a scope covering a constraint covers the find';
  $schema->resultset('Artist')->search({ rank => 2 })->find({ charfield => 'x' });
  pass 'scope and condition together cover u_nullable';
}
throws_ok { $schema->resultset('Artist')->search({ rank => 2 })->find({ rank => 5 }) }
  qr/needs a condition/, 'a scope not covering a constraint does not help';

# --- key => ... ----------------------------------------------------------------

throws_ok { $schema->resultset('Artist')->find({ rank => 5 }, { key => 'artist_name' }) }
  qr/Unable to satisfy requested constraint 'artist_name'/,
  'key names a constraint the condition does not cover';

# a column given as undef does not cover the named constraint: find throws,
# with no warning and no IS NULL lookup
{
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  $storage->reset_captured;

  throws_ok {
    $schema->resultset('Artist')->find({ charfield => undef, rank => 5 }, { key => 'u_nullable' })
  } qr/key 'u_nullable'.*'charfield' (?:is|are) undef/s,
    'key and an undef column of the constraint: find throws';

  throws_ok {
    $schema->resultset('Artist')->find(undef, 5, { key => 'u_nullable' })
  } qr/key 'u_nullable'.*'charfield' (?:is|are) undef/s,
    'key and an undef value in the value list: find throws';

  is scalar(grep { $_->{op} eq 'select' } $storage->captured_queries), 0, 'no query ran';
  is_deeply \@warn, [], 'no warning was issued';
}

# --- relationship values ---------------------------------------------------------

{
  my $artist = $schema->resultset('Artist')->new_result({ artistid => 7, name => 'x' });
  $artist->in_storage(1);

  find_matches_search(
    CD => [ { very_long_artist_relationship => $artist, title => 'T' } ],
    { 'me.artist' => 7, 'me.title' => 'T' },
    'a relationship value resolves to its foreign key columns',
  );

  find_matches_search(
    CD => [ { artist => 7, very_long_artist_relationship => $artist, title => 'T' } ],
    { 'me.artist' => 7, 'me.title' => 'T' },
    'an explicit foreign key equal to the relationship value is fine',
  );

  throws_ok {
    $schema->resultset('CD')->find({ artist => 8, very_long_artist_relationship => $artist, title => 'T' })
  } qr/passes 'artist' explicitly and relationship 'very_long_artist_relationship' resolves it to a different value/,
    'a relationship contradicting an explicit foreign key throws';
}

# --- find_or_new / find_or_create / update_or_new / update_or_create ---------------

my %helper = (
  find_or_new      => sub { $_[0]->find_or_new(@_[1..$#_]) },
  find_or_create   => sub { $_[0]->find_or_create(@_[1..$#_]) },
  update_or_new    => sub { $_[0]->update_or_new(@_[1..$#_]) },
  update_or_create => sub { $_[0]->update_or_create(@_[1..$#_]) },
);

for my $h (sort keys %helper) {
  my $rs = $schema->resultset('Artist');

  # lookup by the covered constraint only; the rest is data
  my $got = captured_select(sub { $helper{$h}->($rs, { name => 'foo', rank => 4 }) });
  my $exp = captured_select(sub { $rs->search({ 'me.name' => 'foo' })->single });
  is_same_sql_bind($got->[0], [ @{$got}[1..$#$got] ], $exp->[0], [ @{$exp}[1..$#$exp] ],
    "$h looks up by the covered constraint only");

  throws_ok { $helper{$h}->($rs, { artistid => 1, name => 'foo' }) }
    qr/covers the unique constraints 'primary' and 'artist_name' -- pass key/,
    "$h with two covered constraints and no key throws";

  $got = captured_select(sub { $helper{$h}->($rs, { artistid => 1, name => 'foo' }, { key => 'artist_name' }) });
  $exp = captured_select(sub { $rs->search({ 'me.name' => 'foo' })->single });
  is_same_sql_bind($got->[0], [ @{$got}[1..$#$got] ], $exp->[0], [ @{$exp}[1..$#$exp] ],
    "$h with key looks up that constraint only");

  throws_ok { $helper{$h}->($rs, { rank => 4 }) }
    qr/needs a condition that gives every column of one unique constraint/,
    "$h with no covered constraint throws";
}

{
  # update_or_create({ id => 1, name => 'neu' }): the id identifies, the name is data
  my $cd_rs = $schema->resultset('CD');
  $storage->clear_mocks;
  $storage->reset_captured;
  $storage->mock(qr/FROM cd "me"/i, [[ 1, 1, 'alt', 1998, undef, undef ]]);

  my $row = $cd_rs->update_or_create({ cdid => 1, title => 'neu' });
  ok $row->in_storage, 'update_or_create found the row by its primary key';
  is $row->title, 'neu', 'the other value was applied as data';

  my @ops = grep { /^(?:select|update|insert)$/ } map { $_->{op} } $storage->captured_queries;
  is_deeply \@ops, [ 'select', 'update' ], 'select by id, then update of the found row';

  my ($upd) = grep { $_->{op} eq 'update' } $storage->captured_queries;
  like $upd->{sql}, qr/UPDATE cd SET "?title"? = \?/i, 'the update carries the data column';
}

# --- a scope through a relationship ------------------------------------------------

{
  my $artist = $schema->resultset('Artist')->new_result({ artistid => 3, name => 'scope' });
  $artist->in_storage(1);

  my $cds = $artist->search_related('cds');

  my $got = captured_select(sub { $cds->find({ title => 'T' }) });
  my $exp = captured_select(sub { $cds->search({ 'me.title' => 'T' })->single });
  is_same_sql_bind($got->[0], [ @{$got}[1..$#$got] ], $exp->[0], [ @{$exp}[1..$#$exp] ],
    'the foreign key of the relationship scope plus title cover cd_artist_title');

  throws_ok { $cds->find({ year => 1999 }) } qr/needs a condition/,
    'the relationship scope alone does not cover a constraint with the given columns';
}

# --- the async variants share the check ---------------------------------------------

throws_ok { $schema->resultset('Artist')->find_async({ rank => 5 }) }
  qr/find\(\) needs a condition that gives every column of one unique constraint/,
  'find_async throws like find';

for my $m (qw(find_or_new_async find_or_create_async update_or_new_async update_or_create_async)) {
  throws_ok { $schema->resultset('Artist')->$m({ rank => 4 })->get }
    qr/needs a condition that gives every column of one unique constraint/,
    "$m with no covered constraint throws";
  throws_ok { $schema->resultset('Artist')->$m({ artistid => 1, name => 'x' })->get }
    qr/covers the unique constraints 'primary' and 'artist_name' -- pass key/,
    "$m with two covered constraints and no key throws";
}

# --- get_from_storage without a primary key -------------------------------------------

{
  # baz alone covers no constraint of NoPrimaryKey: the row is searched for by
  # everything loaded, find does not run
  $storage->clear_mocks;
  $storage->mock_persistent(qr/FROM "noprimarykey"/i, [[ undef, undef, 7 ]]);

  my $row = $schema->resultset('NoPrimaryKey')->new_result({ baz => 7 });
  $row->in_storage(1);
  $row->{_column_data_in_storage} = { %{ $row->{_column_data} } };

  my $copy;
  lives_ok { $copy = $row->get_from_storage }
    'get_from_storage on a row without any covered constraint searches for the loaded columns';
  isa_ok $copy, 'DBIO::Row';
}

done_testing;
