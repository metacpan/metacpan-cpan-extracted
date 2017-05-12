package Dancer2::Plugin::Debugger::Panel::Logger;

=head1 NAME

Dancer2::Plugin::Debugger::Panel::Logger - add logs to debugger panels

=head1 VERSION

0.008

=cut

our $VERSION = '0.008';

use Moo;
with 'Dancer2::Plugin::Debugger::Role::Panel';
use namespace::clean;

my $env_key = 'dancer2.debugger.logger';

sub BUILD {
    my $self = shift;

    $self->plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'engine.logger.after',
            code => sub {
                if ( $self->plugin->app->request ) {
                    my ( $logger, @args ) = @_;
                    push @{ $self->plugin->app->request->env->{$env_key} },
                      \@args;
                }
            },
        )
    );
}

1;
