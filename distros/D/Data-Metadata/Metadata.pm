package Data::Metadata;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils::Array qw(check_array_object check_array_required);
use Mo::utils::Number 0.08 qw(check_positive_natural);

our $VERSION = 0.01;

has id => (
	is => 'ro',
);

has key_values => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'id'.
	check_positive_natural($self, 'id');

	# Check 'key_values'.
	check_array_object($self, 'key_values', 'Data::Metadata::KeyValue');
	check_array_required($self, 'key_values');

	return;
}

=pod

=encoding utf8

=head1 NAME

Data::Metadata - Data object for metadata.

=head1 SYNOPSIS

 use Data::Metadata;

 my $obj = Data::Metadata->new(%params);
 my $id = $obj->id;
 my $key_values_ar = $obj->key_values;

=head1 DESCRIPTION

This class represents metadata as an optional identifier and a required list
of L<Data::Metadata::KeyValue> instances.

=head1 METHODS

=head2 C<new>

 my $obj = Data::Metadata->new(%params);

Constructor.

=over 8

=item * C<id>

Object id. The number is positive natural number.

It's optional.

=item * C<key_value>

Reference to array with L<Data::Metadata::KeyValue> instances.

It's required.

=back

Returns instance of object.

=head2 C<id>

 my $id = $obj->id;

Returns number or undef.

=head2 C<key_values>

 my $key_values_ar = $obj->key_values;

Returns reference to array with L<Data::Metadata::KeyValue> instances.

=head1 ERRORS

 new():
         From Mo::utils::Array::check_array_required():
                 Parameter 'key_values' is required.
                 Parameter 'key_values' with array must have at least one item.
         From Mo::utils::Array::check_array_object():
                 Parameter 'key_values' must be a array.
                         Value: %s
                         Reference: %s
                 Parameter 'key_values' must contain 'Data::Metadata::KeyValue' objects.
                         Value: %s
                         Reference: %s
         From Mo::utils::Number::check_positive_natural():
                 Parameter 'id' must be a positive decimal number.
                         Value: %s

=head1 EXAMPLES

=head2 EXAMPLE

=for comment filename=data_metadata.pl

 use strict;
 use warnings;

 use Data::Metadata;
 use Data::Metadata::KeyValue;

 my $obj = Data::Metadata->new(
         'id' => 7,
         'key_values' => [
                 Data::Metadata::KeyValue->new(
                         'id' => 1,
                         'key' => 'text',
                         'value' => 'This is text',
                 ),
         ],
 );

 # Print out.
 print 'Id: '.$obj->id."\n";
 print 'Number of key/value items: '.scalar @{$obj->key_values}."\n";

 # Output:
 # Id: 7
 # Number of key/value items: 1

=head1 DEPENDENCIES

L<Mo>
L<Mo::utils::Array>,
L<Mo::utils::Number>.

=head1 SEE ALSO

=over

=item L<Data::Metadata::KeyValue>

Class for one metadata key/value pair.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Metadata>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025-2026 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut

1;
