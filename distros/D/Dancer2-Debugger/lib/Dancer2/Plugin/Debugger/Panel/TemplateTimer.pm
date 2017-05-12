package Dancer2::Plugin::Debugger::Panel::TemplateTimer;

=head1 NAME

Dancer2::Plugin::Debugger::Panel::TemplateTimer - add template and layout timing data to debugger panels

=head1 VERSION

0.008

=cut

our $VERSION = '0.008';

use Time::HiRes qw/gettimeofday tv_interval/;
use Moo;
with 'Dancer2::Plugin::Debugger::Role::Panel';
use namespace::clean;

my $env_key = 'dancer2.debugger.templatetimer';

my $template_start;
my $layout_start;

sub BUILD {
    my $self = shift;

    $self->plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_template_render',
            code => sub {
                if ( $self->plugin->app->request ) {
                    $self->plugin->app->request->var(
                        'debugger.timer.template' => [gettimeofday] );
                }
            },
        )
    );

    $self->plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_layout_render',
            code => sub {
                if ( $self->plugin->app->request ) {
                    $self->plugin->app->request->var(
                        'debugger.timer.layout' => [gettimeofday] );
                }
            },
        )
    );

    $self->plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'after_template_render',
            code => sub {
                if ( $self->plugin->app->request ) {

                    my $start = $self->plugin->app->request->var(
                        'debugger.timer.template');

                    my $end = [gettimeofday];

                    $self->plugin->app->request->env->{$env_key}->{template} =
                      tv_interval( $start, $end );
                }
            },
        )
    );

    $self->plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'after_layout_render',
            code => sub {
                if ( $self->plugin->app->request ) {

                    my $start =
                      $self->plugin->app->request->var('debugger.timer.layout');

                    my $end = [gettimeofday];

                    $self->plugin->app->request->env->{$env_key}->{layout} =
                      tv_interval( $start, $end );
                }
            },
        )
    );
}

1;
