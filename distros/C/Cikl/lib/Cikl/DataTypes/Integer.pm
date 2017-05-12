package Cikl::DataTypes::Integer;
use strict;
use warnings;
use namespace::autoclean;
use Mouse::Util::TypeConstraints;
use Scalar::Util qw/looks_like_number/;

subtype "Cikl::DataTypes::Integer", 
  as 'Int',
  where { 
    my $v = $_; 
    return(
      (looks_like_number($v) > 1) # returns 1 if it's a string, > 1 if it is a number
      && ($v == int($v)));  # If it is a number, then check to see if our value 
                            # is actually an integer.
  };

coerce 'Cikl::DataTypes::Integer',
  from 'Defined',
  via { int($_) };

1;
