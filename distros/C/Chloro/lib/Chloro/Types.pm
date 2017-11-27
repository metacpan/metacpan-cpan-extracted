package Chloro::Types;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use MooseX::Types::Common::String ();
use MooseX::Types::Moose          ();

use base 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw(
        MooseX::Types::Common::String
        MooseX::Types::Moose
        Chloro::Types::Internal
        )
);

1;
