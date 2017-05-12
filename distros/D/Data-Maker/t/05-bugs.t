#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;

BEGIN {
  use_ok('Data::Maker');
  use_ok('Data::Maker::Field::Code');
}

# Bug report:
# Operation "<=": no method found,
# left argument has no overloaded magic,
# right argument in overloaded package Data::Maker::Value

my @scores = (0, undef, 95);

my $dm = Data::Maker->new(
  record_count => scalar @scores,
  fields => [
    {
      name => 'score',
      class => 'Data::Maker::Field::Code',
      args => {
        code => sub { shift @scores }
      }
    },
    {
      name => 'grade',
      class => 'Data::Maker::Field::Code',
      args => {
        code => sub {
          my ($self,$maker) = @_;
          my $value = $maker->in_progress('score');
          my ($low,$high) = (90,100);
          if (defined($value) && $low <= $value && $value <= $high) {
            return "A";
          }
          else {
            return "F";
          }
        }
      }
    }
  ],
);

$@ = '';
my $grade = eval { $dm->next_record->grade->value };
is($@, '', 'existence of field in in_progress is not predicated on that field having a "true" value (0)');
is($grade, 'F', 'value dependent upon 0 in_progress field is correct');

$grade = eval { $dm->next_record->grade->value };
is($@, '', 'existence of field in in_progress is not predicated on that field having a "true" value (undef)');
is($grade, 'F', 'value dependent upon undef in_progress field is correct');

$grade = eval { $dm->next_record->grade->value };
is($@, '', 'also works with a true value');
is($grade, 'A', 'value dependent upon true in_progress field is correct');
