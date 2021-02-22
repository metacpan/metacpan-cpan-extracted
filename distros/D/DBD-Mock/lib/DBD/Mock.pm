package DBD::Mock;

# --------------------------------------------------------------------------- #
#   Copyright (c) 2004-2007 Stevan Little, Chris Winters
#   (spawned from original code Copyright (c) 1994 Tim Bunce)
# --------------------------------------------------------------------------- #
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
# --------------------------------------------------------------------------- #

use 5.008001;

use strict;
use warnings;

use DBI;

use DBD::Mock::dr;
use DBD::Mock::db;
use DBD::Mock::st;
use DBD::Mock::StatementTrack;
use DBD::Mock::StatementTrack::Iterator;
use DBD::Mock::Session;
use DBD::Mock::Pool;
use DBD::Mock::Pool::db;

sub import {
    shift;
    $DBI::connect_via = "DBD::Mock::Pool::connect"
      if ( @_ && lc( $_[0] ) eq "pool" );
}

our $VERSION = '1.59';

our $drh    = undef;    # will hold driver handle
our $err    = 0;        # will hold any error codes
our $errstr = '';       # will hold any error messages

# Defaulting a result set's fields to undef changes the way DBD::Mock responds, so we default it to off
our $DefaultFieldsToUndef = 0; 


sub driver {
    return $drh if defined $drh;
    my ( $class, $attributes ) = @_;
    $attributes = {}
      unless ( defined($attributes) && ( ref($attributes) eq 'HASH' ) );
    $drh = DBI::_new_drh(
        "${class}::dr",
        {
            Name    => 'Mock',
            Version => $DBD::Mock::VERSION,
            Attribution =>
'DBD Mock driver by Chris Winters & Stevan Little (orig. from Tim Bunce)',
            Err    => \$DBD::Mock::err,
            Errstr => \$DBD::Mock::errstr,

            # mock attributes
            mock_connect_fail => 0,

            # and pass in any extra attributes given
            %{$attributes}
        }
    );
    return $drh;
}

sub CLONE { undef $drh }

# NOTE:
# this feature is still quite experimental. It is defaulted to
# be off, but it can be turned on by doing this:
#    $DBD::Mock::AttributeAliasing++;
# and then turned off by doing:
#    $DBD::Mock::AttributeAliasing = 0;
# we shall see how this feature works out.

our $AttributeAliasing = 0;

my %AttributeAliases = (
    mysql => {
        db => {

            # aliases can either be a string which is obvious
            mysql_insertid => 'mock_last_insert_id'
        },
        st => {

            # but they can also be a subroutine reference whose
            # first argument will be either the $dbh or the $sth
            # depending upon which context it is aliased in.
            mysql_insertid =>
              sub { (shift)->{Database}->{'mock_last_insert_id'} }
        }
    },

    mariadb => {
        db => {
            mariadb_insertid => 'mock_last_insert_id'
        },
        st => {
            mariadb_insertid =>
              sub { (shift)->{Database}->{'mock_last_insert_id'} }
        }
    }
);

sub _get_mock_attribute_aliases {
    my ($dbname) = @_;
    ( exists $AttributeAliases{ lc($dbname) } )
      || die "Attribute aliases not available for '$dbname'";
    return $AttributeAliases{ lc($dbname) };
}

sub _set_mock_attribute_aliases {
    my ( $dbname, $dbh_or_sth, $key, $value ) = @_;
    return $AttributeAliases{ lc($dbname) }->{$dbh_or_sth}->{$key} = $value;
}

## Some useful constants

use constant NULL_RESULTSET => [ [] ];

1;

__END__

=head1 NAME

DBD::Mock - Mock database driver for testing

=head1 SYNOPSIS

    use DBI;

    # connect to your as normal, using 'Mock' as your driver name
    my $dbh = DBI->connect( 'DBI:Mock:', '', '' )
        || die "Cannot create handle: $DBI::errstr\n";

    # create a statement handle as normal and execute with parameters
    my $sth = $dbh->prepare( 'SELECT this, that FROM foo WHERE id = ?' );
    $sth->execute( 15 );

    # Now query the statement handle as to what has been done with it
    my $mock_params = $sth->{mock_params};
    print "Used statement: ", $sth->{mock_statement}, "\n",
       "Bound parameters: ", join( ', ', @{ $mock_params } ), "\n";

=head1 DESCRIPTION

Testing with databases can be tricky. If you are developing a system married to
a single database then you can make some assumptions about your environment and
ask the user to provide relevant connection information. But if you need to
test a framework that uses DBI, particularly a framework that uses different
types of persistence schemes, then it may be more useful to simply verify what
the framework is trying to do -- ensure the right SQL is generated and that the
correct parameters are bound. C<DBD::Mock> makes it easy to just modify your
configuration (presumably held outside your code) and just use it instead of
C<DBD::Foo> (like L<DBD::Pg> or L<DBD::mysql>) in your framework.

There is no distinct area where using this module makes sense. (Some people may
successfully argue that this is a solution looking for a problem...) Indeed, if
you can assume your users have something like L<DBD::AnyData> or L<DBD::SQLite>
or if you do not mind creating a dependency on them then it makes far more sense
to use these legitimate driver implementations and test your application in the
real world -- at least as much of the real world as you can create in your
tests...

And if your database handle exists as a package variable or something else
easily replaced at test-time then it may make more sense to use
L<Test::MockObject> to create a fully dynamic handle. There is an excellent
article by chromatic about using L<Test::MockObject> in this and other ways,
strongly recommended. (See L<SEE ALSO> for a link)

=head2 How does it work?

C<DBD::Mock> comprises a set of classes used by DBI to implement a database
driver. But instead of connecting to a datasource and manipulating data found
there it tracks all the calls made to the database handle and any created
statement handles. You can then inspect them to ensure what you wanted to
happen actually happened. For instance, say you have a configuration file with
your database connection information:

    [DBI]
    dsn      = DBI:Pg:dbname=myapp
    user     = foo
    password = bar

