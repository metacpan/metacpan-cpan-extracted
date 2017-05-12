package TestApp;

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

use Catalyst qw/-Debug FormValidator::Lazy/;

our $VERSION = '0.01';

# Configure the application. 
#
# Note that settings in TestApp.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( 
    name => 'TestApp',
    form_validator_lazy => {
        mess_stash => 1,
        method_pkg => 'TestApp::Constraints',
        regexp_map => {
            '_id$' => '^\d+$',
            '_neko$' => [ qw(nyan 2 3 ) ],
        },
        strict => {
            osaka => '^\d+$',
            kyoto => 'method',
            hyogo => '^hyogo$',
            neko  => [ qw(nyan 2 3) ],
            inu   => [ qw(won) ],
        },
        loose => {
            hyogo => '^h+$',
            kyoto => 'method',
        }
    },
);

# Start the application
__PACKAGE__->setup;


=head1 NAME

TestApp - Catalyst based application

=head1 SYNOPSIS

    script/testapp_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<TestApp::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Tomohiro Teranishi

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
