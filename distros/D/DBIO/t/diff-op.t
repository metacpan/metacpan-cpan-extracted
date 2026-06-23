use strict;
use warnings;
use Test::More;

use DBIO::Diff::Compare qw(changed_column_fields changed_index_fields);

{
  package Test::ColOp;
  use base 'DBIO::Diff::Op';
  __PACKAGE__->mk_diff_accessors(qw/table_name column_name old_info new_info/);
  sub summary { my $s = shift; sprintf '%s%s.%s', $s->summary_prefix, $s->table_name, $s->column_name }

  package Test::IdxOp;
  use base 'DBIO::Diff::Op';
  __PACKAGE__->mk_diff_accessors(qw/table_name index_name index_info/);
}

# --- new + accessors + action from base ---
{
  my $op = Test::ColOp->new(action => 'add', table_name => 't', column_name => 'c');
  is $op->action, 'add', 'action accessor from base';
  is $op->table_name, 't', 'declared accessor (table_name)';
  is $op->column_name, 'c', 'declared accessor (column_name)';
  is $op->new_info, undef, 'undeclared-value accessor returns undef';
}

# --- summary_prefix ---
{
  is(Test::ColOp->new(action => 'add')->summary_prefix, '+', 'add -> +');
  is(Test::ColOp->new(action => 'drop')->summary_prefix, '-', 'drop -> -');
  is(Test::ColOp->new(action => 'modify')->summary_prefix, '~', 'modify -> ~');
  is(Test::ColOp->new(action => 'create')->summary_prefix, '+', 'create -> +');
  is(Test::ColOp->new(action => 'whatever')->summary_prefix, '~', 'unknown -> ~');
  is(Test::ColOp->new(action => 'add')->summary_prefix(add => '*'), '*', 'override map');
}

# --- diff_toplevel: create for target-only, drop for source-only ---
{
  my $source = { keep => {}, gone => {} };
  my $target = { keep => {}, fresh => {} };
  my @ops = Test::ColOp->diff_toplevel($source, $target,
    create => sub { my ($n) = @_; Test::ColOp->new(action => 'create', table_name => $n) },
    drop   => sub { my ($n) = @_; Test::ColOp->new(action => 'drop',   table_name => $n) },
  );
  is scalar(@ops), 2, 'two ops (one create, one drop)';
  is_deeply [ map { [ $_->action, $_->table_name ] } @ops ],
    [ ['create','fresh'], ['drop','gone'] ],
    'create fresh (target-only), drop gone (source-only); "keep" untouched';
}

# --- diff_nested scope=both: columns keyed from arrays, change via changed_column_fields ---
{
  my $src_tables = { both => {}, dropped => {} };
  my $tgt_tables = { both => {}, brandnew => {} };

  my $source = {
    both => [
      { column_name => 'id',   data_type => 'integer' },
      { column_name => 'old',  data_type => 'text' },
      { column_name => 'name', data_type => 'varchar', size => 10 },
    ],
    dropped => [ { column_name => 'x', data_type => 'text' } ],
  };
  my $target = {
    both => [
      { column_name => 'id',   data_type => 'integer' },          # unchanged
      { column_name => 'name', data_type => 'varchar', size => 20 }, # changed (size)
      { column_name => 'fresh', data_type => 'text' },             # added
    ],
    brandnew => [ { column_name => 'y', data_type => 'text' } ],
  };

  my @ops = Test::ColOp->diff_nested($source, $target,
    index_by      => 'column_name',
    scope         => 'both',
    source_tables => $src_tables,
    target_tables => $tgt_tables,
    changed_when  => sub { scalar changed_column_fields($_[0], $_[1]) },
    on_new     => sub { my ($t,$n,$new) = @_; Test::ColOp->new(action=>'add',  table_name=>$t, column_name=>$n) },
    on_changed => sub { my ($t,$n,$o,$nw) = @_; Test::ColOp->new(action=>'modify', table_name=>$t, column_name=>$n) },
    on_gone    => sub { my ($t,$n,$o) = @_; Test::ColOp->new(action=>'drop', table_name=>$t, column_name=>$n) },
  );

  my @got = sort map { join ':', $_->action, $_->table_name, $_->column_name } @ops;
  is_deeply \@got,
    [ sort 'add:both:fresh', 'modify:both:name', 'drop:both:old' ],
    'scope=both: add/modify/drop only on tables in both; brandnew+dropped skipped';
}

# --- diff_nested scope=all: hash members, skip auto, change -> drop+create pair ---
{
  my $source = {
    keep => {
      i_keep => { is_unique => 0, columns => ['a'] },
      i_chg  => { is_unique => 0, columns => ['b'] },
      i_pk   => { is_unique => 1, columns => ['id'], origin => 'pk' },  # auto -> skipped
      i_gone => { is_unique => 0, columns => ['c'] },
    },
    dropped_table => {
      i_orphan => { is_unique => 0, columns => ['z'] },
    },
  };
  my $target = {
    keep => {
      i_keep => { is_unique => 0, columns => ['a'] },          # unchanged
      i_chg  => { is_unique => 1, columns => ['b'] },          # changed (unique)
      i_new  => { is_unique => 0, columns => ['d'] },          # new
    },
  };

  my @ops = Test::IdxOp->diff_nested($source, $target,
    scope        => 'all',
    skip         => sub { ($_[0]->{origin} || '') eq 'pk' },
    changed_when => sub { scalar changed_index_fields($_[0], $_[1]) },
    on_new     => sub { my ($t,$n,$new) = @_; Test::IdxOp->new(action=>'create', table_name=>$t, index_name=>$n) },
    on_gone    => sub { my ($t,$n,$o)   = @_; Test::IdxOp->new(action=>'drop',   table_name=>$t, index_name=>$n) },
    on_changed => sub {
      my ($t,$n,$o,$nw) = @_;
      return (
        Test::IdxOp->new(action=>'drop',   table_name=>$t, index_name=>$n),
        Test::IdxOp->new(action=>'create', table_name=>$t, index_name=>$n),
      );
    },
  );

  my @got = sort map { join ':', $_->action, $_->table_name, $_->index_name } @ops;
  is_deeply \@got, [ sort
    'create:keep:i_new',
    'drop:keep:i_chg', 'create:keep:i_chg',   # change -> drop+create pair
    'drop:keep:i_gone',
    'drop:dropped_table:i_orphan',            # scope=all emits drops for source-only tables
  ], 'scope=all: new/changed(drop+create)/gone + source-only-table drops; pk index skipped';
}

done_testing;
