package Cikl::DataTypes::LowerCaseStr;
use strict;
use warnings;
use namespace::autoclean;
use Mouse::Util::TypeConstraints;

subtype "Cikl::DataTypes::LowerCaseStr", 
  as 'Str',
  where { !/\p{Upper}/ms },
  message { "Must be lowercase." };

coerce 'Cikl::DataTypes::LowerCaseStr',
  from 'Str',
  via { lc };

1;


