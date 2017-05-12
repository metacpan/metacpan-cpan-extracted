#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test the folding of Lisp lists and alists into perl lists and hashes.

=cut

use Test::More tests => 12;
use Test::Deep;

use Data::SExpression;

my $ds = Data::SExpression->new({fold_lists => 1});

cmp_deeply(
    scalar $ds->read('(1 2 3 4)'),
    [1, 2, 3, 4],
    "Folded a simple list");

cmp_deeply(
    scalar $ds->read('(1 2 . 3)'),
    methods(
        car => 1,
        cdr => methods(
            car => 2,
            cdr => 3)),
    "Didn't fold an improper list");

cmp_deeply(
    scalar $ds->read('((fg . red) (bg . black) (weight . bold))'),
    [
        methods(car => \*fg, cdr => \*red),
        methods(car => \*bg, cdr => \*black),
        methods(car => \*weight, cdr => \*bold)
       ],
    "Read an alist");

# Reported by clkao, 2009-07-08
# Data::SExpression <= 0.37 don't handle the empty list

cmp_deeply(scalar $ds->read('()'), [], "Folded the empty list");

cmp_deeply(scalar $ds->read('(())'), [[]]);

cmp_deeply(scalar $ds->read('(1 ())'), [1, []]);

cmp_deeply(scalar $ds->read('(() ())'), [[],[]]);


$ds = Data::SExpression->new({fold_alists => 1});

cmp_deeply(
    scalar $ds->read('(1 2 3 4)'),
    [1, 2, 3, 4],
    "fold_alists implies fold_lists");

cmp_deeply(
    scalar $ds->read('((fg . red) (bg . black) (weight . bold))'),
  {
      \*fg     => \*red,
      \*bg     => \*black,
      \*weight => \*bold
     },
    "Folded an alist");


cmp_deeply(
    scalar $ds->read('((fg red) (bg black) (weight bold))'),
    [
        [\*fg,     \*red],
        [\*bg,     \*black],
        [\*weight, \*bold]
       ],
    "Didn't fold an alist of lists",
   );

cmp_deeply(
    scalar $ds->read('((fg red) (bg black) (weight bold))'),
    [
        [\*fg,     \*red],
        [\*bg,     \*black],
        [\*weight, \*bold]
       ],
    "Didn't fold an alist of lists",
   );


{
    no warnings 'once';
    cmp_deeply(
        scalar $ds->read('(((first name) . Joe) ((last name) . Bob))'),
        [
            methods(
                car => [\*first, \*name],
                cdr => \*Joe),
            methods(
                car => [\*last, \*name],
                cdr => \*Bob)
           ],
        "Didn't fold an alist with list keys",
       );
}
