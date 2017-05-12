#!perl -w

use strict;

use Test::More tests => 11;
use List::Util qw(max);

use Array::GroupBy qw(igroup_by str_row_equal);

#
# 2D arrays (arrays of arrays)
#

my $l1 = [ qw( Smith John  Red    ) ];
my $l2 = [ qw( Smith John  Orange ) ];
my $l3 = [ qw( Smith Alice Yellow ) ];
my $l4 = [ qw( Black David Green  ) ];
my $l5 = [ qw( Black David Blue   ) ];

my $data = [ $l1, $l2, $l3, $l4, $l5 ];

# result
my @r = ( [ $l1, $l2 ], [$l3], [$l4, $l5] );

# look at first two columns ([0, 1])
my $iter = igroup_by(
              data    => $data,
              compare => sub { my ($row1, $row2, $slice) = @_;
                            join('|', @{ $row1 }[ @{ $slice } ] )
                            eq
                            join('|', @{ $row2 }[ @{ $slice } ] )
                          },
              args    => [ 0, 1 ],
);

my $i = 0;
while (my $v = $iter->()) {
  is_deeply($v, $r[$i], "2D array test, custom sub() compare $i");
  $i++;
}

# repeat previous test, but use str_row_equal()
$iter = igroup_by(
              data    => $data,
              compare => \&str_row_equal,
              args    => [ 0, 1 ],
);

$i = 0;
while (my $v = $iter->()) {
  is_deeply($v, $r[$i], "2D array test, str_row_equal() compare: $i");
  $i++;
}

# look at all columns - this will return each row, one at a time
$iter = igroup_by(
              data    => $data,
              compare => \&str_row_equal,
              args    => [ 0..2 ],
);

# results
@r = ($l1, $l2, $l3, $l4, $l5);

$i = 0;
while (my $v = $iter->()) {
  is_deeply($v, [ shift @r ], "array data whole row str_row_equal(): $i");
  $i++;
}
