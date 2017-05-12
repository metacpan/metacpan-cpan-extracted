## no critic (RCS,VERSION,POD)
package Class::User::DBI::DB;

use strict;
use warnings;
use 5.008;

use Exporter;
our @ISA       = qw( Exporter );     ## no critic (ISA)
our @EXPORT    = qw( db_run_ex );    ## no critic (export)
our @EXPORT_OK = qw(
  %USER_QUERY
  %PRIV_QUERY
  %DOM_QUERY
  %ROLE_QUERY
  %RP_QUERY
  %UD_QUERY
  _db_run_ex
);

use Carp;

our $VERSION = '0.10';
# $VERSION = eval $VERSION;    ## no critic (eval)

# ---------------- SQL queries for Class::User::DBI --------------------------

our %USER_QUERY = (
    SQL_get_valid_ips   => 'SELECT ip FROM user_ips WHERE userid = ?',
    SQL_get_credentials => 'SELECT salt, password, ip_required '
      . 'FROM users WHERE userid = ?',
    SQL_exists_user => 'SELECT userid FROM users WHERE userid = ?',
    SQL_load_profile =>
      'SELECT userid, username, email, role, ip_required FROM users WHERE userid = ?',
    SQL_add_ips    => 'INSERT INTO user_ips ( userid, ip ) VALUES( ?, ? )',
    SQL_delete_ips => 'DELETE FROM user_ips WHERE userid = ? AND ip = ?',
    SQL_add_user => 'INSERT INTO users ( userid, salt, password, ip_required, '
      . 'username, email, role ) VALUES( ?, ?, ?, ?, ?, ?, ? )',
    SQL_delete_user     => 'DELETE FROM users WHERE userid = ?',
    SQL_delete_user_ips => 'DELETE FROM user_ips WHERE userid = ?',
    SQL_set_email       => 'UPDATE users SET email = ? WHERE userid = ?',
    SQL_set_username    => 'UPDATE users SET username = ? WHERE userid = ?',
    SQL_set_ip_required => 'UPDATE users SET ip_required = ? where userid = ?',
    SQL_update_password =>
      'UPDATE users SET salt = ?, password = ? WHERE userid = ?',
    SQL_list_users => 'SELECT userid, username, email, role, ip_required FROM users ORDER BY userid',
    SQL_get_role   => 'SELECT role FROM users WHERE userid = ?',
    SQL_get_ip_required => 'SELECT ip_required FROM users WHERE userid = ?',
    SQL_is_role    => 'SELECT role FROM users WHERE userid = ? AND role = ?',
    SQL_set_role   => 'UPDATE users SET role = ? WHERE userid = ?',
    SQL_configure_db_users => << 'END_SQL',
    CREATE TABLE IF NOT EXISTS users (
        userid      VARCHAR(24)           NOT NULL DEFAULT '',
        salt        CHAR(128)             DEFAULT NULL,
        password    CHAR(128)             DEFAULT NULL,
        ip_required TINYINT(1)            NOT NULL DEFAULT '1',
        username    VARCHAR(40)           DEFAULT NULL,
        email       VARCHAR(320)          DEFAULT NULL,
        role        VARCHAR(24)           DEFAULT NULL,
        PRIMARY KEY( userid )
    )
END_SQL
    SQL_configure_db_user_ips => << 'END_SQL',
    CREATE TABLE IF NOT EXISTS user_ips (
        userid      VARCHAR(24)           NOT NULL DEFAULT '',
        ip          BIGINT                NOT NULL DEFAULT '0',
        PRIMARY KEY ( userid, ip )
    )
END_SQL
);

#------------ Queries for Class::User::DBI::Privileges -----------------------

