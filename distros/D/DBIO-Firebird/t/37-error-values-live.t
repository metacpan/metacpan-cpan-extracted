use strict;
use warnings;
use Test::More;
use utf8;
binmode(Test::More->builder->$_, ":utf8") for qw(output failure_output todo_output);

# LIVE: the text of an error names the type, the column, the constraint and
# the table, never a value (ADR 0075 of core). Firebird writes the value of a
# key into the sentence of a PRIMARY KEY / UNIQUE / FOREIGN KEY violation
# ("Problematic key value is ("ID" = 7, "EMAIL" = 'x')") and the string of a
# failed conversion ("conversion error from string "x""), also when the value
# was bound and also when it is one character long, which the net of core (a
# bound value of four characters or more) leaves standing. Every case binds
# a marker value and asks four things of the exception: the marker is not in
# it, the words around the value are, the count of bind values is, and a
# literal that stands in the statement itself is untouched.
#
#   DBIO_TEST_FIREBIRD_DSN / _USER / _PASS
#
# WARNING: creates and drops the tables "fw_parent", "fw_child", "fw_typed"
# and "fw_dup".

my ($dsn, $user, $pass) = @ENV{qw(DBIO_TEST_FIREBIRD_DSN DBIO_TEST_FIREBIRD_USER DBIO_TEST_FIREBIRD_PASS)};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live error-value test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

{
  package FwLive::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('Firebird');

  package FwLive::Schema::Result::Parent;
  use DBIO 'Core';
  __PACKAGE__->table('fw_parent');
  __PACKAGE__->add_columns(
    a => { data_type => 'integer' },
    b => { data_type => 'varchar', size => 40 },
    c => { data_type => 'varchar', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key(qw(a b));

  package FwLive::Schema::Result::Child;
  use DBIO 'Core';
  __PACKAGE__->table('fw_child');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    a  => { data_type => 'integer' },
    b  => { data_type => 'varchar', size => 40 },
  );
  __PACKAGE__->set_primary_key('id');

  package FwLive::Schema::Result::Typed;
  use DBIO 'Core';
  __PACKAGE__->table('fw_typed');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    d  => { data_type => 'date', is_nullable => 1 },
    ts => { data_type => 'timestamp', is_nullable => 1 },
    v  => { data_type => 'varchar', size => 5, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package FwLive::Schema::Result::Dup;
  use DBIO 'Core';
  __PACKAGE__->table('fw_dup');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    v  => { data_type => 'varchar', size => 40 },
  );
  __PACKAGE__->set_primary_key('id');

  package main;
  FwLive::Schema->register_class($_ => "FwLive::Schema::Result::$_") for qw(Parent Child Typed Dup);
}

$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^non-transactional DDL on |problem parsing SQL_/ };

my $schema = FwLive::Schema->connect($dsn, $user, $pass, { quote_names => 1 });
my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach Firebird server: $@";

sub cleanup { eval { $dbh->do(qq{DROP TABLE "$_"}) } for qw(fw_child fw_parent fw_typed fw_dup) }
cleanup();
$dbh->do($_) for
  q{CREATE TABLE "fw_parent" ("a" INTEGER NOT NULL, "b" VARCHAR(40) NOT NULL, "c" VARCHAR(40),
      PRIMARY KEY ("a", "b"), CONSTRAINT "fw_parent_c_uq" UNIQUE ("c"))},
  q{CREATE TABLE "fw_child" ("id" INTEGER NOT NULL PRIMARY KEY, "a" INTEGER NOT NULL, "b" VARCHAR(40) NOT NULL,
      CONSTRAINT "fw_child_fk" FOREIGN KEY ("a", "b") REFERENCES "fw_parent" ("a", "b"))},
  q{CREATE TABLE "fw_typed" ("id" INTEGER NOT NULL PRIMARY KEY, "d" DATE, "ts" TIMESTAMP, "v" VARCHAR(5))},
  q{CREATE TABLE "fw_dup" ("id" INTEGER NOT NULL PRIMARY KEY, "v" VARCHAR(40) NOT NULL)};

my $p = $schema->resultset('Parent');
my $err = sub { my $code = shift; eval { $code->(); 1 } ? undef : "$@" };

# $e is the exception text; @gone must not be in it, @kept must be
sub check {
  my ($name, $e, $gone, $kept) = @_;
  ok defined $e, "$name: the statement is refused" or return;
  for my $g (@$gone) { unlike $e, qr/\Q$g\E/, "$name: '$g' is not in the message" }
  for my $k (@$kept) { like   $e, $k,          "$name: $k is in the message" }
}

