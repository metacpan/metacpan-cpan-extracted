#!perl

# Tests slurp() (and, incidently, new() )

# This really ought to work like example.t

use Test::More tests => 6;
use strict;
use warnings;

use Data::Iterator::Hierarchical ();

# Short hand forms
sub U { undef }

my $sth = 
    [ [ 1, 1, 1 ],
      [ 2, 2, 2 ],
      [ 2, 2, 3 ],
      [ 2, 3, 2 ],
      [ 3, 1, 2 ],
      [ 3, 2, U ],
      [ 4, U, U ]];

{
    my $it = Data::Iterator::Hierarchical->new( [ @$sth ] );
    my $got = $it->slurp;
    my $expect = $sth; # Identity!
    is_deeply($got,$expect,'slurp');
}
{
    my $it = Data::Iterator::Hierarchical->new( [ @$sth ] );
    my $got = $it->slurp( hash_depth => 1 );

    my $expect = 
    { 1 => [[ 1, 1 ]],
      2 => [[ 2, 2 ],
	    [ 2, 3 ],
	    [ 3, 2 ]],
      3 => [[ 1, 2,],
	    [ 2, U ]],
      4 => [        ]};
    
    is_deeply($got,$expect,'slurp hash_depth=1');
}
{
    my $it = Data::Iterator::Hierarchical->new( [ @$sth ] );
    my $got = $it->slurp( hash_depth => 2 );

    my $expect = 
    { 1 => { 1 => [[ 1 ]] },
      2 => { 2 => [[ 2 ],
		   [ 3 ]],
	     3 => [[ 2 ]] },
      3 => { 1 => [[ 2 ]],
	     2 => [     ] },
      4 => {              }};

    is_deeply($got,$expect,'slurp hash_depth=2');
}
{
    my $it = Data::Iterator::Hierarchical->new( [ @$sth ] );
    my $got = $it->slurp( hash_depth => 3, one_row => 1 );

    my $expect = 
    { 1 => { 1 => { 1 => U }},
      2 => { 2 => { 2 => U,
		    3 => U },
	     3 => { 2 => U }},
      3 => { 1 => { 2 => U },
	     2 => {        }},
      4 => {                }};

    is_deeply($got,$expect,'slurp hash_depth=3 one_row');
}
{
    my $it = Data::Iterator::Hierarchical->new( [ @$sth ] );
    my $got = $it->slurp( hash_depth => 99 );

    my $expect = 
    { 1 => { 1 => { 1 => {} }},
      2 => { 2 => { 2 => {},
		    3 => {} },
	     3 => { 2 => {} }},
      3 => { 1 => { 2 => {} },
	     2 => {         }},
      4 => {                 }};

    is_deeply($got,$expect,'slurp hash_depth=99');
}
{
    my $it = Data::Iterator::Hierarchical->new( [ @$sth ] );
    my $got = $it->slurp( hash_depth=>1, one_row=>1, one_column=>1 );

    my $expect = 
    { 1 => 1,
      2 => 2,
      3 => 1,
      4 => U };

    is_deeply($got,$expect,'slurp hash_depth=1 one_row one_column');
};
