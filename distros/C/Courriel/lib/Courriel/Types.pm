package Courriel::Types;

use strict;
use warnings;
use namespace::autoclean;

use parent 'MooseX::Types::Combine';

our $VERSION = '0.47';

__PACKAGE__->provide_types_from(
    qw(
        MooseX::Types::Common::String
        MooseX::Types::Moose
        Courriel::Types::Internal
        )
);

1;
