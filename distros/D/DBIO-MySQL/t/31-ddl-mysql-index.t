use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;

# Regression for karr k50.
#
# `using` is the only knob mysql_index offers for the shape of an index, and
# DDL.pm used to render whatever it was given as ` USING $v` at the end of the
# statement. That is right for exactly two of the four values the POD
# advertised: MySQL's CREATE INDEX grammar (8.4 Reference Manual) is
#
#   CREATE [UNIQUE | FULLTEXT | SPATIAL] INDEX name [index_type]
#       ON tbl (key_part,...) [index_option] ...
#
# where index_type is USING {BTREE | HASH} and index_option includes an
# index_type -- so a trailing `USING BTREE` is valid, and BTREE/HASH keep
# rendering exactly as they did. FULLTEXT and SPATIAL are index CLASSES in
# that grammar, not index types; the manual says in so many words that "the
# index_type clause cannot be used for FULLTEXT INDEX specifications". So
# `CREATE INDEX ... USING FULLTEXT` was never SQL any server would accept: it
# was a documented option that produced a statement that fails at deploy time.
#
# Each case below therefore pins WHY, not just WHAT:
#
#  - FULLTEXT / SPATIAL render as the index class in front of INDEX, because
#    that is the only place the grammar has for them. A deploy that used to
#    die on a syntax error now creates the index the user asked for.
#  - BTREE / HASH keep their trailing USING clause unchanged -- they were the
#    one correct path before this fix, and a fix that moved them would break
#    working schemas to repair broken ones.
#  - A lowercase value is the same request: MySQL's own parser is
#    case-insensitive here, so `using => 'btree'` is a legal thing for a user
#    to write and must not fall through to the rejection branch. It renders
#    uppercase because that is the one spelling the generated DDL uses.
#  - Any other value is refused loudly at DDL-generation time rather than
#    passed through. Passing it through is what caused this bug: the failure
#    surfaced as a server syntax error at deploy, far from the mysql_index
#    line that caused it. RTREE is the deliberate member of this set -- the
#    server parses it, but only for a SPATIAL index it chooses itself, never
#    as something a user asks for by name. The message must name the index and
#    the value, because a schema has many indexes and the whole point is to
#    point at the offending one.
#  - No `using` at all, and `unique => 1` without `using`, are pinned so the
#    fix is provably additive: the two paths that never involved `using`
#    render byte-for-byte what they rendered before.

sub index_stmts {
  my ($schema) = @_;
  my $ddl = DBIO::MySQL::DDL->install_ddl($schema);
  my %by_name;
  for my $stmt (split /\n\n/, $ddl) {
    # The name stands in backticks, like every name in the DDL (karr k77).
    next unless $stmt =~ /^CREATE\b.*?\bINDEX\s+`(\w+)`\s/;
    $by_name{$1} = $stmt;
  }
  return \%by_name;
}

{
  package DDLIndexTest::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package DDLIndexTest::Schema::Result::Doc;
  use DBIO 'Core', -mysql;

  __PACKAGE__->table('docs');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    bio  => { data_type => 'text' },
    loc  => { data_type => 'text' },
    name => { data_type => 'varchar', size => 64 },
  );
  __PACKAGE__->set_primary_key('id');

  __PACKAGE__->mysql_index('idx_docs_ft'    => { using => 'FULLTEXT', columns => ['bio'] });
  __PACKAGE__->mysql_index('idx_docs_sp'    => { using => 'SPATIAL',  columns => ['loc'] });
  __PACKAGE__->mysql_index('idx_docs_btree' => { using => 'BTREE',    columns => ['name'] });
  __PACKAGE__->mysql_index('idx_docs_hash'  => { using => 'HASH',     columns => ['name'] });
  __PACKAGE__->mysql_index('idx_docs_lc_bt' => { using => 'btree',    columns => ['name'] });
  __PACKAGE__->mysql_index('idx_docs_lc_ft' => { using => 'fulltext', columns => ['bio'] });
  __PACKAGE__->mysql_index('idx_docs_plain' => { columns => ['name'] });
  __PACKAGE__->mysql_index('idx_docs_uniq'  => { unique => 1, columns => ['name'] });
  __PACKAGE__->mysql_index('idx_docs_multi' => { using => 'BTREE', columns => ['name', 'bio'] });
}
DDLIndexTest::Schema->register_class(Doc => 'DDLIndexTest::Schema::Result::Doc');