our %PRIV_QUERY = (
    SQL_configure_db_cud_privileges => << 'END_SQL',
    CREATE TABLE IF NOT EXISTS cud_privileges (
        privilege   VARCHAR(24)           NOT NULL,
        description VARCHAR(40)           NOT NULL DEFAULT '',
        PRIMARY KEY (privilege)
    )
END_SQL
    SQL_exists_privilege =>
      'SELECT privilege FROM cud_privileges WHERE privilege = ?',
    SQL_add_privileges =>
      'INSERT INTO cud_privileges ( privilege, description ) VALUES ( ?, ? )',
    SQL_delete_privileges => 'DELETE FROM cud_privileges WHERE privilege = ?',
    SQL_get_privilege_description =>
      'SELECT description FROM cud_privileges WHERE privilege = ?',
    SQL_set_privilege_description =>
      'UPDATE cud_privileges SET description = ? WHERE privilege = ?',
    SQL_list_privileges => 'SELECT * FROM cud_privileges',
);

#----------------- Queries for Class::User::DBI::Domains ---------------------

our %DOM_QUERY = (
    SQL_configure_db_cud_domains => << 'END_SQL',
    CREATE TABLE IF NOT EXISTS cud_domains (
        domain      VARCHAR(24)           NOT NULL,
        description VARCHAR(40)           NOT NULL DEFAULT '',
        PRIMARY KEY (domain)
    )
END_SQL
    SQL_exists_domain => 'SELECT domain FROM cud_domains WHERE domain = ?',
    SQL_add_domains =>
      'INSERT INTO cud_domains ( domain, description ) VALUES ( ?, ? )',
    SQL_delete_domains => 'DELETE FROM cud_domains WHERE domain = ?',
    SQL_get_domain_description =>
      'SELECT description FROM cud_domains WHERE domain = ?',
    SQL_set_domain_description =>
      'UPDATE cud_domains SET description = ? WHERE domain = ?',
    SQL_list_domains => 'SELECT * FROM cud_domains',
);

#----------------- Queries for Class::User::DBI::Roles ---------------------

our %ROLE_QUERY = (
    SQL_configure_db_cud_roles => << 'END_SQL',
    CREATE TABLE IF NOT EXISTS cud_roles (
        role        VARCHAR(24)           NOT NULL,
        description VARCHAR(40)           NOT NULL DEFAULT '',
        PRIMARY KEY (role)
    )
END_SQL
    SQL_exists_role => 'SELECT role FROM cud_roles WHERE role = ?',
    SQL_add_roles =>
      'INSERT INTO cud_roles ( role, description ) VALUES ( ?, ? )',
    SQL_delete_roles => 'DELETE FROM cud_roles WHERE role = ?',
    SQL_get_role_description =>
      'SELECT description FROM cud_roles WHERE role = ?',
    SQL_set_role_description =>
      'UPDATE cud_roles SET description = ? WHERE role = ?',
    SQL_list_roles => 'SELECT * FROM cud_roles',
);

# ----------------- Queries for Class::User::DBI::RolePrivileges ------------

our %RP_QUERY = (
    SQL_configure_db_cud_roleprivs => << 'END_SQL',
    CREATE TABLE IF NOT EXISTS cud_roleprivs (
        role        VARCHAR(24)           NOT NULL DEFAULT '',
        privilege   VARCHAR(24)           NOT NULL DEFAULT '',
        PRIMARY KEY (role,privilege)
    )
END_SQL
    SQL_exists_priv =>
      'SELECT privilege FROM cud_roleprivs WHERE role = ? AND privilege = ?',
    SQL_add_priv =>
      'INSERT INTO cud_roleprivs ( role, privilege ) VALUES ( ?, ? )',
    SQL_delete_privileges =>
      'DELETE FROM cud_roleprivs WHERE role = ? AND privilege = ?',
    SQL_list_privileges => 'SELECT privilege FROM cud_roleprivs WHERE role = ?',
);

# ----------------- Queries for Class::User::DBI::UserDomains ------------

