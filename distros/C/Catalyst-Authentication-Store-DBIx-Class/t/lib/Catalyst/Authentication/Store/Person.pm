package Catalyst::Authentication::Store::Person;

use strict;
use warnings;
use base qw/Catalyst::Authentication::Store::DBIx::Class/;

our $VERSION= "0.01";

sub new {
    my ( $class, $config, $app ) = @_;    
    $config->{user_class}       = 'TestApp::User';
    $config->{store_user_class} = 'Catalyst::Authentication::Store::Person::User';
    $config->{role_relation}    = 'role';
    $config->{role_field}       = 'role';

    return $class->SUPER::new( $config, $app );
}

__PACKAGE__;

__END__