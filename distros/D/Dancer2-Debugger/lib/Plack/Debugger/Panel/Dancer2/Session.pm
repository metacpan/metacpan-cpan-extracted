package Plack::Debugger::Panel::Dancer2::Session;

=head1 NAME

Plack::Debugger::Panel::Dancer2::Session - Dancer2 session panel for Plack::Debugger

=head1 VERSION

0.008

=cut

our $VERSION = '0.008';

use strict;
use warnings;

use parent 'Plack::Debugger::Panel';

sub new {
    my $class = shift;
    my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    $args{title} ||= 'Dancer2::Session';

    $args{'formatter'} ||= 'generic_data_formatter';

    $args{'after'} = sub {
        my ( $self, $env, $resp ) = @_;

        my $env_key = 'dancer2.debugger.session';

        my $session = delete $env->{$env_key};
        return unless $session;

        $self->set_result( $session );
    };

    $class->SUPER::new( \%args );
}

1;
