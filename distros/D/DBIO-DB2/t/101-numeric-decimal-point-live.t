use strict;
use warnings;

use Test::More;
use IPC::Open3 ();
use Symbol ();
use DBIO::Optional::Dependencies ();

# LIVE ONLY. Under a German client locale (LC_ALL / LC_CTYPE / LANG de_DE.*,
# set when the process starts) the Db2 CLI hands numeric values over as text
# with a comma: DECIMAL '1234567890,12', REAL '1,500000E+00', DECFLOAT '1,25'.
# Perl reads '1234567890,12' as 1234567890. The cursor and select_single give
# the point back. The locale has to be there at process start, so the reads
# run in child processes: C locale, de_DE.utf8 and de_DE.iso88591. Writes are
# checked on the server (a comparison in WHERE, a calculation).
# Offline counterpart: t/100.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

# the German locales are what the test is about; without them it has nothing to show
my %have = map { $_ => 1 } split /\n/, scalar `locale -a 2>/dev/null`;
my @missing = grep { !$have{$_} } qw(de_DE.utf8 de_DE.iso88591);
plan skip_all => "Test needs the locales @missing (locale -a)" if @missing;

my $TABLE = "dbio_decpoint_$$";

# the part that runs inside the child process, in the locale it was started in
my $CHILD = <<'CHILD';
use strict; use warnings;
{
  package K61::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table($ENV{K61_TABLE});
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer', is_auto_increment => 1 },
    d12 => { data_type => 'decimal', size => [12, 2], is_nullable => 1 },
    d20 => { data_type => 'decimal', size => [20, 4], is_nullable => 1 },
    num => { data_type => 'numeric', size => [10, 3], is_nullable => 1 },
    rl  => { data_type => 'real', is_nullable => 1 },
    dbl => { data_type => 'double precision', is_nullable => 1 },
    f16 => { data_type => 'decfloat', size => 16, is_nullable => 1 },
    f34 => { data_type => 'decfloat', size => 34, is_nullable => 1 },
    txt => { data_type => 'varchar', size => 20, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  package K61::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->register_class(Item => 'K61::Item');
}
my $schema = K61::Schema->connect(@ENV{qw(K61_DSN K61_USER K61_PASS)});
my $rs = $schema->resultset('Item');
my @cols = qw(d12 d20 num rl dbl f16 f34 txt);
sub out {
  my ($label, $row) = @_;
  my %h = ref $row eq 'HASH' ? %$row : ref $row eq 'ARRAY' ? (map { $cols[$_] => $row->[$_] } 0 .. $#cols) : $row->get_columns;
  print join("\t", $label, map { "$_=" . ($h{$_} // 'NULL') } @cols), "\n";
}

# strings, a big value and a comma in text
my $s = $rs->create({ d12 => '1234567890.12', d20 => '1234567890123456.7890', num => '1234567.125',
  rl => '1.5', dbl => '1.5', f16 => '1.25', f34 => '1234567890123456.7890', txt => 'a,b' });
# Perl numbers
my $n = $rs->create({ d12 => 1234.5, d20 => 0.25, num => 7.5, rl => 2.5, dbl => 0.125,
  f16 => 3.5, f34 => 0.75, txt => '1,5' });
# NULLs
my $z = $rs->create({});

my $sid = $s->id; my $nid = $n->id; my $zid = $z->id;
out('find',    $rs->find($sid));
out('findn',   $rs->find($nid));
out('findnull',$rs->find($zid));
out('all',     scalar $rs->search({ id => $sid })->first);
{ my @all = $rs->search({ id => $nid }, { columns => \@cols })->all; out('allcols', $all[0]); }
{ my $c = $rs->search({ id => $sid }, { columns => \@cols })->cursor; out('cursor-next', [ $c->next ]); }
{ my $c = $rs->search({ id => $sid }, { columns => \@cols })->cursor; out('cursor-all', ($c->all)[0]); }
out('single',  scalar $rs->search({ id => $sid })->single);
{
  my @r = $schema->storage->select_single($rs->result_source, [@cols], { id => $sid }, {});
  out('select_single', \@r);
}
{ my @v = $rs->search({ id => $sid })->get_column('d12')->all;
  print join("\t", 'get_column', "d12=$v[0]"), "\n"; }

# write direction, answered by the server
{
  my $c1 = $rs->search({ d12 => '1234567890.12' })->count;
  my $c2 = $rs->search({ d12 => 1234.5 })->count;
  my $c3 = $rs->search({ rl => 2.5, dbl => 0.125 })->count;
  my $c4 = $rs->search({ f34 => '1234567890123456.7890' })->count;
  print join("\t", 'where', "string=$c1", "number=$c2", "float=$c3", "decfloat=$c4"), "\n";
  my ($x, $y) = $schema->storage->dbh_do(sub {
    $_[1]->selectrow_array('SELECT cast(cast(? as decimal(12,2))*100 as integer), cast(cast(? as decimal(12,2))*100 as integer) FROM sysibm.sysdummy1', undef, '1.5', 1.5) });
  print join("\t", 'calc', "string=$x", "number=$y"), "\n";
}
CHILD

sub run_child {
  my ($locale) = @_;
  local %ENV = %ENV;
  delete @ENV{qw(LC_ALL LC_CTYPE LC_NUMERIC LANG LANGUAGE)};
  if (defined $locale) { $ENV{$_} = $locale for qw(LC_ALL LANG) }
  @ENV{qw(K61_TABLE K61_DSN K61_USER K61_PASS)} = ($TABLE, $dsn, $user, $pass // '');
  my $err = Symbol::gensym;
  my $pid = IPC::Open3::open3(my $in, my $out, $err, $^X, (map { "-I$_" } grep { !ref } @INC), '-e', $CHILD);
  close $in;
  my $stdout = do { local $/; <$out> }; my $stderr = do { local $/; <$err> };
  waitpid $pid, 0;
  return ($stdout // '', $stderr // '', $? >> 8);
}

{
  package K61::AdminSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
}
my $admin = K61::AdminSchema->connect($dsn, $user, $pass);
my $dbh = eval { $admin->storage->dbh } or plan skip_all => "Cannot reach DB2: $@";

sub drop_table { local $dbh->{PrintError} = 0; eval { $dbh->do(qq{DROP TABLE "$TABLE"}) } }
END { drop_table() if $dbh && $dbh->{Active} }

sub make_table {
  drop_table();
  $dbh->do(qq{CREATE TABLE "$TABLE" ("id" INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "d12" DECIMAL(12,2), "d20" DECIMAL(20,4), "num" NUMERIC(10,3), "rl" REAL, "dbl" DOUBLE,
    "f16" DECFLOAT(16), "f34" DECFLOAT(34), "txt" VARCHAR(20))});
}

my %expect_text = (
  d12 => '1234567890.12', d20 => '1234567890123456.7890', num => '1234567.125',
  f16 => '1.25', f34 => '1234567890123456.7890', txt => 'a,b',
);
my %expect_num_row = (d12 => '1234.50', d20 => '0.2500', num => '7.500', f16 => '3.5', f34 => '0.75', txt => '1,5');

sub parse {
  my ($stdout) = @_;
  my %r;
  for my $line (split /\n/, $stdout) {
    my ($label, @kv) = split /\t/, $line;
    $r{$label} = { map { split /=/, $_, 2 } @kv };
  }
  return \%r;
}

for my $locale (undef, 'de_DE.utf8', 'de_DE.iso88591') {
  my $name = $locale // 'C locale (reference)';
  make_table();
  my ($stdout, $stderr, $rc) = run_child($locale);
  is $rc, 0, "$name: the child ran" or diag $stderr;
  my $r = parse($stdout);

  for my $label (qw(find all single cursor-next cursor-all select_single)) {
    my $row = $r->{$label} or do { fail "$name: $label gave no row"; next };
    for my $c (qw(d12 d20 num f16 f34 txt)) {
      is $row->{$c}, $expect_text{$c}, "$name: $label: $c is $expect_text{$c}";
    }
    for my $c (qw(rl dbl)) {
      unlike $row->{$c}, qr/,/, "$name: $label: $c has no comma";
      ok abs($row->{$c} - 1.5) < 1e-9, "$name: $label: $c is 1.5 as a number ($row->{$c})";
    }
  }
  {
    my $row = $r->{findn} or fail "$name: findn gave no row";
    is $row->{$_}, $expect_num_row{$_}, "$name: Perl numbers written, read back: $_ is $expect_num_row{$_}"
      for sort keys %expect_num_row;
    ok abs($row->{rl} - 2.5) < 1e-9 && abs($row->{dbl} - 0.125) < 1e-9, "$name: REAL 2.5 and DOUBLE 0.125 read back"
      or diag "rl=$row->{rl} dbl=$row->{dbl}";
    my $all = $r->{allcols};
    is $all->{d12}, '1234.50', "$name: all with columns: d12 has the point";
  }
  {
    my $row = $r->{findnull} or fail "$name: findnull gave no row";
    is $row->{$_}, 'NULL', "$name: NULL stays NULL: $_" for qw(d12 d20 num rl dbl f16 f34);
  }
  is $r->{get_column}{d12}, '1234567890.12', "$name: get_column: the point";
  is_deeply $r->{where}, { string => 1, number => 1, float => 1, decfloat => 1 },
    "$name: the server finds the rows written (values compared in WHERE)";
  is_deeply $r->{calc}, { string => 150, number => 150 },
    "$name: a bound '1.5' and 1.5 are 1.5 on the server (cast * 100 = 150)";
}

done_testing;