# PRIMARY KEY, composite, a value with ' " , and :
my $odd = q{geheim"x'y, z:1};
$p->create({ a => 987654321, b => $odd, c => 'first-c' });
check 'primary key long',
  $err->(sub { $p->create({ a => 987654321, b => $odd, c => 'second-c' }) }),
  [ 987654321, 'geheim', 'x\'y', 'z:1' ],
  [ qr/PRIMARY or UNIQUE KEY constraint "INTEG_\d+" on table "fw_parent"/,
    qr/Problematic key value is \("[Aa]" = \*\*\*, "[Bb]" = \*\*\*\)/, qr/with 3 bind values/ ];

# the short value the net of core leaves standing
$p->create({ a => 7, b => 'ab', c => undef });
{
  my $e = $err->(sub { $p->create({ a => 7, b => 'ab', c => undef }) });
  check 'primary key short', $e, [ "'ab'" ],
    [ qr/Problematic key value is \("[Aa]" = \*\*\*, "[Bb]" = \*\*\*\)/, qr/with 3 bind values/ ];
  unlike $e // q{}, qr/"[Aa]" = 7\b/i, 'primary key short: 7 is not in the message';
}

# UNIQUE key: a long value, a short one, quotes, a line break, UTF8
my $n = 100;
for my $c ('geheim@x.y', 'ab', qq{it's "q", x}, "line1\nline2", "\x{e4}\x{f6}\x{20ac}geheim") {
  $n++;
  $p->create({ a => $n, b => 'u', c => $c });
  (my $show = $c) =~ s/\n/\\n/g;
  my $e = $err->(sub { $p->create({ a => $n + 1000, b => 'u', c => $c }) });
  check "unique '$show'", $e, [ (grep { length > 3 } split /[\n"',]/, $c), (length $c < 4 ? qq{'$c'} : ()) ],
    [ qr/KEY constraint "fw_parent_c_uq"|KEY constraint "FW_PARENT_C_UQ"/i, qr/on table "fw_parent"/,
      qr/Problematic key value is \("[Cc]" = \*\*\*\)/, qr/with 3 bind values/ ];
}

# the literal of the statement itself stays
{
  my $e = $err->(sub { $p->create({ a => 7, b => \q{'ab'}, c => undef }) });
  like $e // '', qr/\[for Statement ".*'ab'.*" with 2 bind values/, 'a literal in the statement is left as it is';
  like $e // '', qr/Problematic key value is \("[Aa]" = \*\*\*, "[Bb]" = \*\*\*\)/, '... and the key of that error is masked';
}

# FOREIGN KEY, composite
check 'foreign key',
  $err->(sub { $schema->resultset('Child')->create({ id => 1, a => 424242, b => 'geheim"x' }) }),
  [ 424242, 'geheim' ],
  [ qr/FOREIGN KEY constraint "INTEG_\d+" on table "fw_child"|FOREIGN KEY constraint "fw_child_fk"/i,
    qr/Foreign key reference target does not exist/,
    qr/Problematic key value is \("[Aa]" = \*\*\*, "[Bb]" = \*\*\*\)/, qr/with 3 bind values/ ];
check 'foreign key short',
  $err->(sub { $schema->resultset('Child')->create({ id => 2, a => 9, b => 'q' }) }),
  [ q{'q'} ], [ qr/Problematic key value is \("[Aa]" = \*\*\*, "[Bb]" = \*\*\*\)/ ];

# UPDATE of a key
check 'update of a key',
  $err->(sub { $p->find({ a => 100 + 1, b => 'u' })->update({ a => 987654321, b => $odd }) }),
  [ 987654321, 'geheim' ], [ qr/Problematic key value is \("[Aa]" = \*\*\*, "[Bb]" = \*\*\*\)/ ];

# bulk path, several rows
check 'populate in void context',
  $err->(sub { $p->populate([ [qw(a b c)], [ 5001, 'bulk', 'bulk-geheim42' ], [ 5002, 'bulk', 'bulk-geheim42' ] ]) }),
  [ 'geheim42' ], [ qr/Problematic key value is \("[Cc]" = \*\*\*\)/ ];
check 'populate with a duplicate key in one batch',
  $err->(sub { $p->populate([ [qw(a b c)], [ 6001, 'geheim42', undef ], [ 6001, 'geheim42', undef ] ]) }),
  [ 'geheim42' ], [ qr/Problematic key value is \("[Aa]" = \*\*\*, "[Bb]" = \*\*\*\)/ ];

# conversion errors
my $t = $schema->resultset('Typed');
check 'date',      $err->(sub { $t->create({ id => 1, d  => 'geheimdate' }) }), [ 'geheimdate' ],
  [ qr/-303/, qr/conversion error from string "\*\*\*"/, qr/with 2 bind values/ ];
check 'timestamp', $err->(sub { $t->create({ id => 2, ts => 'geheim-ts' }) }),  [ 'geheim-ts' ],
  [ qr/conversion error from string "\*\*\*"/ ];
check 'date short', $err->(sub { $t->create({ id => 3, d => 'x1' }) }), [ '"x1"' ],
  [ qr/conversion error from string "\*\*\*"/ ];
check 'date with a quote', $err->(sub { $t->create({ id => 4, d => 'ge"heim' }) }), [ 'ge"heim', 'heim"' ],
  [ qr/conversion error from string "\*\*\*"/ ];
check 'date out of range', $err->(sub { $t->create({ id => 5, d => '99999-01-01' }) }), [ '99999' ],
  [ qr/conversion error from string "\*\*\*"/ ];

# errors that never held a value keep their words
{
  my $e = $err->(sub { $t->create({ id => 6, v => 'geheim-too-long' }) });
  like $e // '', qr/string right truncation/, 'too long: the server\'s words stay';
  like $e // '', qr/expected length 5, actual 15/, '... with the lengths';
  unlike $e // '', qr/geheim-too-long(?!.*\[for Statement)/s, '... and no value';
}

# the commit that is refused (CREATE UNIQUE INDEX over duplicates)
{
  my $d = $schema->resultset('Dup');
  $d->create({ id => 1, v => 'geheimdup' });
  $d->create({ id => 2, v => 'geheimdup' });
  my $e = $err->(sub { $schema->txn_do(sub { $dbh->do('CREATE UNIQUE INDEX "fw_dup_v" ON "fw_dup" ("v")') }) });
  check 'refused commit', $e, [ 'geheimdup' ],
    [ qr/Problematic key value is \("[Vv]" = \*\*\*\)|unique|UNIQUE/ ];
}

cleanup();
done_testing;