And this file is read in at process startup and the handle stored for other
procedures to use:

    package ObjectDirectory;

    my ( $DBH );

    sub run_at_startup {
        my ( $class, $config ) = @_;
        $config ||= read_configuration( ... );
        my $dsn  = $config->{DBI}{dsn};
        my $user = $config->{DBI}{user};
        my $pass = $config->{DBI}{password};
        $DBH = DBI->connect( $dsn, $user, $pass ) || die ...;
    }

    sub get_database_handle {
        return $DBH;
    }

A procedure might use it like this (ignoring any error handling for the
moment):

    package My::UserActions;

    sub fetch_user {
        my ( $class, $login ) = @_;
        my $dbh = ObjectDirectory->get_database_handle;
        my $sql = q{
            SELECT login_name, first_name, last_name, creation_date, num_logins
            FROM users
            WHERE login_name = ?
        };
        my $sth = $dbh->prepare( $sql );
        $sth->execute( $login );
        my $row = $sth->fetchrow_arrayref;
        return ( $row ) ? User->new( $row ) : undef;
  }

So for the purposes of our tests we just want to ensure that:

=over 4

=item 1. The right SQL is being executed

=item 2. The right parameters are bound

=back

Assume whether the SQL actually B<works> or not is irrelevant for this test :-)

To do that our test might look like:

    my $config = ObjectDirectory->read_configuration( ... );
    $config->{DBI}{dsn} = 'DBI:Mock:';
    ObjectDirectory->run_at_startup( $config );

    my $login_name = 'foobar';
    my $user = My::UserActions->fetch_user( $login_name );

    # Get the handle from ObjectDirectory;
    # this is the same handle used in the
    # 'fetch_user()' procedure above
    my $dbh = ObjectDirectory->get_database_handle();

    # Ask the database handle for the history
    # of all statements executed against it
    my $history = $dbh->{mock_all_history};

    # Now query that history record to
    # see if our expectations match reality
    is(scalar(@{$history}), 1, 'Correct number of statements executed' ;

    my $login_st = $history->[0];
    like($login_st->statement,
        qr/SELECT login_name.*FROM users WHERE login_name = ?/sm,
        'Correct statement generated' );

    my $params = $login_st->bound_params;
    is(scalar(@{$params}), 1, 'Correct number of parameters bound');
    is($params->[0], $login_name, 'Correct value for parameter 1' );

    # Reset the handle for future operations
    $dbh->{mock_clear_history} = 1;

The list of properties and what they return is listed below. But in an overall
view:

=over 4

=item *

A database handle contains the history of all statements created against it.
Other properties set for the handle (e.g., C<PrintError>, C<RaiseError>) are
left alone and can be queried as normal, but they do not affect anything. (A
future feature may track the sequence/history of these assignments but if there
is no demand it probably will not get implemented.)

=item *

A statement handle contains the statement it was prepared with plus all bound
parameters or parameters passed via C<execute()>. It can also contain
predefined results for the statement handle to C<fetch>, track how many fetches
were called and what its current record is.

=back

=head2 A Word of Warning

This may be an incredibly naive implementation of a DBD. But it works for me...

=head1 DBD::Mock

Since this is a normal DBI statement handle we need to expose our tracking
information as properties (accessed like a hash) rather than methods.

=head2 Database Driver Properties

=over 4

=item B<C<mock_connect_fail>>

This is a boolean property which when set to true (C<1>) will not allow DBI to
connect. This can be used to simulate a DSN error or authentication failure.
This can then be set back to false (C<0>) to resume normal DBI operations. Here
is an example of how this works:

    # install the DBD::Mock driver
    my $drh = DBI->install_driver('Mock');

    $drh->{mock_connect_fail} = 1;

    # this connection will fail
    my $dbh = DBI->connect('dbi:Mock:', '', '') || die "Cannot connect";

    # this connection will throw an exception
    my $dbh = DBI->connect('dbi:Mock:', '', '', { RaiseError => 1 });

    $drh->{mock_connect_fail} = 0;

    # this will work now ...
    my $dbh = DBI->connect(...);

This feature is conceptually different from the C<mock_can_connect> attribute
of the C<$dbh> in that it has a driver-wide scope, where C<mock_can_connect>
is handle-wide scope. It also only prevents the initial connection, any C<$dbh>
handles created prior to setting C<mock_connect_fail> to true (C<1>) will still
go on working just fine.

=item B<C<mock_data_sources>>

This is an ARRAY reference which holds fake data sources which are returned by
the Driver and Database Handle's C<data_source()> method.

=item B<C<mock_add_data_sources>>

This takes a string and adds it to the C<mock_data_sources> attribute.

=back

=head2 Database Handle Properties

=over 4

=item B<C<mock_all_history>>

Returns an array reference with all history (a.k.a.
C<DBD::Mock::StatementTrack>) objects created against the database handle in
the order they were created. Each history object can then report information
about the SQL statement used to create it, the bound parameters, etc..

=item B<C<mock_all_history_iterator>>

Returns a C<DBD::Mock::StatementTrack::Iterator> object which will iterate
through the current set of C<DBD::Mock::StatementTrack> object in the history.
See the L</DBD::Mock::StatementTrack::Iterator> documentation below for more
information.

=item B<C<mock_clear_history>>

If set to a true value all previous statement history operations will be
erased. This B<includes> the history of currently open handles, so if you do
something like:

    my $dbh = get_handle( ... );
    my $sth = $dbh->prepare( ... );
    $dbh->{mock_clear_history} = 1;
    $sth->execute( 'Foo' );

You will have no way to learn from the database handle that the statement
parameter 'Foo' was bound.

This is useful mainly to ensure you can isolate the statement histories from
each other. A typical sequence will look like:

    set handle to framework
    perform operations
    analyze mock database handle
    reset mock database handle history
    perform more operations
    analyze mock database handle
    reset mock database handle history
    ...

=item B<C<mock_can_connect>>

This statement allows you to simulate a downed database connection. This is
useful in testing how your application/tests will perform in the face of some
kind of catastrophic event such as a network outage or database server failure.
It is a simple boolean value which defaults to on, and can be set like this:

    # turn the database off
    $dbh->{mock_can_connect} = 0;

    # turn it back on again
    $dbh->{mock_can_connect} = 1;

The statement handle checks this value as well, so something like this
will fail in the expected way:

    $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    $dbh->{mock_can_connect} = 0;

    # blows up!
    my $sth = eval { $dbh->prepare( 'SELECT foo FROM bar' ) });
    if ( $@ ) {
        # Here, $DBI::errstr = 'No connection present'
    }

