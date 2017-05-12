package Bio::Grid::Run::SGE::Index::Dummy;

use Mouse;

use warnings;
use strict;

use POSIX qw/ceil/;

our $VERSION = '0.042'; # VERSION

has idx => (is => 'rw', default => sub { [ 'a'..'z' ] });
has idx_file  => ( is => 'rw', required => 0 );
has _is_created => (is => 'rw');

with 'Bio::Grid::Run::SGE::Role::Indexable';


sub get_elem {
    my ($self, $i) = @_;

    confess "Index not created, yet. You have to call the create function" unless($self->_is_created);
    my $chunk_size = $self->chunk_size;

    my $num_elem = $self->num_elem;

    my $elems_from = $i * $chunk_size;
    my $elems_to = $elems_from + $chunk_size -1 > @{$self->idx} ? @{$self->idx} - 1 : $elems_from + $chunk_size -1;

    return join("", @{$self->idx}[$elems_from .. $elems_to]);
}

sub type {
    return;
}

sub create {
  my ($self) = @_;
  $self->_is_created(1);
  
    return $self;
}

sub num_elem {
    my ($self) = @_;

    confess "Index not created, yet. You have to call the create function" unless($self->_is_created);
    
    my $num = scalar @{$self->idx};

    my $size = ceil($num/$self->chunk_size);

    return $size;
}


sub close { return $_[0]}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Bio::Grid::Run::SGE::Index::Dummy - dummy index for testing purposes

=head1 SYNOPSIS

  use Bio::Grid::Run::SGE::Index::Dummy;

  my $idx = Bio::Grid::Run::SGE::Index::Dummy->new( idx_file => undef )->create;
  my @letters = ( 'a' .. 'z' );
  for ( my $i = 0; $i < $idx->num_elem; $i++ ) {
    is( $idx->get_elem($i), $letters[$i] );
  }

=head1 DESCRIPTION

This index contains the letters of the alphabet (a-z), hardcoded. The first element corresponds to 'a'. If you create an iterator class, it might be usfull for testing purposes.

=head1 METHODS

=over 4

=item B<< $idx = $idx->create() >>

Creates the index. You need to call it, before you want to use the index. Returns the index object.

=item B<< $idx = $idx->close() >>

Does nothing. Returns the index object.

=item B<< $number_of_elements = $idx->num_elem() >>

Returns the number of elements. This number is not fixed, because the number of elements depends on the chunk size.

=item B<< $idx->type >>

Does nothing.

=item B<< $elem = $idx->get_elem($element_index) >>

returns the element at index position C<$element_index>.

=back


=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
