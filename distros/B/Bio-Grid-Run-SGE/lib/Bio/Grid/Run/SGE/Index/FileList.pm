package Bio::Grid::Run::SGE::Index::FileList;

use Mouse;

use warnings;
use strict;
use Carp;
use Storable qw/retrieve/;
use List::MoreUtils qw/uniq/;
use Bio::Grid::Run::SGE::Util qw/glob_list/;
extends 'Bio::Grid::Run::SGE::Index::List';

our $VERSION = '0.066'; # VERSION

around 'create' => sub {
  my $orig = shift;
  my $self = shift;

  my $file_name_elements = shift;

  my $file_name_elements_abs = glob_list($file_name_elements);

  return $self->$orig($file_name_elements_abs);
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Bio::Grid::Run::SGE::Index::FileList - Creates an index from a list of files

=head1 SYNOPSIS

  my $idx = Bio::Grid::Run::SGE::Index::FileList->new(
    'writeable' => 1,
    'idx_file'  => '/tmp/example_file_index'
  );

  my @files = (...);
  $idx->create( \@files );

  my $number_of_elements = $idx->num_elem, 3 );    # is equal to the number of files in @files

  for ( my $i = 0; $i < $number_of_elements; $i++ ) {
      my $data = $idx->get_elem($i);
  }

=head1 DESCRIPTION

=head1 OPTIONS

=head1 SUBROUTINES
=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
