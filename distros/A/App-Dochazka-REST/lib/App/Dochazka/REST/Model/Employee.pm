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

package App::Dochazka::REST::Model::Employee;

use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::Common qw( $today init_timepiece );
use App::Dochazka::REST::LDAP qw( ldap_search );
use App::Dochazka::REST::Model::Shared qw( 
    cud 
    load 
    load_multiple 
    noof 
    priv_by_eid 
    schedule_by_eid 
    select_single 
    select_set_of_single_scalar_rows
);
use Carp;
use Data::Dumper;
use DBI qw(:sql_types);
use Params::Validate qw( :all );
use Try::Tiny;

# send DBI warnings to the log
$SIG{__WARN__} = sub {
    $log->notice( $_[0] );
};

# we get 'spawn', 'reset', and accessors from parent
use parent 'App::Dochazka::Common::Model::Employee';



=head1 NAME

App::Dochazka::REST::Model::Employee - Employee data model




=head1 SYNOPSIS

Employee data model

    use App::Dochazka::REST::Model::Employee;

    ...



=head1 DESCRIPTION

A description of the employee data model follows.


=head2 Employees in the database

At the database level, C<App::Dochazka::REST> needs to be able to distinguish
one employee from another. This is accomplished by the EID. All the other
fields in the C<employees> table are optional. 

The C<employees> database table is defined as follows:

    CREATE TABLE IF NOT EXISTS employees (
        eid        serial PRIMARY KEY,
        nick       varchar(32) UNIQUE NOT NULL,
        sec_id     varchar(64) UNIQUE,
        fullname   varchar(96) UNIQUE,
        email      text UNIQUE,
        passhash   text,
        salt       text,
        supervisor integer REFERENCES employees (eid),
        remark     text,
        CONSTRAINT kosher_nick CHECK (nick ~* '^[[:alnum:]_][[:alnum:]_-]+$')
    )

=head3 EID

The Employee ID (EID) is Dochazka's principal means of identifying an 
employee. At the site, employees will be known by other means, like their
full name, their username, their user ID, etc. But these can and will
change from time to time. The EID should never, ever change.


=head3 nick

The idea behind the C<nick> field is that each employee can have an
easy-to-remember nickname - ideally something that appeals to them, personally.
The C<nick> is required and can only contain certain characters (alphanumerics,
underscore, hyphen).


=head3 sec_id

The secondary ID is an optional unique string identifying the employee.
This could be useful at sites where employees already have a nick (username)
and a numeric ID, for example. This gives administrators and supervisors the
ability to look up employees by their numeric ID as well as their username
(nick).


=head3 fullname, email

These fields are optional. If they have a value, it must be unique.  value.
Dochazka does not check if the email address is valid. 

Depending on how C<App::Dochazka::REST> is configured (see especially the
C<DOCHAZKA_PROFILE_EDITABLE_FIELDS> site parameter), these fields may be
read-only for employees (changeable by admins only), or the employee may be
allowed to maintain their own information.


=head3 passhash, salt

The optional passhash and salt fields are designed to hold a hashed password
and random salt. See L<App::Dochazka::REST::Guide/AUTHENTICATION AND SESSION
MANAGEMENT> for details.


=head3 supervisor

If the employee has a supervisor who will use Dochazka to monitor the
employee's attendance, and provided that supervisor has an EID, this field can
be used to set up the relationship.


=head3 remark

This field can be used by administrators for any purpose. Ordinarily, the
employee herself is not permitted to edit or even display it.



=head2 Employees in the Perl API

Individual employees are represented by "employee objects". All methods and
functions for manipulating these objects are contained in
L<App::Dochazka::REST::Model::Employee>. The most important methods are:

=over

=item * constructor (L<spawn>)

=item * basic accessors (L<eid>, L<sec_id>, L<nick>, L<fullname>, L<email>,
L<passhash>, L<salt>, L<remark>)

=item * L<priv> (privilege "accessor" - but privilege info is not stored in
the object)

=item * L<schedule> (schedule "accessor" - but schedule info is not stored
in the object)

