# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use TLDBH;

my $mod = 'DBIx::TableLoader';
eval "require $mod" or die $@;

my $loader;
my $dbh = TLDBH->new;

my %def_args = (
  columns => ['a'],
  dbh     => $dbh,
  # without a DBI default_column_type won't work (so set it)
  default_column_type => 'foo',
);

my $default_drop = [
  qr/DROP\s+TABLE/,
  qr/"data"/,
  qr/\s*/,
];

sub test_statement {
  my ($method, $title, $loader, $prefix, $middle, $suffix) = @_;
  like($loader->${\"${method}_prefix"}, qr/^${prefix}$/, "$title $method prefix");
  like($loader->${\"${method}_suffix"}, qr/^${suffix}$/, "$title $method suffix");
  like($loader->${\"${method}_sql"}, qr/^${prefix}\s*${middle}\s*${suffix}$/, "$title $method sql");
  # call the method which sends the sql to dbh->do (which is mocked)
       $loader->${\"${method}"};
  like($dbh->{do}, qr/^${prefix}\s*${middle}\s*${suffix}$/, "$title $method sql passed to dbh");
}
sub test_create { test_statement('create', @_); }
sub test_drop   { test_statement('drop',   @_); }
sub test_all {
  my ($title, $loader, $create, $insert, $drop) = @_;
  test_statement('create', $title, $loader, @$create) if $create;
  like($loader->insert_sql, $insert, "$title insert sql") if $insert;
  test_statement('drop',   $title, $loader, @$drop) if $drop;
}

test_all(default => new_ok($mod, [{%def_args}]),
[
  qr/CREATE\s+TABLE\s+"data"\s+\(/,
  qr/\s*"a"\s+foo\s*/,
  qr/\)/,
],
  qr/^INSERT INTO "data"\s*\(\s*"a"\s*\)\s*VALUES\s*\(\s*\?\s*\)$/,
  $default_drop,
);

test_all(constraint_suffix =>
  new_ok($mod, [{%def_args, create_suffix => 'CONSTRAINT primary key a)'}]),
[
  qr/CREATE\s+TABLE\s+"data"\s+\(/,
  qr/\s*"a"\s+foo\s*/,
  qr/CONSTRAINT primary key a\)/,
],
  qr/^INSERT INTO "data"\s*\(\s*"a"\s*\)\s*VALUES\s*\(\s*\?\s*\)$/,
  $default_drop,
);

test_all(create_prefix_suffix =>
  new_ok($mod, [{%def_args, create_prefix => 'CREATE A TABLE FOR ME', create_suffix => ') NOT!'}]),
[
  qr/CREATE A TABLE FOR ME/,
  qr/\s*"a"\s+foo\s*/,
  qr/\) NOT!/,
],
  qr/^INSERT INTO "data"\s*\(\s*"a"\s*\)\s*VALUES\s*\(\s*\?\s*\)$/,
  $default_drop,
);

test_all(multiple_columns =>
  new_ok($mod, [{%def_args, columns => [[a => 'bar'], ['b'], 'c']}]),
[
  qr/CREATE\s+TABLE\s+"data"\s+\(/,
  qr/\s*"a"\s+bar,\s+"b"\s+foo,\s+"c"\s+foo\s*/,
  qr/\)/,
],
  qr/^INSERT INTO "data"\s*\(\s*"a", "b", "c"\s*\)\s*VALUES\s*\(\s*\?, \?, \?\s*\)$/,
  $default_drop,
);

test_all(multi_word_name_type =>
  new_ok($mod, [{%def_args, columns => [[a => 'bar foo'], ['b b', 'gri zz ly'], 'c']}]),
[
  qr/CREATE\s+TABLE\s+"data"\s+\(/,
  qr/\s*"a"\s+bar foo,\s+"b b"\s+gri zz ly,\s+"c"\s+foo\s*/,
  qr/\)/,
],
  qr/^INSERT INTO "data"\s*\(\s*"a", "b b", "c"\s*\)\s*VALUES\s*\(\s*\?, \?, \?\s*\)$/,
  $default_drop,
);

test_all(table_type =>
  new_ok($mod, [{%def_args, table_type => 'TEMP'}]),
[
  qr/CREATE\s+TEMP\s+TABLE\s+"data"\s+\(/,
  qr/\s*"a"\s+foo\s*/,
  qr/\)/,
],
  undef,
  $default_drop
);

test_drop(cascade =>
  new_ok($mod, [{%def_args, drop_suffix => 'CASCADE'}]),
  qr/DROP\s+TABLE/,
  qr/"data"/,
  qr/CASCADE/,
);

test_drop(prefix_suffix_drop =>
  new_ok($mod, [{%def_args, drop_prefix => 'DROP TABLE IF EXISTS', drop_suffix => 'CASCADE'}]),
  qr/DROP TABLE IF EXISTS/,
  qr/"data"/,
  qr/CASCADE/,
);

# insert_all

foreach my $test (
  [ [qw(a)], [1] ],
  [ [qw(a b)], [1, 2], [3, 4] ],
  [ [[a => 'A'], 'b'], ['a a', 'b b'], [3, 4] ],
){
  my $data = $test;
  my $rows = @$data - 1;
  $dbh->reset;
  $loader = new_ok($mod, [{%def_args, columns => undef, data => $data}]);
  is($loader->insert_all, $rows, 'inserted all records');
  is($dbh->{prepared}, 1, 'prepare called 1 time');
  shift @$data; # remove columns from the top for comparison
  is_deeply($dbh->{sth}->{execute}, $data, 'expectation executed')
    or diag explain $data;
}

done_testing;
