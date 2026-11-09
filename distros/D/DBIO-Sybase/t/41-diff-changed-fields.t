use strict;
use warnings;
use Test::More;

# Focused offline coverage for the "is this column/index the same?" gate inside
# the Sybase Diff classes. DBIO::Diff::Compare::changed_column_fields / changed_index_fields
# are *misnamed*: they return the LIST of changed field names, so an empty list
# (identical defs) is falsy and a non-empty list (differing defs) is truthy.
# Diff::Column / Diff::Index therefore emit an Alter op only when the defs
# actually DIFFER. These tests pin that real behaviour so a future rename of the
# core helpers (changed_column_fields / changed_index_fields) cannot silently
# invert it.

use_ok 'DBIO::Sybase::Diff::Column';
use_ok 'DBIO::Sybase::Diff::Index';
use DBIO::Diff::Compare qw(changed_column_fields changed_index_fields);

# `size` is modelled deliberately (karr k32): changed_column_fields compares it
# as a `dim` field, so a helper that never produced one left the size axis of
# the sameness gate untested here.
sub col {
  my ($name, %o) = @_;
  +{ column_name => $name, data_type => $o{type} // 'integer',
     size => $o{size},
     not_null => $o{not_null} // 0, default_value => $o{default} };
}
sub idx {
  my ($name, %o) = @_;
  +{ index_name => $name, is_unique => $o{unique} // 0,
     columns => $o{columns} // [] };
}

# --- direct semantics of the core helpers ---------------------------------
{
  my $same = col('id', type => 'integer', not_null => 1);
  my @changed = changed_column_fields($same, { %$same });
  is_deeply(\@changed, [], 'identical columns => no changed fields (falsy)');

  my @diff = changed_column_fields(
    col('id', type => 'integer'),
    col('id', type => 'bigint'),
  );
  ok(scalar(@diff), 'differing columns => non-empty changed-field list (truthy)');
  ok((grep { $_ eq 'data_type' } @diff), 'data_type reported as changed');
}
{
  # size is compared as a `dim` field -- order-preserving, so [10,2] and [2,10]
  # differ -- and it obeys the same desired-state skip as the scalar fields:
  # a target leaving it undef prescribes nothing and the live width stands.
  my @same = changed_column_fields(
    col('name', type => 'varchar', size => 64),
    col('name', type => 'varchar', size => 64),
  );
  is_deeply(\@same, [], 'equal sizes => no changed fields');

  my @wider = changed_column_fields(
    col('name', type => 'varchar', size => 64),
    col('name', type => 'varchar', size => 128),
  );
  is_deeply(\@wider, ['size'], 'size-only change reported, and only size');

  my @unprescribed = changed_column_fields(
    col('name', type => 'varchar', size => 64),
    col('name', type => 'varchar'),
  );
  is_deeply(\@unprescribed, [], 'a target prescribing no size leaves the live width alone');
}
{
  my $same = idx('ix', unique => 1, columns => ['a', 'b']);
  my @changed = changed_index_fields($same, { %$same, columns => ['a', 'b'] });
  is_deeply(\@changed, [], 'identical indexes => no changed fields (falsy)');

  my @diff = changed_index_fields(
    idx('ix', unique => 0, columns => ['a']),
    idx('ix', unique => 1, columns => ['a']),
  );
  ok(scalar(@diff), 'differing indexes => non-empty changed-field list (truthy)');
}

# --- behaviour through Diff::Column ----------------------------------------
{
  # identical column in source + target: must NOT produce an Alter op
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('id', type => 'integer', not_null => 1) ] },
    { t => [ col('id', type => 'integer', not_null => 1) ] },
  );
  is(scalar(@ops), 0, 'identical column => no Alter op emitted');
}
{
  # differing column: must produce exactly one Alter op
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('id', type => 'integer') ] },
    { t => [ col('id', type => 'bigint') ] },
  );
  is(scalar(@ops), 1, 'differing column => one op emitted');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Column::Alter', 'op is an Alter');
}

# --- behaviour through Diff::Index -----------------------------------------
{
  my @ops = DBIO::Sybase::Diff::Index->diff(
    { t => { ix => idx('ix', unique => 1, columns => ['a', 'b']) } },
    { t => { ix => idx('ix', unique => 1, columns => ['a', 'b']) } },
  );
  is(scalar(@ops), 0, 'identical index => no Alter op emitted');
}
{
  my @ops = DBIO::Sybase::Diff::Index->diff(
    { t => { ix => idx('ix', unique => 0, columns => ['a']) } },
    { t => { ix => idx('ix', unique => 1, columns => ['a']) } },
  );
  is(scalar(@ops), 1, 'differing index => one op emitted');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Index::Alter', 'op is an Alter');
}

done_testing;
