use strict;
use warnings;

use Test::More;
use Test::Deep;

use lib 't/lib';

use A::Schema;

my $s = A::Schema->connect('dbi:SQLite::memory:');
$s->deploy;

my $shirts     = $s->resultset('Category')->create({ name => 'Shirt' });
my $tshirt     = $shirts->child_categories->create({ name => 'T-Shirt' });
my $woot_shirt = $tshirt->child_categories->create({ name => 'Woot Shirt' });
my $red_shirt  = $tshirt->child_categories->create({ name => 'Red Shirt' });

cmp_deeply(
   [$woot_shirt->ancestry->get_column('id')->all],
   [$shirts->id, $tshirt->id, $woot_shirt->id],
   'woot shirt has correct ancestry'
);
is(
   $woot_shirt->parent_path,
   (join '~', $shirts->id, $tshirt->id, $woot_shirt->id),
   'woot shirt has correct parent_path (~ is used for sep)',
);


cmp_deeply(
   [$red_shirt->ancestry->get_column('id')->all],
   [$shirts->id, $tshirt->id, $red_shirt->id],
   'red shirt has correct ancestry'
);
is(
   $red_shirt->parent_path,
   (join '~', $shirts->id, $tshirt->id, $red_shirt->id),
   'red shirt has correct parent_path (~ is used for sep)',
);

my $clothes = $s->resultset('Category')->create({ name => 'Clothing' });
$shirts->update({ parent_id => $clothes->id });
# XXX: this should also work: $shirts->update({ parent_category => $clothes });

$woot_shirt->discard_changes;
$red_shirt->discard_changes;

# XXX: do we care that things are coming out in the "wrong" order?
cmp_set(
   [$woot_shirt->ancestry->get_column('id')->all],
   [$clothes->id, $shirts->id, $tshirt->id, $woot_shirt->id],
   'woot shirt correctly updated ancestry'
);
cmp_set(
   [$red_shirt->ancestry->get_column('id')->all],
   [$clothes->id, $shirts->id, $tshirt->id, $red_shirt->id],
   'red shirt has correctly updated ancestry'
);

is(
   $shirts->descendants->count,
   1 + 1 + 2, # shirt -> tshirt -> ( woot_shirt, red_shirt )
   'shirt has the correct number of descendants (plus itself)',
);

is (
   $red_shirt->ancestry->count,
   4,
   'red shirt has the correct number of ancestors (plus itself)',
);


done_testing;