Turning off the database after a statement prepare will fail on the statement
C<execute()>, which is hopefully what you would expect:

    $dbh = DBI->connect( 'DBI:Mock:', '', '' );

    # ok!
    my $sth = eval { $dbh->prepare( 'SELECT foo FROM bar' ) });
    $dbh->{mock_can_connect} = 0;

    # blows up!
    $sth->execute;

Similarly:

    $dbh = DBI->connect( 'DBI:Mock:', '', '' );

    # ok!
    my $sth = eval { $dbh->prepare( 'SELECT foo FROM bar' ) });

    # ok!
    $sth->execute;

    $dbh->{mock_can_connect} = 0;

    # blows up!
    my $row = $sth->fetchrow_arrayref;

Note: The handle attribute C<Active> and the handle method C<ping> will behave
according to the value of C<mock_can_connect>. So if C<mock_can_connect> were
to be set to C<0> (or off), then both C<Active> and C<ping> would return false
values (or C<0>).

=item B<C<mock_add_resultset( \@resultset | \%resultset_and_options )>>

This stocks the database handle with a record set, allowing you to seed data
for your application to see if it works properly. Each recordset is a simple
arrayref of arrays with the first arrayref being the field names used. Every
time a statement handle is created it asks the database handle if it has any
resultsets available and if so uses it.

Here is a sample usage, partially from the test suite:

    my @user_results = (
        [ 'login', 'first_name', 'last_name' ],
        [ 'cwinters', 'Chris', 'Winters' ],
        [ 'bflay', 'Bobby', 'Flay' ],
        [ 'alincoln', 'Abe', 'Lincoln' ],
    );
    my @generic_results = (
        [ 'foo', 'bar' ],
        [ 'this_one', 'that_one' ],
        [ 'this_two', 'that_two' ],
    );

    my $dbh = DBI->connect( 'DBI:Mock:', '', '' );
    $dbh->{mock_add_resultset} = \@user_results;    # add first resultset
    $dbh->{mock_add_resultset} = \@generic_results; # add second resultset
    my ( $sth );
    eval {
        $sth = $dbh->prepare( 'SELECT login, first_name, last_name FROM foo' );
        $sth->execute();
    };

    # this will fetch rows from the first resultset...
    my $row1 = $sth->fetchrow_arrayref;
    my $user1 = User->new( login => $row->[0],
                           first => $row->[1],
                           last  => $row->[2] );
    is( $user1->full_name, 'Chris Winters' );

    my $row2 = $sth->fetchrow_arrayref;
    my $user2 = User->new( login => $row->[0],
                           first => $row->[1],
                           last  => $row->[2] );
    is( $user2->full_name, 'Bobby Flay' );
    ...

    my $sth_generic = $dbh->prepare( 'SELECT foo, bar FROM baz' );
    $sth_generic->execute;

    # this will fetch rows from the second resultset...
    my $row = $sth->fetchrow_arrayref;

It is possible to assign a hashref where the resultset must be given as
value for the C<results> key:

    $dbh->{mock_add_resultset} = {
        results => [
            [ 'foo', 'bar' ],
            [ 'this_one', 'that_one' ],
            [ 'this_two', 'that_two' ],
        ],
    };

The reason for the hashref form is that you can add options as described
in the following.

You can associate a resultset with a particular SQL statement instead of
adding them in the order they will be fetched:

    $dbh->{mock_add_resultset} = {
        sql     => 'SELECT foo, bar FROM baz',
        results => [
            [ 'foo', 'bar' ],
            [ 'this_one', 'that_one' ],
            [ 'this_two', 'that_two' ],
        ],
    };

This will return the given results when the statement
'C<SELECT foo, bar FROM baz>' is prepared/executed. Note that they will be
returned B<every time> the statement is prepared/executed, not just the first.
It should also be noted that if you want, for some reason, to change the result
set bound to a particular SQL statement, all you need to do is add the result
set again with the same SQL statement and C<DBD::Mock> will overwrite it.

If the C<sql> parameter is a regular expression reference then the results will
be returned for any SQL statements that matches it:

    $dbh->{mock_add_resultset} = {
        sql     => qr/^SELECT foo FROM/i,
        results => [
            [ 'foo' ],
            [ 'this_one' ],
        ],
    };

If an SQL statement matches both a specified SQL statement result set and a
regular expression result set then the specified SQL statement takes precedence.
If two regular expression result sets match then the first one added takes
precedence:

    # Set up our first regex matching result set
    $dbh->{mock_add_resultset} = {
        sql => qr/^SELECT foo/,
        results => [ [ 'foo' ], [ 200 ] ],
    };

    # Set up our second regex matching result set
    #   Note - This results set would never be used as the one above will match
    #   and thus take precedence
    $dbh->{mock_add_resultset} = {
        sql => qr/^SELECT foo FROM/,
        results => [ [ 'foo' ], [ 300 ] ],
    };

    # Set up our first statically defined result set
    # This result set will take precedence over the regex matching ones above
    $dbh->{mock_add_resultset} = {
        sql => 'SELECT foo FROM bar',
        results => [[ 'foo' ], [ 50 ]]
    };

    # This query will be served by the first regex matching result set
    my $sth = $dbh->prepare('SELECT foo FROM oof');
    $sth->execute()

    my ($result) = $sth->fetchrow_array();
    is( $result, 200 );

    # This quere will be served by the statically defined result set
    $sth = $dbh->prepare('SELECT foo FROM bar');
    $sth->execute();

    my ($result2) = $sth->fetchrow_array();
    is( $result2, 50 );

It should also be noted that the C<rows> method will return the number of
records stocked in the result set. So if your code/application makes use of the
C<< $sth->rows >> method for things like C<UPDATE> and C<DELETE> calls you
should stock the result set like so:

    $dbh->{mock_add_resultset} = {
        sql     => 'UPDATE foo SET baz = 1, bar = 2',
        # this will appear to have updated 3 rows
        results => [[ 'rows' ], [], [], []],
    };

    # or ...

    $dbh->{mock_add_resultset} = {
        sql     => 'DELETE FROM foo WHERE bar = 2',
        # this will appear to have deleted 1 row
        results => [[ 'rows' ], []],
    };

