# *************************************************************************
# Copyright (c) 2014-2017, SUSE LLC
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# *************************************************************************

package App::Dochazka::REST::Model::Shared;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $site );
use Data::Dumper;
use JSON;
use Params::Validate qw( :all );
use Try::Tiny;




=head1 NAME

App::Dochazka::REST::Model::Shared - functions shared by several modules within
the data model




=head1 SYNOPSIS

    use App::Dochazka::REST::Model::Shared;

    ...




=head1 EXPORTS

=cut 

use Exporter qw( import );
our @EXPORT_OK = qw( 
    canonicalize_date
    canonicalize_ts
    canonicalize_tsrange
    cud 
    cud_generic
    decode_schedule_json 
    get_history
    load 
    load_multiple 
    noof 
    priv_by_eid 
    schedule_by_eid 
    select_single 
    select_set_of_single_scalar_rows
    split_tsrange
    timestamp_delta_minus
    timestamp_delta_plus
    tsrange_intersection
    tsrange_equal
);




=head1 FUNCTIONS


=head2 canonicalize_date

Given a string that PostgreSQL might recognize as a date, pass it to
the database via the SQL statement:

    SELECT CAST( ? AS date )

and return the resulting status object.

=cut

sub canonicalize_date {
    my ( $conn, $ts ) = @_;

    my $status = select_single(
        conn => $conn,
        sql => 'SELECT CAST( ? AS date )',
        keys => [ $ts ],
    );
    _replace_payload_array_with_string( $status ) if $status->ok;
    return $status;    
}


=head2 canonicalize_ts

Given a string that might be a timestamp, "canonicalize" it by running it
through the database in the SQL statement:

    SELECT CAST( ? AS timestamptz )

=cut

sub canonicalize_ts {
    my ( $conn, $ts ) = @_;

    my $status = select_single(
        conn => $conn,
        sql => 'SELECT CAST( ? AS timestamptz )',
        keys => [ $ts ],
    );
    _replace_payload_array_with_string( $status ) if $status->ok;
    return $status;    
}

sub _replace_payload_array_with_string {
    my $status = shift;
    $status->payload( $status->payload->[0] );
    return $status;
}


=head2 canonicalize_tsrange

Given a string that might be a tsrange, "canonicalize" it by running it
through the database in the SQL statement:

    SELECT CAST( ? AS tstzrange )

Returns an L<App::CELL::Status> object. If the status code is OK, then the
tsrange is OK and its canonicalized form is in the payload. Otherwise, some
kind of error occurred, as described in the status object.

=cut

sub canonicalize_tsrange {
    my ( $conn, $tsr ) = @_;

    my $status = select_single(
        conn => $conn,
        sql => 'SELECT CAST( ? AS tstzrange)',
        keys => [ $tsr ],
    );
    _replace_payload_array_with_string( $status ) if $status->ok;
    return $CELL->status_err( 'DOCHAZKA_TSRANGE_EMPTY' ) if $status->ok and $status->payload eq "empty";
    return $status;
}


=head2 cud

Attempts to Create, Update, or Delete a single database record. Takes the
following PARAMHASH:

=over

=item * conn

The L<DBIx::Connector> object with which to gain access to the database.

=item * eid

The EID of the employee originating the request (needed for the audit triggers).

=item * object

The Dochazka datamodel object to be worked on.

=item * sql

The SQL statement to execute (should be INSERT, UPDATE, or DELETE).

=item * attrs

An array reference containing the bind values to be plugged into the SQL
statement.

=back

Returns a status object.

Important note: it is up to the programmer to not pass any SQL statement that
might affect more than one record.

=cut

