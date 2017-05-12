#!perl -w

use strict;

use Test::More tests => 3;
use List::Util qw(max);

use Array::GroupBy qw(igroup_by str_row_equal);

#
# Example 3 - salary dataset
#

my @amounts = (
    [ "Smith, J", 2009, 65 ],
    [ "Smith, J", 2010, 63 ],
    [ "Smith, J", 2011, 68 ],
    [ "Smith, J", 2012, 72 ],

    [ "Brown, F", 2006, 45 ],
    [ "Brown, F", 2007, 47 ],
    [ "Brown, F", 2008, 49 ],
    [ "Brown, F", 2010, 49 ],
    [ "Brown, F", 2009, 49 ],

    [ "White, R", 2007, 47 ],
    [ "White, R", 2008, 57 ],
    [ "White, R", 2009, 59 ],
    [ "White, R", 2010, 61 ],
);

my $iter = igroup_by(
              data    => \@amounts,
              compare => sub { $_[0]->[0] eq $_[1]->[0] }
                    );

my @expected = (
    'Name: Smith, J, Max: 72, Year(s): 2012',
    'Name: Brown, F, Max: 49, Year(s): 2008, 2010, 2009',
    'Name: White, R, Max: 61, Year(s): 2010',

    );

my $i = 0;
while (my $subset = $iter->()) {

  my $max_sal = max map { $_->[2] } @$subset; # max salary

  is ($expected[$i],

      "Name: "
      . $subset->[0]->[0] 
      . ", Max: $max_sal, Year(s): "
      . join(', ',
          map  { $_->[1] }
          grep { $_->[2] == $max_sal } @$subset
        )
      ,

      "salary dataset group $i"
  );
  $i++
};