my $idx = index_stmts('DDLIndexTest::Schema');

# FULLTEXT/SPATIAL are index classes, not index types.
is $idx->{idx_docs_ft}, 'CREATE FULLTEXT INDEX `idx_docs_ft` ON `docs` (`bio`);',
  'FULLTEXT renders as the index class, not as a USING clause';

is $idx->{idx_docs_sp}, 'CREATE SPATIAL INDEX `idx_docs_sp` ON `docs` (`loc`);',
  'SPATIAL renders as the index class, not as a USING clause';

unlike $idx->{idx_docs_ft} // '', qr/USING/,
  'no USING clause survives on a FULLTEXT index -- the manual forbids it there';

unlike $idx->{idx_docs_sp} // '', qr/USING/,
  'no USING clause survives on a SPATIAL index either';

# The one path that was already correct must not move.
is $idx->{idx_docs_btree}, 'CREATE INDEX `idx_docs_btree` ON `docs` (`name`) USING BTREE;',
  'BTREE keeps its trailing USING clause unchanged';

is $idx->{idx_docs_hash}, 'CREATE INDEX `idx_docs_hash` ON `docs` (`name`) USING HASH;',
  'HASH keeps its trailing USING clause unchanged';

is $idx->{idx_docs_multi}, 'CREATE INDEX `idx_docs_multi` ON `docs` (`name`, `bio`) USING BTREE;',
  'a multi-column BTREE index is untouched by the class/type split';

# Case-insensitive input, uppercase output -- both branches.
is $idx->{idx_docs_lc_bt}, 'CREATE INDEX `idx_docs_lc_bt` ON `docs` (`name`) USING BTREE;',
  q{lowercase 'btree' is the same request, rendered uppercase};

is $idx->{idx_docs_lc_ft}, 'CREATE FULLTEXT INDEX `idx_docs_lc_ft` ON `docs` (`bio`);',
  q{lowercase 'fulltext' is the same request, rendered uppercase};

# No `using` at all: unchanged, with and without unique.
is $idx->{idx_docs_plain}, 'CREATE INDEX `idx_docs_plain` ON `docs` (`name`);',
  'an index without `using` renders exactly as before';

is $idx->{idx_docs_uniq}, 'CREATE UNIQUE INDEX `idx_docs_uniq` ON `docs` (`name`);',
  'unique => 1 without `using` renders exactly as before';

# An unusable value is refused where it was written, not at the server.
{
  package DDLIndexTest::BadSchema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package DDLIndexTest::BadSchema::Result::Doc;
  use DBIO 'Core', -mysql;

  __PACKAGE__->table('docs');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer', is_auto_increment => 1 },
    loc => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->mysql_index('idx_docs_rtree' => { using => 'RTREE', columns => ['loc'] });
}
DDLIndexTest::BadSchema->register_class(Doc => 'DDLIndexTest::BadSchema::Result::Doc');

my $ddl = eval { DBIO::MySQL::DDL->install_ddl('DDLIndexTest::BadSchema') };
my $err = $@;
is $ddl, undef, 'an unusable `using` value aborts DDL generation instead of emitting SQL';
like $err, qr/idx_docs_rtree/,
  'the refusal names the offending index -- a schema has many';
like $err, qr/RTREE/,
  'the refusal names the value that was rejected';
like $err, qr/BTREE/,   'the refusal lists BTREE as accepted';
like $err, qr/HASH/,    'the refusal lists HASH as accepted';
like $err, qr/FULLTEXT/, 'the refusal lists FULLTEXT as accepted';
like $err, qr/SPATIAL/,  'the refusal lists SPATIAL as accepted';

