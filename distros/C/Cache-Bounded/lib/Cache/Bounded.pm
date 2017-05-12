package Cache::Bounded;
$Cache::Bounded::VERSION='1.09';

use warnings;
use strict;

sub new {
  my $class = shift @_;
  my $self = {};
  bless($self,$class);

  $self->{cache}    = {};
  $self->{count}    = 0;
  $self->{interval} = 1000;
  $self->{size}     = 500000;

  if ( UNIVERSAL::isa($_[0],'HASH') ) {
    $self->{interval} = $_[0]->{interval} if $_[0]->{interval} > 1;
    $self->{size}     = $_[0]->{size}     if $_[0]->{size}     > 1;
  }

  return $self;
}

sub get {
  my $self = shift @_;
  my $key  = shift @_;
  return $self->{cache}->{$key};
}

sub purge {
  my $self = shift @_;
  $self->{count} = 0;
  $self->{cache} = {};
}

sub set {
  my $self = shift @_;
  my $key  = shift @_;
  my $data = shift @_;
  $self->{count}++;

  if ( $self->{count} >= $self->{interval} ) {
    $self->{count} = 0;
    $self->purge() if (scalar(keys %{$self->{cache}})+1) >= $self->{size};
  }

  $self->{cache}->{$key} = $data;
  return 1;
}

1;

=head1 NAME:

Cache::Bounded - A size-aware in-memory cache optimized for speed.

=head1 SYNOPSIS:

Cache::Bounded is designed for caching items into memory in a very fast
but rudimentarily size-aware fashion.

=head1 DESCRIPTION:

Most intelligent caches take either a size-aware or use-aware approach.  
They do so by either anlysing the size of all the elements in the cache or
their frequency of usage before determining which elements to drop from
the cache.  Unfortunately, the processing overhead for this logic (usually
applied on insert) will often slow these caches singnificantly when
frequent insertions are needed.

This module was designed address when this speed-penalty becomes a
problem. Specifically, it is a rudimentarily size-aware cache that is
optimized to be very fast.

For its size analysis, this module merely checks the number of elements in
the cache against a raw size limit. (The default limit is 500,000)  
Additionally, to aid speed, the "size" check doesn't occur on every
insertion. Only after a count of a certain number of insertions (default
1,000) is the size check performed. If the size limit has been exceeded,
the entire cache is purged. (Since there is no usage analysis, there is no
other logical depreciation that can be applied.)

This produces a very fast in-memory cache that you can tune to approximate
size based upon your data elements.

=head1 USAGE:

  my $cache = new Cache::Bounded;

  $cache->set($key,$value);
  my $value = $cache->get($key);

=head2 Methods

=head3 new($ref) 

  my $cache = new Cache::Bounded ({ interval=>1000 size=>500000 });

Instances the object as is typical with an OO module. You may also pass a 
hashref with configurations to tune the cache.

Configurable values are:

=over

=item interval

The number of inserts before the size of the cache is checked. Setting 
this to a lower number reduces the "sloppiness" of the size limit. 
However, it also slows cache inserts.

The default of this value is 1,000.

=item size

The number of entries allowed in the cache. Once this is exceeded the 
cache will be purged at the next size check.

The default of this value is 500,000.

=back

=head3 get($key)

Returns the cached value associated with the given key. If no value has 
been cached for that key, the returned value is undefined.

=head3 set($key,$value)

Caches the given value for the given key. The cache size is checked during 
the set method. If a purge occurs, the value is cached post-purge.

=head3 purge()

This dumps the currently in-memory cache.

=head1 KNOWN ISSUES:

=head3 Memory Allocation

Due to perl's methodology of allocating memory, you will not see memory 
freed back to general usage until perl exits after instancing this module. 
On each purge of the internal cache, the memory is retained by perl and 
reallocated internally as the cache grows again.

Consequently after the initial population and purge of the cache, the 
memory allocated should be of a relatively constant size.

=head3 Scalar Values

In the name of speed, there is no checking to see if the data being stored 
is complex or not. Technically you should be able to store complex memory 
structures, though this module is not designed for it and the ability is 
not guarenteed.

Use scalar data.

=head1 BUGS AND SOURCE

	Bug tracking for this module: https://rt.cpan.org/Dist/Display.html?Name=Cache-Bounded

	Source hosting: http://www.github.com/bennie/perl-Cache-Bounded

=head1 VERSION

    Cache::Bounded v1.09 (2015/06/18)

=head1 COPYRIGHT

    (c) 2004-2015, Phillip Pollard <bennie@cpan.org>

=head1 LICENSE

This source code is released under the "Perl Artistic License 2.0," the text of 
which is included in the LICENSE file of this distribution. It may also be 
reviewed here: http://opensource.org/licenses/artistic-license-2.0

=head1 AUTHORISHIP

    Original derived from Cache::Sloppy v1.3 2004/03/02
    With permission granted from Health Market Science, Inc.

=cut
