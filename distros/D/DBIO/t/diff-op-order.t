use strict;
use warnings;
use Test::More;

{
  package Test::OrdOp;
  use base 'DBIO::Diff::Op';
  __PACKAGE__->mk_diff_accessors(qw/table_name fk_name/);
}

my %mk = (
  create => sub { Test::OrdOp->new(action => 'create', table_name => $_[0]) },
  drop   => sub { Test::OrdOp->new(action => 'drop',   table_name => $_[0]) },
);
my $flat = sub { join ' ', map { $_->action . ':' . $_->table_name } @_ };

# --- diff_nested scope both: the last FK of a table is removed, the table
# has no members left and is missing from the target hash ---
{
  my $tables = { orders => {}, items => {} };
  my $source = { orders => { fk_cust => { columns => ['customer_id'] } } };
  my $target = {};

  my @ops = Test::OrdOp->diff_nested($source, $target,
    scope         => 'both',
    source_tables => $tables,
    target_tables => $tables,
    on_gone       => sub {
      Test::OrdOp->new(action => 'drop', table_name => $_[0], fk_name => $_[1]);
    },
  );
  is_deeply [ map { $_->table_name . '.' . $_->fk_name } @ops ], ['orders.fk_cust'],
    'both: the dropped last FK of a table missing from the target is seen';
}

# a table gone from either model stays out under scope both
{
  my @ops = Test::OrdOp->diff_nested(
    { gone => { a => {} }, kept => { b => {} } }, { kept => {} },
    scope         => 'both',
    source_tables => { gone => {}, kept => {} },
    target_tables => { kept => {} },
    on_gone       => sub { Test::OrdOp->new(action => 'drop', table_name => $_[0], fk_name => $_[1]) },
  );
  is_deeply [ map { $_->table_name . '.' . $_->fk_name } @ops ], ['kept.b'],
    'both: a table dropped as a whole is still skipped';
}

# scope all: no double emission for source-only tables
{
  my @ops = Test::OrdOp->diff_nested(
    { gone => { a => {} }, kept => { b => {} } }, { kept => {} },
    scope   => 'all',
    on_gone => sub { Test::OrdOp->new(action => 'drop', table_name => $_[0], fk_name => $_[1]) },
  );
  is_deeply [ map { $_->table_name . '.' . $_->fk_name } @ops ], ['kept.b', 'gone.a'],
    'all: each gone member once, source-only tables in the trailing pass';
}

# --- diff_toplevel dependency order ---
my $deps = { orders => ['customers'], items => ['orders', 'products'], customers => [] };

{
  my @ops = Test::OrdOp->diff_toplevel({}, { map { $_ => {} } qw(customers items orders products) },
    %mk);
  is $flat->(@ops), 'create:customers create:items create:orders create:products',
    'without depends: alphabetical as before';

  @ops = Test::OrdOp->diff_toplevel({}, { map { $_ => {} } qw(customers items orders products) },
    %mk, depends => $deps);
  is $flat->(@ops), 'create:customers create:orders create:products create:items',
    'create: FK targets before their readers, stable otherwise';

  @ops = Test::OrdOp->diff_toplevel({}, { map { $_ => {} } qw(customers items orders products) },
    %mk, depends => sub { $deps->{ $_[0] } });
  is $flat->(@ops), 'create:customers create:orders create:products create:items',
    'depends as coderef';
}

{
  my $src = { map { $_ => {} } qw(customers items orders products) };
  my @ops = Test::OrdOp->diff_toplevel($src, {}, %mk);
  is $flat->(@ops), 'drop:customers drop:items drop:orders drop:products',
    'without depends: drops alphabetical as before';

  @ops = Test::OrdOp->diff_toplevel($src, {}, %mk, depends => $deps);
  is $flat->(@ops), 'drop:items drop:products drop:orders drop:customers',
    'drop: readers before the tables they read';

  @ops = Test::OrdOp->diff_toplevel($src, {}, %mk,
    depends => {}, source_depends => $deps);
  is $flat->(@ops), 'drop:items drop:products drop:orders drop:customers',
    'source_depends orders the drops';
}

{
  # a dependency outside the walked set does not count; kept tables are not in it
  my @ops = Test::OrdOp->diff_toplevel({ customers => {} },
    { customers => {}, orders => {} }, %mk, depends => $deps);
  is $flat->(@ops), 'create:orders', 'dependency on an existing table is no constraint';
}

{
  my $cyc = { a => ['b'], b => ['a'], c => ['a'], z => [] };
  my @ops = Test::OrdOp->diff_toplevel({}, { map { $_ => {} } qw(a b c z) },
    %mk, depends => $cyc);
  is $flat->(@ops), 'create:z create:a create:b create:c',
    'cycle: no crash, the remainder alphabetical at the end';
}

done_testing;
