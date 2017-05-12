package App::PAIA::Command::login;
use strict;
use v5.10;
use parent 'App::PAIA::Command';

our $VERSION = '0.30';

sub _execute {
    my ($self, $opt, $args) = @_;

    # don't take scope from session
    my $scope = $self->app->global_options->{scope} # command line
                // $self->config->get('scope');     # config file

    $self->login( $scope );
}

1;

=head1 NAME

App::PAIA::Command::login - get a access token and patron identifier

=head1 DESCRIPTION

requests or renews an access_token from a PAIA auth server

=cut
