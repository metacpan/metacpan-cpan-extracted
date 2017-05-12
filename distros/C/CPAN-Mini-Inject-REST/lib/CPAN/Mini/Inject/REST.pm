package CPAN::Mini::Inject::REST;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    ConfigLoader
    Static::Simple
/;

extends 'Catalyst';

our $VERSION = '0.03';

# Configure the application.
#
# Note that settings in cpan_mini_inject_rest.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'CPAN::Mini::Inject::REST',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
);

# Start the application
__PACKAGE__->setup();


=head1 NAME

CPAN::Mini::Inject::REST - Remote API for CPAN::Mini::Inject

=head1 SYNOPSIS

    script/cpan_mini_inject_rest_server.pl

=head1 DESCRIPTION

Provides a REST API for remote access to a CPAN::Mini::Inject mirror.

Using the API, the contents of the repository can be queried and new
distributions added. See L<CPAN::Mini::Inject::REST::Controller::API::Version1_0>
for full details of the API features and documentation.

=head1 INSTALLATION

The API is a Catalyst application, so can be used with any webserver
supported by Catalyst or Plack.

You must already have a L<CPAN::Mini::Inject> mirror configured and working
on your machine. Set the path to your mirror's config file in F<cpan_mini_inject_rest.conf>.

Note that in order for files to be added to the repository, the
API must be running as a user with write access to the underlying
CPAN::Mini::Mirror itself.

=head1 SEE ALSO

L<CPAN::Mini::Inject::REST::Client>

L<CPAN::Mini::Inject>

=head1 AUTHOR

Jon Allen (JJ) <jj@jonallen.info>

=head1 LICENSE

Copyright (C) 2011 Jon Allen

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
