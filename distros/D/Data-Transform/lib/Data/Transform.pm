# vim: ts=2 sw=2 expandtab
package Data::Transform;
use strict;

use vars qw($VERSION);
$VERSION = '0.06';

use Carp qw(croak);
use Scalar::Util qw(blessed);
use Data::Transform::Meta;

=head1 NAME

Data::Transform - base class for protocol abstractions

=head1 DESCRIPTION

POE::Filter objects plug into the wheels and define how the data will
be serialized for writing and parsed after reading.  POE::Wheel
objects are responsible for moving data, and POE::Filter objects
define how the data should look.

POE::Filter objects are simple by design.  They do not use POE
internally, so they are limited to serialization and parsing.  This
may complicate implementation of certain protocols (like HTTP 1.x),
but it allows filters to be used in stand-alone programs.

Stand-alone use is very important.  It allows application developers
to create lightweight blocking libraries that may be used as simple
clients for POE servers.  POE::Component::IKC::ClientLite is a notable
example.  This lightweight, blocking event-passing client supports
thin clients for gridded POE applications.  The canonical use case is
to inject events into an IKC application or grid from CGI interfaces,
which require lightweight resource use.

POE filters and drivers pass data in array references.  This is
slightly awkward, but it minimizes the amount of data that must be
copied on Perl's stack.


=head1 PUBLIC INTERFACE

All Data::Transform classes must support the minimal interface,
defined here. Specific filters may implement and document additional
methods.

=cut

=head2 new PARAMETERS

new() creates and initializes a new filter.  Constructor parameters
vary from one Data::Transform subclass to the next, so please consult the
documentation for your desired filter.

=cut

sub new {
  my $type = shift;
  croak "$type is not meant to be used directly";
}

=head2 get_one_start ARRAYREF

get_one_start() accepts an array reference containing unprocessed
stream chunks.  The chunks are added to the filter's internal buffer
for parsing by get_one().

=cut

sub get_one_start {
  my ($self, $stream) = @_;

  push (@{$self->[0]}, @$stream);
}

=head2 get_one

get_one() parses zero or one complete item from the filter's internal
buffer.

get_one() is the lazy form of get(). It only parses only one item at
a time from the filter's buffer. This is vital for applications that
may switch filters in mid-stream, as it ensures that the right filter
is in use at any given time.

=cut

sub get_one {
  my $self = shift;

  if (my $val = $self->_handle_get_data) {
    return [ $val ];
  }
  return [ ] unless (@{$self->[0]});

  while (defined (my $data = shift (@{$self->[0]}))) {
    if (blessed $data and $data->isa('Data::Transform::Meta')) {
      return [ $self->_handle_get_meta($data) ];
    }
    my $ret = $self->_handle_get_data($data);
    if (defined $ret) {
      return [ $ret ];
    }
  }
  return [];
}

=head2 get ARRAYREF

get() is the greedy form of get_one().  It accepts an array reference
containing unprocessed stream chunks, and it adds that data to the
filter's internal buffer.  It then parses as many full items as
possible from the buffer and returns them in another array reference.
Any unprocessed data remains in the filter's buffer for the next call.

This should only be used if you don't care how long the processing takes.
Unless responsiveness doesn't matter for your application, you should
really be using get_one_start() and get_one().

=cut

sub get {
  my ($self, $stream) = @_;
  my @return;

  $self->get_one_start($stream);
  while (1) {
    my $next = $self->get_one();
    last unless @$next;
    push @return, @$next;
  }

  return \@return;
}

=head2 put ARRAYREF

put() serializes items into a stream of octets that may be written to
a file or sent across a socket.  It accepts a reference to a list of
items, and it returns a reference to a list of marshalled stream
chunks.  The number of output chunks is not necessarily related to the
number of input items.

=cut

sub put {
  my ($self, $packets) = @_;
  my @raw;

  foreach my $packet (@$packets) {
    if (blessed $packet and $packet->isa('Data::Transform::Meta')) {
      if (my @ret = $self->_handle_put_meta($packet)) {
        push @raw, @ret;
      }
      next;
    } elsif (my @data = $self->_handle_put_data($packet)) {
      push @raw, @data;
    }
  }

  return \@raw;
}