sub cud {
    my %ARGS = validate( @_, {
        conn => { isa => 'DBIx::Connector' },
        eid => { type => SCALAR },
        object => { can => [ qw( insert delete ) ] }, 
        sql => { type => SCALAR }, 
        attrs => { type => ARRAYREF }, # order of attrs must match SQL statement
    } );

    my ( $status, $rv, $count );

    try {
        local $SIG{__WARN__} = sub {
                die @_;
            };

        # start transaction
        $ARGS{'conn'}->txn( fixup => sub {

            # get DBI db handle
            my $dbh = shift;

            # set the dochazka.eid GUC session parameter
            $dbh->do( $site->SQL_SET_DOCHAZKA_EID_GUC, undef, ( $ARGS{'eid'}+0 ) );

            # prepare the SQL statement and bind parameters
            my $sth = $dbh->prepare( $ARGS{'sql'} );
            my $counter = 0;
            map {
                $counter += 1;
                $sth->bind_param( $counter, $ARGS{'object'}->{$_} );
            } @{ $ARGS{'attrs'} }; 

            # execute the SQL statement
            $rv = $sth->execute;
            $log->debug( "cud: DBI execute returned " . Dumper( $rv ) );
            if ( $rv == 1 ) {

                # a record was returned; get the values
                my $rh = $sth->fetchrow_hashref;
                $log->info( "Statement " . $sth->{'Statement'} . " RETURNING values: " . Dumper( $rh ) );
                # populate object with all RETURNING fields 
                map { $ARGS{'object'}->{$_} = $rh->{$_}; } ( keys %$rh );

                # count number of rows affected
                $count = $sth->rows;

            } elsif ( $rv eq '0E0' ) {

                # no error, but no record returned either
                $count = $sth->rows;

            } elsif ( $rv > 1 ) {
                $status = $CELL->status_crit( 
                    'DOCHAZKA_CUD_MORE_THAN_ONE_RECORD_AFFECTED', 
                    args => [ $sth->{'Statement'} ] 
                ); 
            } elsif ( $rv == -1 ) {
                $status = $CELL->status_err( 
                    'DOCHAZKA_CUD_UNKNOWN_NUMBER_OF_RECORDS_AFFECTED', 
                    args => [ $sth->{'Statement'} ] 
                ); 
            } else {
                $status = $CELL->status_crit( 'DOCHAZKA_DBI_EXECUTE_WEIRDNESS' );
            }
        } );
    } catch {
        my $errmsg = $_;
        if ( not defined( $errmsg ) ) {
            $log->err( '$_ undefined in catch' );
            $errmsg = '<NONE>';
        }
        if ( ! $site->DOCHAZKA_SQL_TRACE ) {
            $errmsg =~ s/^DBD::Pg::st execute failed: //;
            $errmsg =~ s#at /usr/lib/perl5/.* line .*\.$##;
        }
        if ( ! defined( $status ) ) {
            $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', 
                args => [ $errmsg ],
                DBI_return_value => $rv,
            );
        }
    };

    if ( not defined( $status ) ) {
        $status = $CELL->status_ok( 'DOCHAZKA_CUD_OK', 
            DBI_return_value => $rv,
            payload => $ARGS{'object'}, 
            count => $count,
        );
    }

    return $status;
}


=head2 cud_generic

Attempts to execute a generic Create, Update, or Delete database operation.
Takes the following PARAMHASH:

=over

=item * conn

The L<DBIx::Connector> object with which to gain access to the database.

=item * eid

The EID of the employee originating the request (needed for the audit triggers).

=item * sql

The SQL statement to execute (should be INSERT, UPDATE, or DELETE).

=item * bind_params

An array reference containing the bind values to be plugged into the SQL
statement.

=back

Returns a status object.

Important note: it is up to the programmer to not pass any SQL statement that
might affect more than one record.

=cut

