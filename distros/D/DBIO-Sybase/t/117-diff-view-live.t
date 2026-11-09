use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::Sybase::Introspect;
use DBIO::Sybase::Diff;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless $dsn && $user;

# LIVE (karr k98): views read from syscomments and sysdepends, and a chain of
# views on views dropped and created in dependency order by the diff. The
# objects are the test's own (k98_*) in the database of the DSN, and are
# dropped at the end. The conformance cases of the Diff list (t/106) cover the
# schema-level path.

my $dbh = DBI->connect($dsn, $user, $pass,
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

my @objects = ([ VIEW => 'k98_top' ], [ VIEW => 'k98_mid' ], [ VIEW => 'k98_low' ],
               [ TABLE => 'k98_base' ]);
sub cleanup {
  for my $o (@objects) {
    eval { $dbh->do("DROP $o->[0] $o->[1]") };
  }
}
cleanup();
END { cleanup() if $dbh }

# More than the 255 characters of one syscomments row.
my $pad = join ' AND ', map { "name <> 'pad$_'" } 1 .. 30;
my %sql = (
  low => 'SELECT id, name FROM k98_base',
  mid => "SELECT id, name FROM k98_low WHERE id > 0 AND $pad",
  top => 'SELECT id FROM k98_mid',
);
cmp_ok length($sql{mid}), '>', 255, 'a definition longer than one syscomments row';

$dbh->do('CREATE TABLE k98_base (id int NOT NULL, name varchar(20) NULL)');
$dbh->do("CREATE VIEW k98_$_ AS $sql{$_}") for qw(low mid top);

# The model of the test's objects alone: the database may hold others.
sub model {
  my $m = DBIO::Sybase::Introspect->new(dbh => $dbh)->model;
  my $own = sub { +{ map { $_ => $_[0]{$_} } grep { /^k98_/ } keys %{ $_[0] } } };
  return {
    tables       => $own->($m->{tables}),
    columns      => $own->($m->{columns}),
    indexes      => $own->($m->{indexes}),
    foreign_keys => $own->($m->{foreign_keys}),
    views        => $own->($m->{views}),
  };
}

my $src = model();
is_deeply [ sort keys %{ $src->{views} } ], [ qw(k98_low k98_mid k98_top) ], 'the three views';
is $src->{views}{k98_mid}{definition}, $sql{mid}, 'rows joined: the long definition comes back whole';
is $src->{views}{k98_low}{definition}, $sql{low}, 'the CREATE VIEW head is stripped';
is_deeply $src->{views}{k98_top}{depends_on}, [ 'k98_mid' ], 'top reads from mid';
is_deeply $src->{views}{k98_mid}{depends_on}, [ 'k98_low' ], 'mid reads from low';
is_deeply $src->{views}{k98_low}{depends_on}, [], 'low reads from a table only';
is $src->{tables}{k98_low}{kind}, 'view', 'listed as a view';

is scalar(@{ DBIO::Sybase::Diff->new(source => $src, target => model())->operations }), 0,
  'no change, no operation';

# The desired side: low and mid changed, top as it was.
my %want = (%sql, low => 'SELECT id, name FROM k98_base WHERE id > 0', mid => 'SELECT id FROM k98_low');
my $target = model();
for my $v (qw(low mid)) {
  $target->{views}{"k98_$v"} = { %{ $target->{views}{"k98_$v"} }, definition => $want{$v} };
}

my $diff = DBIO::Sybase::Diff->new(source => $src, target => $target);
my @sql = map { $_->as_sql } @{ $diff->operations };
is_deeply \@sql, [
  'DROP VIEW k98_mid;', 'DROP VIEW k98_low;',
  "CREATE VIEW k98_low AS $want{low};", "CREATE VIEW k98_mid AS $want{mid};",
], 'the changed views, dependents dropped first and created last (top is untouched)';

for my $stmt (@sql) {
  (my $one = $stmt) =~ s/;\z//;
  $dbh->do($one);
}
pass 'the statements run, each as a batch of its own';

my $after = model();
is $after->{views}{k98_low}{definition}, $want{low}, 'low changed';
is $after->{views}{k98_mid}{definition}, $want{mid}, 'mid changed';
is scalar(@{ DBIO::Sybase::Diff->new(source => $after, target => $target)->operations }), 0,
  'a second diff is empty';

done_testing;
