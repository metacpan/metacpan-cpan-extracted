#!perl

# Test all the basic functionality

use Test::More tests => 1;
use strict;
use warnings;

use Data::Iterator::Hierarchical;

# Short hand forms
sub U { undef }
sub X { -999 }

my $sth = [
    [ 1, 1, 1, 1, 1, 1, 1 ],
    [ 2, 2, 2, 2, 2, 2, 2 ],
    [ 2, 2, 2, 2, 2, 3, 3 ],
    [ 2, 2, 2, 2, 3, 2, 2 ],
    [ 2, 2, 2, 2, 3, 3, 3 ],
    [ 2, 2, 2, 3, 1, U, U ], # All undef at level 4
    [ 2, 2, 2, 3, 2, U, U ], # Omit undef (don't bail)
    [ 2, 2, 2, 3, 2, 1, 5 ],
    [ 2, 2, 2, 3, 2,      ],
    [ U, U, 1, 1, 2, U,   ], # Undef that can't be omitted
    [ U, U, 1, 1, 2, U, U ],
    [ U, 3, 3, U          ], 
    [ 4, 4, 1, 1, 2, 3, 3 ],
    [ 4, 4, 1, X, 2, 4, 3 ], # Don't decend from level 2
    [ 4, 4, 1, X, 6, 2, 4 ],
    [ 4, 4, 1, 6, 2, 3, 3 ],
    [ 5, 5, 1, 1, 1, 1, 1 ],
    [ 5, 5, 1, 1, 1, 2, 2 ],
    [ 5, 5, 1, 1, 2, 1, 1 ],
    [ 5, 5, 1, 1, X, 1, 1 ], # Bail out of level 3
    [ 5, 5, 1, 1, 4, 1, 1 ],
    [ 5, 5, 1, 1, 4, 1, 2 ],
    [ 5, 5, 2, 2, 1, 1, 1 ],
    [ 5, 5, 2, 2, 1, 2, 2 ],
    [ 6, 6, 1, 1, 1, 1, 1 ], 
    [ 6, 6, 1, 1, 1, X, 2 ], # Bail out of level 3 (from 4) 
    [ 6, 6, 1, 1, 2, 1, 1 ],
    [ 6, 6, 1, 1, 4, 1, 1 ],
    [ 6, 6, 1, 1, 4, 1, 2 ],
    [ 6, 6, 2, 2, 1, 1, 1 ],
    [ 6, 6, 2, 2, 1, 2, 2 ],
    [ 6, 6, 2, 2, 1, 2, X ], # Bail out of level 2 (from 4) 
    [ 6, 6, 3, 3, 1, 1, 1 ],
    [ 7, 7, 1, 1, 1, 1, 1 ],
    ];

my $expect =
    [[ 1, 1, [[ 1, 1, [[ 1, [[ 1, 1 ]] ]] ]] ],
     [ 2, 2, [[ 2, 2, [[ 2, [[ 2, 2 ],
			     [ 3, 3 ]] ],
		       [ 3, [[ 2, 2 ],
			     [ 3, 3 ]] ]] ],
	      [ 2, 3, [[ 1, [        ] ],
		       [ 2, [[ 1, 5 ]] ]] ]] ],
     [ U, U, [[ 1, 1, [[ 2, [        ] ]] ]] ],
     [ U, 3, [[ 3, U, [                 ] ]] ],
     [ 4, 4, [[ 1, 1, [[ 2, [[ 3, 3 ]] ]] ],
	      [ 1, X                      ],
	      [ 1, 6, [[ 2, [[ 3, 3 ]] ]] ]] ],
     [ 5, 5, [[ 1, 1, [[ 1, [[ 1, 1 ],
			     [ 2, 2 ]] ],
		       [ 2, [[ 1, 1 ]] ]] ],
	      [ 2, 2, [[ 1, [[ 1, 1 ],
			     [ 2, 2 ]] ]] ]] ],
     [ 6, 6, [[ 1, 1, [[ 1, [[ 1, 1 ]] ]] ],
	      [ 2, 2, [[ 1, [[ 1, 1 ],
			     [ 2, 2 ]] ]] ]] ],
     [ 7, 7, [[ 1, 1, [[ 1, [[ 1, 1 ]] ]] ]] ]];

		
my $it = hierarchical_iterator($sth);

my @got;
while( my @c = $it->(my $it, 2)) {
    push @got => [ @c, \my @got ];
  TWO:
    while( my @c = $it->(my $it, 2)) {
	# Test don't decend
	push @got => \@c and next if $c[1] && $c[1] == X;
	push @got => [ @c, \my @got ];
      THREE:
	while( my @c = $it->(my $it, 1)) {
	    # Test bail out of a single level
	    last THREE if $c[0] == X;
	    push @got => [ @c, \my @got ];
	    while( my @c = $it->()) {
		# Test bail out more than one level
		last TWO   if $c[1] && $c[1] == X;
		last THREE if $c[0] && $c[0] == X;
		push @got => \@c;
	    }
	}
    }
}

is_deeply(\@got,$expect,'expected output for good input');