sub cud_generic {
    my %ARGS = validate( @_, {
        conn => { isa => 'DBIx::Connector' },
        eid => { type => SCALAR },
        sql => { type => SCALAR }, 
        bind_params => { type => ARRAYREF, optional => 1 }, # order must match SQL statement
    } );
    $log->info( "Entering " . __PACKAGE__ . "::cud_generic with" );
    $log->info( "sql: $ARGS{sql}" );
    $log->info( "bind_param: " . Dumper( $ARGS{bind_params} ) );

    my ( $status, $rv, $count );

    try {
        local $SIG{__WARN__} = sub {
                die @_;
            };

        # start transaction
        $ARGS{'conn'}->txn( fixup => sub {

            # get DBI db handle
            my $dbh = shift;

            # set the dochazka.eid GUC session parameter
            $dbh->do( $site->SQL_SET_DOCHAZKA_EID_GUC, undef, ( $ARGS{'eid'}+0 ) );

            # prepare the SQL statement and bind parameters
            my $sth = $dbh->prepare( $ARGS{'sql'} );
            my $counter = 0;
            map {
                $counter += 1;
                $sth->bind_param( $counter, $_ || undef );
            } @{ $ARGS{'bind_params'} }; 

            # execute the SQL statement
            $rv = $sth->execute;
            $log->debug( "cud_generic: DBI execute returned " . Dumper( $rv ) );
            if ( $rv >= 1 ) {

                # count number of rows affected
                $count = $sth->rows;

            } elsif ( $rv eq '0E0' ) {

                # no error, but no record returned either
                $count = $sth->rows;

            } elsif ( $rv == -1 ) {
                $status = $CELL->status_err( 
                    'DOCHAZKA_CUD_UNKNOWN_NUMBER_OF_RECORDS_AFFECTED', 
                    args => [ $sth->{'Statement'} ] 
                ); 
            } else {
                $status = $CELL->status_crit( 'DOCHAZKA_DBI_EXECUTE_WEIRDNESS' );
            }
        } );
    } catch {
        my $errmsg = $_;
        if ( not defined( $errmsg ) ) {
            $log->err( '$_ undefined in catch' );
            $errmsg = '<NONE>';
        }
        if ( not defined( $status ) ) {
            $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', 
                args => [ $errmsg ],
                DBI_return_value => $rv,
            );
        }
    };

    if ( not defined( $status ) ) {
        $status = $CELL->status_ok( 'DOCHAZKA_CUD_OK', 
            DBI_return_value => $rv, 
            count => $count,
        );
    }

    return $status;
}


=head2 decode_schedule_json

Given JSON string representation of the schedule, return corresponding HASHREF.

=cut

sub decode_schedule_json {
    my ( $json_str ) = @_;

    return unless $json_str;
    return JSON->new->utf8->canonical(1)->decode( $json_str );
}


=head2 get_history

This function takes a number of arguments. The first two are (1) a SCALAR
argument, which can be either 'priv' or 'schedule', and (2) a L<DBIx::Connector>
object.

Following these there is a PARAMHASH which can have one or more of the
properties 'eid', 'nick', and 'tsrange'. At least one of { 'eid', 'nick' } must
be specified. If both are specified, the employee is determined according to
'eid'.

The function returns the history of privilege level or schedule changes for
that employee over the given tsrange, or the entire history if no tsrange is
supplied. 

The return value will always be an L<App::CELL::Status|status> object.

Upon success, the payload will be a reference to an array of history
objects. If nothing is found, the array will be empty. If there is a DBI error,
the payload will be undefined.

=cut

