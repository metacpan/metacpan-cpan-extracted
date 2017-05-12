package RestTest;

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

use Catalyst;

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in RestTest.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => 'RestTest' );

# Start the application
__PACKAGE__->setup;

my $logger = Class::MOP::Class->create(
    'MyLog',
    methods => {
        (map { ($_ => sub { () }), ("is_${_}" => sub { () }) } qw(debug info warn error fatal)),
        (map { ($_ => sub { () }) } qw(level levels enable disable abort)),
    },
);

__PACKAGE__->log($logger->new_object);

=head1 NAME

RestTest - Catalyst based application

=head1 SYNOPSIS

    script/resttest_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<RestTest::Controller::Root>, L<Catalyst>

=head1 AUTHOR

luke saunders

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