=head2 meta

A flag method that always returns 1. This can be used in e.g. POE to check
if the class supports L<Data::Transform::Meta>, which all Data::Transform
subclasses should, but L<POE::Filter> classes don't. Doing it this way
instead of checking if a filter is a Data::Transform subclass allows for
yet another filters implementation that is meant to transparently replace
this to be used by POE without changes to POE.

=cut

sub meta {
  return 1;
}

=head2 clone

clone() creates and initializes a new filter based on the constructor
parameters of the existing one.  The new filter is a near-identical
copy, except that its buffers are empty.

=cut

sub clone {
  my $self = shift;
  my $type = ref $self;
  croak "$type has to implement a clone method";
}

=head2 get_pending

get_pending() returns any data remaining in a filter's input buffer.
The filter's input buffer is not cleared, however.  get_pending()
returns a list reference if there's any data, or undef if the filter
was empty.

Full items are serialized whole, so there is no corresponding "put"
buffer or accessor.

=cut

sub get_pending {
  my $self = shift;

  return [ @{$self->[0]} ] if @{$self->[0]};
  return undef;
}

=head1 IMPLEMENTORS NOTES

L<Data::Transform> implements most of the public API above to help
ensure uniform behaviour across all subclasses. This implementation
expects your object to be an array ref. Data::Transform provides
a default implementation for the following methods:

=over 2

=item get(), get_one_start(), get_one()

get() is implemented in terms of get_one_start() and get_one(). Since
having to handle L<Data::Transform::Meta> packets means that you have
to keep a list of incoming packets, it is highly unlikely that you
will ever need to override get_one_start(), since all it does is add
to the list. It assumes the list is kept as an array ref in the first
entry of your object's list.

get_one is in turn implemented in terms of the following two methods:

=over 2

=cut

=item _handle_get_data(<data>)

This is where you do all your filter's input work. There is no default
implementation. It has a single method parameter which may contain a single
chunk of raw data to process. get_one() will also call it without new
data to see if not all raw data from the previous chunk had been processed.

=cut

sub _handle_get_data {
  croak ref($_[0]) . " must implement _handle_get_data";
}

=item _handle_get_meta(<Data::Transform::Meta>)

Override this if you need to act on metadata packets that are embedded
into the input stream. The default implementation just returns the
packet. If you override this, make sure you return the packet as well, so
that if your filter is being used in a filter stack, the filters below you
get a chance to handle it as well.

=back

=cut

sub _handle_get_meta {
  return $_[1];
}

=item put()

put() is implemented in terms of the following methods. It's unlikely
you want to override put() instead of these:

=over 2

=cut

=item  _handle_put_data(<data>) 

Gets called for each packet of regular data in the list passed to put().

=cut

sub _handle_put_data {
  croak ref($_[0]) . " must implement _handle_put_data";
}

=item _handle_put_meta(<Data::Transform::Meta>)

Gets called for each packet of metadata in the list passed to put(). The
default implementation just returns the packet. If you override this,
make sure you end with returning it too, so that when your filter is
used in a stack, the filters above you get a chance to handle it too.

=cut

sub _handle_put_meta {
  return $_[1];
}

1;

__END__

=back

=item get_pending()

The default implementation just returns the list of raw packets still
in your queue. If your filter doesn't always return one cooked packet
for each raw packet it receives, you will have to override this to
also return the data it has stored while assembing complete cooked
packets.

=item meta()

This is just a flag method signifying that Data::Transform, unlike
L<POE::Filter> supports handling metadata.

=back

So, in the best case, you only have to implement new(), clone(),
_handle_get_data() and _handle_put_data(). Likely you will want
to override get_pending() as well, but usually nothing more is
needed.

=head1 SEE ALSO

L<Data::Transform> is based on L<POE::Filter>
L<POE::Wheel>
The SEE ALSO section in L<POE> contains a table of contents covering
the entire POE distribution.

=head1 LICENSE

Data::Transform is released under the GPL version 2.0 or higher.
See the file LICENCE for details.

=head1 AUTHORS

L<Data::Transform> is based on L<POE::Filter>, by Rocco Caputo. New
code in Data::Transform is copyright 2008 by Martijn van Beers  <martijn@cpan.org>