Now I admit this is not the most elegant way to go about this, but it works for
me for now, and until I can come up with a better method, or someone sends me a
patch ;) it will do for now.

If you want a given statement to fail, you will have to use the hashref method
and add a C<failure> key. That key must be handed an arrayref with the error
number and error string, in that order.

    $dbh->{mock_add_resultset} = {
        sql => 'SELECT foo FROM bar',
        results => DBD::Mock->NULL_RESULTSET,
        failure => [ 5, 'Ooops!' ],
    };

Without the C<sql> attribute the next statement will fail in any case:

    $dbh->{mock_add_resultset} = {
        results => DBD::Mock->NULL_RESULTSET,
        failure => [ 5, 'Ooops!' ],
    };

=item B<C<mock_get_info>>

This attribute can be used to set up values for C<get_info()>. It takes a
hashref of attribute_name/value pairs. See L<DBI> for more information on the
information types and their meaning.

=item B<C<mock_session>>

This attribute can be used to set a current C<DBD::Mock::Session> object. For
more information on this, see the L</DBD::Mock::Session> docs below. This
attribute can also be used to remove the current session from the C<$dbh>
simply by setting it to C<undef>.

=item B<C<mock_last_insert_id>>

This attribute is incremented each time an C<INSERT> statement is passed to
C<prepare> on a per-handle basis. It's starting value can be set with the
C<mock_start_insert_id> attribute (see below).

    $dbh->{mock_start_insert_id} = 10;

    my $sth = $dbh->prepare('INSERT INTO Foo (foo, bar) VALUES(?, ?)');

    $sth->execute(1, 2);
    # $dbh->{mock_last_insert_id} == 10

    $sth->execute(3, 4);
    # $dbh->{mock_last_insert_id} == 11

For more examples, please refer to the test file
F<t/025_mock_last_insert_id.t>.

To access C<last_insert_id> using driver specific attributes like
C<mysql_insertid> and C<mariadb_insertid> then you can use
L<Attribute Aliasing>.

=item B<C<mock_start_insert_id>>

This attribute can be used to set a start value for the C<mock_last_insert_id>
attribute. It can also be used to effectively reset the C<mock_last_insert_id>
attribute as well.

This attribute also can be used with an ARRAY ref parameter, it's behavior is
slightly different in that instead of incrementing the value for every
C<prepare> it will only increment for each C<execute>. This allows it to be
used over multiple C<execute> calls in a single C<$sth>. It's usage looks like
this:

    $dbh->{mock_start_insert_id} = [ 'Foo', 10 ];
    $dbh->{mock_start_insert_id} = [ 'Baz', 20 ];

    my $sth1 = $dbh->prepare('INSERT INTO Foo (foo, bar) VALUES(?, ?)');

    my $sth2 = $dbh->prepare('INSERT INTO Baz (baz, buz) VALUES(?, ?)');

    $sth1->execute(1, 2);
    # $dbh->{mock_last_insert_id} == 10

    $sth2->execute(3, 4);
    # $dbh->{mock_last_insert_id} == 20

Note that C<DBD::Mock>'s matching of table names in C<INSERT> statements is
fairly simple, so if your table names are quoted in the insert statement
(C<INSERT INTO "Foo">) then you need to quote the name for
C<mock_start_insert_id>:

    $dbh->{mock_start_insert_id} = [ q{"Foo"}, 10 ];

=item B<C<mock_add_parser>>

DBI provides some simple parsing capabilities for C<SELECT> statements to
ensure that placeholders are bound properly. And typically you may simply want
to check after the fact that a statement is syntactically correct, or at least
what you expect.

But other times you may want to parse the statement as it is prepared rather
than after the fact. There is a hook in this mock database driver for you to
provide your own parsing routine or object.

The syntax is simple:

    $dbh->{mock_add_parser} = sub {
        my ( $sql ) = @_;
        unless ( $sql =~ /some regex/ ) {
            die "does not contain secret fieldname";
        }
    };

You can also add more than one for a handle. They will be called in order, and
the first one to fail will halt the parsing process:

    $dbh->{mock_add_parser} = \&parse_update_sql;
    $dbh->{mock_add-parser} = \&parse_insert_sql;

Depending on the C<PrintError> and C<RaiseError> settings in the database
handle any parsing errors encountered will issue a C<warn> or C<die>. No matter
what the statement handle will be C<undef>.

Instead of providing a subroutine reference you can use an object. The only
requirement is that it implements the method C<parse()> and takes a SQL
statement as the only argument. So you should be able to do something like the
following (untested):

    my $parser = SQL::Parser->new( 'mysql', { RaiseError => 1 } );
    $dbh->{mock_add_parser} = $parser;

=item B<C<mock_data_sources>> & B<C<mock_add_data_sources>>

These properties will dispatch to the Driver's properties of the same name.

=back

=head2 Attribute Aliasing

Basically this feature allows you to alias attributes to other attributes. So
for instance, you can alias a commonly expected attribute like
C<mysql_insertid> to something C<DBD::Mock> already has like
C<mock_last_insert_id>. While you can also just set C<mysql_insertid> yourself,
this functionality allows it to take advantage of things like the
autoincrementing of the C<mock_last_insert_id> attribute.

The functionality is off by default so as to not cause any issues with
backwards compatibility, but can easily be turned on and off like this:

    # turn it on
    $DBD::Mock::AttributeAliasing++;

    # turn it off
    $DBD::Mock::AttributeAliasing = 0;

Once this is turned on, you will need to choose a database specific attribute
aliasing table like so:

    DBI->connect('dbi:Mock:MySQL', '', '');

Or, by using the database name if using driver DSNs:

    DBI->connect('dbi:Mock:host=localhost;port=3306;database=MySQL', '', '');

The C<MySQL> in the DSN will be picked up and the MySQL specific attribute
aliasing will be used.

Right now there is only minimal support for MySQL and MariaDB:

=over 4

=item MySQL

Currently the C<mysql_insertid> attribute for C<$dbh> and C<$sth> are aliased
to the C<$dbh> attribute C<mock_last_insert_id>.

=item MariaDB

