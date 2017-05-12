#!perl -w

use strict;

use Test::More tests => 9;
use List::Util qw(max);

use Array::GroupBy qw(igroup_by str_row_equal);

#
# One-dimensional array
#

# String array

my $a1 = [ 'alpha' x 5 ];
my $a2 = [ 'beta' x 7 ];
my $a3 = [ 'charlie' x 2 ];
my $a4 = [ 'alpha' x 3 ];

my $data = [ @$a1, @$a2, @$a3, @$a4 ];

# result
my @r = ( $a1, $a2, $a3, $a4 );

my $iter = igroup_by(
                    data    => $data,
                    compare => sub { $_[0] eq $_[1] },
);

my $i = 0;
while (my $v = $iter->()) {
  is_deeply($v, shift @r, "text array test $i");
  $i++;
}

# Numeric array

my $n1 = [ 1, 1, 1.0       ];
my $n2 = [ 4.5, 4.50       ];
my $n3 = [ 0.2, .2, .200   ];
my $n4 = [ 1, 1.000, 1.0   ];
my $n5 = [ 255, 0377, 0xff ];

$data = [ @$n1, @$n2, @$n3, @$n4, @$n5 ];

# results
@r = ( $n1, $n2, $n3, $n4, $n5 );

$iter = igroup_by(
                data    => $data,
                compare => sub { $_[0] == $_[1] },
);

$i = 0;
while (my $v = $iter->()) {
  is_deeply($v, shift @r, "numeric array test $i");
  $i++;
}
