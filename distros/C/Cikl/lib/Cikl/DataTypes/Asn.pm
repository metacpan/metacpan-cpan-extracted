package Cikl::DataTypes::Asn;
use strict;
use warnings;
use namespace::autoclean;
use Mouse::Util::TypeConstraints;

use constant MAX_ASN => 2**32 - 1;

subtype 'Cikl::DataTypes::Asn',
  as 'Int',
  where { $_ >= 0 && $_ <= MAX_ASN && $_ !~ /\s/},
  message { "Invalid ASN: $_"} ;
1;