=item * L<reset> (recycles an existing object by setting it to desired state)

=item * L<insert> (inserts object into database)

=item * L<update> (updates database to match the object)

=item * L<delete> (deletes record from database if nothing references it)

=item * L<load_by_eid> (loads a single employee into the object)

=item * L<load_by_nick> (loads a single employee into the object)

=item * L<team_nicks> (returns list of nicks of employees whose supervisor is this employee)

=back

L<App::Dochazka::REST::Model::Employee> also exports some convenience
functions:

=over

=item * L<nick_exists> (given a nick, return true/false)

=item * L<eid_exists> (given an EID, return true/false)

=item * L<list_employees_by_priv> (given a priv level, return hash of employees with that priv level)

=item * L<noof_employees_by_priv> (given a priv level, return number of employees with that priv level)

=back

For basic C<employee> object workflow, see the unit tests in
C<t/model/employee.t>.



=head1 EXPORTS

This module provides the following exports:

=over 

=item L<autocreate_employee> - function

=item L<eid_exists> - function

=item L<get_all_sync_employees> - function

=item L<list_employees_by_priv> - function

=item L<nick_exists> - function

=item L<noof_employees_by_priv> - function

=back

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( 
    autocreate_employee
    eid_exists 
    get_all_sync_employees
    list_employees_by_priv 
    nick_exists 
    noof_employees_by_priv 
);



=head1 METHODS

The following functions expect to be called as methods on an employee object.

The standard way to create an object containing an existing employee is to use
'load_by_eid' or 'load_by_nick':

    my $status = App::Dochazka::REST::Model::Employee->load_by_nick( 'georg' );
    return $status unless $status->ok;
    my $georg = $status->payload;
    $georg->remark( 'Likes to fly kites' );
    $status = $georg->update;
    return $status unless $status->ok;

... and the like. To insert a new employee, do something like this:

    my $friedrich = App::Dochazka::REST::Model::Employee->spawn( nick => 'friedrich' );
    my $status = $friedrich->insert;
    return $status unless $status->ok;

=head2 priv

Accessor method. Wrapper for App::Dochazka::REST::Model::Shared::priv_by_eid
N.B.: for this method to work, the 'eid' attribute must be populated

=cut

sub priv {
    my $self = shift;
    my ( $conn, $timestamp ) = validate_pos( @_,
       { isa => 'DBIx::Connector' },
       { type => SCALAR, optional => 1 },
    );
    my $return_value = ( $timestamp )
        ? priv_by_eid( $conn, $self->eid, $timestamp )
        : priv_by_eid( $conn, $self->eid );
    return if ref( $return_value );
    return $return_value;
}


=head2 schedule

Accessor method. Wrapper for App::Dochazka::REST::Model::Shared::schedule_by_eid
N.B.: for this method to work, the 'eid' attribute must be populated

=cut

sub schedule {
    my $self = shift;
    my ( $conn, $timestamp ) = validate_pos( @_,
       { isa => 'DBIx::Connector' },
       { type => SCALAR, optional => 1 },
    );
    my $return_value = ( $timestamp )
        ? schedule_by_eid( $conn, $self->eid, $timestamp )
        : schedule_by_eid( $conn, $self->eid );
    return if ref( $return_value );
    return $return_value;
}


=head2 insert

Instance method. Takes the object, as it is, and attempts to insert it into
the database. On success, overwrites object attributes with field values
actually inserted. Returns a status object.

=cut

sub insert {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    $self->{sync} = 0 unless defined( $self->{sync} );

    my $status = cud(
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_EMPLOYEE_INSERT,
        attrs => [ 'sec_id', 'nick', 'fullname', 'email', 'passhash', 'salt',
                   'sync', 'supervisor', 'remark' ],
    );
    return $status;
}


=head2 update

Instance method. Assuming that the object has been prepared, i.e. the EID
corresponds to the employee to be updated and the attributes have been
changed as desired, this function runs the actual UPDATE, hopefully
bringing the database into line with the object. Overwrites all the
object's attributes with the values actually written to the database.
Returns status object.

