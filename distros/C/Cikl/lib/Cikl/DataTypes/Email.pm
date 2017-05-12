package Cikl::DataTypes::Email;
use strict;
use warnings;
use namespace::autoclean;
use Cikl::DataTypes::LowerCaseStr;
use Mouse::Util::TypeConstraints;
use Mail::RFC822::Address qw/valid/;

subtype 'Cikl::DataTypes::Email',
  as 'Cikl::DataTypes::LowerCaseStr',
  where { valid($_) && $_ !~ /^\s+|\s+$/ },
  message { "Invalid E-Mail address: $_"} ;
1;



