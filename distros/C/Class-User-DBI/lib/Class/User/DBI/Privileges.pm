## no critic (RCS,VERSION)
package Class::User::DBI::Privileges;

use strict;
use warnings;

use Carp;

use Class::User::DBI::DB qw( db_run_ex  %PRIV_QUERY );

our $VERSION = '0.10';
# $VERSION = eval $VERSION;    ## no critic (eval)

# Class methods.

sub new {
    my ( $class, $conn ) = @_;
    my $self = bless {}, $class;
    croak 'Constructor called without a DBIx::Connector object.'
      if !ref $conn || !$conn->isa('DBIx::Connector');
    $self->{_db_conn}   = $conn;
    $self->{privileges} = {};
    return $self;
}

sub configure_db {
    my ( $class, $conn ) = @_;
    croak 'Must provide a valid constructor object.'
      if !ref $conn || !$conn->isa('DBIx::Connector');
    $conn->run(
        fixup => sub {
            $_->do( $PRIV_QUERY{SQL_configure_db_cud_privileges} );
        }
    );
    return 1;
}

# Object methods.

sub _db_conn {
    my $self = shift;
    return $self->{_db_conn};
}

# Usage:
# $priv->exists_privilege( $priv );
# returns 0 or 1.
sub exists_privilege {
    my ( $self, $privilege ) = @_;
    croak 'Must pass a defined value in privilege test.'
      if !defined $privilege;
    croak 'Must pass a non-empty value in privilege test.'
      if !length $privilege;
    return 1 if exists $self->{privileges}{$privilege};
    my $sth =
      db_run_ex( $self->_db_conn, $PRIV_QUERY{SQL_exists_privilege},
        $privilege );
    my $result = defined $sth->fetchrow_array;
    $self->{privileges}{$privilege}++ if $result;    # Cache the result.
    return $result;
}

# Usage:
# $priv->add_privileges( [ qw( privilege description ) ], [...] );
# Returns the number of privs actually added.

sub add_privileges {
    my ( $self, @privileges ) = @_;
    my @privs_to_insert =
      grep {
             ref $_ eq 'ARRAY'
          && $_->[0]
          && !$self->exists_privilege( $_->[0] )
      } @privileges;

    # Set undefined descriptions to q{}.
    foreach my $priv_bundle (@privs_to_insert) {

        # This change is intended to propagate back to @privs_to_insert.
        $priv_bundle->[1] = q{} if !$priv_bundle->[1];
    }
    my $sth = db_run_ex( $self->_db_conn, $PRIV_QUERY{SQL_add_privileges},
        @privs_to_insert );
    return scalar @privs_to_insert;
}

# Deletes all privileges in @privileges (if they exist).
# Silent if non-existent. Returns the number of privs actually deleted.
sub delete_privileges {
    my ( $self, @privileges ) = @_;
    my @privs_to_delete;
    foreach my $privilege (@privileges) {
        next if !$privilege || !$self->exists_privilege($privilege);
        push @privs_to_delete, [$privilege];
        delete $self->{privileges}{$privilege};  # Remove it from the cache too.
    }
    my $sth = db_run_ex( $self->_db_conn, $PRIV_QUERY{SQL_delete_privileges},
        @privs_to_delete );
    return scalar @privs_to_delete;
}

# Gets the description for a single privilege.  Must specify a valid privilege.
sub get_privilege_description {
    my ( $self, $privilege ) = @_;
    croak 'Must specify a privilege.'
      if !defined $privilege;
    croak 'Specified privilege must exist.'
      if !$self->exists_privilege($privilege);
    my $sth =
      db_run_ex( $self->_db_conn, $PRIV_QUERY{SQL_get_privilege_description},
        $privilege );
    return ( $sth->fetchrow_array )[0];
}

# Pass a privilege and a new description.  All parameters required.  Description
# of q{} deletes the description.
sub set_privilege_description {
    my ( $self, $privilege, $description ) = @_;
    croak 'Must specify a privilege.'
      if !defined $privilege;
    croak 'Specified privilege doesn\'t exist.'
      if !$self->exists_privilege($privilege);
    croak 'Must specify a description (q{} is ok too).'
      if !defined $description;
    my $sth =
      db_run_ex( $self->_db_conn, $PRIV_QUERY{SQL_set_privilege_description},
        $description, $privilege );
    return 1;
}

# Returns an array of pairs (AoA).  Pairs are [ privilege, description ],...
sub fetch_privileges {
    my $self = shift;
    my $sth = db_run_ex( $self->_db_conn, $PRIV_QUERY{SQL_list_privileges} );
    my @privileges = @{ $sth->fetchall_arrayref };
    return @privileges;
}

