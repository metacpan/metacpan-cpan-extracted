#
# This file is part of Data-Importer
#
# This software is copyright (c) 2014 by Kaare Rasmussen.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Test::Import::Products;

use 5.010;
use namespace::autoclean;
use Moose;
use MooseX::Traits;

extends 'Data::Importer';

=head1 METHODS

=head2 handle_row

Validates input

Called for each row in the input file

=cut

sub validate_row {
	my ($self, $row, $lineno) = @_;
	#product
	my %prow = ( %$row );
	$self->add_row(\%prow);
}

=head2 import_row

Performs the actual database update

=cut

sub import_row {
	my ($self, $row) = @_;
	return unless $row->{item_name};

	my $schema = $self->schema;

	my $data = {
		name => $row->{item_name},
		ingredients => $row->{ingredients},
		qty => $row->{qty},
	};
	$schema->resultset('Product')->create($data) or die;
}

__PACKAGE__->meta->make_immutable;

#
# This file is part of Data-Importer
#
# This software is copyright (c) 2014 by Kaare Rasmussen.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

__END__