=cut

sub update {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    return $CELL->status_err( 'DOCHAZKA_MALFORMED_400' ) unless $self->{'eid'};

    $self->{sync} = 0 unless defined( $self->{sync} );

    my $status = cud(
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_EMPLOYEE_UPDATE_BY_EID,
        attrs => [ 'sec_id', 'nick', 'fullname', 'email', 'passhash', 'salt',
                   'sync', 'supervisor', 'remark', 'eid' ],
    );
    return $status;
}


=head2 delete

Instance method. Assuming the EID really corresponds to the employee to be
deleted, this method will execute the DELETE statement in the database. It
won't succeed if there are any records anywhere in the database that point
to this EID. Returns a status object.

=cut

sub delete {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    my $status = cud(
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_EMPLOYEE_DELETE,
        attrs => [ 'eid' ],
    );
    #$self->reset( eid => $self->eid ) if $status->ok;
    return $status;
}


=head2 ldap_sync

Sync the mapping fields to the values found in the LDAP database.

=cut

sub ldap_sync {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::sync()" );
    die "Employee nick property not populated!" unless $self->nick =~ /\S+/;
    my $nick = $self->nick;

    return $CELL->status_err( 'DOCHAZKA_LDAP_NOT_ENABLED' ) unless $site->DOCHAZKA_LDAP;
    return $CELL->status_err(
        'DOCHAZKA_LDAP_SYNC_PROP_FALSE',
        args => [ $nick ],
    ) unless $self->sync;
    return $CELL->status_err(
        'DOCHAZKA_LDAP_SYSTEM_USER_NOSYNC',
        args => [ $nick ],
    ) if grep { $nick eq $_; } @{ $site->DOCHAZKA_SYSTEM_USERS };

    $log->debug( "About to populate $nick from LDAP" );

    require Net::LDAP;

    # initiate connection to LDAP server (anonymous bind)
    my $server = $site->DOCHAZKA_LDAP_SERVER;
    my $ldap = Net::LDAP->new( $server );
    $log->error("$@") unless $ldap;
    return $CELL->status_err( 'Could not connect to LDAP server' ) unless $ldap;

    # get LDAP properties and stuff them into the employee object
    my $count = 0;
    foreach my $key ( keys( %{ $site->DOCHAZKA_LDAP_MAPPING } ) ) {
        my $prop = $site->DOCHAZKA_LDAP_MAPPING->{ $key };
        my $value = ldap_search( $ldap, $nick, $prop );
        last unless $value;
        $log->debug( "Setting $key to $value" );
        $self->set( $key, $value );
        $count += 1;
    }

    $ldap->unbind;

    return $CELL->status_ok( 
        'DOCHAZKA_LDAP_SYNC_SUCCESS',
        args => [ $count ],
    ) unless $count < 1;

    return $CELL->status_not_ok( 'DOCHAZKA_LDAP_SYNC_FAILURE' );
}


=head2 load_by_eid

Analogous method to L<App::Dochazka::REST::Model::Activity/"load_by_aid">.

=cut

sub load_by_eid {
    my $self = shift;
    my ( $conn, $eid ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
#        { type => SCALAR, regex => qr/^-?\d+$/ }, <-- causes a regression
    );
    $log->debug( "Entering " . __PACKAGE__ . "::load_by_eid with argument $eid" );

    return load( 
        conn => $conn,
        class => __PACKAGE__, 
        sql => $site->SQL_EMPLOYEE_SELECT_BY_EID,
        keys => [ $eid ],
    );
}


=head2 load_by_nick

Analogous method to L<App::Dochazka::REST::Model::Activity/"load_by_aid">.

=cut

sub load_by_nick {
    my $self = shift;
    my ( $conn, $nick ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );
    $log->debug( "Entering " . __PACKAGE__ . "::load_by_nick with argument $nick" );

    return load( 
        conn => $conn,
        class => __PACKAGE__, 
        sql => $site->SQL_EMPLOYEE_SELECT_BY_NICK,
        keys => [ $nick ], 
    );
}


