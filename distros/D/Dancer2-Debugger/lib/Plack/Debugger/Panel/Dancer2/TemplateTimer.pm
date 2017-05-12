package Plack::Debugger::Panel::Dancer2::TemplateTimer;

=head1 NAME

Plack::Debugger::Panel::Dancer2::TemplateTimer - Dancer2 template timer panel for Plack::Debugger

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

    $args{title} ||= 'Dancer2::TemplateTimer';
    $args{'formatter'} ||= 'ordered_key_value_pairs';

    $args{'after'} = sub {
        my ( $self, $env, $resp ) = @_;

        my $env_key = 'dancer2.debugger.templatetimer';

        my $data = delete $env->{$env_key};
        return unless $data;

        my $subtitle;
        my @result;
        my $total;

        if ( $data->{template} ) {
            $total += $data->{template};
            push @result, 'Template', $data->{template};
        }
        if ( $data->{layout} ) {
            $total += $data->{layout};
            push @result, 'Layout', $data->{layout};
        }

        if ( defined $total ) {
            $self->set_subtitle($total);
            push @result, 'Total', $total;
            $self->set_result( [@result] );
        }
    };

    $class->SUPER::new( \%args );
}

1;
