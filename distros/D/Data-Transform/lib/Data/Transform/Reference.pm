# vim: ts=2 sw=2 expandtab
package Data::Transform::Reference;
use strict;
use Data::Transform;

use vars qw($VERSION @ISA);
$VERSION = '0.01';
@ISA = qw(Data::Transform);

use Carp qw(croak);

sub INPUT       () { 0 }
sub BUFFER      () { 1 }
sub SERIALIZE   () { 2 }
sub DESERIALIZE () { 3 }

=pod

=head1 NAME

Data::Transform::Reference - freeze and thaw arbitrary Perl data

=head1 SYNOPSIS

  use YAML;
  use Data::Transform::Reference;

  my $filter = Data::Transform::Reference->new(
    serialize   => YAML->can('Dump');
    deserialize => YAML->can('Load');
  );

  ...
  my $string = $filter->put($some_var);

  ...
  my $other_var = $filter->get($serialized_var);

=head1 DESCRIPTION

Data::Transform::Reference allows programs to send and receive arbitrary
Perl data structures without worrying about a line protocol.  Its
put() method serializes Perl data into a byte stream suitable for
transmission.  get_one() parses the data structures back out of such a
stream.

=head1 METHODS

Data::Transform::Reference implements the standard Data::Transform API. Only
the differences are documented here.

=cut

=head2 new

new() creates and initializes a Data::Transform::Reference object. It
requires the following parameters:

=over 2

=item serializer

A code ref used to serialize data. Good candidates for this are nfreeze()
from L<Storable> or Dump() from a YAML implementation.

=item deserializer

A code ref used to de-serialize data. Good candidates for this are thaw()
from L<Storable> or Load() from a YAML implementation.

=back

Both code references are expected to accept a single parameter containing
the data on which to act on.

=cut

sub new {
  my $type = shift;

  croak "$type requires an even number of arguments"
    if (@_ & 1);

  my %param = @_;

  croak "$type requires a serialize parameter"
    unless defined $param{'serialize'};
  croak "$type: serialize parameter must be a CODE reference"
    unless (ref $param{'serialize'} eq 'CODE');
  croak "$type requires a deserialize parameter"
    unless defined $param{'deserialize'};
  croak "$type: deserialize parameter must be a CODE reference"
    unless (ref $param{'deserialize'} eq 'CODE');
  

  my $self = bless [
      [],                     # INPUT
      '',                     # BUFFER
      $param{'serialize'},    # FREEZE
      $param{'deserialize'},  # THAW
    ];

  return bless $self, $type;
}

sub clone {
  my $self = shift;

  my $new = [
      [],
      '',
      $self->[SERIALIZE],
      $self->[DESERIALIZE],
    ];

  return bless $new, ref $self;
}

sub get_pending {
   my $self = shift;
   my @ret;

   @ret = @{$self->[INPUT]};
   if (length $self->[BUFFER]) {
      unshift @ret, $self->[BUFFER];
   }

   return @ret ? \@ret : undef;
}

sub _handle_get_data {
  my ($self, $data) = @_;

  if (defined $data) {
    $self->[BUFFER] .= $data;
  }

  # Need to check lengths in octets, not characters.
  use bytes;

  if ($self->[BUFFER] =~ /^(\d+)\0/ and
      length($self->[BUFFER]) >= $1 + length($1) + 1  ) {

    substr($self->[BUFFER], 0, length($1) + 1) = "";
    my $return = substr($self->[BUFFER], 0, $1);
    substr($self->[BUFFER], 0, $1) = "";
    return $self->[DESERIALIZE]->($return);
  }

  return;
}

sub _handle_put_data {
  my ($self, $reference) = @_;

  # Need to check lengths in octets, not characters.
  use bytes;

  my $frozen = $self->[SERIALIZE]->($reference);
  return length($frozen) . "\0" . $frozen;
}

1;

__END__

=head1 SEE ALSO

Please see L<Data::Transform> for documentation regarding the base
interface.

=head1 CAVEATS

It's important to use identical serializers on each end of a
connection.  Even different versions of the same serializer can break
data in transit.

Most (if not all) serializers will rebless data at the destination,
but many of them will not load the necessary classes to make their
blessings work.

=head1 AUTHORS & COPYRIGHTS

The original Reference filter was contributed by Artur Bergman,
with changes by Philip Gwyn. Martijn van Beers simplified the API
when starting Data::Transform

=cut