=head2 load_by_sec_id

Analogous method to L<App::Dochazka::REST::Model::Activity/"load_by_aid">.

FIXME: add unit tests

=cut

sub load_by_sec_id {
    my $self = shift;
    my ( $conn, $sec_id ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );
    $log->debug( "Entering " . __PACKAGE__ . "::load_by_sec_id with argument $sec_id" );

    return load( 
        conn => $conn,
        class => __PACKAGE__, 
        sql => $site->SQL_EMPLOYEE_SELECT_BY_SEC_ID,
        keys => [ $sec_id ], 
    );
}


=head2 priv_change_during_range

Given a DBIx::Connector object and a tsrange, returns the employee's privlevel
during that range, or NULL if the privlevel changed during the range.

=cut

sub priv_change_during_range {
    my $self = shift;
    my ( $conn, $tsr ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );
    $log->debug( "Entering " . __PACKAGE__ . "::priv_change_during_range with argument $tsr" );

    my ( $boolean_result ) = @{ select_single( 
        conn => $conn, 
        sql => $site->SQL_EMPLOYEE_PRIV_CHANGE_DURING_RANGE, 
        keys => [ $self->eid, $tsr ], 
    )->payload };

    return $boolean_result;
}


=head2 privhistory_at_timestamp

Given a DBIx::Connector object and a string that can be either a timestamp
or a tsrange, returns an L<App::Dochazka::REST::Model::Privhistory> object
containing the privhistory record applicable to the employee either at the
timestamp or at the lower bound of the tsrange. If there is no such record,
the object's properties will be undefined.

=cut

sub privhistory_at_timestamp {
    my $self = shift;
    my ( $conn, $arg ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );
    $log->debug( "Entering " . __PACKAGE__ . "::privhistory_at_timestamp with argument $arg" );

    # if it looks like a tsrange, use tsrange, otherwise use timestamp
    my $sql = ( $arg =~ m/[[(].*,.*[])]/ )
        ? $site->SQL_EMPLOYEE_PRIVHISTORY_AT_TSRANGE
        : $site->SQL_EMPLOYEE_PRIVHISTORY_AT_TIMESTAMP;

    my $array = select_single( 
        conn => $conn, 
        sql => $sql,
        keys => [ $self->eid, $arg ], 
    )->payload;

    $log->debug( 'privhistory_at_timestamp: database said: ' . Dumper( $array ) );

    return App::Dochazka::REST::Model::Privhistory->spawn(
        phid => $array->[0],
        eid  => $array->[1],
        priv  => $array->[2],
        effective  => $array->[3],
        remark  => $array->[4],
    );
}


=head2 schedule_change_during_range

Given a DBIx::Connector object and a tsrange, returns true or false value
reflecting whether or not the employee's schedule changed during
the range.

=cut

sub schedule_change_during_range {
    my $self = shift;
    my ( $conn, $tsr ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );
    $log->debug( "Entering " . __PACKAGE__ . "::schedule_change_during_range with argument $tsr" );

    my ( $boolean_result ) = @{ select_single( 
        conn => $conn, 
        sql => $site->SQL_EMPLOYEE_SCHEDULE_CHANGE_DURING_RANGE,
        keys => [ $self->eid, $tsr ], 
    )->payload };

    return $boolean_result;
}


=head2 schedhistory_at_timestamp

Given a DBIx::Connector object and a string that can be either a timestamp
or a tsrange, returns an L<App::Dochazka::REST::Model::Schedhistory> object
containing the history record applicable to the employee either at the
timestamp or at the lower bound of the tsrange. If there is no such record,
the object's properties will be undefined.

=cut

