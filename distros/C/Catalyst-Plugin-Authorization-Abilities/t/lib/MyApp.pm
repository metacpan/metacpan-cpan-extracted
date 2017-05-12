package MyApp;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
                 ConfigLoader
                 Static::Simple
                 Session
                 Session::State::Cookie
                 Session::Store::FastMmap
                 Authentication
                 Authorization::Abilities
                 +CatalystX::SimpleLogin
               /;

extends 'Catalyst';

our $VERSION = '0.01';
$VERSION = eval $VERSION;

# Configure the application.
#
# Note that settings in myapp.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'MyApp',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
);

__PACKAGE__->config( authentication => {
   default_realm => 'members',
   use_session   => 1,
   realms => {
       members => {
           credential => {
               class               => 'Password',
               password_field      => 'password',
               password_type       => 'hashed',
               password_hash_type  => 'SHA-1',
           },
           store => {
               class         => 'DBIx::Class',
               user_class    => 'DBIC::User',
               role_relation => 'user_roles',
               role_field    => 'name',

           },
       },
   }
});

__PACKAGE__->config->{session} = {
    expires        => 3600,
    flash_to_stash => 1,
};


# Start the application
__PACKAGE__->setup();


=head1 NAME

MyApp - Catalyst based application

=head1 SYNOPSIS

    script/myapp_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<MyApp::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Daniel Brosseau C<dab@catapulse.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