Currently the C<mariadb_insertid> attribute for C<$dbh> and C<$sth> are aliased
to the C<$dbh> attribute C<mock_last_insert_id>.

=back

It is possible to add more aliases though, using the
C<DBD::Mock:_set_mock_attribute_aliases> function (see the source code for
details)

=head2 Database Driver Methods

=over 4

=item B<C<last_insert_id>>

This returns the value of C<mock_last_insert_id>.

=back

In order to capture C<begin_work()>, C<commit()>, and C<rollback()>,
C<DBD::Mock> will create statements for them, as if you had issued them in the
appropriate SQL command line program. They will go through the standard
C<prepare()>-C<execute()> cycle, meaning that any custom SQL parsers will be
triggered and C<DBD::Mock::Session> will need to know about these statements.

=over 4

=item B<C<begin_work>>

This will create a statement with SQL of C<BEGIN WORK> and no parameters.

=item B<C<commit>>

This will create a statement with SQL of C<COMMIT> and no parameters.

=item B<C<rollback>>

This will create a statement with SQL of C<ROLLBACK> and no parameters.

=back


=head2 Statement Handle Properties

=over 4

=item B<C<Active>>

Returns true if the handle is a C<SELECT> and has more records to fetch, false
otherwise. (From the DBI.)

=item B<C<mock_statement>>

The SQL statement this statement handle was C<prepare>d with. So if the handle
was created with:

    my $sth = $dbh->prepare( 'SELECT * FROM foo' );

This would return:

    SELECT * FROM foo

The original statement is unmodified so if you are checking against it in tests
you may want to use a regex rather than a straight equality check. (However if
you use a phrasebook to store your SQL externally you are a step ahead...)

=item B<C<mock_fields>>

Fields used by the statement. As said elsewhere we do no analysis or parsing to
find these, you need to define them beforehand. That said, you do not actually
need this very often.

Note that this returns the same thing as the normal statement property
C<FIELD>.

=item B<C<mock_params>>

Returns an arrayref of parameters bound to this statement in the order
specified by the bind type. For instance, if you created and stocked a handle
with:

    my $sth = $dbh->prepare( 'SELECT * FROM foo WHERE id = ? AND is_active = ?' );
    $sth->bind_param( 2, 'yes' );
    $sth->bind_param( 1, 7783 );

This would return:

    [ 7738, 'yes' ]

The same result will occur if you pass the parameters via C<execute()> instead:

    my $sth = $dbh->prepare( 'SELECT * FROM foo WHERE id = ? AND is_active = ?' );
    $sth->execute( 7783, 'yes' );

The same using named parameters

    my $sth = $dbh->prepare( 'SELECT * FROM foo WHERE id = :id AND is_active = :active' );
    $sth->bind_param( ':id' => 7783 );
    $sth->bind_param( ':active' => 'yes' );

=item B<C<mock_param_attrs>>

Returns an arrayref of any attributes (parameter type) defined for bound
parameters (note: you rarely need to define attributes for bound parameters).
Where an attribute/type hasn't been that slot in the returned arrayref will be
C<undef>. e.g. for:

    my $sth = $dbh->prepare( 'SELECT * FROM foo WHERE id = ? AND is_active = ?' );
    $sth->bind_param( 2, 'yes' );
    $sth->bind_param( 1 7783, SQL_INTEGER );

This would return:

    [ SQL_INTEGER, undef ]

Passing parameters via C<execute()> will always populate the array with
C<undef>, so for:

    $sth->execute( 7783, 'yes' );

This would return:

    [ undef, undef ]

=item B<C<mock_execution_history>>

Returns an arrayref where each entry contains the details for an execution of
the prepared statement. e.g. after:

    my $sth = $dbh->prepare( 'SELECT * FROM foo WHERE id = ? AND is_active = ?' );
    $sth->bind_param( 2, 'yes' );
    $sth->bind_param( 1 7783, SQL_INTEGER );
    $sth->execute();

    $sth->execute( 1023, 'no' );

Then C<< $sth->{mock_execution_history} >> would be:

    [
        {
            params => [ 7783, 'yes' ],
            attrs  => [ SQL_INTEGER, undef ],
        }, {
            params => [ 1023, 'no' ],
            attrs  => [ undef, undef ],
        }
    ]

=item B<C<mock_records>>

An arrayref of arrayrefs representing the records the mock statement was
stocked with.

=item B<C<mock_num_records>>

Number of records the mock statement was stocked with; if never stocked it is
still C<0>. (Some weirdos might expect undef...)

=item B<C<mock_num_rows>>

This returns the same value as I<mock_num_records>. And is what is returned by
the C<rows> method of the statement handle.

=item B<C<mock_current_record_num>>

Current record the statement is on; returns C<0> in the instances when you have
not yet called C<execute()> and if you have not yet called a C<fetch> method
after the execute.

=item B<C<mock_is_executed>>

Whether C<execute()> has been called against the statement handle. Returns
'yes' if so, 'no' if not.

=item B<C<mock_is_finished>>

Whether C<finish()> has been called against the statement handle. Returns 'yes'
if so, 'no' if not.

=item B<C<mock_is_depleted>>

Returns 'yes' if all the records in the recordset have been returned. If no
C<fetch()> was executed against the statement, or If no return data was set
this will return 'no'.

=item B<C<mock_my_history>>

Returns a C<DBD::Mock::StatementTrack> object which tracks the actions
performed by this statement handle. Most of the actions are separately
available from the properties listed above, so you should never need this.

=back

=head1 DBD::Mock::Pool

This module can be used to emulate L<Apache::DBI> style DBI connection pooling.
Just as with C<Apache::DBI>, you must enable C<DBD::Mock::Pool> before loading
DBI.

    use DBD::Mock qw(Pool);
    # followed by ...
    use DBI;

While this may not seem to make a lot of sense in a single-process testing
scenario, it can be useful when testing code which assumes a multi-process
C<Apache::DBI> pooled environment.

=head1 DBD::Mock::StatementTrack

Under the hood this module does most of the work with a
C<DBD::Mock::StatementTrack> object. This is most useful when you are reviewing
multiple statements at a time, otherwise you might want to use the C<mock_*>
statement handle attributes instead.

=over 4

=item B<C<new( %params )>>

Takes the following parameters:

=over 4

=item *

B<C<return_data>>: Arrayref of return data records

=item *

B<C<fields>>: Arrayref of field names

=item *

B<C<bound_params>>: Arrayref of bound parameters

=item *

B<C<bound_param_attrs>>: Arrayref of bound parameter attributes

=back

=item B<C<statement>> (Statement attribute C<mock_statement>)

Gets/sets the SQL statement used.

=item B<C<fields>>  (Statement attribute C<mock_fields>)

Gets/sets the fields to use for this statement.

=item B<C<bound_params>>  (Statement attribute C<mock_params>)

Gets/set the bound parameters to use for this statement.

=item B<C<return_data>>  (Statement attribute C<mock_records>)

Gets/sets the data to return when asked (that is, when someone calls C<fetch>
on the statement handle).

=item B<C<current_record_num>> (Statement attribute C<mock_current_record_num>)

Gets/sets the current record number.

=item B<C<is_active()>> (Statement attribute C<Active>)

Returns true if the statement is a C<SELECT> and has more records to fetch,
false otherwise. (This is from the DBI, see the 'Active' docs under 'ATTRIBUTES
COMMON TO ALL HANDLES'.)

=item B<C<is_executed( $yes_or_no )>> (Statement attribute C<mock_is_executed>)

Sets the state of the tracker C<executed> flag.

=item B<C<is_finished( $yes_or_no )>> (Statement attribute C<mock_is_finished>)

If set to C<yes> tells the tracker that the statement is finished. This resets
the current record number to C<0> and clears out the array ref of returned
records.

=item B<C<is_depleted()>> (Statement attribute C<mock_is_depleted>)

Returns true if the current record number is greater than the number of records
set to return.

=item B<C<num_fields>>

Returns the number of fields set in the C<fields> parameter.

=item B<C<num_rows>>

Returns the number of records in the current result set.

=item B<C<num_params>>

Returns the number of parameters set in the C<bound_params> parameter.

=item B<C<bound_param( $param_num, $value )>>

Sets bound parameter C<$param_num> to C<$value>. Returns the arrayref of
currently-set bound parameters. This corresponds to the C<bind_param> statement
handle call.

=item B<C<bound_param_trailing( @params )>>

Pushes C<@params> onto the list of already-set bound parameters.

=item B<C<mark_executed()>>

Tells the tracker that the statement has been executed and resets the current
record number to C<0>.

=item B<C<next_record()>>

If the statement has been depleted (all records returned) returns C<undef>;
otherwise it gets the current record for returning, increments the current
record number and returns the current record.

=item B<C<to_string()>>

Tries to give a decent depiction of the object state for use in debugging.

=back

=head1 DBD::Mock::StatementTrack::Iterator

This object can be used to iterate through the current set of
C<DBD::Mock::StatementTrack> objects in the history by fetching the
C<mock_all_history_iterator> attribute from a database handle. This object is
very simple and is meant to be a convenience to make writing long test script
easier. Aside from the constructor (C<new>) this object has the following
methods.

=over 4

=item B<C<next()>>

Calling C<next> will return the next C<DBD::Mock::StatementTrack> object in the
history. If there are no more C<DBD::Mock::StatementTrack> objects available,
then this method will return false.

=item B<C<reset()>>

This will reset the internal pointer to the beginning of the statement history.

=back

=head1 DBD::Mock::Session

The C<DBD::Mock::Session> object is an alternate means of specifying the SQL
statements and result sets for C<DBD::Mock>. The idea is that you can specify a
complete 'session' of usage, which will be verified through C<DBD::Mock>. Here
is an example:

    my $session = DBD::Mock::Session->new('my_session' => (
        {
            statement => "SELECT foo FROM bar", # as a string
            results   => [[ 'foo' ], [ 'baz' ]]
        },
        {
            statement => qr/UPDATE bar SET foo \= \'bar\'/, # as a reg-exp
            results   => [[]]
        },
        {
            statement => sub {  # as a CODE ref
                    my ($SQL, $state) = @_;
                    return $SQL eq "SELECT foo FROM bar";
                    },
            results   => [[ 'foo' ], [ 'bar' ]]
        },
        {
            # with bound parameters
            statement    => "SELECT foo FROM bar WHERE baz = ? AND borg = ?",
            # check exact bound param value,
            # then check it against regexp
            bound_params => [ 10, qr/\d+/ ],
            results      => [[ 'foo' ], [ 'baz' ]]
        }
    ));

As you can see, a session is essentially made up a list of HASH references we
call 'states'. Each state has a C<statement> and a set of C<results>. If
C<DBD::Mock> finds a session in the C<mock_session> attribute, then it will
pass the current C<$dbh> and SQL statement to that C<DBD::Mock::Session>. The
SQL statement will be checked against the C<statement> field in the current
state. If it passes, then the C<results> of the current state will get fed to
C<DBD::Mock> through the C<mock_add_resultset> attribute. We then advance to
the next state in the session, and wait for the next call through C<DBD::Mock>.
If at any time the SQL statement does not match the current state's
C<statement>, or the session runs out of available states, an error will be
raised (and propagated through the normal DBI error handling based on your
values for C<RaiseError> and C<PrintError>).

As can be seen in the session element, bound parameters can also be supplied
and tested. In this statement, the SQL is compared, then when the statement is
executed, the bound parameters are also checked. The bound parameters must
match in both number of parameters and the parameters themselves, or an error
will be raised.

As can also be seen in the example above, C<statement> fields can come in many
forms. The simplest is a string, which will be compared using C<eq> against the
currently running statement. The next is a reg-exp reference, this too will get
compared against the currently running statement. The last option is a CODE
ref, this is sort of a catch-all to allow for a wide range of SQL comparison
approaches (including using modules like L<SQL::Statement> or L<SQL::Parser>
for detailed functional comparisons). The first argument to the CODE ref will
be the currently active SQL statement to compare against, the second argument
is a reference to the current state HASH (in case you need to alter the
results, or store extra information). The CODE is evaluated in boolean context
and throws and exception if it is false.

=over 4

=item B<C<new ($session_name, @session_states)>>

A C<$session_name> can be optionally be specified, along with at least one
C<@session_states>. If you don't specify a C<$session_name>, then a default one
will be created for you. The C<@session_states> must all be HASH references as
well, if this conditions fail, an exception will be thrown.

=item B<C<verify_statement ($dbh, $SQL)>>

This will check the C<$SQL> against the current state's C<statement> value, and
if it passes will add the current state's C<results> to the C<$dbh>. If for
some reason the C<statement> value is bad, not of the prescribed type, an
exception is thrown. See above for more details.

=item B<C<verify_bound_params ($dbh, $params)>>

If the C<bound_params> slot is available in the current state, this will check
the C<$params> against the current state's C<bound_params> value. Both number
of parameters and the parameters themselves must match, or an error will be
raised.

=item B<C<reset>>

Calling this method will reset the state of the session object so that it can
be reused.

=back

=head1 EXPERIMENTAL FUNCTIONALITY

All functionality listed here is highly experimental and should be used with
great caution (if at all).

=over 4

=item Connection Callbacks

This feature allows you to define callbacks that get executed when
C<< DBI->connect >> is called.

To set a series of callbacks you use the
C<DBD::Mock::dr::set_connect_callbacks> function

    use DBD::Mock::dr;

    DBD::Mock::dr::set_connect_callbacks( sub {
        my ( $dbh, $dsn, $user, $password, $attributes ) = @_;

        $dbh->{mock_add_resultset} = {
            sql => 'SELECT foo FROM bar',
            results => [[ 'foo' ], [ 10 ]]
        };
    } );

To set more than one callback to you can simply add extra callbacks to your
call to C<DBD::Mock::dr::set_connect_callbacks>

    DBD::Mock::dr::set_connect_callbacks(
        sub {
            my ( $dbh, $dsn, $user, $password, $attributes ) = @_;

            $dbh->{mock_add_resultset} = {
                sql => 'SELECT foo FROM bar',
                results => [[ 'foo' ], [ 10 ]]
            };
        },

        sub {
            my ( $dbh, $dsn, $user, $password, $attributes ) = @_;

            $dbh->{mock_add_resultset} = {
                sql => 'SELECT foo FROM bar',
                results => [[ 'foo' ], [ 10 ]]
            };
        }
    );

Or you can extend the existing set of callbacks with the
C<DBD::Mock::dr::add_connect_callbacks> function

    DBD::Mock::dr::add_connect_callbacks( sub {
        ( my $dbh, $dsn, $user, $password, $attributes ) = @_;

        $dbh->{mock_add_resultset} = {
            sql => 'SELECT bar FROM foo',
            results => [[ 'bar' ], [ 50 ]]
        };
    } );

=item table_info

This feature adds support for DBI's C<table_info> method (
I<Note this functionality is unstable when used with DBI version 1.634 and below>).