sub schedhistory_at_timestamp {
    my $self = shift;
    my ( $conn, $arg ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );
    $log->debug( "Entering " . __PACKAGE__ . "::schedhistory_at_timestamp with argument $arg" );

    # if it looks like a tsrange, use tsrange, otherwise use timestamp
    my $sql = ( $arg =~ m/[[(].*,.*[])]/ )
        ? $site->SQL_EMPLOYEE_SCHEDHISTORY_AT_TSRANGE
        : $site->SQL_EMPLOYEE_SCHEDHISTORY_AT_TIMESTAMP;

    my $array = select_single( 
        conn => $conn, 
        sql => $sql,
        keys => [ $self->eid, $arg ], 
    )->payload;

    $log->debug( 'schedhistory_at_timestamp: database said: ' . Dumper( $array ) );

    return App::Dochazka::REST::Model::Schedhistory->spawn(
        shid => $array->[0],
        eid  => $array->[1],
        sid  => $array->[2],
        effective  => $array->[3],
        remark  => $array->[4],
    );
}


=head2 team_nicks

Given a L<DBIx::Connector> object, return a status object that, if successful,
will contain in the payload a list of employees whose supervisor is the
employee corresponding to C<$self>.

=cut

sub team_nicks {
    my $self = shift;
    my ( $conn ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
    );
    $log->debug( "Entering " . __PACKAGE__ . "::team_nicks for supervisor " . ( $self->nick || 'undefined' ) );

    # no EID, no team
    return $CELL->status_ok( 'TEAM', payload => [] ) unless $self->eid;

    # if nick not populated, get it
    $self->load_by_eid( $conn, $self->eid ) unless $self->nick =~ /\S+/;

    my $status = select_set_of_single_scalar_rows( 
        'conn' => $conn,
        'sql' => $site->SQL_EMPLOYEE_SELECT_TEAM,
        'keys' => [ $self->eid ],
    );
    return $status unless $status->ok;
    return $CELL->status_ok( 
        'DISPATCH_LIST_EMPLOYEE_NICKS_TEAM',
        args => [ $self->nick ],
        payload => $status->payload,
    );
}




=head1 FUNCTIONS

The following functions are not object methods.



=head1 EXPORTED FUNCTIONS

The following functions are exported and are not called as methods.


=head2 autocreate_employee

Takes a DBIx::Connector object and a nick - the nick is assumed not to exist in
the Dochazka employees table. If DOCHAZKA_LDAP_AUTOCREATE is true, attempts to 
create the employee. Returns a status object.

=cut

