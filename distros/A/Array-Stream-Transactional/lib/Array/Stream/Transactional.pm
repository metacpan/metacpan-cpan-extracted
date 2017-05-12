# $Id: Transactional.pm,v 1.6 2004/04/08 19:36:28 claes Exp $

package Array::Stream::Transactional;

use 5.00503;
use Carp qw(croak);
use strict;
use warnings;

our $VERSION = '1.02';

sub new {
  my ($class, $tokens) = @_;
  $class = ref $class || $class;
  croak "Not an ARRAY reference" unless(UNIVERSAL::isa($tokens, "ARRAY"));
  my $self = bless { data => $tokens }, $class;
  $self->reset;

  return $self;
}

sub reset {
  my $self = shift;
  $self->{pos} = 0;
  $self->{transactions} = [];
  $self->{current} = $self->{data}->[0];
  $self->{previous} = undef;
  1;
}

sub pos {
  $_[0]->{pos};
}

sub next {
  my $self = shift;
  $self->{previous} = $self->{current};
  $self->{current} = $self->{data}->[++$self->{pos}];
  return $self->{current};
}

sub rewind {
  my $self = shift;
  $self->{previous} = $self->{current};
  $self->{current} = $self->{data}->[--$self->{pos}];
  return $self->{current};
}

sub following {
  my $self = shift;
  return undef if($self->{pos} == @{$self->{data}});
  return $self->{data}->[$self->{pos} + 1];
}

sub commit {
  my $self = shift;
  push @{$self->{transactions}}, [ $self->{pos}, $self->{current}, $self->{previous} ];
  1;
}

sub rollback {
  my $self = shift;
  croak "No more commits to rollback" unless(@{$self->{transactions}});
  ($self->{pos}, $self->{current}, $self->{previous}) = @{pop @{$self->{transactions}}};
  1;
}

sub regret {
  my $self = shift;
  croak "No more commits to regret" unless(@{$self->{transactions}});
  return @{pop @{$self->{transactions}}};
}

sub current {
  my $self = shift;
  return $self->{current};
}

sub previous {
  my $self = shift;
  return $self->{previous};
}

sub length {
  my $self = shift;
  return scalar @{$self->{data}};
}

sub has_more {
  my $self = shift;
  return $self->{pos} < @{$self->{data}};
}

1;

__END__
=pod
=head1 NAME

Array::Stream::Transactional - Transactional array wrapper

=head1 SYNOPSIS

  use Array::Stream::Transactional;
  my $stream = Array::Stream::Transactional->new([1..100]);
  $stream->commit;
  while($stream->has_more) {
    if($stream->next == 50 && !$reverted) {
      $stream->rollback;
      $reverted = 1;
    }
    print $stream->current, "\n";
  }

=head1 DESCRIPTION

Array::Stream::Transactional is a Perl extension for wrapping an array and 
having it pose as a stream. The streams current position can be 
commited and rollbacked at any time.

=head1 CONSTRUCTOR

=over 4

=item new ( ARRAYREF )

Creates an C<Array::Stream::Transactional>. Wrapps the passed array reference. Position is set to 0, current is set the first element in ARRAYREF, previous is set to undef and the transaction stack is empty.

=back

=head1 METHODS

=over 4

=item next ( )

Get the next element from the stream and increment the position in the current transaction.

=item rewind ( )

Get the previous element from the stream and decrement the position in the current transaction.

=item current ( )

Get the current element read from the stream in the current transaction.

=item previous ( )

Get the previous element read from the stream in the current transaction.

=item following ( )

Get the following element read from the strean in the current transaction. This method is like L</next> except it doesn't increment the position.

=item pos ( )

Return the current position in the stream.

=item length ( )

Return the length of the wrapped array

=item has_more ( )

Return true if there are more elements in the stream, false otherwise.

=item commit ( )

Push the current position, element and previous element on the transaction stack.

=item rollback ( )

Rollback the current transaction by reseting the stream position, current and previous element. The transaction will be removed from the transaction stack so that next rollback will rollback to the commit previous to the commit that created the rollbacked transaction.

=item regret ( )

Removes the top item of the commit stack. Returns the position, current element and previous element of the stream at the time the commit was made.

=item reset ( )

Resets the reading of the stream to position 0, current to first element and previous to undefined.

=back

=head1 AUTHOR

Claes Jacobsson, claesjac@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Claes Jacobsson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
