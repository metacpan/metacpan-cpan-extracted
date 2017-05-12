## no critic (RCS,VERSION)
package Class::User::DBI::RolePrivileges;

use strict;
use warnings;

use Carp;

use Class::User::DBI::DB qw( db_run_ex  %RP_QUERY );
use Class::User::DBI::Roles;
use Class::User::DBI::Privileges;

our $VERSION = '0.10';
# $VERSION = eval $VERSION;    ## no critic (eval)

# Table is role, privilege.
# Table allows duplicate roles, but not duplicate role/priv.

# Class methods.

sub new {
    my ( $class, $conn, $role ) = @_;
    croak 'Constructor called without a DBIx::Connector object.'
      if !ref $conn || !$conn->isa('DBIx::Connector');
    my $self = bless {}, $class;
    $self->{_db_conn} = $conn;
    my $r = Class::User::DBI::Roles->new( $self->_db_conn );
    croak 'Constructor called without passing a valid role by name.'
      if !defined $role
          || !length $role
          || !$r->exists_role($role);
    $self->{role} = $role;
    return $self;
}

sub configure_db {
    my ( $class, $conn ) = @_;
    croak 'Must provide a valid constructor object.'
      if !ref $conn || !$conn->isa('DBIx::Connector');
    $conn->run(
        fixup => sub {
            $_->do( $RP_QUERY{SQL_configure_db_cud_roleprivs} );
        }
    );
    return 1;
}

# Object methods.

sub _db_conn {
    my $self = shift;
    return $self->{_db_conn};
}

sub get_role {
    my $self = shift;
    return $self->{role};
}

# Usage:
# $role->exists_role( $some_role );
# returns 0 or 1.
sub has_privilege {
    my ( $self, $privilege ) = @_;
    croak 'Must pass a non-empty value in privilege test.'
      if !length $privilege;
    my $p = Class::User::DBI::Privileges->new( $self->_db_conn );
    return 0
      if !$p->exists_privilege($privilege);
    return 1
      if exists $self->{privileges}{$privilege}
          && $self->{privileges}{$privilege};
    my $sth = db_run_ex( $self->_db_conn, $RP_QUERY{SQL_exists_priv},
        $self->get_role, $privilege );
    my $result = defined $sth->fetchrow_array;
    $self->{privileges}{$privilege}++ if $result;    # Cache the result.

    return $result;
}

# Usage:
# $r->add_privileges( qw( privileges ) );
# Returns the number of privileges actually added to the role.

sub add_privileges {
    my ( $self, @privileges ) = @_;
    my $p = Class::User::DBI::Privileges->new( $self->_db_conn );
    my @privileges_to_insert = grep {
             defined $_
          && length $_
          && $p->exists_privilege($_)
          && !$self->has_privilege($_)
    } @privileges;
    $self->{privileges}{$_}++ for @privileges_to_insert;    # Cache.
      # Transform the array of privileges to an AoA of [ $role, $priv ] packets.
    @privileges_to_insert =
      map { [ $self->get_role, $_ ] } @privileges_to_insert;
    return 0 if !scalar @privileges_to_insert;
    my $sth =
      db_run_ex( $self->_db_conn, $RP_QUERY{SQL_add_priv},
        @privileges_to_insert );
    return scalar @privileges_to_insert;
}

# Deletes all roles in @roles (if they exist).
# Silent if non-existent. Returns the number of roles actually deleted.
sub delete_privileges {
    my ( $self, @privileges ) = @_;
    my @privileges_to_delete;
    foreach my $privilege (@privileges) {
        next
          if !defined $privilege
              || !length $privilege
              || !$self->has_privilege($privilege);
        push @privileges_to_delete, [ $self->get_role, $privilege ];
        delete $self->{privileges}{$privilege};    # Remove from cache.
    }
    my $sth = db_run_ex( $self->_db_conn, $RP_QUERY{SQL_delete_privileges},
        @privileges_to_delete );
    return scalar @privileges_to_delete;
}

# Returns a list of priviliges for this object's role.
sub fetch_privileges {
    my $self = shift;
    my $sth  = db_run_ex( $self->_db_conn, $RP_QUERY{SQL_list_privileges},
        $self->get_role );
    my @privileges = map { $_->[0] } @{ $sth->fetchall_arrayref };
    $self->{priviliges} = {    # Construct an anonymous hash.
        map { $_ => 1 } @privileges
    };    # Refresh the cache.
    return @privileges;
}

1;

__END__

=head1 NAME

Class::User::DBI::RolePrivileges - A user roles and privileges class.

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

Through a DBIx::Connector object, this module models a class of privileges
belonging to roles.

    # Set up a connection using DBIx::Connector:
    # MySQL database settings:

    my $conn = DBIx::Connector->new(
        'dbi:mysql:database=cudbi_tests, 'testing_user', 'testers_pass',
        {
            RaiseError => 1,
            AutoCommit => 1,
        }
    );


    # Now we can play with Class::User::DBI::RolePrivileges

    # Set up a 'role-privileges' table in the database.
    Class::User::DBI::RolePrivileges->configure_db( $conn );
    
    # Instantiate a "worker_role" role so that we can manipulate its privileges.
    my $rp = Class::User::DBI::Privileges->new( $conn, 'worker_role' );

    $rp->add_privileges( 'work', 'play' ); # This role can work and play.

    print "Workers can play.\n" if $rp->has_privilege( 'play' );

    my @privileges = $rp->fetch_privileges;
    foreach my $privilege ( @privileges ) {
        print "Workers can $privilege\n";
    }
    
    $rp->delete_privileges( 'work' ); # Pass a list for multiple deletes.