sub get_history { 
    my $t = shift; # 'priv' or 'sched'
    my $conn = shift;
    validate_pos( @_, 1, 1, 0, 0, 0, 0 );
    my %ARGS = validate( @_, { 
        eid => { type => SCALAR, optional => 1 },
        nick => { type => SCALAR, optional => 1 },
        tsrange => { type => SCALAR|UNDEF, optional => 1 },
    } );

    $log->debug("Entering get_history for $t - arguments: " . Dumper( \%ARGS ) );

    my ( $sql, $sk, $status, $result, $tsr );
    if ( exists $ARGS{'nick'} ) {
        $sql = ($t eq 'priv') 
            ? $site->SQL_PRIVHISTORY_SELECT_RANGE_BY_NICK
            : $site->SQL_SCHEDHISTORY_SELECT_RANGE_BY_NICK;
        $result->{'nick'} = $ARGS{'nick'};
        $result->{'eid'} = $ARGS{'eid'} if exists $ARGS{'eid'};
        $sk = $ARGS{'nick'};
    }
    if ( exists $ARGS{'eid'} ) {
        $sql = ($t eq 'priv') 
            ? $site->SQL_PRIVHISTORY_SELECT_RANGE_BY_EID
            : $site->SQL_SCHEDHISTORY_SELECT_RANGE_BY_EID;
        $result->{'eid'} = $ARGS{'eid'};
        $result->{'nick'} = $ARGS{'nick'} if exists $ARGS{'nick'};
        $sk = $ARGS{'eid'};
    }
    $log->debug("sql == $sql");
    $tsr = ( $ARGS{'tsrange'} )
        ? $ARGS{'tsrange'}
        : '[,)';
    $result->{'tsrange'} = $tsr;
    $log->debug("tsrange == $tsr");

    die "AAAAAAAAAAAHHHHH! Engulfed by the abyss" unless $sk and $sql and $tsr;

    $result->{'history'} = [];
    try {
        $conn->run( fixup => sub {
            my $sth = $_->prepare( $sql );
            $sth->execute( $sk, $tsr );
            while( defined( my $tmpres = $sth->fetchrow_hashref() ) ) {
                push @{ $result->{'history'} }, $tmpres;
            }
        } );
    } catch {
        $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', args => [ $_ ] );
    };
    return $status if defined $status;

    my $counter = scalar @{ $result->{'history'} };
    return ( $counter ) 
        ? $CELL->status_ok( 'DISPATCH_RECORDS_FOUND', 
            args => [ $counter ], payload => $result, count => $counter ) 
        : $CELL->status_notice( 'DISPATCH_NO_RECORDS_FOUND', 
            payload => $result, count => $counter );
}


=head2 load

Load a database record into an object based on an SQL statement and a set of
search keys. The search key must be an exact match: this function returns only
1 or 0 records.  Call, e.g., like this:

    my $status = load( 
        conn => $conn,
        class => __PACKAGE__, 
        sql => $site->DOCHAZKA_SQL_SOME_STATEMENT,
        keys => [ 44 ]
    ); 

The status object will be one of the following:

=over

=item * 1 record found

Level C<OK>, code C<DISPATCH_RECORDS_FOUND>, payload: object of type 'class'

=item * 0 records found

Level C<NOTICE>, code C<DISPATCH_NO_RECORDS_FOUND>, payload: none

=item * Database error

Level C<ERR>, code C<DOCHAZKA_DBI_ERR>, text: error message, payload: none

=back

=cut

sub load {
    # get and verify arguments
    my %ARGS = validate( @_, { 
        conn => { isa => 'DBIx::Connector' },
        class => { type => SCALAR }, 
        sql => { type => SCALAR }, 
        keys => { type => ARRAYREF }, 
    } );

    # consult the database; N.B. - select may only return a single record
    my ( $hr, $status );
    try {
        $ARGS{'conn'}->run( fixup => sub {
            $hr = $_->selectrow_hashref( $ARGS{'sql'}, undef, @{ $ARGS{'keys'} } );
        } );
    } catch {
        $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', args => [ $_ ] );
    };

    # report the result
    return $status if $status;
    return $CELL->status_ok( 'DISPATCH_RECORDS_FOUND', args => [ '1' ],
        payload => $ARGS{'class'}->spawn( %$hr ), count => 1 ) if defined $hr;
    return $CELL->status_notice( 'DISPATCH_NO_RECORDS_FOUND', count => 0 );
}


=head2 load_multiple

Load multiple database records based on an SQL statement and a set of search
keys. Example:

    my $status = load_multiple( 
        conn => $conn,
        class => __PACKAGE__, 
        sql => $site->DOCHAZKA_SQL_SOME_STATEMENT,
        keys => [ 'rom%' ] 
    ); 

The return value will be a status object, the payload of which will be an
arrayref containing a set of objects. The objects are constructed by calling
$ARGS{'class'}->spawn

For convenience, a 'count' property will be included in the status object.

=cut

