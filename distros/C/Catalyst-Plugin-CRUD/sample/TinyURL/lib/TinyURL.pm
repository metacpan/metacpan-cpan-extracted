package TinyURL;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use Catalyst qw/-Debug ConfigLoader I18N CRUD Static::Simple/;

our $VERSION = '0.01';

# Configure the application. 
#
# Note that settings in TinyURL.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => 'TinyURL' );

# Start the application
__PACKAGE__->setup;


=head1 NAME

TinyURL - Catalyst based application

=head1 SYNOPSIS

    cd TinyURL/sql/schema
    createdb tinyurl
    psql tinyurl < tiny_url.sql
    cd ../../script
    ./tinyurl_server.pl

=head1 DESCRIPTION

This is sample Catalyst application using Catalyst::Plugin::CRUD.
Default model uses PostgreSQL.

=head1 SEE ALSO

L<TinyURL::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Jun Shimizu, E<lt>bayside@cpan.orgE<gt>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
