package App::CISetup::Types;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.11';

use MooseX::Getopt::OptionTypeMap ();
use MooseX::Types::Path::Tiny qw( File Dir );

use parent 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw(
        MooseX::Types::Moose
        MooseX::Types::Path::Tiny
        )
);

MooseX::Getopt::OptionTypeMap->add_option_type_to_map( $_ => '=s' )
    for ( File, Dir );

1;
