package Bio::Grid::Run::SGE::Index::ListFromFile;

use Mouse;

use warnings;
use strict;
use Carp;
use Storable qw/retrieve/;
use List::MoreUtils qw/uniq/;
use Bio::Gonzales::Util::File qw/gonzopen/;

extends 'Bio::Grid::Run::SGE::Index::List';

our $VERSION = '0.060'; # VERSION

around 'create' => sub {
  my $orig = shift;
  my $self = shift;

  my $files = shift;

  # check here again (even though the parent class checks, too)
  # because we want to skip the file reading, also
  return $self if ( $self->_is_indexed );

  my @elements;
  for my $f (@$files) {
    my $fh = gonzopen( $f, '<' );
    while (<$fh>) {
      chomp;
      push @elements, $_;
    }
    $fh->close;
  }

  return $self->$orig( \@elements );
};

__PACKAGE__->meta->make_immutable;
1;
