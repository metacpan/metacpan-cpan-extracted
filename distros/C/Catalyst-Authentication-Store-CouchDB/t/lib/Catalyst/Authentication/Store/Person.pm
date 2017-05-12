package Catalyst::Authentication::Store::Person;

use strict;
use warnings;
use base qw/Catalyst::Authentication::Store::CouchDB/;

our $VERSION= "0.01";

sub new {
    my ( $class, $config, $app ) = @_;    
    $config->{user_class}       = 'TestApp::User';
    $config->{store_user_class} = 'Catalyst::Authentication::Store::Person::User';

    return $class->SUPER::new( $config, $app );
}

__PACKAGE__;

__END__
