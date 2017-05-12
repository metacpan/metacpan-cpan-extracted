package Plack::Debugger::Panel::Dancer2::Logger;

=head1 NAME

Plack::Debugger::Panel::Dancer2::Logger - Dancer2 logger panel for Plack::Debugger

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

    $args{title} ||= 'Dancer2::Logger';

    $args{'formatter'} ||= 'generic_data_formatter';

    $args{'after'} = sub {
        my ( $self, $env, $resp ) = @_;

        my $env_key = 'dancer2.debugger.logger';

        my $logs = delete $env->{$env_key};
        return unless $logs;

        my %levels = (
            error   => 0,
            warning => 0,
            success => 0,
        );

        foreach my $log ( @$logs ) {
            my $level = $log->[0];
            if ( $level eq 'error' ) {
                $levels{error}++;
            }
            elsif ( $level =~ /^warn/ ) {
                $levels{warning}++;
            }
            else {
                $levels{success}++;
            }
        }

        if ( $levels{error} ) {
            $self->notify('error', $levels{error});
        }
        elsif ( $levels{warning} ) {
            $self->notify('warning', $levels{warning});
        }
        elsif ( $levels{success} ) {
            $self->notify('success', $levels{success});
        }

        $self->set_result( $logs );
    };

    $class->SUPER::new( \%args );
}

1;
