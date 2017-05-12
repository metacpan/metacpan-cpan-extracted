use strict;
use warnings;

use Test::More;

# FILENAME: basic.t
# CREATED: 08/04/14 15:40:32 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test the continuum

use Acme::Time::Constant qw( constant_time );

my $timestamp = time;
constant_time(
  sub {
    my $j;
    for my $i ( 0 .. 1 ) {
      $j += $i;
    }
  }
);
my $delta = time - $timestamp;
cmp_ok( $delta, '>', 0.5, 'Constant time fixed at at least 0.5 second pass 1' );
cmp_ok( $delta, '<', 1.5, 'Constant time fixed at at most 1.5 second pass 1' );

done_testing;
