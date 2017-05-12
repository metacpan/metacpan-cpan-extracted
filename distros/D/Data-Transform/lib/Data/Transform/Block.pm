# vim: ts=3 sw=3 expandtab
package Data::Transform::Block;
use strict;
use Data::Transform;

use vars qw($VERSION @ISA);
$VERSION = '0.01';
@ISA = qw(Data::Transform);

use Carp qw(croak);

sub BUFFER         () { 0 }
sub FRAMING_BUFFER () { 1 }
sub BLOCK_SIZE     () { 2 }
sub EXPECTED_SIZE  () { 3 }
sub ENCODER        () { 4 }
sub DECODER        () { 5 }

=head1 NAME

Data::Transform::Block - translate data between streams and blocks

=head1 SYNOPSIS

  #!perl

  use warnings;
  use strict;
  use Data::Transform::Block;

  my $filter = Data::Transform::Block->new( BlockSize => 8 );

  # Prints three lines: abcdefgh, ijklmnop, qrstuvwx.
  # Bytes "y" and "z" remain in the buffer and await completion of the
  # next 8-byte block.

  $filter->get_one_start([ "abcdefghijklmnopqrstuvwxyz" ]);
  while (1) {
    my $block = $filter->get_one();
    last unless @$block;
    print $block->[0], "\n";
  }

  # Print one line: yz123456

  $filter->get_one_start([ "123456" ]);
  while (1) {
    my $block = $filter->get_one();
    last unless @$block;
    print $block->[0], "\n";
  }

=head1 DESCRIPTION

Data::Transform::Block translates data between serial streams and blocks.
It can handle fixed-length and length-prepended blocks, and it may be
extended to handle other block types.

Fixed-length blocks are used when Block's constructor is called with a
BlockSize value.  Otherwise the Block filter uses length-prepended
blocks.

Users who specify block sizes less than one deserve what they get.

In variable-length mode, a LengthCodec parameter may be specified.
The LengthCodec value should be a reference to a list of two
functions: the length encoder, and the length decoder:

  LengthCodec => [ \&encoder, \&decoder ]

The encoder takes a reference to a buffer and prepends the buffer's
length to it.  The default encoder prepends the ASCII representation
of the buffer's length and a chr(0) byte to separate the length from
the actual data:

  sub _default_encoder {
    my $stuff = shift;
    substr($$stuff, 0, 0) = length($$stuff) . "\0";
    return;
  }

The corresponding decoder returns the block length after removing it
and the separator from the buffer.  It returns nothing if no length
can be determined.

  sub _default_decoder {
    my $stuff = shift;
    unless ($$stuff =~ s/^(\d+)\0//s) {
      warn length($1), " strange bytes removed from stream"
        if $$stuff =~ s/^(\D+)//s;
      return;
    }
    return $1;
  }

This filter holds onto incomplete blocks until they are completed.

=head1 METHODS

Data::Transform::Block implements the L<Data::Transform> API. Only
differences and additions are documented here.

=cut

sub _default_decoder {
   my $stuff = shift;

   unless ($$stuff =~ s/^(\d+)\0//s) {
      warn length($1), " strange bytes removed from stream"
         if $$stuff =~ s/^(\D+)//s;
      return;
   }

   return $1;
}

sub _default_encoder {
   my $stuff = shift;

   substr($$stuff, 0, 0) = length($$stuff) . "\0";

   return;
}

sub new {
   my $type = shift;

   croak "$type must be given an even number of parameters" if @_ & 1;
   my %params = @_;

   my ($encoder, $decoder);
   my $block_size = delete $params{BlockSize};
   if (defined $block_size) {
      croak "$type doesn't support zero or negative block sizes"
         if $block_size < 1;
      croak "Can't use both LengthCodec and BlockSize at the same time"
         if exists $params{LengthCodec};
   }
   else {
      my $codec = delete $params{LengthCodec};
      if ($codec) {
         croak "LengthCodec must be an array reference"
            unless ref($codec) eq "ARRAY";
         croak "LengthCodec must contain two items"
            unless @$codec == 2;
         ($encoder, $decoder) = @$codec;
         croak "LengthCodec encoder must be a code reference"
            unless ref($encoder) eq "CODE";
         croak "LengthCodec decoder must be a code reference"
            unless ref($decoder) eq "CODE";
      }
      else {
         $encoder = \&_default_encoder;
         $decoder = \&_default_decoder;
      }
   }

   my $self = [
      [],           # BUFFER
      '',           # FRAMING_BUFFER
      $block_size,  # BLOCK_SIZE
      undef,        # EXPECTED_SIZE
      $encoder,     # ENCODER
      $decoder,     # DECODER
   ];

   return bless $self, $type;
}

