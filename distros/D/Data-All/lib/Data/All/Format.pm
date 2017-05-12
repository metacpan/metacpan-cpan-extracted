package Data::All::Format;


use strict;

#   CPAN Modules
use base qw( Class::Factory );

our $VERSION = 0.10;

#   TODO: Give Data::All control of creating the Format objects. It should send them to IO 

#   TODO: Allow external code to add new instance objects
Data::All::Format->register_factory_type( delim     => 'Data::All::Format::Delim' );
Data::All::Format->register_factory_type( fixed     => 'Data::All::Format::Fixed' );
Data::All::Format->register_factory_type( hash      => 'Data::All::Format::Hash' );


sub new()
{
     my ( $pkg, $type ) = ( shift, shift );
     my $class = $pkg->get_factory_class( $type );
     
     #  Use the base's new b/c it's will properly create the modules in
     #  spiffy styles
     return $class->new(@_);
}









1;



