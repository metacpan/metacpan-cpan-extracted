use strict;
use warnings;

use Test::More;
use lib qw(t/lib);

use_ok 'DBIO::Skills';

# --- canonical name normalisation: always the dbio- form ---
is(DBIO::Skills->canonical_name('db2-database'), 'dbio-db2-database',
  'bare name gets dbio- prepended');
is(DBIO::Skills->canonical_name('dbio-core'), 'dbio-core',
  'already-prefixed name is left as-is');

# Unknown skill with no installed sharedir resolves to undef (does not die).
is(DBIO::Skills->skill('does-not-exist-anywhere'), undef,
  'unknown skill -> undef');

# --- declaration sugar populates the schema skills() classdata ---
require SkillTestSchema;

is_deeply([ sort keys %{ SkillTestSchema->skills } ],
  [ 'core', 'mysql-database' ],
  'skills({...}) + skill(k=>v) populate the skills classdata');

# After namespace::clean, ->skill / ->skills resolve to the inherited
# DBIO::Schema method/accessor, not the (removed) declaration helpers.
is(SkillTestSchema->skill('core'), "CLASS-CORE\n",
  'class-level override wins for core');
is(SkillTestSchema->skill('mysql-database'), "CLASS-MYSQL\n",
  'merged single-entry override returned');

# A name with no override and no sharedir is undef (the override map is
# consulted by canonical name, so a near-miss does not match).
is(SkillTestSchema->skill('postgresql-database'), undef,
  'non-overridden skill with no sharedir -> undef');

# --- connect-time override is instance-level and shadows the class default ---
SKIP: {
  eval { require DBD::SQLite; 1 }
    or skip 'DBD::SQLite required for the connect path', 2;

  my $schema = SkillTestSchema->connect(
    'dbi:SQLite::memory:', '', '',
    { skills => { core => "CONN-CORE\n" } },
  );

  is($schema->skill('core'), "CONN-CORE\n",
    'connect-time skills override wins on the connected instance');
  is(SkillTestSchema->skill('core'), "CLASS-CORE\n",
    'class-level default is unchanged by the connection override');
}

done_testing;
