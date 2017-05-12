#!perl -w
use strict;
use warnings; 

use Test::Simple 'no_plan';

use Data::Maker;
use Data::Maker::Field::Currency;

ok(
  my $maker = new Data::Maker(
    seed => 1234,
    record_count => 10,
    delimiter => "\t",
    fields => [
      {
        name => 'amount',
        class => 'Data::Maker::Field::Currency',
        args => {
          min => 200,
          max => 2000
        }
      }
    ]
  )
);

ok(my $record = $maker->next_record);
ok($record->amount->value);