sub autocreate_employee {
    my ( $dbix_conn, $nick ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::autocreate_employee()" );
    my $status;

    return $CELL->status_ok() if nick_exists( $dbix_conn, $nick );
    return $CELL->status_not_ok( 'DOCHAZKA_NO_AUTOCREATE' ) unless $site->DOCHAZKA_LDAP_AUTOCREATE;

    my $emp = App::Dochazka::REST::Model::Employee->spawn(
        nick => $nick,
        sync => 1,
        remark => 'LDAP autocreate',
    );
    $status = $emp->ldap_sync();
    return $status unless $status->ok;

    my $faux_context = { 'dbix_conn' => $dbix_conn, 'current' => { 'eid' => 1 } };
    $status = $emp->insert( $faux_context );
    if ( $status->not_ok ) {
        my $reason = $status->text;
        return $CELL->status_err(
            'DOCHAZKA_EMPLOYEE_CREATE_FAIL',
            args => [ $nick, $reason ],
        );
    }
    $log->notice( "Auto-created employee $nick, who was authenticated via LDAP" );

    my $priv = $site->DOCHAZKA_LDAP_AUTOCREATE_AS;
    if ( $priv !~ m/^(inactive)|(active)$/ ) {
        return $CELL->status_err(
            'DOCHAZKA_INVALID_PARAM',
            args => [ 'DOCHAZKA_LDAP_AUTOCREATE_AS', $priv ],
        );
    }

    # create a privhistory record (inactive/active only)
    init_timepiece();
    my $ph_obj = App::Dochazka::REST::Model::Privhistory->spawn(
        eid => $emp->eid,
        priv => $priv,
        effective => ( $today . ' 00:00' ),
        remark => 'LDAP autocreate',
    );
    $status = $ph_obj->insert( $faux_context );
    if ( $status->not_ok ) {
        my $reason = $status->text;
        $status = $CELL->status_err(
            'DOCHAZKA_AUTOCREATE_PRIV_PROBLEM',
            args => [ $nick, $reason ],
        );
    }

    return $status;
}


=head2 nick_exists

See C<exists> routine in L<App::Dochazka::REST::Model::Shared>


=head2 eid_exists

See C<exists> routine in L<App::Dochazka::REST::Model::Shared>

=cut

BEGIN {
    no strict 'refs';
    *{"eid_exists"} = App::Dochazka::REST::Model::Shared::make_test_exists( 'eid' );
    *{"nick_exists"} = App::Dochazka::REST::Model::Shared::make_test_exists( 'nick' );
}


=head2 list_employees_by_priv

Get employee nicks. Argument can be one of the following:

    all admin active inactive passerby

=cut

sub list_employees_by_priv {
    my ( $conn, $priv ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR, regex => qr/^(all)|(admin)|(active)|(inactive)|(passerby)$/ },
    );
    $log->debug( "Entering " . __PACKAGE__ . "::list_employees_by_priv with priv $priv" );

    my $nicks = [];  # reference to array of nicks
    my $sql = '';    # SQL statement
    my $keys_arrayref = [];   # reference to array of keys (may be empty)
    if ( $priv eq 'all' ) {
        $sql = $site->SQL_EMPLOYEE_SELECT_NICKS_ALL
    } else {
        $sql = $site->SQL_EMPLOYEE_SELECT_NICKS_BY_PRIV_LEVEL;
        $keys_arrayref = [ $priv ];
    }
    my $status = select_set_of_single_scalar_rows( 
        'conn' => $conn, 
        'sql' => $sql, 
        'keys' => $keys_arrayref,
    );
    return $status unless $status->ok;
    
    return $CELL->status_ok( 'DISPATCH_LIST_EMPLOYEE_NICKS', 
        args => [ $priv ],
        payload => $status->payload,
    );
}


=head2 noof_employees_by_priv

Get number of employees. Argument can be one of the following:

    total admin active inactive passerby

=cut

sub noof_employees_by_priv {
    my ( $conn, $priv ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR, regex => qr/^(total)|(admin)|(active)|(inactive)|(passerby)$/ },
    );
    $log->debug( "Entering " . __PACKAGE__ . "::noof_employees_by_priv with priv $priv" );

    $priv = lc $priv;

    if ( $priv eq 'total' ) {
        my $count = noof( $conn, 'employees' );
        return $CELL->status_ok( 
            'DISPATCH_COUNT_EMPLOYEES', 
            args => [ $count, $priv ], 
            payload => { count => $count } );
    }

    return $CELL->status_err( 'DOCHAZKA_NOT_FOUND_404' ) unless 
        $priv =~ m/^(passerby)|(inactive)|(active)|(admin)$/i;

    my $sql = $site->SQL_EMPLOYEE_COUNT_BY_PRIV_LEVEL;
    my ( $count ) = @{ select_single( conn => $conn, sql => $sql, keys => [ $priv ] )->payload };
    $log->debug( "select_single returned: $count" );
    $count += 0;
    $CELL->status_ok( 'DISPATCH_COUNT_EMPLOYEES', args => [ $count, $priv ], 
        payload => { 'priv' => $priv, 'count' => $count } );
}


=head2 get_all_sync_employees

Function returns a status object. If the status is OK, the payload will contain
a reference to an array of employee objects whose sync property is true.

=cut

sub get_all_sync_employees {
    my ( $conn ) = validate_pos( @_,
       { isa => 'DBIx::Connector' },
    );
    return load_multiple(
        conn => $conn,
        class => 'App::Dochazka::REST::Model::Employee',
        sql => $site->SQL_EMPLOYEE_SELECT_MULTIPLE_BY_SYNC,
        keys => [ 1 ],
    );
}


=head1 AUTHOR

Nathan Cutler, C<< <presnypreklad@gmail.com> >>

=cut 

1;

