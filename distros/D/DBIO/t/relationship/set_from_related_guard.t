use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;

# ADR 0034, write path: set_from_related resolves the related value down to a
# condition on THIS row's own columns and applies it with set_columns. A plain
# hashref of the related row's NON-key columns (e.g. a might_have searched by a
# non-key column) resolves to { self_pk => undef }, which -- applied blindly --
# clobbers the real key column with an undef. Row::update -> set_inflated_columns
# reaches set_from_related with exactly that raw hashref, so the clobber hit any
# caller passing a nested relation sub-hash to a 'single' relationship. The guard
# must refuse it rather than corrupt the row; a concrete belongs_to hashref, a
# blessed related object, and an explicit undef must still work.

my $schema = DBIO::Test->init_schema(no_deploy => 1);

# --- set_from_related refuses a non-concrete relation hashref ----------------
{
  my $cd = $schema->resultset('CD')->new_result({
    cdid => 42, artist => 1, title => 'Concrete', year => 2020,
  });

  throws_ok {
    $cd->set_from_related('liner_notes', { notes => 'hello' });
  } qr/Relationship 'liner_notes' does not resolve to a concrete column condition/,
    'set_from_related refuses a non-concrete relation hashref';

  is $cd->get_column('cdid'), 42,
    'the key column was NOT clobbered with undef';
}

# --- the same clobber via the documented update() trace ----------------------
# Row::update -> set_inflated_columns -> per-relation dispatch -> set_from_related
{
  my $cd = $schema->resultset('CD')->new_result({
    cdid => 7, artist => 1, title => 'Concrete2', year => 2021,
  });

  throws_ok {
    $cd->set_inflated_columns({ liner_notes => { notes => 'x' } });
  } qr/Relationship 'liner_notes' does not resolve to a concrete column condition/,
    'set_inflated_columns (the update path) refuses a non-concrete relation hashref';

  is $cd->get_column('cdid'), 7, 'the key column survived the update path';
}

# --- a concrete belongs_to hashref still resolves and is applied -------------
# genre is a belongs_to on CD keyed by genreid; a hashref carrying that FK
# resolves to a concrete { genreid => 5 } and must NOT be refused.
{
  my $cd = $schema->resultset('CD')->new_result({
    cdid => 1, artist => 1, title => 'Has Genre', year => 2000,
  });

  lives_ok {
    $cd->set_from_related('genre', { genreid => 5 });
  } 'a concrete belongs_to hashref is not refused';

  is $cd->get_column('genreid'), 5,
    'the resolvable FK was applied to the row';
}

# --- an explicit undef (disassociation) is left untouched --------------------
{
  my $cd = $schema->resultset('CD')->new_result({
    cdid => 2, artist => 1, title => 'Drop Genre', year => 2002, genreid => 9,
  });

  lives_ok {
    $cd->set_from_related('genre', undef);
  } 'set_from_related(undef) nulls the FK without tripping the guard';

  ok !defined $cd->get_column('genreid'),
    'the belongs_to FK was set to undef as requested';
}

done_testing;
