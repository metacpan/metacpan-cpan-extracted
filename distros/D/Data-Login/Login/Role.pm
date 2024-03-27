package Data::Login::Role;

use strict;
use warnings;

use DateTime;
use Error::Pure qw(err);
use Mo qw(build default is);
use Mo::utils qw(check_bool check_isa check_length check_number check_required);

our $VERSION = 0.03;

has active => (
	default => 1,
	is => 'ro',
);

has id => (
	is => 'ro',
);

has role => (
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

	# Check active.
	check_bool($self, 'active');

	# Check id.
	check_number($self, 'id');

	# Check role.
	check_length($self, 'role', '100');
	check_required($self, 'role');

	# Check valid_from.
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

Data::Login::Role - Data object for login role.

=head1 SYNOPSIS

 use Data::Login::Role;

 my $obj = Data::Login::Role->new(%params);
 my $action = $obj->action;
 my $id = $obj->id;
 my $role = $obj->role;
 my $valid_from = $obj->valid_from;
 my $valid_to = $obj->valid_to;

=head1 METHODS

=head2 C<new>

 my $obj = Data::Login::Role->new(%params);

Constructor.

=over 8

=item * C<active>

I<It will be removed in near future.>

Active flag.
It's boolean.
Default value is 1.

=item * C<id>

Id of record.
Id could be number.
It's optional.
Default value is undef.

=item * C<role>

Role name.
Maximal length of value is 100 characters.
It's required.

=item * C<valid_from>

I<It will be required in near future. Optional is because backward
compatibility.>

Date and time of start of use.
Must be a L<DateTime> object.
It's optional.

=item * C<valid_to>

Date and time of end of use. An undefined value means it is in use.
Must be a L<DateTime> object.
It's optional.

=back

Returns instance of object.

=head2 C<active>

 my $active = $obj->active;

I<It will be removed in near future.>

Get active flag.

Returns 0/1.

=head2 C<id>

 my $id = $obj->id;

Get login role record id.

Returns number.

=head2 C<role>

 my $role = $obj->role;

Get role name.

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
         Parameter 'active' must be a bool (0/1).
                 Value: %s
         Parameter 'id' must be a number.
                 Value: %s
         Parameter 'role' has length greater than '100'.
                 Value: %s
         Parameter 'role' is required.
         Parameter 'valid_from' must be a 'DateTime' object.
                 Value: %s
                 Reference: %s
         Parameter 'valid_to' must be a 'DateTime' object.
                 Value: %s
                 Reference: %s
         Parameter 'valid_to' must be older than 'valid_from' parameter.
                 Value: %s
                 Valid from: %s

=head1 EXAMPLE

=for comment filename=create_and_print_login_role.pl

 use strict;
 use warnings;

 use Data::Login::Role;

 my $obj = Data::Login::Role->new(
         'id' => 2,
         'role' => 'admin',
         'valid_from' => DateTime->new(
                 'day' => 1,
                 'month' => 1,
                 'year' => 2024,
         ),
         'valid_from' => DateTime->new(
                 'day' => 31,
                 'month' => 12,
                 'year' => 2024,
         ),
 );

 # Print out.
 print 'Id: '.$obj->id."\n";
 print 'Role: '.$obj->role."\n";
 print 'Valid from: '.$obj->valid_from->ymd."\n";
 print 'Valid to: '.$obj->valid_from->ymd."\n";

 # Output:
 # Id: 2
 # Role: admin
 # Valid from: 2024-01-01
 # Valid to: 2024-12-31

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
