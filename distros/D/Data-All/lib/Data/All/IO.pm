package Data::All::IO;


use strict;

use base qw( Class::Factory );

our $VERSION = 0.10;

#   NOTE: I need to be given factory type before I am useful
#   i.e. Data::All::IO->register_factory_type( pkg => 'Data::All::IO::Pkg' );

sub new()
{
     my ( $pkg, $type ) = ( shift, shift );
     my $class = $pkg->get_factory_class( $type );
     
     #  Use the base's new 
     return $class->new(@_);
}

1;