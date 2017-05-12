package Bit::MorseSignals::Emitter;

use strict;
use warnings;

use Carp     qw<croak>;
use Encode   qw<encode_utf8 is_utf8>;
use Storable qw<freeze>;

use Bit::MorseSignals qw<:consts>;

=head1 NAME

Bit::MorseSignals::Emitter - Base class for Bit::MorseSignals emitters.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    use Bit::MorseSignals::Emitter;

    my $deuce = Bit::MorseSignals::Emitter->new;
    $deuce->post("hlagh") for 1 .. 3;
    while (defined(my $bit = $deuce->pop)) {
     sends_by_some_mean_lets_say_signals($bit);
    }

=head1 DESCRIPTION

Base class for L<Bit::MorseSignals> emitters. Please refer to this module for more general information about the protocol.

The emitter object enqueues messages and prepares them one by one into L<Bit::MorseSignals> packets. It gives then back the bits of the packet in the order they should be sent.

=cut

sub _check_self {
 croak 'First argument isn\'t a valid ' . __PACKAGE__ . ' object'
  unless ref $_[0] and $_[0]->isa(__PACKAGE__);
}

sub _count_bits {
 my ($len, $cur, $seq, $lng) = @_[1 .. 4];
 for (my $i = 0; $i < $len; ++$i) {
  my $bit = vec $_[0], $i, 1;
  if ($cur == $bit) {
   ++$seq;
  } else {
   $lng->[$cur] = $seq if $seq > $lng->[$cur];
   $seq = 1;
   $cur = $bit;
  }
 }
 $lng->[$cur] = $seq if $seq > $lng->[$cur];
 return $cur, $seq;
}

=head1 METHODS

=head2 C<new>

L<Bit::MorseSignals::Emitter> object constructor. Currently does not take any optional argument.

=cut

sub new {
 my $class = shift;
 return unless $class = ref $class || $class;
 croak 'Optional arguments must be passed as key => value pairs' if @_ % 2;
 my %opts = @_;
 my $self = {
  queue => [],
 };
 bless $self, $class;
 $self->reset;
 return $self;
}

=head2 C<< post $msg, < type => $type > >>

Adds C<$msg> to the message queue and, if no other message is currently processed, dequeue the oldest item and prepare it. The type is automatically chosen, but you may want to try to force it with the C<type> option : C<$type> is then one of the C<BM_DATA_*> constants listed in L<Bit::MorseSignals/CONSTANTS>

=cut

sub post {
 my $self = shift;
 my $msg  = shift;
 _check_self($self);
 croak 'Optional arguments must be passed as key => value pairs' if @_ % 2;
 my %opts = @_;

 my $type = $opts{type};

 if (defined $msg) {

  my @manglers = (sub { $_[0] }, \&encode_utf8, \&freeze);
  #      BM_DATA_{PLAIN,         UTF8,          STORABLE}
  $type = BM_DATA_AUTO unless defined $type and exists $manglers[$type];
  if (ref $msg) {
   return if { map { $_ => 1 } qw<CODE GLOB> }->{ref $msg};
   $type = BM_DATA_STORABLE;
  } elsif ($type == BM_DATA_AUTO) {
   $type = is_utf8($msg) ? BM_DATA_UTF8 : BM_DATA_PLAIN;
  }
  $msg = $manglers[$type]->($msg);

  if ($self->{state}) { # Busy/queued, can't handle this message right now.
   push @{$self->{queue}}, [ $msg, $type ];
   return -1 if $self->{state} == 2;           # Currently sending
   ($msg, $type) = @{shift @{$self->{queue}}}; # Otherwise something's queued
  }

 } elsif ($self->{state} == 1) { # No msg was given, but the queue isn't empty.

  ($msg, $type) = @{shift @{$self->{queue}}};

 } else { # Either unused or busy sending.

  return;

 }

 $self->{state} = 2;

 my $head = '';
 vec($head, 0, 1) = ($type & 1);
 vec($head, 1, 1) = ($type & 2) >> 1;
 vec($head, 2, 1) = 0;
 my $hlen = 3;

 my $len = 8 * length $msg;
 my @lng = (0, 0, 0);
 my ($cur, $seq) = _count_bits $head, $hlen, 2,    0,    \@lng;
    ($cur, $seq) = _count_bits $msg,  $len,  $cur, $seq, \@lng;
    ($cur, $seq) = ($lng[0] > $lng[1]) ? (1, $lng[1])
                                       : (0, $lng[0]); # Take the smallest.
 ++$seq;

 $self->{len} = 1 + $seq + $hlen + $len + $seq + 1;
 $self->{buf} = '';
 my ($i, $j, $k) = (0, 0, 0);
 vec($self->{buf}, $i++, 1) = $cur for 1 .. $seq;
 vec($self->{buf}, $i++, 1) = 1 - $cur;
 vec($self->{buf}, $i++, 1) = vec($head, $j++, 1) for 1 .. $hlen;
 vec($self->{buf}, $i++, 1) = vec($msg,  $k++, 1) for 1 .. $len;
 vec($self->{buf}, $i++, 1) = 1 - $cur;
 vec($self->{buf}, $i++, 1) = $cur for 1 .. $seq;

 $self->{pos} = 0;

 return 1;
}

=head2 C<pop>

If a message is being processed, pops the next bit in the packet. When the message is over, the next in the queue is immediatly prepared and the first bit of the new packet is given back. If the queue is empty, C<undef> is returned. You may want to use this method with the idiom :

    while (defined(my $bit = $deuce->pop)) {
     ...
    }

=cut

sub pop {
 my ($self) = @_;
 _check_self($self);
 return      if $self->{state} == 0;
 $self->post if $self->{state} == 1;
 my $bit   = vec $self->{buf}, $self->{pos}++, 1;
 $self->reset if $self->{pos} >= $self->{len};
 return $bit;
}

=head2 C<len>

The length of the currently posted message.

=cut

sub len {
 my ($self) = @_;
 _check_self($self);
 return $self->{len};
}

=head2 C<pos>

The number of bits that have already been sent for the current message.

=cut

sub pos {
 my ($self) = @_;
 _check_self($self);
 return $self->{pos};
}

=head2 C<reset>

Cancels the current transfer, but does not empty the queue.

=cut

sub reset {
 my ($self) = @_;
 _check_self($self);
 $self->{state} = @{$self->{queue}} > 0;
 @{$self}{qw<buf len pos>} = ();
 return $self;
}

=head2 C<flush>

Flushes the queue, but does not cancel the current transfer.

=cut

sub flush {
 my ($self) = @_;
 _check_self($self);
 $self->{queue} = [];
 return $self;
}

=head2 C<busy>

True when the emitter is busy, i.e. when a packet is being chunked.

=cut

sub busy {
 my ($self) = @_;
 _check_self($self);
 return $self->{state} >= 2;
}

=head2 C<queued>

Returns the number of queued items.

=cut

sub queued {
 my ($self) = @_;
 _check_self($self);
 return @{$self->{queue}};
}

=head1 EXPORT

An object module shouldn't export any function, and so does this one.

=head1 DEPENDENCIES

L<Carp> (standard since perl 5), L<Encode> (since perl 5.007003), L<Storable> (idem).

=head1 SEE ALSO

L<Bit::MorseSignals>, L<Bit::MorseSignals::Receiver>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-bit-morsesignals-emitter at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bit-MorseSignals>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bit::MorseSignals::Emitter

Tests code coverage report is available at L<http://www.profvince.com/perl/cover/Bit-MorseSignals>.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Bit::MorseSignals::Emitter
