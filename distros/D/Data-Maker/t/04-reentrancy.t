#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

use Data::Maker;
use Data::Maker::Field::Code;

my $outer = Data::Maker->new(
  record_count => 1,
  fields => [
    {
      name => 'name',
      class => 'Data::Maker::Field::Code',
      args => {
        code => sub { 'OUTER' }
      }
    }
  ],
);

# do enough work to ensure caching would be used if present
$outer->next_record->name->value;

my $inner = Data::Maker->new(
  record_count => 1,
  fields => [
    {
      name => 'name',
      class => 'Data::Maker::Field::Code',
      args => {
        code => sub { 'INNER' }
      }
    }
  ],
);

# in v0.23, this would return 'OUTER'
is($inner->next_record->name->value, 'INNER', 'OUTER did not clobber INNER');