sub load_multiple {
    # get and verify arguments
    my %ARGS = validate( @_, { 
        conn => { isa => 'DBIx::Connector' },
        class => { type => SCALAR }, 
        sql => { type => SCALAR }, 
        keys => { type => ARRAYREF }, 
    } );
    $log->debug( "Entering " . __PACKAGE__ . "::load_multiple" );

    my $status;
    my $results = [];
    try {
        $ARGS{'conn'}->run( fixup => sub {
            my $sth = $_->prepare( $ARGS{'sql'} );
            my $bc = 0;
            map {
                $bc += 1;
                $sth->bind_param( $bc, $_ || undef );
            } @{ $ARGS{'keys'} };
            $sth->execute();
            # assuming they are objects, spawn them and push them onto @results
            while( defined( my $tmpres = $sth->fetchrow_hashref() ) ) {
                push @$results, $ARGS{'class'}->spawn( %$tmpres );
            }
        } );
    } catch {
        $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', args => [ $_ ] );
    };
    return $status if defined $status;

    my $counter = scalar @$results;
    $status = ( $counter )
        ? $CELL->status_ok( 'DISPATCH_RECORDS_FOUND', 
            args => [ $counter ], payload => $results, count => $counter, keys => $ARGS{'keys'} )
        : $CELL->status_notice( 'DISPATCH_NO_RECORDS_FOUND',
            payload => $results, count => $counter );
    #$log->debug( Dumper $status );
    return $status;
}


=head2 make_test_exists

Returns coderef for a function, 'test_exists', that performs a simple
true/false check for existence of a record matching a scalar search key.  The
record must be an exact match (no wildcards).

Takes one argument: a type string C<$t> which is concatenated with the string
'load_by_' to arrive at the name of the function to be called to execute the
search.

The returned function takes a single argument: the search key (a scalar value).
If a record matching the search key is found, the corresponding object
(i.e. a true value) is returned. If such a record does not exist, 'undef' (a
false value) is returned. If there is a DBI error, the error text is logged
and undef is returned.

=cut

sub make_test_exists {

    my ( $t ) = validate_pos( @_, { type => SCALAR } );
    my $pkg = (caller)[0];

    return sub {
        my ( $conn, $s_key ) = @_;
        require Try::Tiny;
        my $routine = "load_by_$t";
        my ( $status, $txt );
        $log->debug( "Entered $t" . "_exists with search key $s_key" );
        try {
            no strict 'refs';
            $status = $pkg->$routine( $conn, $s_key );
        } catch {
            $txt = "Function " . $pkg . "::test_exists was generated with argument $t, " .
                "so it tried to call $routine, resulting in exception $_";
            $status = $CELL->status_crit( $txt );
        };
        if ( ! defined( $status ) or $status->level eq 'CRIT' ) {
            die $txt;
        }
        #$log->debug( "Status is " . Dumper( $status ) );
        return $status->payload if $status->ok;
        return;
    }
}


=head2 noof

Given a L<DBIx::Connector> object and the name of a data model table, returns
the total number of records in the table.

    activities employees intervals locks privhistory schedhistory
    schedintvls schedules tempintvls

On failure, returns undef.

=cut

sub noof {
    my ( $conn, $table ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR } 
    );

    return unless grep { $table eq $_; } qw( activities employees intervals locks
            privhistory schedhistory schedintvls schedules tempintvls );

    my $count;
    try {
        $conn->run( fixup => sub {
            ( $count ) = $_->selectrow_array( "SELECT count(*) FROM $table" );
        } );
    } catch {
        $CELL->status_crit( 'DOCHAZKA_DBI_ERR', args => [ $_ ] );
    };
    return $count;
}


=head2 priv_by_eid

Given an EID, and, optionally, a timestamp, returns the employee's priv
level as of that timestamp, or as of "now" if no timestamp was given. The
priv level will default to 'passerby' if it can't be determined from the
database.

=cut

sub priv_by_eid {
    my ( $conn, $eid, $ts ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
        { type => SCALAR|UNDEF, optional => 1 } 
    );
    #$log->debug( "priv_by_eid: EID is " . (defined( $eid ) ? $eid : 'undef') . " - called from " . (caller)[1] . " line " . (caller)[2] );
    return _st_by_eid( $conn, 'priv', $eid, $ts );
}


=head2 schedule_by_eid

Given an EID, and, optionally, a timestamp, returns the SID of the employee's
schedule as of that timestamp, or as of "now" if no timestamp was given.

=cut

sub schedule_by_eid {
    my ( $conn, $eid, $ts ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
        { type => SCALAR|UNDEF, optional => 1 },
    );
    return _st_by_eid( $conn, 'schedule', $eid, $ts );
}


