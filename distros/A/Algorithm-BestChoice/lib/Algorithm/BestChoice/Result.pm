package Algorithm::BestChoice::Result;

use Moose;

has rank => qw/is ro required 1 isa Num/;
has value => qw/is ro required 1/;

1;
