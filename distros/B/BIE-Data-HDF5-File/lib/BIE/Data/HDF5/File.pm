package BIE::Data::HDF5::File;
our $VERSION = '0.01';
use Moose;
use namespace::autoclean;
use v5.10;
use BIE::Data::HDF5 ':all';
use BIE::Data::HDF5::Path;

has 'h5File' => (
		 is => 'ro',
		 isa => 'Str',
		 required => 1,
		);

has 'fileID' => (
		 is => 'ro',
		 isa => 'Int',
		 writer => 'set_fileID',
		);

# 'loc' always tracks current location
has 'loc' => (
		is => 'rw',
		isa => 'Str',
		default => '/',
	       );

has 'locID' => (
		is => 'ro',
		writer => 'setLoc',
		isa => 'Int',
		lazy => 1,
		default => sub {
		  my $self = shift;
		  H5Gopen($self->fileID, '/');
		},
	       );

around 'loc' => sub {
  my $orig = shift;
  my $self = shift;
  return $self->$orig
    unless @_;

  my $p = shift;
  my $newLocID = H5Gopen($self->locID, $p);
  if ($newLocID >= 0) {
    H5Gclose($self->locID);
    $self->setLoc($newLocID);
    $self->$orig(h5name($newLocID));
  }
};

sub pwd {
  my $self = shift;
  BIE::Data::HDF5::Path->new(id => H5Gopen($self->fileID, $self->loc));
}

sub list {
  my $self = shift;
  h5ls($self->locID);
}

sub cd {
  my $self = shift;
  if (@_) {
    my $p = shift;
    $self->loc($p);
  }
  $self->pwd;
}

sub BUILD {
  my $self = shift;
  if (-e $self->h5File) {
    $self->set_fileID(H5Fopen($self->h5File));
  } else {
    $self->set_fileID(H5Fcreate($self->h5File));
  }
}

sub DEMOLISH {
  my $self = shift;
  H5Gclose($self->locID);
  H5Fclose($self->fileID);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

BIE::Data::HDF5::File - Perl extension for blah with HDF5 file.

=head1 SYNOPSIS

  use BIE::Data::HDF5::File;
  my $h5 = BIE::Data::HDF5::File->new(h5File => $HDF5file);

=head1 DESCRIPTION

BIE::Data::HDF5::File is a module for dealing with HDF5 file written with great help from Moose.

=head2 ATTRIBUTES AND METHODS

=over

=item *

"h5File": The required argument for constructing a new BIE::Data::HDF5::File object.

=item *

"loc": Always return current location in HDF5 data file.

=item *

"pwd": Return a BIE::Data::HDF5::Path object for more path related operations.

=item *

"list": Return the list of all entries under current path in HDF5 data file.

=item *

"cd": Enter a new location in HDF5 data file.

=back

=head1 SEE ALSO

L<BIE::Data::HDF5::Path>

L<BIE::Data::HDF5::Data>

L<BIE::App::PacBio> See this module for a live example.

=head1 AUTHOR

Xin Zheng, E<lt>xin@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Xin Zheng

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
