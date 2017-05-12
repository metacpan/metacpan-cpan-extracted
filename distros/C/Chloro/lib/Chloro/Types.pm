package Chloro::Types;
BEGIN {
  $Chloro::Types::VERSION = '0.06';
}

use strict;
use warnings;
use namespace::autoclean;

use base 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw(
        MooseX::Types::Common::String
        MooseX::Types::Moose
        Chloro::Types::Internal
        )
);
