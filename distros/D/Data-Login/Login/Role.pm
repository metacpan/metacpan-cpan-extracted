package Data::Login::Role;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils qw(check_bool check_length check_number check_required);

our $VERSION = 0.01;

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

sub BUILD {
	my $self = shift;

	# Check active.
	check_bool($self, 'active');

	# Check id.
	check_number($self, 'id');

	# Check role.
	check_length($self, 'role', '100');
	check_required($self, 'role');

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

=head1 METHODS

=head2 C<new>

 my $obj = Data::Login::Role->new(%params);

Constructor.

=over 8

=item * C<active>

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

=back

Returns instance of object.

=head2 C<active>

 my $active = $obj->active;

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

=head1 ERRORS

 new():
         Parameter 'active' must be a bool (0/1).
                 Value: %s
         Parameter 'id' must be a number.
                 Value: %s
         Parameter 'role' has length greater than '100'.
                 Value: %s
         Parameter 'role' is required.

=head1 EXAMPLE

=for comment filename=create_and_print_login_role.pl

 use strict;
 use warnings;

 use Data::Login::Role;

 my $obj = Data::Login::Role->new(
         'active' => 1,
         'id' => 2,
         'role' => 'admin',
 );

 # Print out.
 print 'Active flag: '.$obj->active."\n";
 print 'Id: '.$obj->id."\n";
 print 'Role: '.$obj->role."\n";

 # Output:
 # Active flag: 1
 # Id: 2
 # Role: admin

=head1 DEPENDENCIES

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

0.01

=cut
