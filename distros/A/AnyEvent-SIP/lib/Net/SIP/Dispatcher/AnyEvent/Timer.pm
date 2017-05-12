use strict;
use warnings;
package Net::SIP::Dispatcher::AnyEvent::Timer;
{
  $Net::SIP::Dispatcher::AnyEvent::Timer::VERSION = '0.002';
}
# ABSTRACT: A timer object for Net::SIP::Dispatcher::AnyEvent

use AnyEvent;
use Net::SIP::Util 'invoke_callback';

sub new {
    my $class = shift;
    my ( $name, $when, $repeat, $cb ) = @_;
    my $self  = bless {}, $class;

    $self->{'timer'} = AE::timer $when, $repeat, sub {
        invoke_callback( $cb, $self );
    };

    return $self;
}

sub cancel {
    my $self = shift;
    delete $self->{'timer'};
}

1;



=pod

=head1 NAME

Net::SIP::Dispatcher::AnyEvent::Timer - A timer object for Net::SIP::Dispatcher::AnyEvent

=head1 VERSION

version 0.002

=head1 DESCRIPTION

The timer object L<Net::SIP::Dispatcher::AnyEvent> creates when asked for a
new timer.

=head1 INTERNAL ATTRIBUTES

These attributes have no accessors, they are saved as internal keys.

=head2 timer

The actual timer object

=head1 METHODS

=head2 new($name, $when, $repeat, $cb_data)

A constructor creating the new timer. You set when to start, the callback and
how often to repeat.

=head2 cancel

Cancel the timer.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