=head3 _st_by_eid 

Function that 'priv_by_eid' and 'schedule_by_eid' are wrappers of.

=cut

sub _st_by_eid {
    my ( $conn, $st, $eid, $ts ) = @_;
    my ( @args, $sql, $row );
    $log->debug( "Entering _st_by_eid with \$st == $st, \$eid == $eid, \$ts == " . ( $ts || '<NONE>' ) );
    if ( $ts ) {
        # timestamp given
        if ( $st eq 'priv' ) {
            $sql = $site->SQL_EMPLOYEE_PRIV_AT_TIMESTAMP;
        } elsif ( $st eq 'schedule' ) {
            $sql = $site->SQL_EMPLOYEE_SCHEDULE_AT_TIMESTAMP;
        } 
        @args = ( $sql, undef, $eid, $ts );
    } else {
        # no timestamp given
        if ( $st eq 'priv' ) {
            $sql = $site->SQL_EMPLOYEE_CURRENT_PRIV;
        } elsif ( $st eq 'schedule' ) {
            $sql = $site->SQL_EMPLOYEE_CURRENT_SCHEDULE;
        } 
        @args = ( $sql, undef, $eid );
    }

    $log->debug("About to run SQL statement $sql with parameter $eid - " . 
                " called from " . (caller)[1] . " line " . (caller)[2] );

    my $status;
    try {
        $conn->run( fixup => sub {
            ( $row ) = $_->selectrow_array( @args );
        } );
    } catch {
        $log->debug( 'Encountered DBI error' );
        $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', args => [ $_ ] );
    };
    return $status if $status;

    $log->debug( "_st_by_eid success; returning payload " . Dumper( $row ) );
    return $row;
}


=head2 select_single

Given a L<DBIx::Connector> object in the 'conn' property, a SELECT statement in
the 'sql' property and, in the 'keys' property, an arrayref containing a list
of scalar values to plug into the SELECT statement, run a C<selectrow_array>
and return the resulting list.

Returns a standard status object (see C<load> routine, above, for description).

=cut

sub select_single {
    my %ARGS = validate( @_, { 
        conn => { isa => 'DBIx::Connector' },
        sql => { type => SCALAR },
        keys => { type => ARRAYREF },
    } );
    my ( $status, @results );
    $log->info( "select_single keys: " . Dumper( $ARGS{keys} ) );
    try {
        $ARGS{'conn'}->run( fixup => sub {
            @results = $_->selectrow_array( $ARGS{'sql'}, undef, @{ $ARGS{'keys'} } );
        } );
        my $count = scalar( @results ) ? 1 : 0;
        $log->info( "count: $count" );
        $status = ( $count )
            ? $CELL->status_ok( 'DISPATCH_RECORDS_FOUND', 
                args => [ $count ], count => $count, payload => \@results )
            : $CELL->status_notice( 'DISPATCH_NO_RECORDS_FOUND' );
    } catch {
        $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', args => [ $_ ] );
    };
    die "AAAAHAHAAHAAAAAAGGGH! " . __PACKAGE__ . "::select_single" unless $status;
    return $status;
}


=head2 select_set_of_single_scalar_rows

Given DBIx::Connector object, an SQL statement, and a set of keys to bind
into the SQL statement, assume that the statement can return 0-n records
and that each record consists of a single field that must fit into a single
scalar value.

=cut