sub clone {
   my $self = shift;

   my $new = [
      [],
      '',
      $self->[BLOCK_SIZE],
      undef,
      $self->[ENCODER],
      $self->[DECODER],
   ];

   return bless $new, ref $self
}

sub get_pending {
   my $self = shift;

   my @ret = @{$self->[BUFFER]};
   if (length $self->[FRAMING_BUFFER]) {
      if (not defined $self->[BLOCK_SIZE] and
          defined $self->[EXPECTED_SIZE]        ) {
         unshift @ret, $self->[ENCODER]->($self->FRAMING_BUFFER);
      } else {
         unshift @ret, $self->[FRAMING_BUFFER];
      }
   }
   return @ret ? \@ret : undef;
}

# get()           is inherited from Data::Transform.
# get_one_start() is inherited from Data::Transform.
# get_one()       is inherited from Data::Transform.

sub _handle_get_data {
  my ($self, $data) = @_;

   $self->[FRAMING_BUFFER] .= $data
      if (defined $data);

  # Need to check lengths in octets, not characters.
  BEGIN { eval { require bytes } and bytes->import; }

  # If a block size is specified, then pull off a block of that many
  # bytes.

  if (defined $self->[BLOCK_SIZE]) {
    return unless length($self->[FRAMING_BUFFER]) >= $self->[BLOCK_SIZE];
    my $block = substr($self->[FRAMING_BUFFER], 0, $self->[BLOCK_SIZE]);
    substr($self->[FRAMING_BUFFER], 0, $self->[BLOCK_SIZE]) = '';
    return $block;
  }

  # Otherwise we're doing the variable-length block thing.  Look for a
  # length marker, and then pull off a chunk of that length.  Repeat.

  if (
    defined($self->[EXPECTED_SIZE]) ||
    defined(
      $self->[EXPECTED_SIZE] = $self->[DECODER]->(\$self->[FRAMING_BUFFER])
    )
  ) {
    return if length($self->[FRAMING_BUFFER]) < $self->[EXPECTED_SIZE];

    # Four-arg substr() would be better here, but it's not compatible
    # with Perl as far back as we support.
    my $block = substr($self->[FRAMING_BUFFER], 0, $self->[EXPECTED_SIZE]);
    substr($self->[FRAMING_BUFFER], 0, $self->[EXPECTED_SIZE]) = '';
    $self->[EXPECTED_SIZE] = undef;

    return $block;
  }

  return;
}

sub _handle_put_data {
   my ($self, $block) = @_;

   # Need to check lengths in octets, not characters.
   BEGIN { eval { require bytes } and bytes->import; }

   # If a block size is specified, then just assume the put is right.
   # This will cause quiet framing errors on the receiving side.  Then
   # again, we'll have quiet errors if the block sizes on both ends
   # differ.  Ah, well!
   if (defined $self->[BLOCK_SIZE]) {
      return $block;
   } 

   # No specified block size. Do the variable-length block
   # thing. This steals a lot of Artur's code from the
   # Reference filter.
   $self->[ENCODER]->(\$block);
   return $block;
}

1;

__END__

=head1 SEE ALSO

Please see L<Data::Transform> for documentation regarding the base
interface.

The SEE ALSO section in L<POE> contains a table of contents covering
the entire POE distribution.

=head1 BUGS

The put() method doesn't verify block sizes.

=head1 AUTHORS & COPYRIGHTS

The Block filter was contributed by Dieter Pearcey, with changes by
Rocco Caputo.

Please see L<POE> for more information about authors and contributors.

=cut
