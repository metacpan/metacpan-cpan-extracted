package Bit::MorseSignals::Receiver;

use strict;
use warnings;

use Carp     qw<croak>;
use Encode   qw<decode_utf8>;
use Storable qw<thaw>;

use Bit::MorseSignals qw<:consts>;

=head1 NAME

Bit::MorseSignals::Receiver - Base class for Bit::MorseSignals receivers.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    use Bit::MorseSignals::Receiver;

    my $pants = Bit::MorseSignals::Receiver->new(done => sub { print "received $_[1]!\n" });
    while (...) {
     my $bit = comes_from_somewhere_lets_say_signals();
     $pants->push($bit);
    }

=head1 DESCRIPTION

Base class for L<Bit::MorseSignals> receivers. Please refer to this module for more general information about the protocol.

Given a sequence of bits coming from the L<Bit::MorseSignals> protocol, the receiver object detects when a packet has been completed and then reconstructs the original message depending of the datatype specified in the header.

=cut

sub _check_self {
 croak 'First argument isn\'t a valid ' . __PACKAGE__ . ' object'
  unless ref $_[0] and $_[0]->isa(__PACKAGE__);
}

=head1 METHODS

=head2 C<< new < done => $cb > >>

L<Bit::MorseSignals::Receiver> object constructor. With the C<'done'> option, you can specify a callback that will be triggered every time a message is completed, and in which C<$_[0]> will be the receiver object and C<$_[1]> the message received.

=cut

sub new {
 my $class = shift;
 return unless $class = ref $class || $class;
 croak 'Optional arguments must be passed as key => value pairs' if @_ % 2;
 my %opts = @_;
 my $self = {
  msg    => undef,
  done   => $opts{done},
 };
 bless $self, $class;
 $self->reset;
 return $self;
}

=head2 C<push $bit>

Tells the receiver that you have received the bit C<$bit>. Returns true while the message isn't completed, and C<undef> as soon as it is.

=cut

sub push {
 my ($self, $bit) = @_;
 _check_self($self);
 if (!defined $bit) {
  $bit = $_;
  return unless defined $bit;
 }
 $bit = $bit ? 1 : 0;

 if ($self->{state} == 3) { # data

  vec($self->{buf}, $self->{len}, 1) = $bit;
  ++$self->{len};
  if ($self->{len} >= $self->{sig_len}) {
   my $res = 1;
   for (1 .. $self->{sig_len}) {
    if (vec($self->{buf}, $self->{len} - $_, 1) != vec($self->{sig}, $_-1, 1)) {
     $res = 0;
     last;
    }
   }
   if ($res) {
    my $base = int $self->{sig_len} / 8 + $self->{sig_len} % 8 != 0;
    substr $self->{buf}, -$base, $base, '';
    my @demanglers = (sub { $_[0] }, \&decode_utf8, \&thaw  );
    #        BM_DATA_{PLAIN,         UTF8,          STORABLE}
    $self->{msg} = defined $demanglers[$self->{type}]
                    ? do {
                       local $SIG{__DIE__} = sub { warn @_ };
                       $demanglers[$self->{type}]->($self->{buf})
                      }
                    : $self->{buf};
    $self->reset;
    $self->{done}->($self, $self->{msg}) if $self->{done};
    return;
   }
  }

 } elsif ($self->{state} == 2) { # header

  vec($self->{buf}, $self->{len}++, 1) = $bit;
  if ($self->{len} >= 3) {
   my $type = 2 * vec($self->{buf}, 1, 1)
                + vec($self->{buf}, 0, 1);
   $type = BM_DATA_PLAIN if vec($self->{buf}, 2, 1);
   @{$self}{qw<state type buf len>} = (3, $type, '', 0);
  }

 } elsif ($self->{state} == 1) { # end of signature

  if ($self->{sig_bit} != $bit) {
   $self->{state} = 2;
  }
  vec($self->{sig}, $self->{sig_len}++, 1) = $bit;

 } else { # first bit

  @{$self}{qw<state sig sig_bit sig_len buf len>}
           = (1,    '', $bit,   1,      '', 0  );
  vec($self->{sig}, 0, 1) = $bit;

 }

 return $self;
}

=head2 C<reset>

Resets the current receiver state, obliterating any current message being received.

=cut

sub reset {
 my ($self) = @_;
 _check_self($self);
 $self->{state} = 0;
 @{$self}{qw<sig sig_bit sig_len type buf len>} = ();
 return $self;
}

=head2 C<busy>

True when the receiver is in the middle of assembling a message.

=cut

sub busy {
 my ($self) = @_;
 _check_self($self);
 return $self->{state} > 0;
}

=head2 C<msg>

The last message completed, or C<undef> when no message has been assembled yet.

=cut

sub msg {
 my ($self) = @_;
 _check_self($self);
 return $self->{msg};
}

=head1 EXPORT

An object module shouldn't export any function, and so does this one.

=head1 DEPENDENCIES

L<Carp> (standard since perl 5), L<Encode> (since perl 5.007003), L<Storable> (idem).

=head1 SEE ALSO

L<Bit::MorseSignals>, L<Bit::MorseSignals::Emitter>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-bit-morsesignals-receiver at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bit-MorseSignals>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bit::MorseSignals::Receiver

Tests code coverage report is available at L<http://www.profvince.com/perl/cover/Bit-MorseSignals>.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Bit::MorseSignals::Receiver
