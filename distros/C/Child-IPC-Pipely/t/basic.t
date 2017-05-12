use strict;
use warnings;

use Child 'child';

use Test::More;

my $child = child {
  my $parent = shift;
  $parent->write('Good');
} pipely => 1;

is $child->read, 'Good', 'read from child';
$child->kill(9) unless $child->is_complete;
$child->wait;

done_testing;

