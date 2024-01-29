package CGI::Application::Plugin::Authentication::Driver::DBI;
$CGI::Application::Plugin::Authentication::Driver::DBI::VERSION = '0.24';
use strict;
use warnings;

use base qw(CGI::Application::Plugin::Authentication::Driver);

=head1 NAME

CGI::Application::Plugin::Authentication::Driver::DBI - DBI Authentication driver

=head1 SYNOPSIS

 use base qw(CGI::Application);
 use CGI::Application::Plugin::Authentication;

 __PACKAGE__->authen->config(
     DRIVER => [ 'DBI',
         DBH         => $self->dbh,
         TABLE       => 'user',
         CONSTRAINTS => {
             'user.name'         => '__CREDENTIAL_1__',
             'MD5:user.password' => '__CREDENTIAL_2__'
         },
     ],
 );


=head1 DESCRIPTION

This Authentication driver uses the DBI module to allow you to authenticate against
any database for which there is a DBD module.  You can either provide an active
database handle, or provide the parameters necessary to connect to the database.

When describing the database structure, you need to specify some or all of the
following parameters: TABLE(S), JOIN_ON, COLUMNS, CONSTRAINTS, ORDER_BY and
LIMIT.

=head2 DBH

The DBI database handle to use. Defaults to C<$self->dbh()>, which is provided and configured
through L<CGI::Application::Plugin::DBH|CGI::Application::Plugin::DBH>

=head2 TABLE(S)  (required)

Provide either a single table name, or an array of table names.  You can give the
table names aliases which can be referenced in later columns.

     TABLE => 'users',

 - or -

     TABLES => ['users U', 'domains D'],


=head2 JOIN_ON  (conditionally required)

If you have specified multiple tables, then you need to provide an SQL expression that
can be used to join those tables.

     JOIN_ON => 'user.domainid = domain.id',

 - or -

     JOIN_ON => 'U.domainid = D.id',


=head2 COLUMNS  (optional)

This is a hash of columns/values that should be pulled out of the database and validated
locally in perl.  Most credentials can be checked right in the database (example
username = ?), but some parameters may need to be tested locally in perl, so they
must be listed in the COLUMNS option.  One example of a value that needs to be tested
in perl is a crypted password.  In order to test a crypted password, you need to
take the entered password, and crypt it with the salt of the already crypted password.
But until we actually see the password that is in the database, we will not know the
value of the salt that was used to encrypt the password.  So we pull the value out
using COLUMNS, and the test will be performed automatically in perl.

Any value that matches __CREDENTIAL_n__ (where n is a number) will be replaced with
the corresponding credential that was entered by the user.  For an explanation of
what the credentials are and where they come from, see the section headed with
CREDENTIALS in L<CGI::Application::Plugin::Authentication>.

     COLUMNS => { 'crypt:password' => '__CREDENTIAL_2__' },


=head2 CONSTRAINTS  (optional)

You will most likely always have some constraints to use.  These constraints
will be added to the WHERE clause of the SQL query, and will ideally reduce
the number of returned rows to one.  

Any value that matches __CREDENTIAL_n__ (where n is a number) will be replaced with
the corresponding credential that was entered by the user.  For an explanation of
what the credentials are and where they come from, see the section headed with
CREDENTIALS in L<CGI::Application::Plugin::Authentication>.

     CONSTRAINTS => {
         'users.email'          => '__CREDENTIAL_1__',
         'MD5:users.passphrase' => '__CREDENTIAL_2__',
         'users.active'         => 1,
     }


=head2 ORDER_BY  (optional)

This option allows you to order the result set, in case the query returns
multiple rows.

     ORDER_BY => 'created DESC'

Note: This option is only useful if you also specify the COLUMNS option.

=head2 LIMIT  (optional)

In some situations your query may return multiple rows when you only want it to
return one.  For example if you insert and date a new row instead of updating
the existing row when the details for an account change.  In this case you want
the newest record from the result set, so it will be important to order the
result set and limit it to return only one row.

     LIMIT => 1

Note: This option is only useful if you also specify the COLUMNS option.

=head1 ENCODED PASSWORDS

It is quite common to store passwords in a database in some form that makes them hard
(or virtually impossible) to guess.  Most of the time one way encryption techniques
like Unix crypt or MD5 hashes are used to store the password securely (I would recommend
using MD5 or SHA1 over Unix crypt).  If you look at the examples listed above, you can
see that you can mark your columns with an encoding type.  Here is another example:

    CONSTRAINTS => {
        username       => '__CREDENTIAL_1__',
        'MD5:password' => '__CREDENTIAL_2__',
    }

