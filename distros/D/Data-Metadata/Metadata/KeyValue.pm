package Data::Metadata::KeyValue;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils qw(check_required);
use Mo::utils::Number 0.08 qw(check_positive_natural);

our $VERSION = 0.01;

has id => (
	is => 'ro',
);

has key => (
	is => 'ro',
);

has value => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'id'.
	check_positive_natural($self, 'id');

	# Check 'key'.
	check_required($self, 'key');

	return;
}

=pod

=encoding utf8

=head1 NAME

Data::Metadata::KeyValue - Data object for one metadata key/value pair.

=head1 SYNOPSIS

 use Data::Metadata::KeyValue;

 my $obj = Data::Metadata::KeyValue->new(%params);
 my $id = $obj->id;
 my $key = $obj->key;
 my $value = $obj->value;

=head1 DESCRIPTION

This class represents one metadata item as a required key, optional value and
optional identifier.

=head1 METHODS

=head2 C<new>

 my $obj = Data::Metadata::KeyValue->new(%params);

Constructor.

=over 8

=item * C<id>

Id of key/value pair. The number is positive natural number.

It's optional.

=item * C<key>

Metadata key string.

It's required.

=item * C<value>

Metadata value string.

It's optional.

=back

Returns instance of object.

=head2 C<id>

 my $id = $obj->id;

Returns number or undef.

=head2 C<key>

 my $key = $obj->key;

Returns string.

=head2 C<value>

 my $value = $obj->value;

Returns string or undef.

=head1 ERRORS

 new():
         From Mo::utils::check_required():
                 Parameter 'key' is required.
         From Mo::utils::Number::check_positive_natural():
                 Parameter 'id' must be a positive natural number.
                         Value: %s

=head1 EXAMPLES

=head2 EXAMPLE

=for comment filename=data_metadata_keyvalue.pl

 use strict;
 use warnings;

 use Data::Metadata::KeyValue;

 my $obj = Data::Metadata::KeyValue->new(
         'id' => 7,
         'key' => 'text',
         'value' => 'This is text',
 );

 # Print out.
 print 'id: '.$obj->id."\n";
 print 'key: '.$obj->key."\n";
 print 'value: '.$obj->value."\n";

 # Output:
 # id: 7
 # key: text
 # value: This is text

=head1 DEPENDENCIES

L<Mo>
L<Mo::utils>,
L<Mo::utils::Number>.

=head1 SEE ALSO

=over

=item L<Data::Metadata>

Class containing multiple metadata key/value items.

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
