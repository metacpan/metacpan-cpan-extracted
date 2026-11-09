use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Column;

# karr dbio-postgresql-postgis k28: a layer supplies the USING expression of a
# column's type change through register_using_hook. These tests pin what the
# diff writes with a fake hook; t/132-diff-column-using-hook-live.t runs it.

my $C = 'DBIO::PostgreSQL::Diff::Column';
my $tables = { 'public.t' => { schema_name => 'public', table_name => 't' } };

sub col {
  my ($type, $category) = @_;
  $category //= 'b';
  return {
    column_name => 'v', data_type => $type, not_null => 0,
    type_category => $category, type_schema => 'public',
    ( $category eq 'e' ? (enum_type => $type) : () ),
    ( $category eq 'c' ? (composite_type => $type) : () ),
  };
}

sub sql {
  my ($from, $to) = @_;
  my @ops = $C->diff({ 'public.t' => [ $from ] }, { 'public.t' => [ $to ] }, $tables, $tables);
  return join "\n", map { $_->as_sql } @ops;
}

my $PLAIN = 'ALTER TABLE public.t ALTER COLUMN v TYPE integer;';
my @asked;

is(sql(col('text'), col('integer')), $PLAIN, 'no hook: no USING');

$C->register_using_hook(h1 => sub {
  my ($ctx) = @_;
  push @asked, $ctx;
  return "$ctx->{column}::integer";
});
is(sql(col('text'), col('integer')),
  'ALTER TABLE public.t ALTER COLUMN v TYPE integer USING v::integer;',
  'a hook: its expression is the USING of the ALTER');
is(scalar @asked, 1, 'asked once');
my $ctx = $asked[0];
is($ctx->{table_key}, 'public.t', 'ctx table_key');
is($ctx->{column_name}, 'v', 'ctx column_name');
is($ctx->{column}, 'v', 'ctx column');
is($ctx->{old_type}, 'text', 'ctx old_type');
is($ctx->{new_type}, 'integer', 'ctx new_type');
is($ctx->{old_info}{data_type}, 'text', 'ctx old_info');
is($ctx->{new_info}{data_type}, 'integer', 'ctx new_info');

@asked = ();
sql(col('integer'), col('integer'));
is(scalar @asked, 0, 'not asked when the type stays');

is(sql(col('text'), col('e_new', 'e')),
  'ALTER TABLE public.t ALTER COLUMN v TYPE e_new USING v::text::e_new;',
  'enum target: the enum path keeps its USING');
sql(col('text'), col('c_new', 'c'));
is(scalar @asked, 0, 'not asked for an enum or composite target');

# first hit wins; undef and empty are passed over
$C->unregister_using_hook('h1');
$C->register_using_hook(none  => sub { undef });
$C->register_using_hook(empty => sub { '' });
$C->register_using_hook(a     => sub { 'first_expr' });
$C->register_using_hook(b     => sub { 'second_expr' });
is(sql(col('text'), col('integer')),
  'ALTER TABLE public.t ALTER COLUMN v TYPE integer USING first_expr;',
  'the first non-empty answer wins');
$C->unregister_using_hook($_) for qw(none empty a b);
is(sql(col('text'), col('integer')), $PLAIN, 'unregistered: the default is back');

# a dying hook stops the diff
$C->register_using_hook(boom => sub { die "boom\n" });
ok(!eval { sql(col('text'), col('integer')); 1 }, 'a dying hook dies');
is($@, "boom\n", 'with its own error');
$C->unregister_using_hook('boom');

# a non-string answer is refused
$C->register_using_hook(ref => sub { [ 'x' ] });
ok(!eval { sql(col('text'), col('integer')); 1 }, 'a reference is refused');
like($@, qr/USING hook 'ref' .*returned a ARRAY reference, not a plain string/,
  'with a clear message');
$C->unregister_using_hook('ref');

is(sql(col('text'), col('integer')), $PLAIN, 'clean afterwards');

done_testing;
