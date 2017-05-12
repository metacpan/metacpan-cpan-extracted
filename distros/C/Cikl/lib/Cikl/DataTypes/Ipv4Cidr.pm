package Cikl::DataTypes::Ipv4Cidr;
use strict;
use warnings;
use namespace::autoclean;
use Mouse::Util::TypeConstraints;
use Regexp::Common;
use Regexp::Common::net::CIDR;

use constant RE_IPV4_CIDR => qr/^$RE{'net'}{'CIDR'}{'IPv4'}$/;

subtype 'Cikl::DataTypes::Ipv4Cidr',
  as 'Str',
  where { $_ =~ RE_IPV4_CIDR },
  message { "Invalid Ipv4 CIDR '$_'"} ;

1;

