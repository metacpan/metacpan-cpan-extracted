package Data::Login;

use strict;
use warnings;

use DateTime;
use Error::Pure qw(err);
use Mo qw(build default is);
use Mo::utils 0.21 qw(check_array_object check_isa check_length check_number check_required);

our $VERSION = 0.03;

has hash_type => (
	is => 'ro',
);

has id => (
	is => 'ro',
);

has login_name => (
	is => 'ro',
);

has password_hash => (
	is => 'ro',
);

has roles => (
	default => [],
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

	# Check hash type.
	check_isa($self, 'hash_type', 'Data::HashType');
	check_required($self, 'hash_type');

	# Check id.
	check_number($self, 'id');

	# Check login_name.
	check_length($self, 'login_name', 50);
	check_required($self, 'login_name');

	# Check password_hash.
	check_length($self, 'password_hash', 128);
	check_required($self, 'password_hash');

	# Check roles.
	check_array_object($self, 'roles', 'Data::Login::Role', 'Roles');

	# Check valid_from.
	check_required($self, 'valid_from');
	check_isa($self, 'valid_from', 'DateTime');

	# Check valid_to.
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

Data::Login - Data object for login.

=head1 SYNOPSIS

 use Data::Login;

 my $obj = Data::Login->new(%params);
 my $hash_type = $obj->hash_type;
 my $id = $obj->id;
 my $login_name = $obj->login_name;
 my $password_hash = $obj->password_hash;
 my $roles_ar = $obj->roles;
 my $valid_from = $obj->valid_from;
 my $valid_to = $obj->valid_to;

=head1 DESCRIPTION

The intention of this module is to store information about the user logins.
User logins are active only within a certain time range, and we need a mechanism to
transition to others.

A real-world example is a database table that follows the same format as this data object,
with multiple records being valid at different times, e.g. for transfering of Digest from
obsolete version to new. Or planning of access to system from concrete date.

=head1 METHODS

=head2 C<new>

 my $obj = Data::Login->new(%params);

Constructor.

=over 8

=item * C<hash_type>

Hash type object.
Possible value is L<Data::HashType> object.
Parameter is required.
Default value is undef.

=item * C<id>

Id of record.
Id could be number.
It's optional.
Default value is undef.

=item * C<login_name>

Login name.
Maximal length of value is 50 characters.
It's required.

=item * C<password_hash>

Password hash.
Maximal length of value is 128 characters.
It's required.

=item * C<roles>

Login roles list.
Possible value is reference to array with L<Data::Login::Role> objects.
Parameter is optional.
Default value is [].

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

=head2 C<hash_type>

 my $hash_type = $obj->hash_type;

Get hash type.

Returns 0/1.

=head2 C<id>

 my $id = $obj->id;

Get hash type record id.

Returns number.

=head2 C<login_name>

 my $login_name = $obj->login_name;

Get login name.

Returns string.

=head2 C<password_hash>

 my $password_hash = $obj->password_hash;;

Get password hash.

Returns string.

=head2 C<roles>

 my $roles_ar = $obj->roles;

Get roles.

Returns reference to array with L<Data::Login::Role> objects.

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
         Parameter 'hash_type' is required.
         Parameter 'hash_type' must be a 'Data::HashType' object.
                 Value: %s
                 Reference: %s
         Parameter 'id' must be a number.
                 Value: %s
         Parameter 'login_name' has length greater than '50'.
                 Value: %s
         Parameter 'login_name' is required.
         Parameter 'password_hash' has length greater than '128'.
                 Value: %s
         Parameter 'password_hash' is required.
         Parameter 'roles' must be a array.
                 Value: %s
                 Reference: %s
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
         Roles isn't 'Data::Login::Role' object.
                 Value: %s
                 Reference: %s

=head1 EXAMPLE

=for comment filename=create_and_print_login.pl

 use strict;
 use warnings;

 use Data::HashType;
 use Data::Login;
 use Data::Login::Role;
 use DateTime;

 my $obj = Data::Login->new(
         'hash_type' => Data::HashType->new(
                 'id' => 1,
                 'name' => 'SHA-512',
                 'valid_from' => DateTime->new(
                         'day' => 1,
                         'month' => 1,
                         'year' => 2024,
                 ),
         ),
         'id' => 2,
         'login_name' => 'michal.josef.spacek',
         'password_hash' => '24ea354ebd9198257b8837fd334ac91663bf52c05658eae3c9e6ad0c87c659c62e43a2e1e5a1e573962da69c523bf1f680c70aedd748cd2b71a6d3dbe42ae972',
         'roles' => [
                 Data::Login::Role->new(
                         'active' => 1,
                         'id' => 1,
                         'role' => 'Admin',
                 ),
                 Data::Login::Role->new(
                         'active' => 1,
                         'id' => 2,
                         'role' => 'User',
                 ),
                 Data::Login::Role->new(
                         'active' => 0,
                         'id' => 3,
                         'role' => 'Bad',
                 ),
         ],
         'valid_from' => DateTime->new(
                 'day' => 1,
                 'month' => 1,
                 'year' => 2024,
         ),
 );

 # Print out.
 print 'Hash type: '.$obj->hash_type->name."\n";
 print 'Id: '.$obj->id."\n";
 print 'Login name: '.$obj->login_name."\n";
 print 'Password hash: '.$obj->password_hash."\n";
 print "Active roles:\n";
 print join "\n", map { $_->active ? ' - '.$_->role : () } @{$obj->roles};
 print "\n";
 print 'Valid from: '.$obj->valid_from->ymd."\n";

 # Output:
 # Hash type: SHA-512
 # Id: 2
 # Login name: michal.josef.spacek
 # Password hash: 24ea354ebd9198257b8837fd334ac91663bf52c05658eae3c9e6ad0c87c659c62e43a2e1e5a1e573962da69c523bf1f680c70aedd748cd2b71a6d3dbe42ae972
 # Active roles:
 #  - Admin
 #  - User
 # Valid from: 2024-01-01

=head1 DEPENDENCIES

L<DateTime>,
L<Error::Pure>,
L<Mo>,
L<Mo::utils>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Login>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
