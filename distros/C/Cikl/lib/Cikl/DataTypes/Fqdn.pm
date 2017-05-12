package Cikl::DataTypes::Fqdn;
use strict;
use warnings;
use namespace::autoclean;
use Cikl::DataTypes::LowerCaseStr;
use Mouse::Util::TypeConstraints;
use Regexp::Common qw/net/;

use constant FQDN_RE => qr/^$RE{net}{domain}{-rfc1101}{-nospace}$/ ;

subtype 'Cikl::DataTypes::Fqdn',
  as 'Cikl::DataTypes::LowerCaseStr',
  where { 
    $_ !~ /\s/  # No whitespace
    && $_ =~ FQDN_RE # proper fqdn
  },
  message { "Invalid fqdn '$_'"} ;

1;

