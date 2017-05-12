#!perl
use strict;
use Test::More tests => 4;
BEGIN { use_ok('Data::Sorting'); }
require 't/sort_tests.pl';

package OpaqueInfo;

sub new { my $class = shift; bless [ @_ ], $class }
sub foo { my $s = shift; if (scalar @_) { $s->[0] = shift } else { $s->[0] } }
sub bar { my $s = shift; if (scalar @_) { $s->[1] = shift } else { $s->[1] } }
sub baz { my $s = shift; if (scalar @_) { $s->[2] = shift } else { $s->[2] } }

package main;

test_sort_cases (
  {
    values => [ 
      OpaqueInfo->new( 'Alpha', 'Sigma', 'On' ),
      OpaqueInfo->new( 'Beta', 'Delta', 'Off' ),
      OpaqueInfo->new( 'Gamma', 'Chi', 'On' ),
      OpaqueInfo->new( 'Omega', 'Epsilon', 'Off' ),
    ],
    sorted => [ 'foo' ],
  },
  {
    values => [ 
      OpaqueInfo->new( 'Gamma', 'Chi', 'On' ),
      OpaqueInfo->new( 'Beta', 'Delta', 'Off' ),
      OpaqueInfo->new( 'Omega', 'Epsilon', 'Off' ),
      OpaqueInfo->new( 'Alpha', 'Sigma', 'On' ),
    ],
    sorted => [ 'bar' ],
  },
  {
    values => [ 
      OpaqueInfo->new( 'Beta', 'Delta', 'Off' ),
      OpaqueInfo->new( 'Omega', 'Epsilon', 'Off' ),
      OpaqueInfo->new( 'Alpha', 'Sigma', 'On' ),
      OpaqueInfo->new( 'Gamma', 'Chi', 'On' ),
    ],
    sorted => [ 'baz' ],
    okidxs => [ [ 1, 2, 3, 4 ], [ 2, 1, 3, 4 ], [ 1, 2, 4, 3 ], [ 2, 1, 4, 3 ] ]
  },
);