our %UD_QUERY = (
    SQL_configure_db_cud_userdomains => << 'END_SQL',
    CREATE TABLE IF NOT EXISTS cud_userdomains (
        userid      VARCHAR(24)           NOT NULL DEFAULT '',
        domain      VARCHAR(24)           NOT NULL DEFAULT '',
        PRIMARY KEY (userid,domain)
    )
END_SQL
    SQL_exists_domain =>
      'SELECT domain FROM cud_userdomains WHERE userid = ? AND domain = ?',
    SQL_add_domain =>
      'INSERT INTO cud_userdomains ( userid, domain ) VALUES ( ?, ? )',
    SQL_delete_domains =>
      'DELETE FROM cud_userdomains WHERE userid = ? AND domain = ?',
    SQL_list_domains => 'SELECT domain FROM cud_userdomains WHERE userid = ?',
);

# ------------------------------ Functions -----------------------------------

# Prepares and executes a database command using DBIx::Connector's 'run'
# method.  Pass bind values as 2nd+ parameter(s).  If the first bind-value
# element is an array ref, bind value params will be executed in a loop,
# dereferencing each element's list upon execution:
# $self->_db_run_ex( 'SQL GOES HERE', @execute_params ); .... OR....
# $self->_db_run_ex(
#     'SQL GOES HERE',
#     [ first param list ], [ second param list ], ...
# );

sub db_run_ex {
    my ( $conn, $sql, @ex_params ) = @_;
    croak ref($conn) . ' is not a DBIx::Connector.'
      if !$conn->isa('DBIx::Connector');
    my $sth = $conn->run(
        fixup => sub {
            my $sub_sth = $_->prepare($sql);

            # Pass an array of arrayrefs if execute() is to be called in a loop.
            if ( @ex_params && ref( $ex_params[0] ) eq 'ARRAY' ) {
                foreach my $param (@ex_params) {
                    $sub_sth->execute( @{$param} );
                }
            }
            else {
                $sub_sth->execute(@ex_params);
            }
            return $sub_sth;
        }
    );
    return $sth;
}

1;

__END__

=head1 NAME

Class::User::DBI::DB - An internal-use class for the various 
C<Class::User::DBI::*> classes.

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

    my $sql = Class::User::DBI::DB::$USER_QUERY{SQL_some_query};
    
    db_run_ex( $connector, $sql, @parameters );
    # or
    db_run_ex( $connector, $sql, ( [ @params1 ], [ @params2 ] ) );


=head1 DESCRIPTION


This package contains all of the SQL queries for the classes in this 
distribution.

There is also one subroutine, intended for use by the classes.  It handles
database queries through the DBIx::Connector object.

This package is generally not intended for external consumption.  However, if
your database flavor doesn't like this distribution's SQL, you may be relieved
to find out that this is the B<only> place you need to look for SQL problems.
All of the distribution's SQL is here; even table creation.

=head1 EXPORT

Exports (by request) hashes containing the SQL queries for each class.  The
hashes are given names that represent abbreviated versions of the classes they
support.

By  default it also exports C<db_run_ex>, which is a utility function 
facilitating database queries through the connector object.

=head1 SUBROUTINES/METHODS


=head2  db_run_ex

    db_run_ex( $connector, $sql, @parameters );

    # or

    db_run_ex( $connector, $sql, ( [ @params1 ], [ @params2 ] ) );

Pass a connector object, an SQL query, and a list of bind values.  For multiple
C<execute()> calls, pass an array of array refs instead of a flat array.  Each
anonymous array holds the bind values for a single C<< $sth->execute() >> call.

=head1 DEPENDENCIES

The dependencies for this module are the same as for L<Class::User::DBI>, from
this same distribution.  Refer to the documentation in that module for a full
description.


=head1 CONFIGURATION AND ENVIRONMENT

All of the SQL for this entire distribution is found in the 
L<Class::User::DBI::DB> module.  Any adjustments required to suit your database
engine may be made here.  This module's SQL is known to run unaltered with 
SQLite and MySQL.

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

    perldoc Class::User::DBI::DB


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

=cut
