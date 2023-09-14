package Data::HashType;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils qw(check_bool check_length check_number check_required);

our $VERSION = 0.02;

has active => (
	is => 'ro',
);

has id => (
	is => 'ro',
);

has name => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check active.
	if (! defined $self->{'active'}) {
		$self->{'active'} = 1;
	}
	check_bool($self, 'active');

	# Check id.
	check_number($self, 'id');

	# Check hash name.
	check_required($self, 'name');
	check_length($self, 'name', 50);

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
 my $active = $obj->active;
 my $id = $obj->id;
 my $name = $obj->name;

=head1 METHODS

=head2 C<new>

 my $obj = Data::HashType->new(%params);

Constructor.

=over 8

=item * C<active>

Flag for activity of hash type.
Possible valuea are 0/1.
Default value is 1 (active).

=item * C<id>

Id of record.
Id could be number.
It's optional.
Default value is undef.

=item * C<name>

Hash type name.
Maximal length of value is 50 characters.
It's required.

=back

Returns instance of object.

=head2 C<active>

 my $active = $obj->active;

Get active flag.

Returns 0/1.

=head2 C<id>

 my $id = $obj->id;

Get hash type record id.

Returns number.

=head2 C<name>

 my $name = $obj->name;

Get hash type name.

Returns string.

=head1 ERRORS

 new():
         Parameter 'active' must be a bool (0/1).
                 Value: %s
         Parameter 'id' must be a number.
                 Value: %s
         Parameter 'name' has length greater than '50'.
                 Value: %s
         Parameter 'name' is required.

=head1 EXAMPLE

=for comment filename=create_and_print_hash_type.pl

 use strict;
 use warnings;

 use Data::HashType;

 my $obj = Data::HashType->new(
         'active' => 1,
         'id' => 10,
         'name' => 'SHA-256',
 );

 # Print out.
 print 'Name: '.$obj->name."\n";
 print 'Active: '.$obj->active."\n";
 print 'Id: '.$obj->id."\n";

 # Output:
 # Name: SHA-256
 # Active: 1
 # Id: 10

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-HashType>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