To mock the table info for a search of the C<testSchema> database schema you
would use the following:

    $dbh->{mock_add_table_info} = {
        cataloge   => undef,
        schema     => 'testSchema',
        table      => undef,
        type       => undef,
        table_info => [
            [ 'TABLE_CAT', 'TABLE_SCHEM', 'TABLE_NAME', 'TABLE_TYPE', 'REMARKS' ],
            [ undef,       'testSchema',  'foo',        'TABLE',      undef     ],
            [ undef,       'testSchema',  'bar',        'VIEW',       undef     ],
        ],
    };

The C<cataloge>, C<schema>, C<table> and C<type> parameters need to explicitly
match what you expect table_info to be called with (note: C<table_info> treats
C<undef> and C<''> the same).

Similar to the C<mock_results_sets>, the C<table_info> parameter's first entry
is an arrayref of column names, and the rest are the values of the rows
returned (one arrayref per row).

If you need to cover listing schemas then you'd use:

    $dbh->{mock_add_table_info} = {
        schema     => '%',
        table_info => [
            [ 'TABLE_CAT', 'TABLE_SCHEM',  'TABLE_NAME', 'TABLE_TYPE', 'REMARKS' ],
            [ undef,       'testSchema',   undef,        undef,        undef     ],
            [ undef,       'testSchema_2', undef,        undef,        undef     ],
        ],
    }

To clear the current mocked table info set the database handle's
C<mock_clear_table_info> attribute to C<1>

    $dbh->{mock_clear_table_info} = 1;

=item Result Set Callbacks

If you need your result sets to be more dynamic (e.g. if they need to return
different results based upon bound parameters) then you can use a callback.

    $dbh->{mock_add_resultset} = {
        sql => 'SELECT a FROM b WHERE c = ?',
        callback => sub {
            my @bound_params = @_;

            my %result = (
                fields => [ "a" ],
                rows => [[ 1] ]
            );

            if ($bound_params[0] == 1) {
                $result{rows} = [ [32] ];
            } elsif ($bound_params[0] == 2) {
                $result{rows} = [ [43] ];
            }

            return %result;
        },
    };

    my $sth = $dbh->prepare('SELECT a FROM b WHERE c = ?');

    my $rows = $sth->execute(1);
    my ($result) = $sth->fetchrow_array();  # $result will be 32

    $rows = $sth->execute(2);
    ($result) = $sth->fetchrow_array();  # $result this time will be 43

    $rows = $sth->execute(33); # $results this time will be 1

    ($result) = $sth->fetchrow_array();

The callback needs to return a hash with a C<rows> key that is an array ref of
arrays containing the values to return as the answer to the query. In addition
a C<fields> key can also be returned with an array ref of field names. If a
C<fields> key isn't present in the returned the hash then the fields will be
taken from the C<mock_add_resultset>'s C<results> parameter.

    $dbh->{mock_add_resultset} = {
        sql => 'SELECT x FROM y WHERE z = ?',
        results => [ ["x"] ],
        callback => sub {
            my @bound_params = @_;

            my %result = ( rows => [[ 1] ] );

            if ($bound_params[0] == 1) {
                $result{rows} = [ [32] ];
            } elsif ($bound_params[0] == 2) {
                $result{rows} = [ [43] ];
            }

            return %result;
        },
    };

    my $sth = $dbh->prepare('SELECT x FROM y WHERE z = ?');

    my $rows = $sth->execute(1);
    my ($result) = $sth->fetchrow_array();  # $result will be 32

    $rows = $sth->execute(2);
    ($result) = $sth->fetchrow_array();  # $result will be 43

    $rows = $sth->execute(33);
    ($result) = $sth->fetchrow_array();  # $result will be 1


