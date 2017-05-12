package BIE::Data::HDF5::Path;
our $VERSION = '0.01';
use Moose;
use namespace::autoclean;
use v5.10;
use BIE::Data::HDF5 ':all';
use BIE::Data::HDF5::Data;

has 'id' => (
	     is => 'ro',
	     isa => 'Int',
	     required => 1,
	    );

has 'name' => (
	       is => 'ro',
	       isa => 'Str',
	       lazy => 1,
	       default => sub {
		 my $self = shift;
		 h5name($self->id);
	       },
	      );

#only support relative path currently
sub mkPath {
  my ($self, $path) = @_;
  my @parts = split /\b\/\b/, $path;
  my $tmp1 = H5Gcreate($self->id, $parts[0]);
  for my $p (@parts[1..$#parts]) {
    my $tmp2 = $tmp1;
    $tmp1 = H5Gcreate($tmp2, $p);
    H5Gclose($tmp2);
  }
  H5Gclose($tmp1);			 
}

sub list {
  my $self = shift;
  h5ls($self->id);
}

sub cd {
  my $self = shift;
  if (@_) {
    my $p = shift;
    BIE::Data::HDF5::Path->new(id => H5Gopen($self->id, $p));
  }
}

sub openData {
  my $self = shift;
  if (@_) {
    BIE::Data::HDF5::Data->new(
			       id => H5Dopen($self->id, shift),
			      );
  }
  else {
    undef;
  }
}

sub DEMOLISH {
  my $self = shift;
  H5Gclose($self->id);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

BIE::Data::HDF5::Path - Perl extension for walking around in HDF5 files.

=head1 SYNOPSIS

  use BIE::Data::HDF5::Path;

  my $h5file = BIE::Data::HDF5::Path->new("data.h5");
  #only support creation of relative group name currently
  $h5file->mkPath("newPath/newSubPath/newSubSubPath");
  #both relative and absolute group names work when set new path
  $h5file->path("newPath");
  $h5file->path("/newPath/newSubPath");

=head1 DESCRIPTION

BIE::Data::HDF5::Path is a module for operation of locations in HDF5 data file.

=head2 ATTRIBUTES AND METHODS

=over

=item *

"id": The ID of the path.

=item *

"mkPath": Create a new location in HDF5 File. Only accept relative path now.

=item *

"list": List all entries under the path.

=item *

"cd": Enter another path. Return a BIE::Data::HDF5::Path object if successfully.

=item *

"openData": Return a BIE::Data::HDF5::Data if successfully.

=back

=head1 SEE ALSO

L<BIE::Data::HDF5::File>

L<BIE::Data::HDF5::Data>

L<BIE::App::PacBio> See this module for a live example.

=head1 AUTHOR

Xin Zheng, E<lt>zhengxin@mail.nih.govE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Xin Zheng

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
