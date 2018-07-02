package Bio::Grid::Run::SGE::Role::Indexable;

use Mouse::Role;

use warnings;
use strict;

use Storable qw/nstore retrieve/;
use Bio::Grid::Run::SGE::Util qw/my_glob/;
use Bio::Gonzales::Util::Log;

our $VERSION = '0.064'; # VERSION

requires qw/num_elem create get_elem type close/;

has writeable => ( is => 'rw' );
has idx_file  => ( is => 'rw', required => 1 );
has idx       => ( is => 'rw', default => sub { [] } );
has chunk_size => ( is => 'ro', default => 1 );
has _reindexing_necessary => ( is => 'rw' );
has _internal_info        => ( is => 'rw', default => sub { {} } );
has log                   => ( is => 'rw', default => sub { Bio::Gonzales::Util::Log->new } );

sub _load_index {
  my ($self) = @_;

  my $idx = retrieve $self->idx_file;
  if ( !ref $idx eq 'HASH' ) {
    $self->log->warn("existing index is in old format, REINDEXING NECESSARY");
    $self->_reindexing_necessary(1);
  }

  if ( $idx->{class} ne blessed($self) ) {
    $self->log->warn( "existing index is of type "
        . $idx->{class}
        . " and not of type "
        . blessed($self)
        . ", REINDEXING NECESSARY" );
    $self->_reindexing_necessary(1);
  }
  if ( !$idx->{chunk_size} || $self->chunk_size != $idx->{chunk_size} ) {
    $self->log->warn("chunk_size differs between old index and new index, REINDEXING NECESSARY");
    $self->_reindexing_necessary(1);
  }
  unless ( $self->_reindexing_necessary ) {
    $self->idx( $idx->{data} );
    $self->_internal_info( $idx->{internal_info} ) if ( defined( $idx->{internal_info} ) );
  }

  return;
}

#sub BUILD { }
#after BUILD => sub {
#my ($self) = @_;

#};

sub _store {
  my ($self) = @_;

  nstore(
    {
      data          => $self->idx,
      chunk_size    => $self->chunk_size,
      class         => blessed($self),
      internal_info => $self->_internal_info
    },
    $self->idx_file
  );
}

sub _check_range_fatal {
  my ( $self, @range ) = @_;

  my $num_elem = $self->num_elem;
  confess "Given range NOT VALID range: $range[0]-$range[1], entries: $num_elem"
    if ( @range < 2
    || $num_elem < $range[0] + 1
    || $num_elem < $range[1] + 1
    || $range[0] < 0
    || $range[1] < 0 );

  if ( @range >= 3 ) {
    confess "Given range NOT VALID extra element: $range[2], entries: $num_elem"
      if ( $num_elem < $range[2] + 1 || $range[2] < 0 );
  }
  return;
}

1;

__END__

=head1 NAME

Bio::Grid::Run::SGE::Role::Indexable - Basic role for all indices

=head1 SYNOPSIS

  use Mouse;

  with 'Bio::Grid::Run::SGE::Role::Indexable';

  # you have to implement these methods
  sub num_elem { ... }
  sub create { ... }
  sub get_elem { ... }
  sub type { ... }
  sub close { ... }

=head1 DESCRIPTION

This role provides (and requires) the basic functionality every index must have.

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<< $idx->writeable >>

You can open the index in writable or in read only mode.

=item B<< $idx->idx_file >>

Every index needs a file to store the index raw data.

=item B<< $idx->idx >>

This attribute gives access to the raw index in memory.

=item B<< $idx->chunk_size >>

It returns or sets the chunk size. The chunk size determins the number of
atomic elements glued together in one index element.

=back

=head1 REQUIRED METHODS

=over 4

=item B<< $idx->num_elem() >>

Return the number of elements in the index.

=item B<< $idx->create(...) >>

Create the index, in C<...> you might have to supply additional arguments,
such as file names. This function is dependent on the class implementing it.

=item B<< $idx->get_elem() >>

Retrieve a certain element from the index. Zero-based.

=item B<< $idx->type() >>

Not used, yet.

=item B<< $idx->close() >>

Close the index.

=item B<< $idx->type() >>

Indicates if L<Bio::Grid::Run::SGE> should store the data returned by the
index in a tempoary file and delete it afterwards, or not.

Returns one of three different options:

=over 4

=item C<undef> or C<tmp>

The index extracts chunks of data and returns them. An example would be a
sequence from a fasta file. Usually the data is stored in a tempoary file and
the file is deleted after the task.

L<Bio::Grid::Run::SGE> stores retrieved elements in a tempoary file.

L<Bio::Grid::Run::SGE> DELETES the tempoary file after the task finished.

=item C<direct>

The index is returning not data, but information. This might be something like a
number, if the index is supposed to iterate through a range of numbers. It
could also be a file name to already existing files on the cluster.

L<Bio::Grid::Run::SGE> supplies retrieved elements directly to a cluster script.

L<Bio::Grid::Run::SGE> DOES NOT TRY TO DELETE a tempoary file after the task finished.

=back

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
