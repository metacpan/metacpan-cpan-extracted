package Data::HashType;

use strict;
use warnings;

use DateTime;
use Error::Pure qw(err);
use Mo qw(build is);
use Mo::utils 0.28 qw(check_isa check_length check_required);
use Mo::utils::Number qw(check_positive_natural);

our $VERSION = 0.07;

has id => (
	is => 'ro',
);

has name => (
	is => 'ro',
);

has valid_from => (
	is => 'ro',
);

has valid_to => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'id'.
	check_positive_natural($self, 'id');

	# Check 'name'.
	check_required($self, 'name');
	check_length($self, 'name', 50);

	# Check 'valid_from'.
	check_required($self, 'valid_from');
	check_isa($self, 'valid_from', 'DateTime');

	# Check 'valid_to'.
	check_isa($self, 'valid_to', 'DateTime');
	if (defined $self->{'valid_to'}
		&& DateTime->compare($self->{'valid_from'}, $self->{'valid_to'}) != -1) {

		err "Parameter 'valid_to' must be older than 'valid_from' parameter.",
			'Value', $self->{'valid_to'},
			'Valid from', $self->{'valid_from'},
		;
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::HashType - Data object for hash type.

=head1 SYNOPSIS

 use Data::HashType;

 my $obj = Data::HashType->new(%params);
 my $id = $obj->id;
 my $name = $obj->name;
 my $valid_from = $obj->valid_from;
 my $valid_to = $obj->valid_to;

=head1 DESCRIPTION

The intention of this module is to store information about the usage of digests.
Digests are active only within a certain time range, and we need a mechanism to
transition to others.

A real-world example is a database table that follows the same format as this data object,
with multiple records being valid at different times, while other database tables
have relations to this table.

=head1 METHODS

=head2 C<new>

 my $obj = Data::HashType->new(%params);

Constructor.

=over 8

=item * C<id>

Id of record.
Id could be number.
It's optional.
Default value is undef.

=item * C<name>

Hash type name.
Maximal length of value is 50 characters.
It's required.

=item * C<valid_from>

Date and time of start of use.
Must be a L<DateTime> object.
It's required.

=item * C<valid_to>

Date and time of end of use. An undefined value means it is in use.
Must be a L<DateTime> object.
It's optional.

=back

Returns instance of object.

=head2 C<id>

 my $id = $obj->id;

Get hash type record id.

Returns number.

=head2 C<name>

 my $name = $obj->name;

Get hash type name.

Returns string.

=head2 C<valid_from>

 my $valid_from = $obj->valid_from;

Get date and time of start of use.

Returns L<DateTime> object.

=head2 C<valid_to>

 my $valid_to = $obj->valid_to;

Get date and time of end of use.

Returns L<DateTime> object or undef.

=head1 ERRORS

 new():
         From Mo::utils:
                 Parameter 'name' has length greater than '50'.
                         Value: %s
                 Parameter 'name' is required.
                 Parameter 'valid_from' is required.
                 Parameter 'valid_from' must be a 'DateTime' object.
                         Value: %s
                         Reference: %s
                 Parameter 'valid_to' must be a 'DateTime' object.
                         Value: %s
                         Reference: %s
                 Parameter 'valid_to' must be older than 'valid_from' parameter.
                         Value: %s
                         Valid from: %s

         From Mo::utils::Number::check_positive_natural():
                 Parameter 'id' must be a positive natural number.

=head1 EXAMPLE

=for comment filename=create_and_print_hash_type.pl

 use strict;
 use warnings;

 use Data::HashType;
 use DateTime;

 my $obj = Data::HashType->new(
         'id' => 10,
         'name' => 'SHA-256',
         'valid_from' => DateTime->new(
                 'year' => 2024,
                 'month' => 1,
                 'day' => 1,
         ),
 );

 # Print out.
 print 'Name: '.$obj->name."\n";
 print 'Id: '.$obj->id."\n";
 print 'Valid from: '.$obj->valid_from->ymd."\n";

 # Output:
 # Name: SHA-256
 # Id: 10
 # Valid from: 2024-01-01

=head1 DEPENDENCIES

L<DateTime>,
L<Error::Pure>,
L<Mo>,
L<Mo::utils>,
L<Mo::utils::Number>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-HashType>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.07

=cut
