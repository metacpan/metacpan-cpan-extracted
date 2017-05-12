package Dancer2::Plugin::Debugger::Panel::Settings;

=head1 NAME

Dancer2::Plugin::Debugger::Panel::Settings - add settings data to debugger panels

=head1 VERSION

0.008

=cut

our $VERSION = '0.008';

use Moo;
with 'Dancer2::Plugin::Debugger::Role::Panel';
use namespace::clean;

my $env_key = 'dancer2.debugger.settings';

sub BUILD {
    my $self = shift;

    $self->plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                if ( $self->plugin->app->request ) {
                    my $settings = $self->plugin->app->config;

                    # make a copy
                    $self->plugin->app->request->env->{$env_key} = {%$settings};
                }
            },
        )
    );
}

1;
