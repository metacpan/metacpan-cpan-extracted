use strict;
use warnings;
use Test::More;
use Test::Exception;

# idx / indices carry one block per driver (pg, sqlite, mysql). A schema is
# bound to one driver, so the reader of that driver gets the entries through
# index_declarations_for(), which refuses loudly an entry that only carries
# another driver's block and an unknown key in its own block.

my $n = 0;
sub declare {
  my ($body) = @_;
  my $pkg = 'TestIdxBlocks::Result::R' . ++$n;
  eval "package $pkg; use DBIO::Cake; table 'r$n'; col id => integer; "
     . "col tags => text; col k => text; primary_key 'id'; $body; 1";
  return ($@, $pkg);
}

# (1) declaring: sqlite and mysql blocks are accepted like pg
{
  my ($err, $pkg) = declare(
    "idx s => ['tags'], sqlite => { where => 'tags IS NOT NULL' }; "
  . "idx m => ['tags'], mysql => { using => 'HASH' }; "
  . "idx p => ['tags'], pg => { using => 'gin' }; "
  . "idx all => ['k'], pg => {}, sqlite => {}, mysql => {}");
  is $err, '', 'sqlite/mysql/pg blocks are accepted';
  my %by = map { $_->{name} => $_ }
    $pkg->result_source_instance->index_declarations;
  is_deeply $by{s}{driver}, { sqlite => { where => 'tags IS NOT NULL' } },
    'sqlite block lands under driver.sqlite';
  is_deeply $by{m}{driver}, { mysql => { using => 'HASH' } },
    'mysql block lands under driver.mysql';
  is_deeply [ sort keys %{ $by{all}{driver} } ], [qw(mysql pg sqlite)],
    'one entry may carry all three blocks';
}

# (2) declaring: strictness of the new blocks
for my $case (
  [ "sqlite => 'x'",              qr/sqlite.*hashref/i ],
  [ "mysql => [1]",               qr/mysql.*hashref/i ],
  [ "sqlite => { usnig => 'x' }", qr/unknown key 'usnig' in sqlite/ ],
  [ "mysql => { where => 'x' }",  qr/unknown key 'where' in mysql/ ],
) {
  my ($err) = declare("idx t => ['tags'], $case->[0]");
  like $err, $case->[1], "refused: $case->[0]";
  like $err, qr/index 't'/, 'message names the index';
}

# (2b) declaring: the blocks of the drivers that adopted the reader later
{
  my ($err, $pkg) = declare(
    "idx o => ['tags'], oracle => { expression => 'UPPER(tags)' }; "
  . "idx m => ['tags'], mssql => { kind => 'clustered' }; "
  . "idx c => ['tags'], clickhouse => { type => 'minmax', granularity => 4 }; "
  . "idx f => ['tags'], firebird => {}");
  is $err, '', 'oracle/mssql/clickhouse/firebird blocks are accepted';
  my %by = map { $_->{name} => $_ }
    $pkg->result_source_instance->index_declarations;
  is_deeply $by{m}{driver}, { mssql => { kind => 'clustered' } },
    'mssql block lands under driver.mssql';
}

# (3) declaring: another driver key is refused with plain text
{
  my ($err) = declare("idx t => ['tags'], nosuchdb => { x => 1 }");
  like $err, qr/unknown key 'nosuchdb'/, 'idx: unknown driver key refused';
  like $err, qr/pg.*sqlite.*mysql/s, 'message lists the accepted names';

  my $src = (declare("1"))[1]->result_source_instance;
  throws_ok {
    $src->add_index_declaration({ name => 'x', columns => 'a',
      driver => { nosuchdb => {} } })
  } qr/driver block 'nosuchdb'.*pg.*sqlite.*mysql/s,
    'add_index_declaration: unknown driver name refused';
  is_deeply [ $src->index_declaration_drivers ],
    [qw(pg sqlite mysql oracle mssql sybase firebird clickhouse duckdb db2 informix)],
    'the accepted names are one list on the source';
}

# (4) the reader
{
  my ($err, $pkg) = declare(
    "idx plain => ['tags']; "
  . "idx own_empty => ['tags'], type => 'unique', sqlite => {}; "
  . "idx own_ok => ['tags'], sqlite => { where => 'k = 1' }, pg => { where => 'k = 2' }; "
  . "idx only_pg => ['k'], type => 'unique', pg => { where => 'k IS NULL' }");
  is $err, '', 'fixture declares';
  my $src = $pkg->result_source_instance;

  throws_ok { $src->index_declarations_for('sqlite', [qw(where expression)]) }
    qr/only_pg.*sqlite|sqlite.*only_pg/s,
    'an entry carrying only a foreign block is refused';
  my $e = $@;
  my $label = $src->source_name // $src->name;
  like "$e", qr/\Q$label\E/, 'message names the source';
  like "$e", qr/\bpg\b/, 'message names the foreign driver';
  like "$e", qr/sqlite => \{\}/, 'message says how to get a plain index';

  # an empty block of another driver is still only a foreign block
  throws_ok { $src->index_declarations_for('pg', [qw(where using)]) }
    qr/own_empty.*'sqlite' block and none for 'pg'/s,
    'pg refuses the entry that only has an (empty) sqlite block';

  # leave only entries the sqlite reader may see
  my $s = DBIO::ResultSource->new($src);
  $s->{_index_declarations} =
    [ grep { $_->{name} ne 'only_pg' } @{ $src->{_index_declarations} } ];
  my @got = $s->index_declarations_for('sqlite', [qw(where expression)]);
  is_deeply [ map $_->{name}, @got ], [qw(plain own_empty own_ok)],
    'plain entry, empty own block and own block are all returned';
  my %by = map { $_->{name} => $_ } @got;
  is_deeply $by{own_empty}{driver}, { sqlite => {} },
    'empty own block is kept: it means plain index';
  $got[0]{name} = 'changed';
  is +($s->index_declarations_for('sqlite', ['where']))[0]{name}, 'plain',
    'entries are copies';

  # unknown key in the own block
  my ($e2, $p2) = declare(
    "idx bad => ['tags'], sqlite => { where => 'x', expression => 'y' }");
  is $e2, '', 'declares (sqlite accepts where and expression)';
  throws_ok {
    $p2->result_source_instance->index_declarations_for('sqlite', ['where'])
  } qr/bad.*expression|expression.*bad/s,
    'a key the driver does not know in its own block is refused';
  like "$@", qr/sqlite/, 'message names the driver';

  throws_ok { $src->index_declarations_for('oracle', []) }
    qr/oracle/, 'a driver name that is not accepted is refused';
  throws_ok { $src->index_declarations_for('sqlite') }
    qr/allowed|keys/i, 'the allowed keys are required';
}

# index_declarations itself stays a plain reader
{
  my (undef, $pkg) = declare("idx only_pg => ['k'], pg => { where => 'k IS NULL' }");
  lives_ok { $pkg->result_source_instance->index_declarations }
    'index_declarations does not refuse anything';
}

done_testing;
