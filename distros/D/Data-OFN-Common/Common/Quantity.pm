package Data::OFN::Common::Quantity;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils qw(check_required);
use Mo::utils::CEFACT 0.02 qw(check_cefact_unit);
use Mo::utils::Number qw(check_number);

our $VERSION = 0.02;

has unit => (
	is => 'ro',
);

has value => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'unit'.
	check_required($self, 'unit');
	check_cefact_unit($self, 'unit');

	# Check 'value'.
	check_required($self, 'value');
	check_number($self, 'value');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::OFN::Common::Quantity - OFN common data object for quantity.

=head1 SYNOPSIS

 use Data::OFN::Common::Quantity;

 my $obj = Data::OFN::Common::Quantity->new(%params);
 my $unit = $obj->unit;
 my $value = $obj->value;

=head1 DESCRIPTION

Immutable data object for OFN (Otevřené formální normy) representation of
quantity in the Czech Republic.

This object is actual with L<2020-07-01|https://ofn.gov.cz/z%C3%A1kladn%C3%AD-datov%C3%A9-typy/2020-07-01/#mno%C5%BEstv%C3%AD>
version of OFN basic data types standard.

=head1 METHODS

=head2 C<new>

 my $obj = Data::OFN::Common::Quantity->new(%params);

Constructor.

=over 8

=item * C<unit>

Quantity unit defined by UN/CEFACT unit common code.

It's required.

Default value is undef.

=item * C<value>

Quantity value in some number form.

It's required.

Default value is undef.

=back

Returns instance of object.

=head2 C<unit>

 my $unit = $obj->unit;

Get UN/CEFACT unit common code.

Returns string.

=head2 C<value>

 my $value = $obj->value;

Get value.

Returns number.

=head1 ERRORS

 new():
         From Mo::utils::check_required():
                 Parameter 'unit' is required.
                 Parameter 'value' is required.
         From Mo::utils::CEFACT::check_cefact_unit():
                 Parameter 'unit' must be a UN/CEFACT unit common code.
                         Value: %s
         From Mo::utils::Number::check_number():
                 Parameter 'value' must be a number.
                         Value: %s

=head1 EXAMPLE1

=for comment filename=quantity_kilogram.pl

 use strict;
 use warnings;

 use Data::OFN::Common::Quantity;

 my $obj = Data::OFN::Common::Quantity->new(
         'value' => 1,
         'unit' => 'KGM',
 );

 # Print out.
 print 'Value: '.$obj->value."\n";
 print 'Unit: '.$obj->unit."\n";

 # Output:
 # Value: 1
 # Unit: KGM

=head1 DEPENDENCIES

L<Error::Pure>
L<Mo>,
L<Mo::utils>,
L<Mo::utils::CEFACT>,
L<Mo::utils::Number>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-OFN-Common>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
