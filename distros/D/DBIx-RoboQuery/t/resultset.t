# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Test::MockObject 1.09;
use lib 't/lib';
use THelper;

my $timer = Test::MockObject->new
  ->mock(stop    => sub { ++$_[0]->{time} })
  ->mock(restart => sub {   $_[0]->{time} })
;
$timer->fake_new('Timer::Simple');

my $qmod = 'DBIx::RoboQuery';

my $transformations = {
  trim => sub { (my $s = $_[0]) =~ s/(^\s+|\s+$)//g; $s; },
  squeeze => sub { (my $s = $_[0]) =~ s/\s+/ /g; $s; },
  uc => sub { uc $_[0] }
};

eval "require $qmod" or die $@;
my $query = $qmod->new(sql => "SELECT * FROM table1", transformations => $transformations);
isa_ok($query, $qmod);

my $rmod = 'DBIx::RoboQuery::ResultSet';
eval "require $rmod" or die $@;

my @non_keys = qw(goo ber bar baz beft blou lou);
my @columns = (qw(foo boo), @non_keys);

my $mock_sth = Test::MockObject->new({NAME_lc => [@columns]})->set_true('execute')->set_true('finish');
my $mock_dbh = Test::MockObject->new();
$mock_dbh->mock('prepare', sub { $mock_sth });

my $opts = {
  dbh => $mock_dbh,
  key_columns => 'foo',
  drop_columns => 'boo'
};

my $r = $rmod->new($query, $opts);
isa_ok($r, $rmod);

foreach my $colattr ( qw(key_columns drop_columns) ){
  isa_ok($r->{$colattr}, 'ARRAY', "$colattr column attribute array ref");
  is_deeply($r->{$colattr}, [$opts->{$colattr} || ()], "$colattr column attribute value");
  is_deeply([$r->$colattr], [$opts->{$colattr} || ()], "$colattr method is a list");
}
is_deeply([$r->key_columns], [$opts->{key_columns}], 'key_columns is a list');

is($r->execute(), 1, 'r->execute()');
is_deeply([$r->non_key_columns], \@non_keys, 'non key columns w/o key, drop');

$mock_sth->{NAME_lc} = [qw(foo boo lou)];
is($r->execute(), 1, 'r->execute()');
is_deeply([$r->non_key_columns], [qw(lou)], 'non key columns w/o key, drop');

$r->{key_columns} = [qw(foo lou)];
is($r->execute(), 1, 'r->execute()');
is_deeply([$r->non_key_columns], [], 'non key columns w/o key, drop');

$mock_sth->{NAME_lc} = [qw(foo boo)];
is($r->execute(), 1, 'r->execute()');
is_deeply([$r->non_key_columns], [], 'non key columns w/o key, drop');

# change things up

$opts->{key_columns} = [qw(foo lou)];
$r = $rmod->new($query, $opts);
isa_ok($r, $rmod);
$mock_sth->{NAME_lc} = [qw(foo lou goo ber boo)];

my %data = (
  foo1lou1a => {foo => 'foo1', lou => 'lou1', goo => 'goo1', ber => 'ber1', boo => 'boo1'},
  foo2lou2  => {foo => 'foo2', lou => 'lou2', goo => 'goo2', ber => 'ber2', boo => 'boo2'},
  foo1lou2  => {foo => 'foo1', lou => 'lou2', goo => 'goo3', ber => 'ber3', boo => 'boo3'},
  foo2lou1  => {foo => 'foo2', lou => 'lou1', goo => 'goo4', ber => 'ber4', boo => 'boo4'},
  foo1lou1b => {foo => 'foo1', lou => 'lou1', goo => 'goo5', ber => 'ber5', boo => 'boo5'},
  foo1lou1c => {foo => 'foo1', lou => 'lou1', goo => 'goo6', ber => 'ber6', boo => 'boo6'},
);
my @data = @data{qw(foo1lou1a foo2lou2 foo1lou2 foo2lou1 foo1lou1b foo1lou1c)};

sub after_drop { my %r = %{$_[0]}; my @d = $opts->{drop_columns}; @d = @{$d[0]} if ref $d[0]; delete @r{ @d }; \%r; }

my $exp = {
  foo1 => {
    lou2 => after_drop($data{foo1lou2})
  },
  foo2 => {
    lou2 => after_drop($data{foo2lou2}),
    lou1 => after_drop($data{foo2lou1}),
  }
};

my $reversed = 0;
sub fetchall {
  my ($root, $sth, $keys) = ({}, @_);
  for my $row ( ordered_data() ){
    my $h = $root;
    $h = ($h->{ $row->{$_} } ||= {}) for @$keys;
    @$h{keys %$row} = values %$row;
    delete @$h{ $opts->{drop_columns} };
  }
  $root;
};
sub ordered_data { $reversed ? reverse @data : @data }
sub set_data { $reversed = $_[0]; $mock_sth->set_series('fetchrow_hashref', ordered_data); }

$mock_sth->mock('fetchall_hashref', \&fetchall);

set_data(0);
$exp->{foo1}{lou1} = after_drop($data{foo1lou1c});

is_deeply($r->hash, $exp, 'hash returned expected w/ no preference');

set_data(1);
$exp->{foo1}{lou1} = after_drop($data{foo1lou1a});

is_deeply($r->hash, $exp, 'hash returned expected w/ no preference');

# now add preference
$r->{preferences} = [q[ber == 'ber4'], q[boo == 'boo5']];

set_data(1);
$exp->{foo1}{lou1} = after_drop($data{foo1lou1b});

is_deeply($r->hash, $exp, 'hash returned expected w/    preference');

# change order, expect the same
set_data(0);

is_deeply($r->hash, $exp, 'hash returned expected w/    preference');

# check columns

my @column_tests = (
  # key,           non-key,               drop
  [ [qw(foo lou)], [qw(goo ber boo)],     [] ],
  [ [qw(foo lou)], [qw(goo ber)],         [qw(boo)] ],
  [ [qw(foo)],     [qw(lou goo ber)],     [qw(boo)] ],
  [ [qw(foo)],     [qw(lou goo ber boo)], [] ],
  [ [],            [qw(foo lou goo ber boo)], [] ],
  [ [],            [],                    [qw(foo lou goo ber boo)] ],
);

foreach my $test ( @column_tests ){
  # for $all_columns and NAME_lc we reverse the groups to put key_columns
  # in the back to confirm that columns() preserves the order
  $opts->{key_columns}  = $$test[0];
  my $all_columns       = [map { @$_ } @$test[1,0]];
  $opts->{drop_columns} = $$test[2];
  $mock_sth->{NAME_lc}  = [map { @$_ } reverse @$test];

  $r = $rmod->new($query, $opts);
  $r->execute();
  is_deeply([$r->key_columns],  $$test[0],    'key  columns');
  is_deeply([$r->columns],      $all_columns, '     columns');
  is_deeply([$r->drop_columns], $$test[2],    'drop columns');
}

$opts->{key_columns} = [];
$opts->{drop_columns} = [];
$r = $rmod->new($query, $opts);

throws_ok(sub { $r->hash }, qr/key_columns/, 'key_columns required for hash()');

SKIP: {
  # To test that the slice we're supplying to fetchall_arrayref is correct
  # we need to use the *real* DBI fetchall_arrayref, so try to use DBD::Mock
  eval "require DBI; require DBD::Mock";
  # save the error if there was one
  my $e = $@;

  # figure out how many tests we're running or skipping
  my @drop_tests = (
    [],
    [qw(boo)],
    [qw(goo ber)],
  );

  skip('DBD::Mock not installed, skipping array() tests', scalar @drop_tests) if $e;

  $opts->{dbh} = my $dbdmock = DBI->connect('dbi:Mock:', qw(u p));

  my @datakeys = keys %{$data[0]};
  foreach my $test ( @drop_tests ){
    $opts->{drop_columns} = $test;
    my @nondrop = do { my %drop = map { $_ => 1 } @$test; grep { !$drop{$_} } @datakeys; };
    foreach my $fetch (
      ['hash',  {}, [map {  after_drop($_) } @data]],
      ['array', [], [map { [@$_{@nondrop}] } @data]]
    ){
      my ($type, $slice, $rows) = @$fetch;
      # Doing this doesn't tell me anything: [\@datakeys, map { [@{after_drop($_)}{ @datakeys }] } @data].
      # Rely on DBI's method to tell me if the slice specification is accurate.
      $dbdmock->{mock_add_resultset} = [\@datakeys, map { [@{$_}{ @datakeys }] } @data];
      $r = $rmod->new($query, $opts);
      is_deeply($r->array($slice), $rows, "array() returned expected $type slices");
    }
  }
}

# test transform

my @trdata = (
  {id => 'a1', hello => ' hello  there ', name => ' ucased '},
  {id => 'B1', hello => ' hello  again ', name => ' u  cased '},
  {id => 'b1', hello => ' hello  three ', name => ' u  case d '},
);

my $trdatarows = [
  {id => 'A1', hello => 'hello there', name => 'UCASED'},
  {id => 'B1', hello => 'hello again', name => 'U CASED'},
  {id => 'B1', hello => 'hello three', name => 'U CASE D'},
];

my $trdatatree = {
  A1 => $trdatarows->[0],
  B1 => $trdatarows->[2],
};

my $arraysfromhashes = sub { [map { [@$_{qw(id hello name)}] } @_] };

$query->transform('trim', groups => 'non_key');
$query->tr_groups('squeeze', 'non_key');
$query->tr_fields('uc',   [qw(id name)]);

# reset dbh, sth
$mock_sth->{NAME_lc} = [qw(id hello name)];
@$opts{qw(key_columns dbh)} = ('id', $mock_dbh);
$timer->{time} = 1;

# array of arrayrefs
$mock_sth->set_series('fetchall_arrayref', $arraysfromhashes->(@trdata));
$r = $rmod->new($query, $opts);
is_deeply($r->array([]), $arraysfromhashes->(@$trdatarows), 'array returns transformed data');
test_times($r, 9); # 2 + 3 + 4
is $r->row_count, scalar(@trdata), 'row_count';

# array of hashrefs
$mock_sth->set_series('fetchall_arrayref', [@trdata]);
$r = $rmod->new($query, $opts);
is_deeply($r->array, $trdatarows, 'array returns transformed data');
test_times($r, 18); # 5 + 6 + 7
is $r->row_count, scalar(@trdata), 'row_count';

# hash of hashrefs
$mock_sth->set_series('fetchrow_hashref', @trdata);
$r = $rmod->new($query, $opts);
is_deeply($r->hash,  $trdatatree, 'hash returns transformed data');
test_times($r, 27); # 8 + 9 + 10
is $r->row_count, 2, 'row_count (only 2 for hash tree)';

# test transfer of attributes
my @key = qw(bl argh);
$query->{key_columns} = [@key];
is_deeply($query->resultset->{key_columns}, [@key], 'key_columns transferred from Q to R');

# test transfer of attributes set in the template
$query = $qmod->new(sql => qq|[% query.key_columns = ['boo'] %]|);
is_deeply($query->resultset->{key_columns}, ['boo'], 'key_columns set in template transferred from Q to R');

done_testing;

sub test_times {
  my $t = shift->times;
  is_deeply [sort keys %$t], [qw(execute fetch prepare total)], '4 times';
  is $t->{total}, $t->{prepare} + $t->{execute} + $t->{fetch}, 'total of the other 3';
  is $t->{total}, shift, 'total time';
}
