use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();
my $rs = $schema->resultset('Artist');

for my $id (
  2,
  \' = 2 ',
  \[ '= ?', 2 ],
) {
  # find needs a concrete value for the key (ADR 0070): literal SQL is looked
  # up through search, the concrete value through find as well
  lives_ok {
    is( $rs->search({ artistid => $id })->single->id, 2 );
    is( $rs->find({ artistid => $id })->id, 2 ) unless ref $id;
  } "Correctly found artist with id of @{[ explain $id ]}";
}

for my $id (
  2,
  \'2',
  \[ '?', 2 ],
) {
  my $cond = { artistid => { '=', $id } };
  lives_ok {
    is( $rs->search($cond)->single->id, 2 );
    is( $rs->find($cond)->id, 2 ) unless ref $id;
  } "Correctly found artist with id of @{[ explain $cond ]}";
}

# literal SQL is no concrete value: find refuses it instead of running it
for my $cond (
  { artistid => \' = 2 ' },
  { artistid => \[ '= ?', 2 ] },
  { artistid => { '=', \'2' } },
  { artistid => { '=', \[ '?', 2 ] } },
) {
  throws_ok {
    $rs->find($cond)
  } qr/find\(\) needs a condition that gives every column of one unique constraint of source 'Artist' a concrete value/,
    'find refuses literal SQL as the value of the key';
}

done_testing;