1;

__END__

=head1 NAME

Class::User::DBI::Privileges - A Privileges class.

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

Through a DBIx::Connector object, this module models a "Privileges" class, used 
for Roles Based Access Control.  Class::User::DBI allows each user to have a 
single role, and Class::User::DBI::RolePrivileges allows each role to have 
multiple privileges.  And so goes the heirarchy: A user has a role, and a role 
has privileges.

    # Set up a connection using DBIx::Connector:
    # MySQL database settings:

    my $conn = DBIx::Connector->new(
        'dbi:mysql:database=cudbi_tests, 'testing_user', 'testers_pass',
        {
            RaiseError => 1,
            AutoCommit => 1,
        }
    );


    # Now we can play with Class::User::DBI::Privileges

    # Set up a 'privileges' table in the database.
    Class::User::DBI::Roles->configure_db( $conn );
    
    my $p = Class::User::DBI::Privileges->new( $conn );

    $p->add_privileges( 
        [ 'work', 'Authorized to work' ],
        [ 'play', 'Authorized to play' ],
    );

    print "Privilege exists." if $p->exists_privilege( 'work' );

    my @privileges = $p->fetch_privileges;
    foreach my $privilege ( @privileges ) {
        my( $name, $description ) = @{$privilege};
        print "$name => $description\n";
    }

    print "Description for 'work' privilege: ", 
          $p->get_privilege_description( 'work' );
    
    $p->set_privilege_description( 'work', 'Right to work hard.' );
    
    $p->delete_privileges( 'work' ); # Pass a list for multiple deletes.


=head1 DESCRIPTION

This is a maintenance class facilitating the creation, deletion, and testing of
privileges that are compatible with Class::User::DBI's roles, and 
Class::User::DBI::RolePrivileges privileges.

A common usage is to configure a database table, and then add a few privileges
along with their descriptions.  Think of privileges as authorizations that a
given role (group) may have.

Then use Class::User::DBI::Roles to create roles, and 
Class::User::DBI::RolePrivileges to associate one or more privileges with a
given role.  Finally, use Class::User::DBI to associate a role with one or
more users.

=head1 EXPORT

Nothing is exported.  There are many object methods, and three class methods,
described in the next section.


=head1 SUBROUTINES/METHODS


=head2  new
(The constructor -- Class method.)

    my $priv_obj = Class::User::DBI::Privileges->new( $connector );

Creates a privileges object that can be manipulated to set and get roles from 
the database's 'cud_privileges' table.  Pass a DBIx::Connector object as a 
parameter.  Throws an exception if it doesn't get a valid DBIx::Connector.


=head2  configure_db
(Class method)

    Class::User::DBI::Privileges->configure_db( $connector );

This is a class method.  Pass a valid DBIx::Connector as a parameter.  Builds
a minimal database table in support of the Class::User::DBI::Privileges class.

The table created will be C<cud_privileges>.

=head2 add_privileges

    $p->add_privileges( [ 'goof_off', 'Authorization to goof off' ], ... );

Add one or more privileges.  Each privilege must be bundled along with its 
description in an array ref.  Pass an AoA for multiple privileges, or just an 
aref for a single privilege/description pair.

It will drop requests to add privileges that already exist.

Returns a count of privileges added, which may be less than the number passed if 
one already existed.

=head2 delete_privileges

    $p->delete_privileges( 'goof_off', 'play' ); # Now we can only work.

Deletes from the database all privileges specified.  Return value is the number 
of privileges actually deleted, which may be less than the number of privileges
requested if any of the requested privileges didn't exist in the database to 
begin with.


=head2 exists_privilege

    print "Privilege exists." if $p->exists_privilege( 'work' );

Returns true if a given privilege exists, and false if not.

=head2 fetch_privileges

    foreach my $priv ( $p->fetch_privileges ) {
        print "$priv->[0] = $priv->[1]\n";
    }
    
Returns an array of array refs.  Each array ref contains the privilege's name 
and its description as the first and second elements, respectively.

An empty list means there are no privileges defined.

=head2 get_privilege_description

    my $description = $p->get_privilege_description( 'work' );
    
Returns the description for a given privilege.  Throws an exception if the 
privilege doesn't exist, so be sure to test with 
C<< $r->exists_privilege( 'work' ) >> first.

=head2 set_privilege_description

    $p->set_privilege_description( 'work', 'New work priv description.' );

Sets a new description for a given privilege.  If the privilege doesn't exist 
in the database, if not enough parameters are passed, or if any of the params 
are C<undef>, an exception will be thrown.  To update a privilege by giving it 
a blank description, pass an empty string as the description.


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

    perldoc Class::User::DBI::Privileges


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