sub select_set_of_single_scalar_rows {
    my %ARGS = validate( @_, { 
        conn => { isa => 'DBIx::Connector' },
        sql => { type => SCALAR },
        keys => { type => ARRAYREF },
    } );
    $log->debug( "Entering " . __PACKAGE__ . "::select_set_of_single_scalar_rows with
        paramhash " . Dumper( \%ARGS ) );

    my ( $status, $result_set );
    try {
        $ARGS{'conn'}->run( fixup => sub {
            my $sth = $_->prepare( $ARGS{'sql'} );
            my $bc = 0;
            map {
                $bc += 1;
                $sth->bind_param( $bc, $_ || undef );
            } @{ $ARGS{'keys'} };
            $sth->execute();
            # push results onto $nicks
            while( defined( my $tmpres = $sth->fetchrow_arrayref() ) ) {
                push @$result_set, @$tmpres;
            }
        } );
    } catch {
        $log->debug( 'Encountered DBI error' );
        $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', args => [ $_ ] );
    };

    return $status if $status;
    return $CELL->status_ok( 'RESULT_SET', payload => $result_set );
}


=head2 split_tsrange

Given a string that might be a tsrange, run it through the database
using the SQL statement:

    SELECT lower(CAST( ? AS tstzrange )), upper(CAST( ? AS tstzrange ))

If all goes well, the result will be an array ( from, to ) of two
timestamps.

Returns a status object.

=cut

sub split_tsrange {
    my ( $conn, $tsr ) = @_;

    my $status = select_single(
        conn => $conn,
        sql => 'SELECT lower(CAST( ? AS tstzrange )), upper(CAST( ? AS tstzrange ))',
        keys => [ $tsr, $tsr ],
    );
    return $status unless $status->ok;
    my ( $lower, $upper ) = @{ $status->payload };
    return $CELL->status_err( 'DOCHAZKA_UNBOUNDED_TSRANGE' ) unless defined( $lower ) and 
        defined( $upper ) and $lower ne 'infinity' and $upper ne 'infinity';
    return $status;
}


=head2 timestamp_delta_minus

Given a timestamp string and an interval string (e.g. "1 week 3 days" ), 
subtract the interval from the timestamp.

Returns a status object. If the database operation is successful, the payload
will contain the resulting timestamp.

=cut

sub timestamp_delta_minus {
    my ( $conn, $ts, $delta ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
        { type => SCALAR },
    );
    $log->info( "timestamp_delta_minus: timestamp $ts, delta $delta" );
    my $status = select_single(
        conn => $conn,
        sql => "SELECT CAST( ? AS timestamptz ) - CAST( ? AS interval )",
        keys => [ $ts, $delta ],
    );
    if ( $status->ok ) {
        my ( $result ) = @{ $status->payload };
        return $CELL->status_ok( 'SUCCESS', payload => $result );
    }
    return $status;
}


=head2 timestamp_delta_plus

Given a timestamp string and an interval string (e.g. "1 week 3 days" ), 
add the interval to the timestamp.

Returns a status object. If the database operation is successful, the payload
will contain the resulting timestamp.

=cut

sub timestamp_delta_plus {
    my ( $conn, $ts, $delta ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
        { type => SCALAR },
    );
    $log->info( "timestamp_delta_plus: timestamp $ts, delta $delta" );
    my $status = select_single(
        conn => $conn,
        sql => "SELECT CAST( ? AS timestamptz ) + CAST( ? AS interval )",
        keys => [ $ts, $delta ],
    );
    if ( $status->ok ) {
        my ( $result ) = @{ $status->payload };
        return $CELL->status_ok( 'SUCCESS', payload => $result );
    }
    return $status;
}


=head2 tsrange_intersection

Given two strings that might be tsranges, consult the database and return
the result of tsrange1 * tsrange2 (also a tsrange).

=cut

sub tsrange_intersection {
    my ( $conn, $tr1, $tr2 ) = @_;

    my $status = select_single(
        conn => $conn,
        sql => 'SELECT CAST( ? AS tstzrange) * CAST( ? AS tstzrange )',
        keys => [ $tr1, $tr2 ],
    );
    die $status->text unless $status->ok;
    return $status->payload->[0];
}


=head2 tsrange_equal

Given two strings that might be equal tsranges, consult the database and return
the result (true or false).

=cut

sub tsrange_equal {
    my ( $conn, $tr1, $tr2 ) = @_;

    my $status = select_single(
        conn => $conn,
        sql => 'SELECT CAST( ? AS tstzrange) = CAST( ? AS tstzrange )',
        keys => [ $tr1, $tr2 ],
    );
    die $status->text unless $status->ok;
    return $status->payload->[0];
}



=head1 AUTHOR

Nathan Cutler, C<< <presnypreklad@gmail.com> >>

=cut 

1;

