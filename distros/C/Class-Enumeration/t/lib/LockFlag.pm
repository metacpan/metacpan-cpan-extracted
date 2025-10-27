use strict;
use warnings;
use feature 'state';

package LockFlag;

use parent 'Exporter::Tiny';
use Class::Enumeration::Builder
  { counter => sub { state $i = 0; 2**$i++ }, prefix => 'LOCK_', export => 1 },
  qw( SH EX NB UN );

1
