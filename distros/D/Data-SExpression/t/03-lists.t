#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test the parsing of lists, without folding.

=cut

use Test::More tests => 12;
use Test::Deep;
use Symbol;

use Data::SExpression;

my $ds = Data::SExpression->new({
    fold_lists  => 0,
    fold_alists => 0
});

cmp_deeply(
    scalar $ds->read("(1 2 3 4)"),
    methods(
        car => 1,
        cdr => methods(
            car => 2,
            cdr => methods(
                car => 3,
                cdr => methods(
                    car => 4,
                    cdr => undef)))),
    "Read a simple list");

cmp_deeply(
    scalar $ds->read("(1 2 3 . 4)"),
    methods(
        car => 1,
        cdr => methods(
            car => 2,
            cdr => methods(
                car => 3,
                cdr => 4))),
    "Read an improper list");

cmp_deeply(
    scalar $ds->read("((1 2) (3 4))"),
    methods(
        car => methods(
            car => 1,
            cdr => methods(
                car => 2,
                cdr => undef)),
        cdr => methods(
            car => methods(
                car => 3,
                cdr => methods(
                    car => 4,
                    cdr => undef)))),
    "Read a tree");

cmp_deeply(
    scalar $ds->read(qq{("")}),
    methods(
        car => "",
        cdr => undef),
    "Read an empty string");

cmp_deeply(
    scalar $ds->read(qq{("" "")}),
    methods(
        car => "",
        cdr => methods(
            car => "",
            cdr => undef)),
    "Read an empty strings");

no warnings 'once';     #For the symbol globs

cmp_deeply(
    scalar $ds->read("((fg . red) (bg . black) (weight . bold))"),
    methods(
        car => methods(
            car => \*fg,
            cdr => \*red),
        cdr => methods(
            car => methods(
                car => \*bg,
                cdr => \*black),
            cdr => methods(
                car => methods(
                    car => \*weight,
                    cdr => \*bold),
                cdr => undef))),
    "Read an alist");

cmp_deeply(
    scalar $ds->read(q{
;;A comment
(
;; More comments
;; Comment comment comment
1 ;same-line comment
2
;comment comment
)
}),
    methods(
        car => 1,
        cdr => methods(
           car => 2,
           cdr => undef)),
    "Skipped comments in list");

# Reported by Avinash Varadarajan, 2008-04-09
# Data::SExpression <= 0.352 misparses "0"

cmp_deeply(
    scalar $ds->read(q{("value" "0")}),
    methods(car => "value",
            cdr => methods(
                car => "0",
                cdr => undef
               ))
   );

# Reported by clkao, 2009-07-08
# Data::SExpression <= 0.37 don't handle the empty list

is(scalar $ds->read('()'), undef);

cmp_deeply(
    scalar $ds->read('(())'),
    methods(car => undef,
            cdr => undef));

cmp_deeply(
    scalar $ds->read('(1 ())'),
    methods(car => 1,
            cdr => methods(
                car => undef,
                cdr => undef)));

cmp_deeply(
    scalar $ds->read('(() ())'),
    methods(car => undef,
            cdr => methods(
               car => undef,
               cdr => undef)));