By default result sets which only define their field names in their callback
return values will have a C<NUM_OF_FIELDS> property of C<0> until after the
statement has actually been executed. This is to make sure that C<DBD::Mock>
stays compatible with previous versions. If you need the C<NUM_OF_FIELDS>
property to be undef in this situation then set the
C<$DBD::Mock::DefaultFieldsToUndef> flag to C<1>.

If you're mocking an INSERT statement with a callback and you want to
explicitly set the database's C<last_insert_id> value then you can use the
C<last_insert_id> key in the result set.  If you don't specify a
C<last_insert_id> then the standard C<DBD::Mock> logic for generating an value
for the last inserted item will be followed.  This will allow you to mock
MySQL/MariaDB INSERT queries that use C<ON DUPLICATE KEY UPDATE> logic to set
the C<last_insert_id>.


    $dbh->{mock_add_resultset} = {
        sql => 'INSERT INTO y ( x ) VALUES ( ? ) ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID( id )',
        callback => sub {
            my @bound_params = @_;

            my %result = (
                fields => [],
                rows => [],
                last_insert_id => 99,
            );

            return %result;
        },
    };

=item Result Set Custom Attributes

If you're mocking a database driver that has it's own custom attributes
attached to its statement handles then you can use the result sets
C<prepare_attributes> and C<execute_attributes> options.

The C<prepare_attributes> option takes a hashref that maps statement handle
attribute names to their values.  The attributes are set at the point that
the statement is prepared.

    $dbh->{mock_add_resultset} = {
        sql => 'SELECT foo FROM bar',
        prepare_attributes => {
            sqlite_unprepared_statements => '   ',
        },
        results => [[ 'foo' ], [ 10 ]]
    };


The C<execute_attributes> option also takes a hashref that maps statement
handle attribute names to their values, however these will only be set when the
statement is executed.

    $dbh->{mock_add_resultset} = {
        sql => 'SELECT foo FROM bar',
        execute_attributes => {
            syb_result_type => 1,
        },
        results => [[ 'foo' ], [ 10 ]]
    };

If an attribute is also present in the C<prepare_attributes> option then the
C<prepare_attributes> version will take precedence up to the point the
statement handle is executed, at which point the C<execute_attributes> version
will take precedence.

It is also possible to set C<execute_attributes> from a result set's callback
by returning them under the C<execute_attributes> key in your callback's
response.

    $dbh->{mock_add_resultset} = {
        sql => 'SELECT baz FROM qux',
        callback => sub {
            my @bound_params = @_;

            my %result = (
                fields => [ 'baz'],
                rows => [],
                execute_attributes => {
                    foo => 'bar'
                },
            );

            return %result;
        }
    };

If a result set has an C<execute_attributes> option and a callback that also
returns an C<execute_attributes> key then the callback's C<execute_attributes>
value will take precedence.

=back

=head1 BUGS

=over

=item Odd C<$dbh> attribute behavior

When writing the test suite I encountered some odd behavior with some C<$dbh>
attributes. I still need to get deeper into how DBD's work to understand what
it is that is actually doing wrong.

=back

=head1 TO DO

=over

=item Make DBD specific handlers

Each DBD has its own quirks and issues, it would be nice to be able to handle
those issues with C<DBD::Mock> in some way. I have an number of ideas already,
but little time to sit down and really flesh them out. If you have any
suggestions or thoughts, feel free to email me with them.

=item Enhance the C<DBD::Mock::StatementTrack> object

I would like to have the C<DBD::Mock::StatementTrack> object handle more of the
C<mock_*> attributes. This would encapsulate much of the C<mock_*> behavior in
one place, which would be a good thing.

=back

=head1 SEE ALSO

L<DBI>

L<DBD::NullP>, which provided a good starting point

L<Test::MockObject>, which provided the approach

Test::MockObject article - L<http://www.perl.com/pub/a/2002/07/10/tmo.html>

Perl Code Kata: Testing Databases - L<http://www.perl.com/pub/a/2005/02/10/database_kata.html>

=head1 ACKNOWLEDGEMENTS

=over 4

=item Thanks to Ryan Gerry for his patch in RT #26604.

=item Thanks to Marc Beyer for his patch in RT #16951.

=item Thanks to Justin DeVuyst for the mock_connect_fail idea.

=item Thanks to Thilo Planz for the code for C<bind_param_inout>.

=item Thanks to Shlomi Fish for help tracking down RT Bug #11515.

=item Thanks to Collin Winter for the patch to fix the C<begin_work()>,
C<commit()> and C<rollback()> methods.

=item Thanks to Andrew McHarg E<lt>amcharg@acm.orgE<gt> for
C<fetchall_hashref()>, C<fetchrow_hashref()> and C<selectcol_arrayref()>
methods and tests.

=item Thanks to Andrew W. Gibbs for the C<mock_last_insert_ids> patch and test.

=item Thanks to Chas Owens for patch and test for the C<mock_can_prepare>,
C<mock_can_execute>, and C<mock_can_fetch> features.

=item Thanks to Tomas Zemresfor the unit test in RT #71438.

=item Thanks to Bernhard Graf for multiple patches fixing a range of issues
and adding a new I<One Shot Failure> feature to C<mock_add_resultset>.

=item Thanks to Erik Huelsmann for testing the new result set custom attributes
feature.

=back

=head1 COPYRIGHT

Copyright (C) 2004 Chris Winters E<lt>chris@cwinters.comE<gt>

Copyright (C) 2004-2007 Stevan Little E<lt>stevan@iinteractive.comE<gt>

Copyright (C) 2007 Rob Kinyon E<lt>rob.kinyon@gmail.comE<gt>

Copyright (C) 2011 Mariano Wahlmann E<lt>dichoso  _at_ gmail.comE<gt>

Copyright (C) 2019 Jason Cooper E<lt>JLCOOPER@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Rob Kinyon E<lt>rob.kinyon@gmail.comE<gt>

Mariano Wahlmann E<lt>dichoso _at_ gmail.comE<gt>

Jason Cooper E<lt>JLCOOPER@cpan.orgE<gt>

=cut
