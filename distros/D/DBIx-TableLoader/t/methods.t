# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use TLDBH;

my ($commit, $begun);
my $dbh = TLDBH->new;

$INC{'DBI.pm'} = __FILE__;
sub DBI::SQL_LONGVARCHAR { ':-P' }

my $mod = 'DBIx::TableLoader';
eval "require $mod" or die $@;

my $loader;

foreach my $args (
  [],
  [{columns => []}],
){
  is(eval { $loader = $mod->new(@$args) }, undef, 'useless without columns');
  like($@, qr/columns/, 'Died without columns');
}

my %def_args = (
  default_column_type => 'foo',
  dbh => $dbh,
);

# NOTE: determine_column_types is not specifically tested
# but it sets the values returned from columns() and column_names()

foreach my $args (
  [{columns =>  [qw(d b i)] , %def_args}],
  [{data    => [[qw(d b i)]], %def_args}],
){
  $loader = new_ok($mod, $args);
  is_deeply($loader->columns, [[qw(d foo)], [qw(b foo)], [qw(i foo)]], 'string columns');
  is_deeply($loader->column_names, [qw(d b i)], 'string columns (names)');
  is_deeply($loader->quoted_column_names, [qw("d" "b" "i")], 'string columns (names) (quoted)');
}

  $loader = new_ok($mod, [{columns => [[a => 'bar'], ['b'], 'c'], %def_args}]);
  is_deeply($loader->columns, [[qw(a bar)], [qw(b foo)], [qw(c foo)]], 'mixed columns');
  is_deeply($loader->column_names, [qw(a b c)], 'mixed columns (names)');
  is_deeply($loader->quoted_column_names, [qw("a" "b" "c")], 'mixed columns (names) (quoted)');

  $loader = new_ok($mod, [{columns => [[a => 'bar foo'], ['b', 'gri zz ly'], 'c'], %def_args}]);
  is_deeply($loader->columns, [['a', 'bar foo'], ['b', 'gri zz ly'], [qw(c foo)]], 'multi-word data types');
  is_deeply($loader->column_names, [qw(a b c)], 'multi-word data types (names)');
  is_deeply($loader->quoted_column_names, [qw("a" "b" "c")], 'multi-word data types (names) (quoted)');

{

  # column type

  my $args = [dbh => $dbh, columns => ['foo']];

  # create new instance for each test to avoid internal caching
  $dbh->{driver_type} = 'boo';
  is(new_ok($mod, $args)->default_column_type, 'boo', 'column type from dbh');
  $dbh->{driver_type} = '';
  is(new_ok($mod, $args)->default_column_type, 'text', 'default column type');
  $dbh->{driver_type} = 'no matter';
  is(new_ok($mod, [@$args, default_column_type => 'bear'])->default_column_type, 'bear', 'default column type');

  # sql data type

  is(new_ok($mod, $args)->default_sql_data_type, ':-P', 'default sql data type');

}

# get_row
my $get_row_override_data = {cat => [qw(meow string)], dog => [qw(bark squirrel)], bear => [qw(grr picnicbasket)]};
foreach my $test (
  # normal behavior
  [ simple => {}, [
    [1, 2, 3],
    [qw(a b c)],
    [0, 0, 0],
  ]],
  # modify each row
  [ map_rows => {map_rows => sub { [map { $_ . $_ } @{ $_[0] }] }}, [
    [qw(11 22 33)],
    [qw(aa bb cc)],
    [qw(00 00 00)],
  ]],
  # example from POD (using $_)
  [ uppercase_example => {map_rows => sub { [ map { uc $_ } @$_ ] }}, [
    [qw(1 2 3)],
    [qw(A B C)],
    [qw(0 0 0)],
  ]],
  # stupid example of alternate get_row... not useful, but it works
  # (map_rows would more appropriately do the same thing)
  # NOTE: columns are reversed because we're using get_row rather than map_rows
  [ get_row =>  {get_row  => sub { [reverse @{ shift @{ $_[0]->{data} } || return undef }] }}, [
    [3, 2, 1],
    [qw(c b a)],
    [0, 0, 0],
  ], [qw(c b a)]],
  # example of both
  [ get_row_map_rows =>  {
      get_row  => sub { [reverse @{ shift @{ $_[0]->{data} } || return undef }] },
      map_rows => sub { [map { join('', ($_) x 3) } @{ $_[0] }] }}, [
    [qw(333 222 111)],
    [qw(ccc bbb aaa)],
    [qw(000 000 000)],
  ], [qw(c b a)]],
  # more useful get_row... using an alternate input data format
  [ alt_get_row => {
      data => undef,
      columns => [qw(animal says chases)],
      get_row => sub { my ($an, $ar) = each %$get_row_override_data; $ar && [$an x 2, @$ar] }}, [
    # map keys() so that the data comes out in the same order
    map { [$_ x 2, @{$$get_row_override_data{$_}}] } keys %$get_row_override_data,
  ]],
  # filter some out
  [ grep_rows => {grep_rows => sub { $_->[1] =~ /^\d+$/ }}, [
    [qw(1 2 3)],
    [qw(0 0 0)],
  ]],
  # grep then map
  [ grep_map_rows => {
      grep_rows => sub { $_->[1] },
      map_rows => sub { [map { ord($_) } @$_] }}, [
    [qw(49 50 51)],
    [qw(97 98 99)],
  ]],
  # let validator alter rows to fit
  [ validate => {
      handle_invalid_row => sub { [ @{$_[2]}[0,1] ] },
      # declare that we only want 2 columns
      columns => [qw(d e)],
    }, [
      # input data has 4 rows, just use the first two columns of each
      [qw(a b)],
      [qw(1 2)],
      [qw(a b)],
      [qw(0 0)],
    ],
  ],
){
  my ($title, $over, $exp, $columns) = @$test;
  $columns ||= $over->{columns} || [qw(a b c)];
  my $args = [dbh => $dbh, data => [ [qw(a b c)],
    [1, 2, 3],
    [qw(a b c)],
    [0, 0, 0],
  ]];

  my $loader = new_ok($mod, [@$args, %$over]);

  is_deeply($loader->column_names, $columns, "$title: column names");
  is_deeply($loader->get_row, $_, "$title: get_row")
    foreach @$exp;

  is($loader->get_row, undef, "$title: no more rows");
}

# name
foreach my $test (
  [ [], 'data' ],
  [ [name_prefix => 'pre_'], 'pre_data' ],
  [ [name_prefix => 'pre', name_suffix => 'post'], 'predatapost' ],
  [ [name => 'tab', name_suffix => ' grr'], 'tab grr' ],
){
  my ($attr, $exp) = @$test;
  my $loader = new_ok($mod, [columns => ['goo'], dbh => $dbh, @$attr]);
  is($loader->name, $exp, 'expected name');
  is($loader->quoted_name, qq{"$exp"}, 'expected quoted name');
}

# transaction
{
  my $args = [data => [[qw(a b)], [1, 2]], dbh => $dbh];
  my $loader = new_ok($mod, [@$args]);
  $dbh->reset;
  $loader->load;
  is($dbh->{begin},  1, 'transaction');
  is($dbh->{commit}, 1, 'transaction');

  $loader = new_ok($mod, [@$args, transaction => 0]);
  $dbh->reset;
  $loader->load;
  is($dbh->{begin},  0, 'no transaction');
  is($dbh->{commit}, 0, 'no transaction');
}

done_testing;
