package Arepa::Web::Base;

use strict;
use warnings;

use base 'Mojolicious::Controller';

use Arepa::Config;

use constant DEFAULT_CONFIG_PATH => '/etc/arepa/config.yml';
our $config      = undef;
our $config_path = $ENV{AREPA_CONFIG} || DEFAULT_CONFIG_PATH;

if (-r $config_path) {
    $config = Arepa::Config->new($config_path);
}
else {
    die "Couldn't read configuration file $config_path.\n" .
        "Use the environment variable AREPA_CONFIG to specify one.\n";
}

sub config      { return $Arepa::Web::Base::config; }
sub config_path { return $Arepa::Web::Base::config_path; }


sub _add_error {
    my ($self, $error, $output) = @_;
    push @{$self->{error_list}}, {error  => $error,
                                  output => $output || ""};
}

sub _error_list {
    my ($self) = @_;
    @{$self->{error_list} || []};
}

sub _only_if_admin {
    my ($self, $f) = @_;

    if ($self->stash('is_user_admin')) {
        $f->();
    }
    else {
        $self->vars(errors =>
                    [{error => "You need to be an admin to do this!"}]);
        $self->render('error');
    }
}

sub vars {
    my ($self, %args) = @_;

    my $auth_key = 'web_ui:authentication:type';
    my $external_auth = ($self->config->key_exists($auth_key) &&
                         $self->config->get_key($auth_key) eq 'external');
    $self->stash(
        base_url         => $self->config->get_key('web_ui:base_url'),
        external_auth    => $external_auth,
        %args);
}

sub show_view {
    my ($self, $stash, %opts) = @_;

    $self->vars(%$stash);
    if ($opts{template}) {
        $self->render($opts{template}, layout => 'default');
    }
    else {
        $self->render(layout => 'default');
    }
}

1;
