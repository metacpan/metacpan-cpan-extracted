use strict;
use warnings;

use Test::More;
use Test::Deep;

use lib 't/lib';

use A::Schema;

my $s = A::Schema->connect('dbi:SQLite::memory:');
my $humans = $s->resultset('Human');

$s->deploy;

my $adam = $humans->create({
   name => 'Adam',
});

my $eve = $humans->create({
   name => 'Eve',
});

my $everest = $humans->create({
   mom_id => $eve->id,
   name => 'Everest',
});

my $cain = $humans->create({
   dad_id => $adam->id,
   name => 'Cain',
   mom_id => $eve->id,
});

my $lillith = $humans->create({
   dad_id => $cain->id,
   mom_id => $everest->id,
   name => 'Lillith', # I know this is false, but it's a test.
});

is($lillith->dad_id, $cain->id, q(cain is lillith's dad));
cmp_deeply(
   [$lillith->paternal_lineage->get_column('id')->all],
   [$adam->id, $cain->id],
   'grampa and dad in paternal_lineage',
);
is(
   $lillith->dad_path,
   (join '.', $adam->id, $cain->id, $lillith->id),
   'dad_path is correct',
);

use Devel::Dwarn;
is($lillith->mom_id, $everest->id, q(everest is eve's mom));
cmp_deeply(
   [$lillith->maternal_lineage->get_column('id')->all],
   [$eve->id, $everest->id],
   'gramma and mom are in maternal_lineage',
);
is(
   $lillith->mom_path,
   (join '/', $eve->id, $everest->id, $lillith->id),
   'mom_path is correct'
);

done_testing;
