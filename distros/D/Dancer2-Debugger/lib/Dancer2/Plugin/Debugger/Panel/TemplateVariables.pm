package Dancer2::Plugin::Debugger::Panel::TemplateVariables;

=head1 NAME

Dancer2::Plugin::Debugger::Panel::TemplateVariables - add template tokens to debugger panels

=head1 VERSION

0.008

=cut

our $VERSION = '0.008';

use Moo;
with 'Dancer2::Plugin::Debugger::Role::Panel';
use namespace::clean;

my $env_key = 'dancer2.debugger.template_variables';

sub BUILD {
    my $self = shift;

    $self->plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_layout_render',
            code => sub {
                if ( $self->plugin->app->request ) {
                    my $tokens = shift;
                    $self->plugin->app->request->env->{$env_key} = $tokens;
                }
            },
        )
    );
}

1;
