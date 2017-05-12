#!perl -w
use strict;
use warnings; 

use Test::More tests => 6;

BEGIN { use_ok('Data::Maker'); }
BEGIN { use_ok('Data::Maker::Field::Person::FirstName'); }

my $maker = Data::Maker->new(
  seed => 37854,
  record_count => 10,
  delimiter => "\t",
  fields => [
    { name => 'firstname', class => 'Data::Maker::Field::Person::FirstName' },
  ]
);
ok($maker, "created new instance ok");

my $record = $maker->next_record;
ok($record, "creates a record ok");
#$record->firstname->value);

ok($record->firstname->value, "field returns a value");
is($record->firstname->value, $record->firstname.'', "field stringifies");
