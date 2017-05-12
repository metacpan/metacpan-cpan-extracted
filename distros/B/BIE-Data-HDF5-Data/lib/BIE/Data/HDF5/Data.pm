package BIE::Data::HDF5::Data;
our $VERSION = '0.01';
use Moose;
use namespace::autoclean;
use v5.10;
use BIE::Data::HDF5 ':all';

has 'name' => (
	       is => 'ro',
	       isa => 'Str',
	       lazy => 1,
	       default => sub {
		 my $self = shift;
		 h5name($self->id);
	       },
);

has 'id' => (
	     is => 'ro',
	     isa => 'Int',
	     required => 1,
);

has 'code' => (
	       is => 'ro',
	       isa => 'Str',
	       lazy => 1,
	       default => sub {
		 my $self = shift;
		 getH5DCode($self->id);
	       },
	      );

has 'value' => (
		is => 'ro',
		lazy => 1,
		default => sub {
		  my $self = shift;
		  H5Dread($self->id);
		},
	       );

has 'dType' => (
	       is => 'ro',
	       isa => 'Int',
);

has 'mType' => (
	       is => 'ro',
	       isa => 'Int',
);

has 'space' => (
		is => 'ro',
		isa => 'Int',
);

has 'size' => (
	       is => 'ro',
	       isa => 'Int'
);

sub read {
  my $self = shift;
  my @val = unpack $self->code, $self->value;
  return \@val;
}

sub DEMOLISH {
  my $self = shift;
  H5Dclose($self->id);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

BIE::Data::HDF5::Data - Perl extension for blah with datasets in HDF5.

=head1 SYNOPSIS

  use BIE::Data::HDF5::Data;

=head1 DESCRIPTION

BIE::Data::HDF5::Data is an interface to operate datasets in 
B<HDF5> format.

=head2 ATTRIBUTES AND METHODS

=over

=item *

"name": Dataset name.

=item *

"id": Dataset id.

=item *

"code": Data type code.

=item *

"read": Read data value.

=back

=head1 SEE ALSO

L<BIE::Data::HDF5::Path>

L<BIE::Data::HDF5::File>

L<BIE::App::PacBio> See this module for a live example.

=head1 AUTHOR

Xin Zheng, E<lt>zhengxin@mail.nih.govE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Xin Zheng

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