Here the password field is expected to be stored in the database in MD5 format.  In order for the
MD5 check to work for all databases, the password will be encoded using perl, and then checked
against the value in the database.  So in effect, the following will be done:

    $username = 'test';
    $password = '123';
    $encoded_password = 'ICy5YqxZB1uWSwcVLSNLcA';
    $sth = $dbh->prepare('SELECT count(*) FROM users WHERE username = ? AND password = ?';
    $sth->execute($username, $encoded_password);
    # I we found a row, then the user credentials are valid and the user is logged in

This is all automatically performed behind the scenes when you specify that a certain field
in the database is encoded.

We have to handle this slightly different when working with Unix crypt.  In order to crypt
a password, you need to provide the crypt function with a 2 character salt value.  These are
usually just generated randomly, and when the value is crypted, the first two characters of
the resulting string will be the 2 salt characters.  The problem comes into play when you want
to check a password against a crypted password.  You need to know the salt in order to
properly test the password.  But in our case, the crypted password is in the DB.  This means we
can not generate the crypted test password before we run the query against the database.

So instead we pull the value of the crypted password out of the database, and then perform the
tests after the query, instead of before.  Here is an example:

    CONSTRAINTS => { 'username'       => '__CREDENTIAL_1__' },
    COLUMNS     => { 'crypt:password' => '__CREDENTIAL_2__' },

And here is what will happen behind the scenes:

    $username = 'test';
    $password = '123';
    $sth = $dbh->prepare('SELECT password FROM users WHERE username = ?';
    $sth->execute($username);
    ($encoded_password) = $sth->fetchrow_array;
    if ($encoded_password eq crypt($password, $encoded_password)) {
        # The credentials are valid and the user is logged in
    }

Again, this is all done automatically behind the scenes, but I've included it here to illustrate how
the queries are performed, and how the comparisons are handled.  For more information
see the section labelled ENCODED PASSWORDS in the L<CGI::Application::Plugin::Authentication::Driver>
docs.



=head1 EXAMPLE

 # using multiple tables
 #  Here we check three credentials (user, password and domain) across
 #  two separate tables.
 __PACKAGE__->authen->config(
     DRIVER => [ 'DBI',
         # the handle comes from $self->dbh, via the "DBH" plugin. 
         TABLES      => ['user', 'domain'],
         JOIN_ON     => 'user.domainid = domain.id',
         CONSTRAINTS => {
             'user.name'     => '__CREDENTIAL_1__',
             'user.password' => '__CREDENTIAL_2__',
             'domain.name'   => '__CREDENTIAL_3__'
         }
     ],
 );

  - or -

 # using filtered fields
 #  Here the password column contains values that are encoded using unix crypt
 #  and since we need to know the salt in order to encrypt the password
 #  properly, we need to pull out the password, and check it locally
 __PACKAGE__->authen->config(
     DRIVER => [ 'DBI',
         DBH         => $dbh,   # provide your own DBI handle
         TABLE       => 'user',
         CONSTRAINTS => { 'user.name'      => '__CREDENTIAL_1__' }
         COLUMNS     => { 'crypt:password' => '__CREDENTIAL_2__' },
     ],
 );

 - or -

 # extra constraints
 #  Here we only check users where the 'active' column is true
 __PACKAGE__->authen->config(
     DRIVER => [ 'DBI',
         TABLE       => 'user',
         CONSTRAINTS => {
             'user.name'     => '__CREDENTIAL_1__',
             'user.password' => '__CREDENTIAL_2__',
             'user.active'   => 't'
         },
     ],
 );

 - or -

 # all of them combined
 #  Here the user is required to enter a username and password (which is
 #  crypted), and a daily code that changes every day (which is encoded using
 #  an MD5 hash hex format and stored in upper case).
 __PACKAGE__->authen->config(
     DRIVER => [ 'DBI',
         TABLES      => ['user U', 'dailycode D'],
         JOIN_ON     => 'U.userid = D.userid',
         CONSTRAINTS => {
             'U.name'            => '__CREDENTIAL_1__',
             'uc:md5_hex:D.code' => '__CREDENTIAL_3__',
             'D.date'            => 'now'
         },
         COLUMNS     => {
             'crypt:U.password' => '__CREDENTIAL_2__'
         },
     ],
 );



=head1 METHODS

=head2 verify_credentials

This method will test the provided credentials against the values found in the database,
according to the Driver configuration.

=cut

sub verify_credentials {
    my $self  = shift;
    my @creds = @_;

    # verify that all the options are OK
    my @_options = $self->options;
    die "The DBI driver requires a hash of options" if @_options % 2;
    my %options = @_options;

    # Get a database handle - either one that is given to us, or see if there
    # is a ->dbh method in the CGIApp module (This is provided by the
    # CGI::Application::Plugin::DBH module, so use it if it is there).
    my $dbh;
    if ( $options{DBH} ) {
        $dbh = $options{DBH};
    } elsif ( $self->authen->_cgiapp->can('dbh') ) {
        $dbh = $self->authen->_cgiapp->dbh;
    } else {
        die "No DBH handle passed to the DBI Driver, and no dbh() method detected";
    }

    # Grab the database table names (TABLE and TABLES are synonymous)
    my $tables = $options{TABLES} || $options{TABLE};
    die "No TABLE parameter defined" unless defined($tables);
    $tables = [$tables] unless ref $tables eq 'ARRAY';

    # See if we need to order the result set
    my $order_by = $options{ORDER_BY} ? ' ORDER BY '.$options{ORDER_BY} : '';

    # See if we need to limit the result set
    my $limit = $options{LIMIT} ? ' LIMIT '.$options{LIMIT} : '';

    # Grab all the columns that we need to pull out.  We also grab a list of
    # columns that are stripped of any encoding information.
    # If no columns are provided we just select count(*) for efficiency.
    my @columns;
    my @stripped_columns;
    if ( $options{COLUMNS} ) {
        die "COLUMNS must be a hashref" unless ref $options{COLUMNS} eq 'HASH';
        @columns          = keys %{ $options{COLUMNS} };
        @stripped_columns = $self->strip_field_names(@columns);
    } else {
        @columns          = ('count(*)');
        @stripped_columns = @columns;
    }

    # Process the constraints.
    # We need to check for values indicate they should be replaced by
    # a credential (__CREDENTIAL_\d+__), and we need to filter any values
    # that are configured to be filtered
    my %constraints;
    if ( $options{CONSTRAINTS} ) {
        die "CONSTRAINTS must be a hashref" unless ref $options{CONSTRAINTS} eq 'HASH';
        while ( my ( $column, $value ) = each %{ $options{CONSTRAINTS} } ) {
            if ( $value =~ /^__CREDENTIAL_(\d+)__$/ ) {
                $value = $creds[ $1 - 1 ];
            }
            $value                = $self->filter( $column, $value );
            $column               = $self->strip_field_names($column);
            $constraints{$column} = $value;
        }
    }

    # If we have multiple tables, then we need a join constraint
    my $join_on = $options{JOIN_ON};

    # Build the SQL statement
    my $sql = 'SELECT ' . join( ', ', @stripped_columns ) . ' FROM ' . join( ', ', @$tables ) . ' WHERE ';
    my @where;
    push @where, $join_on if $join_on;
    push @where, map { $_ . ' = ?' } keys %constraints;
    $sql .= join( ' AND ', @where );
    my @params = values %constraints;
    $sql .= $order_by;
    $sql .= $limit;

    # prepare and execute the SQL
    my $sth = $dbh->prepare_cached($sql) || die "Failed to prepare SQL statement:  " . $dbh->errstr;
    $sth->execute(@params) or die $dbh->errstr;

    # Figure out what to do with the results
    if ( $options{COLUMNS} ) {
        # Since we pulled out some columns, we assume that these columns were not checked
        # in the constraints section, and we test them here.
        # It is possible that we could have multiple rows, so keep checking until we
        # find a row where all comparisons are successful.
        while ( my @array = $sth->fetchrow_array ) {
            my $match = 1;
            foreach my $index ( 0 .. $#columns ) {
                my $value = $options{COLUMNS}->{ $columns[$index] };
                if ( $value =~ /^__CREDENTIAL_(\d+)__$/ ) {
                    $value = $creds[ $1 - 1 ];
                }
                if ( !$self->check_filtered( $columns[$index], $value, $array[$index] ) ) {
                    # This test failed, so there is no sense checking the rest of the values
                    # in this row so we bail out early
                    $match = 0;
                    last;
                }
            }
            if ($match) {
                # we found a match so clean up and return the first credential
                $sth->finish;
                return $creds[0];
            }
        }
    } else {
        # Since we are not pulling specific columns we just check
        # to see if we matched at least one row
        my ($count) = $sth->fetchrow_array;
        $sth->finish;
        return $creds[0] if $count;
    }
    return;
}

=head1 SEE ALSO

L<CGI::Application::Plugin::Authentication::Driver>, L<CGI::Application::Plugin::Authentication>, perl(1)


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;