# Regression for karr k52 (part 3).
#
# MySQL's grammar is CREATE [UNIQUE | FULLTEXT | SPATIAL] INDEX name ... --
# UNIQUE, FULLTEXT and SPATIAL share ONE grammar position, so at most one of
# them may appear. `unique => 1` combined with `using => FULLTEXT` (or SPATIAL)
# is therefore not two independent knobs: it asks for two keywords in a slot
# that holds one. DDL.pm set the UNIQUE prefix and the FULLTEXT/SPATIAL class
# keyword independently and concatenated both, silently emitting the invalid
# `CREATE UNIQUE FULLTEXT INDEX ...` -- a statement no MySQL or MariaDB server
# accepts. Like the RTREE case above, this must be refused at DDL-generation
# time, naming the index, not surfaced as a server syntax error far from the
# mysql_index line that caused it. (BTREE/HASH are index *types*, a different
# grammar position, so `unique => 1, using => BTREE` stays valid and is pinned
# below.)
{
  package DDLIndexTest::UniqueFullTextSchema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package DDLIndexTest::UniqueFullTextSchema::Result::Doc;
  use DBIO 'Core', -mysql;

  __PACKAGE__->table('docs');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer', is_auto_increment => 1 },
    bio => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->mysql_index('idx_docs_uft' => { unique => 1, using => 'FULLTEXT', columns => ['bio'] });
}
DDLIndexTest::UniqueFullTextSchema->register_class(
  Doc => 'DDLIndexTest::UniqueFullTextSchema::Result::Doc');

my $uft_ddl = eval { DBIO::MySQL::DDL->install_ddl('DDLIndexTest::UniqueFullTextSchema') };
my $uft_err = $@;
is $uft_ddl, undef,
  'unique + FULLTEXT aborts DDL generation instead of emitting CREATE UNIQUE FULLTEXT INDEX';
like $uft_err, qr/idx_docs_uft/,
  'the refusal names the offending index -- a schema has many';
like $uft_err, qr/UNIQUE/i,
  'the refusal explains UNIQUE is the conflicting keyword';
like $uft_err, qr/FULLTEXT/,
  'the refusal names FULLTEXT as the class it cannot share the slot with';

{
  package DDLIndexTest::UniqueSpatialSchema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package DDLIndexTest::UniqueSpatialSchema::Result::Doc;
  use DBIO 'Core', -mysql;

  __PACKAGE__->table('docs');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer', is_auto_increment => 1 },
    loc => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->mysql_index('idx_docs_usp' => { unique => 1, using => 'SPATIAL', columns => ['loc'] });
}
DDLIndexTest::UniqueSpatialSchema->register_class(
  Doc => 'DDLIndexTest::UniqueSpatialSchema::Result::Doc');

my $usp_ddl = eval { DBIO::MySQL::DDL->install_ddl('DDLIndexTest::UniqueSpatialSchema') };
my $usp_err = $@;
is $usp_ddl, undef,
  'unique + SPATIAL aborts DDL generation instead of emitting CREATE UNIQUE SPATIAL INDEX';
like $usp_err, qr/idx_docs_usp/,
  'the refusal names the offending index';
like $usp_err, qr/UNIQUE/i,
  'the refusal explains UNIQUE is the conflicting keyword';
like $usp_err, qr/SPATIAL/,
  'the refusal names SPATIAL as the class it cannot share the slot with';

# The valid neighbour must stay valid: BTREE/HASH are index *types*, a
# different grammar position, so combining them with unique is legal and must
# NOT be refused.
{
  package DDLIndexTest::UniqueBtreeSchema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package DDLIndexTest::UniqueBtreeSchema::Result::Doc;
  use DBIO 'Core', -mysql;

  __PACKAGE__->table('docs');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 64 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->mysql_index('idx_docs_ubt' => { unique => 1, using => 'BTREE', columns => ['name'] });
}
DDLIndexTest::UniqueBtreeSchema->register_class(
  Doc => 'DDLIndexTest::UniqueBtreeSchema::Result::Doc');

my $ubt = index_stmts('DDLIndexTest::UniqueBtreeSchema');
is $ubt->{idx_docs_ubt},
  'CREATE UNIQUE INDEX `idx_docs_ubt` ON `docs` (`name`) USING BTREE;',
  'unique + BTREE stays valid -- index type, not index class, so no conflict';

done_testing;
