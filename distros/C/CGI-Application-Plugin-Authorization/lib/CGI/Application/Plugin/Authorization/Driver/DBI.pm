package CGI::Application::Plugin::Authorization::Driver::DBI;

use strict;
use warnings;

use base qw(CGI::Application::Plugin::Authorization::Driver);

=head1 NAME

CGI::Application::Plugin::Authorization::Driver::DBI - DBI Authorization driver


=head1 SYNOPSIS

 use base qw(CGI::Application);
 use CGI::Application::Plugin::Authorization;

 # Simple task based authentication
 __PACKAGE__->authz->config(
     DRIVER => [ 'DBI',
         TABLES      => ['account', 'task'],
         JOIN_ON     => 'account.id = task.accountid',
         USERNAME    => 'account.name',
         CONSTRAINTS => {
             'task.name' => '__PARAM_1__',
         }
     ],
 );
 if ($self->authz->authorize('editfoo') {
    # User is allowed access if it can 'editfoo'
 }


=head1 DESCRIPTION

This Authorization driver uses the DBI module to allow you to gather
authorization information from any database for which there is a DBD module.
You can either provide an active database handle, or provide the parameters
necesary to connect to the database.

=head2 DBH

The DBI database handle to use. Defaults to C<$self-E<gt>dbh()>, which is provided and configured
through L<CGI::Application::Plugin::DBH|CGI::Application::Plugin::DBH>

When describing the database structure you have two options:

=over 4

=item TABLE(S), JOIN_ON, USERNAME and CONSTRAINTS:

Use these values to describe the table structure, and an sql statement
will be automatically generated to query the database

=item SQL:

just provide one SQL parameters that gives a complete sql statement that will
be used to query the database

=back

Following is a description of all the avaliable parameters:

=head2 TABLE(S)

Provide either a single table name, or an array of table names.  You can give
the table names aliases which can be referenced in later columns.

     TABLE => 'group',

 - or -

     TABLES => ['user U', 'group G'],


=head2 JOIN_ON

If you have specified multiple tables, then you need to provide an SQL
expression that can be used to join those tables.

     JOIN_ON => 'user.id = group.userid',

 - or -

     JOIN_ON => 'U.id = G.userid',


=head2 USERNAME

This should be set to the column name that contains the username.  This column
will be compared against the currently logged in user.

     USERNAME => 'name'

 - or -

     USERNAME => 'U.name'


=head2 CONSTRAINTS

Constraints are used to restrict the database query against the options that
are passed to the C<authorize> method.  In the common case, you will check these
parameters against a group permission table, although there is no limit to the
number of parameters that can be used.  Each constraint can be set to a static
value, or it can be set to '__PARAM_n__' where 'n' is the position of the
parameter that is passed in to the C<authorize> method.

     CONSTRAINTS => {
         'user.active' => 't',
         'group.type'  => '__PARAM_1__',
         'group.name'  => '__PARAM_2__',
     }


=head2 SQL

If you need to perform a complex query that can not be defined by the above
syntax, then you can provide your own SQL statment where the first placeholder
is used to fill in the username, and the rest of the placeholders are filled in
using the parameters passed to the authorize method.

     SQL => 'SELECT count(*)
               FROM account
               LEFT JOIN ip ON (account.id = ip.accountid)
               LEFT JOIN task ON (account.id = task.accountid)
              WHERE account.name = ?
                AND (ip.address >> inet ? OR task.name = ?)
            ',


=head1 EXAMPLE

 #
 # Example table structure (for PostgreSQL):
 #
 CREATE TABLE account (
   id         SERIAL NOT NULL PRIMARY KEY,
   name       VARCHAR(50) NOT NULL
 );
 CREATE TABLE task (
   id         SERIAL NOT NULL PRIMARY KEY,
   accountid  INTEGER NOT NULL REFERENCES account(id),
   name       VARCHAR(50) NOT NULL
 );
 CREATE TABLE ip (
   id         SERIAL NOT NULL PRIMARY KEY,
   accountid  INTEGER NOT NULL REFERENCES account(id),
   address    INET NOT NULL
 );
 INSERT INTO account (name) VALUES ('testuser');
 INSERT INTO task (accountid, name) VALUES (1, 'editfoo');
 INSERT INTO ip (accountid, address) VALUES (1, '192.168.1.0/24');
 
 # Simple task based authentication
 __PACKAGE__->authz->config(
     DRIVER => [ 'DBI',
         # the handle comes from $self->dbh, via the "DBH" plugin. 
         TABLES      => ['account', 'task'],
         JOIN_ON     => 'account.id = task.accountid',
         USERNAME    => 'account.name',
         CONSTRAINTS => {
             'task.name'   => '__PARAM_1__',
             'task.active' => 't'
         }
     ],
 );
 if ($self->authz->authorize('editfoo') {
    # User is allowed access if they can 'editfoo'
 }

 # IP address configuration
 __PACKAGE__->authz('byIP')->config(
     DRIVER => [ 'DBI',
         SQL => 'SELECT count(*)
                   FROM account JOIN ip ON (account.id = ip.accountid)
                  WHERE account.name = ?
                    AND ip.address >> inet ?
                ',
     ],
 );
 if ($self->authz('byIP')->authorize($ENV{REMOTE_ADDR}) {
    # User is allowed to connect from this address
 }

 # both together in one test
 # IP address configuration
 __PACKAGE__->authz->config(
     DRIVER => [ 'DBI',
         SQL => 'SELECT count(*)
                   FROM account
                   JOIN ip ON (account.id = ip.accountid)
                   JOIN task ON (account.id = task.accountid)
                  WHERE account.name = ?
                    AND task.name = ?
                    AND ip.address >> inet ?
                ',
     ],
 );
 if ($self->authz->authorize('editfoo', $ENV{REMOTE_ADDR}) {
    # User is allowed to connect from this address if they can
    # also 'editfoo'
 }


=head1 METHODS

=head2 authorize_user

This method accepts a username followed by a list of parameters and will
return true if the configured query returns at least one row based on the
given parameters.

=cut

sub authorize_user {
    my $self     = shift;
    my $username = shift;
    my @params   = @_;

    # verify that all the options are OK
    my @_options = $self->options;
    die "The DBI driver requires a hash of options" if @_options % 2;
    my %options = @_options;

    # Get a database handle either one that is given to us, or connect using
    # the information given in the configuration
    my $dbh;
    if ( $options{DBH} ) {
        $dbh = $options{DBH};
    } elsif ( $self->authen->_cgiapp->can('dbh') ) {
        $dbh = $self->authen->_cgiapp->dbh;
    } else {
        die "No DBH or passed to the DBI Driver, and no dbh() method detected";
    }

    # See if the user provided an SQL option
    if ( $options{SQL} ) {
        # prepare and execute the SQL
        my $sth = $dbh->prepare_cached( $options{SQL} )
            || die "Failed to prepare SQL statement:  " . $dbh->errstr;
        $sth->execute( $username, @params ) or die $dbh->errstr;

        # Since we are not pulling specific columns we just check
        # to see if we matched at least one row
        my ($count) = $sth->fetchrow_array;
        $sth->finish;
        return $count ? 1 : 0;
    }

    # Grab the database table names (TABLE and TABLES are synonymous)
    my $tables = $options{TABLES} || $options{TABLE};
    $tables = [$tables] unless ref $tables eq 'ARRAY';

    # Process the constraints.
    # We need to check for values indicate they should be replaced by
    # a parameter (__PARAM_\d+__)
    my %constraints;
    my $used_username = 0;
    if ( $options{CONSTRAINTS} ) {
        die "CONSTRAINTS must be a hashref"
            unless ref $options{CONSTRAINTS} eq 'HASH';
        while ( my ( $column, $value ) = each %{ $options{CONSTRAINTS} } ) {
            if ( $value =~ /^__PARAM_(\d+)__$/ ) {
                $value = $params[ $1 - 1 ];
            }
            elsif ( $value =~ /^__USERNAME__$/ ) {
                $value = $username;
                $used_username = 1;
            }
            elsif ( $value =~ /^__GROUP__$/ ) {
                $value = $params[ 0 ];
            }
            $constraints{$column} = $value;
        }
    }

    # Add in the username constraint if it was provided
    if ($options{USERNAME}) {
        $constraints{$options{USERNAME}} = $username;
    } elsif ( ! $used_username && ! $options{NO_USERNAME} ) {
        warn "Your configuration did not provide for a match against a username column, make sure to provide the USERNAME option, or use the special __USERNAME__ variable in your CONSTRAINTS";
    }

    # If we have multiple tables, then we need a join constraint
    my $join_on = $options{JOIN_ON};

    # Build the SQL statement
    my $sql = 'SELECT count(*) FROM ' . join( ', ', @$tables ) . ' WHERE ';
    my @where;
    push @where, $join_on if $join_on;
    push @where, map { $_ . ' = ?' } keys %constraints;
    $sql .= join( ' AND ', @where );
    my @db_values = values %constraints;

    # prepare and execute the SQL
    my $sth = $dbh->prepare_cached($sql)
        || die "Failed to prepare SQL statement:  " . $dbh->errstr;
    $sth->execute(@db_values) or die $dbh->errstr;

    # Since we are not pulling specific columns we just check
    # to see if we matched at least one row
    my ($count) = $sth->fetchrow_array;
    $sth->finish;
    return $count ? 1 : 0;
}

=head1 SEE ALSO

L<CGI::Application::Plugin::Authorization::Driver>,
L<CGI::Application::Plugin::Authorization>, perl(1)


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU
OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

1;
