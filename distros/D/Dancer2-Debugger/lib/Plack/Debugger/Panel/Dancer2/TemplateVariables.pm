package Plack::Debugger::Panel::Dancer2::TemplateVariables;

=head1 NAME

Plack::Debugger::Panel::Dancer2::TemplateVariables - Dancer2 template variables panel for Plack::Debugger

=head1 VERSION

0.008

=cut

our $VERSION = '0.008';

use strict;
use warnings;

use Data::Dump qw(dump);

use parent 'Plack::Debugger::Panel';

sub new {
    my $class = shift;
    my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    $args{title} ||= 'Dancer2::TemplateVariables';
    $args{'formatter'} ||= 'pass_through';

    $args{'after'} = sub {
        my ( $self, $env, $resp ) = @_;

        my $env_key = 'dancer2.debugger.template_variables';

        my $tokens = delete $env->{$env_key};
        return unless $tokens;

        delete $tokens->{request}->{env}->{$env_key};

        my $html =
          '<table><thead><tr><th>Key</th><th>Value</th></tr></thead><tbody>';

        foreach my $key ( sort keys %$tokens ) {
            $html .=
                '<tr><td>'
              . $key
              . '</td><td><pre>'
              . vardump( $tokens->{$key} )
              . '</pre></td></tr>';
        }

        $html .= '</tbody></table>';

        $self->set_result($html);
    };

    $class->SUPER::new( \%args );
}

sub vardump {
    my $scalar = shift;
    return '(undef)' unless defined $scalar;
    return "$scalar" unless ref $scalar;
    return '<pre>' . Data::Dump::dump($scalar) . '</pre>';
}

1;
