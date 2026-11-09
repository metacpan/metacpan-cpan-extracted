use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff::Extension;

# OFFLINE test: the summary of a diff names the extension it drops and the one
# it creates (core ADR 0066, decision 4).
#
# WHY: the declaration is the statement. An unrestricted deploy drops an
# installed extension the schema does not declare, and what a reader of
# `$diff->summary` has to see is that this is an extension nobody declared and
# that DROP EXTENSION takes what it owns -- not a bare "-extension: age" among
# other lines. A restricted deploy keeps it, and then the summary must not
# mention it at all.
#
# What this file claims:
#   1. a drop is named with its version and schema, says it is not declared,
#      and says what DROP EXTENSION takes -- and nothing the diff cannot know
#      (it does not claim to take objects the extension made at runtime: those
#      are separate operations of the diff, or not in it);
#   2. a create is named with the version, and the schema where one is
#      declared;
#   3. update and move are as before;
#   4. a restricted deploy drops nothing and names nothing of the kind; an
#      unrestricted one does.

sub ext {
  my ($name, %extra) = @_;
  return { extension_name => $name, version => '1.0', schema_name => 'public', relocatable => 1, requires => [], %extra };
}

my @drop = DBIO::PostgreSQL::Diff::Extension->diff({ citext => ext('citext', version => '1.6') }, {});
is scalar @drop, 1, 'one operation';
is $drop[0]->summary,
  '  -extension: citext (1.6, schema public; not declared, DROP EXTENSION takes the objects it owns)',
  'a drop: name, version, schema, that it is not declared, what DROP EXTENSION takes';
unlike $drop[0]->summary, qr/graph|runtime/i, '... and claims nothing about objects the extension made at runtime';
is $drop[0]->as_sql, 'DROP EXTENSION citext;', '... the statement is the same';

my @create = DBIO::PostgreSQL::Diff::Extension->diff({}, { pgcrypto => ext('pgcrypto', version => '1.3') });
is $create[0]->summary, '  +extension: pgcrypto (1.3)', 'a create: name and version';

@create = DBIO::PostgreSQL::Diff::Extension->diff({}, { vector => ext('vector', version => '0.8', declared_schema => 'ext') });
is $create[0]->summary, '  +extension: vector (0.8, schema ext)', '... and the declared schema';

@create = DBIO::PostgreSQL::Diff::Extension->diff({}, { hstore => ext('hstore', version => '1.8', install_schema => 'public') });
is $create[0]->summary, '  +extension: hstore (1.8, schema public)', '... or the schema of a namespaced connection';

my @update = DBIO::PostgreSQL::Diff::Extension->diff({ a => ext('a') }, { a => ext('a', version => '2.0') });
is $update[0]->summary, '  ~extension: a (1.0 -> 2.0)', 'an update is as before';

my @move = DBIO::PostgreSQL::Diff::Extension->diff(
  { a => ext('a') }, { a => ext('a', declared_schema => 'ext') });
is $move[0]->summary, '  ~extension: a (schema public -> ext)', 'a move is as before';

# --- restricted and unrestricted, through the deploy -----------------------------
{
  package T148::Deploy;
  use base 'DBIO::PostgreSQL::Deploy';
  sub _dbh { {} }
  sub _introspect_current { +{ extensions => { citext => ::ext('citext', version => '1.6') } } }
  sub _build_target_model { +{ extensions => { pgcrypto => ::ext('pgcrypto', version => '1.3') } } }
}

my $n = 0;
sub schema_class {
  my (%o) = @_;
  my $pkg = 'T148::S' . ++$n;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_schemas(@{ $o{schemas} }) if $o{schemas};
  return $pkg;
}

{
  my $diff = T148::Deploy->new(schema => schema_class())->diff;
  my $summary = $diff->summary;
  like $summary, qr/^  -extension: citext \(1\.6, schema public; not declared/m,
    'unrestricted: the undeclared extension the diff drops is named, as not declared';
  like $summary, qr/^  \+extension: pgcrypto \(1\.3\)$/m, '... and the one it creates';
  like $diff->as_sql, qr/^DROP EXTENSION citext;$/m, '... and it is dropped';
}
{
  my $diff = T148::Deploy->new(schema => schema_class(schemas => ['public']))->diff;
  my $summary = $diff->summary;
  unlike $summary, qr/citext/, 'restricted: the extension the deploy keeps is not named';
  unlike $diff->as_sql, qr/DROP EXTENSION/, '... and not dropped';
  like $summary, qr/^  \+extension: pgcrypto \(1\.3\)$/m, '... the one to create still is';
}
{
  my $diff = T148::Deploy->new(schema => schema_class(schemas => ['public']),
    manage_extensions_when_restricted => 1)->diff;
  like $diff->summary, qr/^  -extension: citext \(1\.6, schema public; not declared/m,
    'restricted with manage_extensions_when_restricted: dropped, so named';
}

done_testing;