=head1 DESCRIPTION

This is a maintenance class facilitating the creation, deletion, and testing of
privileges belonging to a role.

A common usage is to configure a 'cud_roleprivileges' database table, and then 
add a few role => privilege pairs.  Privileges are authorizations that a
given role (group) may have.  Using C<Class::User::DBI::Roles> you have set up
a list of roles and their descriptions.  Using C<Class::User::DBI::Privileges>
you have set up a list of privileges and their descriptions.  Now this class
allows you to assign one or more of those privileges to the defined roles.

Next, Class::User::DBI may be used to assign a role to a user.  Finally, 
the user object may be queried to determine if a user has a given privilege 
(by his association with his assigned role).

=head1 EXPORT

Nothing is exported.  There are many object methods, and three class methods,
described in the next section.


=head1 SUBROUTINES/METHODS


=head2  new
(The constructor -- Class method.)

    my $role_priv_obj = Class::User::DBI::RolePrivileges->new( $connector, $role );

Creates a role-privileges object that can be manipulated to set and get 
privileges for the instantiated role.  These role/privilege pairs will be stored
in a database table named C<cud_roleprivileges>.  Throws an exception if it 
doesn't get a valid DBIx::Connector or a valid role (where valid means the role
exists in the C<roles> table managed by C<Class::User::DBI::Roles>.

=head2  configure_db
(Class method)

    Class::User::DBI::RolePrivileges->configure_db( $connector );

This is a class method.  Pass a valid DBIx::Connector as a parameter.  Builds
a minimal database table in support of the Class::User::DBI::Privileges class.

The table created will be C<cud_roleprivileges>.

=head2 add_privileges

    $rp->add_privileges( 'goof_off', 'work', ... );

Add one or more privileges.  Each privilege must match a privilege that lives in
the C<privileges> database, managed by C<Class::User::DBI::Privileges>.

It will drop requests to add privileges that already exist for a given role.

Returns a count of privileges added, which may be less than the number passed if 
one already existed.

=head2 delete_privileges

    $rp->delete_privileges( 'goof_off', 'play' ); # Now we can only work.

Deletes from the role all privileges specified.  Return value is the number 
of privileges actually deleted, which may be less than the number of privileges
requested if any of the requested privileges don't exist for the object's target
role.


=head2 has_privilege

    print "This role has the 'work' privilege." 
        if $rp->has_privilege( 'work' );

Returns true if a given privilege exists for the object's target role, and 
false if not.

=head2 fetch_privileges

    foreach my $priv ( $rp->fetch_privileges ) {
        print "Role has $priv privilege\n";
    }
    
Returns a list of privileges belonging to the object's target role.

An empty list means there are no privileges defined for this role.

=head2 get_role

    my $role = $rp->get_role;

Just an accessor for reading the object's target role name.


=head1 DEPENDENCIES

The dependencies for this module are the same as for L<Class::User::DBI>, from
this same distribution.  Refer to the documentation in that module for a full
description.

=head1 CONFIGURATION AND ENVIRONMENT

Please refer to the C<configure_db()> class method for this module for a
simple means of creating the table that supports this class.

All SQL for this distribution is contained in the L<Class::User::DBI::DB> 
module.


=head1 DIAGNOSTICS

If you find that your particular database engine is not playing nicely with the
test suite from this module, it may be necessary to provide the database login 
credentials for a test database using the same engine that your application 
will actually be using.  You may do this by setting C<$ENV{CUDBI_TEST_DSN}>,
C<$ENV{CUDBI_TEST_DATABASE}>, C<$ENV{CUDBI_TEST_USER}>, 
and C<$ENV{CUDBI_TEST_PASS}>.

Currently the test suite tests against a SQLite database since it's such a
lightweight dependency for the testing.  The author also uses this module
with several MySQL databases.  As you're configuring your database, providing
its credentials to the tests and running the test scripts will offer really 
good diagnostics if some aspect of your database tables proves to be at odds 
with what this module needs.


=head1 INCOMPATIBILITIES

This module has only been tested on MySQL and SQLite database engines.  If you
are successful in using it with other engines, please send me an email detailing
any additional configuration changes you had to make so that I can document
the compatibility, and improve the documentation for the configuration process.

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR


David Oswald, C<< <davido at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-user-dbi at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-User-DBI>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::User::DBI::RolePrivileges


You can also look for information at:

=over 4

=item * Class-User-DBI on Github

L<https://github.com/daoswald/Class-User-DBI.git>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-User-DBI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-User-DBI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-User-DBI>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-User-DBI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 David Oswald.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
