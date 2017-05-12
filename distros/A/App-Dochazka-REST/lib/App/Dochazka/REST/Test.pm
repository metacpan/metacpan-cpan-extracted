# ************************************************************************* 
# Copyright (c) 2014-2015, SUSE LLC
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

# ------------------------
# Test helper functions module
# ------------------------

package App::Dochazka::REST::Test;

use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::Common;
use App::Dochazka::REST;
use App::Dochazka::REST::Dispatch;
use App::Dochazka::REST::ConnBank qw( $dbix_conn conn_up );
use App::Dochazka::REST::Util qw( hash_the_password );
use App::Dochazka::REST::Model::Activity;
use App::Dochazka::REST::Model::Component;
use App::Dochazka::REST::Model::Privhistory qw( get_privhistory );
use App::Dochazka::REST::Model::Schedhistory qw( get_schedhistory );
use App::Dochazka::REST::Model::Shared qw( cud_generic noof select_single );
use Authen::Passphrase::SaltedDigest;
use Data::Dumper;
use HTTP::Request::Common qw( GET PUT POST DELETE );
use JSON;
use Params::Validate qw( :all );
use Test::JSON;
use Test::More;
use Try::Tiny;
use Web::MREST;



=head1 NAME

App::Dochazka::REST::Test - Test helper functions





=head1 DESCRIPTION

This module provides helper code for unit tests.

=cut




=head1 EXPORTS

=cut

use Exporter qw( import );
our @EXPORT = qw( 
    initialize_regression_test $faux_context
    req dbi_err docu_check 
    create_bare_employee create_active_employee create_inactive_employee
    delete_bare_employee delete_employee_by_nick
    create_testing_activity delete_testing_activity
    create_testing_interval delete_testing_interval
    create_testing_component delete_testing_component
    create_testing_schedule delete_testing_schedule delete_all_attendance_data
    gen_activity gen_employee gen_interval gen_lock
    gen_privhistory gen_schedhistory gen_schedule
    test_sql_success test_sql_failure do_select_single
    test_employee_list get_aid_by_code test_schedule_model
);




=head1 PACKAGE VARIABLES

=cut

# faux context
our $faux_context;

# dispatch table with references to HTTP::Request::Common functions
my %methods = ( 
    GET => \&GET,
    PUT => \&PUT,
    POST => \&POST,
    DELETE => \&DELETE,
);




=head1 FUNCTIONS

=cut


=head2 initialize_regression_test

Perform the boilerplate tasks that have to be done at the beginning of every
test file that communicates with the Web::MREST server and/or the PostgreSQL
database. Since both Web::MREST and PostgreSQL are external resources,
tests that make use of them are more than mere unit tests

While some test files do not need *all* of these initialization steps,
there is no harm in running them.

The t/unit/ subdirectory is reserved for test files that need *none* of
these initialization steps. Having them in a separate subdirectory enables
them to be run separately.

=cut

sub initialize_regression_test {

    my $status = Web::MREST::init( 
        distro => 'App-Dochazka-REST', 
        sitedir => '/etc/dochazka-rest', 
    );
    plan skip_all => "Web::MREST::init failed: " . $status->text unless $status->ok;

    #diag( "DOCHAZKA_STATE_DIR is set to " . $site->DOCHAZKA_STATE_DIR );

    note( "Set log level" );
    $log->init( 
        ident => $site->MREST_APPNAME, 
        debug_mode => 1,
    );

    note( "Initialize" );
    try {
        App::Dochazka::REST::Dispatch::init();
    } catch {
        $status = $CELL->status_not_ok;
    };
    plan skip_all => 'Integration testing environment not detected' unless $status->ok;

    note( "Check status of database server connection" );
    plan skip_all => "PostgreSQL server is unreachable" unless conn_up();

    my $eids = App::Dochazka::REST::get_eid_of( $dbix_conn, "root", "demo" );
    $site->set( 'DOCHAZKA_EID_OF_ROOT', $eids->{'root'} );
    $site->set( 'DOCHAZKA_EID_OF_DEMO', $eids->{'demo'} );

    is( $status->level, 'OK' );
    ok( $site->DOCHAZKA_EID_OF_ROOT );
    ok( $site->DOCHAZKA_EID_OF_DEMO );
    ok( $site->DOCHAZKA_TIMEZONE );

    $faux_context = { 'dbix_conn' => $dbix_conn, 'current' => { 'eid' => 1 } };
    $meta->set( 'META_DOCHAZKA_UNIT_TESTING' => 1 );

    note( "instantiate Web::Machine object for this application" );
    my $app = Web::Machine->new( resource => 'App::Dochazka::REST::Dispatch', )->to_app;

    note( "A PSGI application is a Perl code reference. It takes exactly " .
    "one argument, the environment and returns an array reference of exactly " .
    "three values." );
    is( ref($app), 'CODE' );

    note( 'initialize App::Dochazka::Common package variables $t, $today, etc.' );
    App::Dochazka::Common::init_timepiece();

    return $app;
}


=head2 status_from_json

L<App::Dochazka::REST> is designed to return status objects in the HTTP
response body. These, of course, are sent in JSON format. This simple routine
takes a JSON string and blesses it, thereby converting it back into a status
object.

FIXME: There may be some encoding issues here!

=cut

sub status_from_json {
    my ( $json ) = @_;
    bless from_json( $json ), 'App::CELL::Status';
}


=head2 req

Assemble and process a HTTP request. Takes the following positional arguments:

    * Plack::Test object
    * expected HTTP result code
    * user to authenticate with (can be 'root', 'demo', or 'active')
    * HTTP method
    * resource string
    * optional JSON string

If the HTTP result code is 200, the return value will be a status object, undef
otherwise.

=cut

sub req {
    my ( $test, $code, $user, $method, $resource, $json ) = validate_pos( @_, 1, 1, 1, 1, 1, 0 );

    if ( ref( $test ) ne 'Plack::Test::MockHTTP' ) {
        diag( "Plack::Test::MockHTTP object not passed to 'req' from " . (caller)[1] . " line " . (caller)[2] );
        BAIL_OUT(0);
    }

    # assemble request
    my %pl = (
        Accept => 'application/json',
        Content_Type => 'application/json',
    );
    if ( $json ) {
        $pl{'Content'} = $json;
    } 
    my $r = $methods{$method}->( $resource, %pl ); 

    my $pass;
    if ( $user eq 'root' ) {
        $pass = 'immutable';
    } elsif ( $user eq 'inactive' ) {
        $pass = 'inactive';
    } elsif ( $user eq 'active' ) {
        $pass = 'active';
    } elsif ( $user eq 'demo' ) {
        $pass = 'demo';
    } else {
        #diag( "Unusual user $user - trying password $user" );
        $pass = $user;
    }

    $r->authorization_basic( $user, $pass );
    note( "About to send request $method $resource as $user " . ( $json ? "with $json" : "" ) );
    my $res = $test->request( $r );
    $code += 0;
    if ( $code != $res->code ) {
        diag( Dumper $res );
        BAIL_OUT(0);
    }
    is( $res->code, $code, "Response code is $code" );
    my $content = $res->content;
    if ( $content ) {
        #diag( Dumper $content );
        is_valid_json( $res->content, "Response entity is valid JSON" );
        my $status = status_from_json( $content );
        if ( my $location_header = $res->header( 'Location' ) ) {
            $status->{'location_header'} = $location_header;
        }
        return $status;
    }
    return;
}


=head2 dbi_err

Wrapper for 'req' intended to eliminate duplicated code on tests that are
expected to return DOCHAZKA_DBI_ERR. In addition to the arguments expected
by 'req', takes one additional argument, which should be:

    qr/error message subtext/

(i.e. a regex quote by which to test the $status->text)

=cut

sub dbi_err {
    my ( $test, $code, $user, $method, $resource, $json, $qr ) = validate_pos( @_, 1, 1, 1, 1, 1, 1, 1 );
    my $status = req( $test, $code, $user, $method, $resource, $json );
    is( $status->level, 'ERR' );
    ok( $status->text );
    if ( ! ( $status->text =~ $qr ) ) {
        diag( "$user $method $resource\n$json" );
        diag( $status->text . " does not match $qr" );
        BAIL_OUT(0);
    }
    like( $status->text, $qr );
}


=head2 docu_check

Check that the resource has on-line documentation (takes Plack::Test object
and resource name without quotes)

=cut

sub docu_check {
    my ( $test, $resource ) = @_;
    #diag( "Entering " . __PACKAGE__ . "::docu_check with argument $resource" );

    if ( ref( $test ) ne 'Plack::Test::MockHTTP' ) {
        diag( "Plack::Test::MockHTTP object not passed to 'req' from " . (caller)[1] . " line " . (caller)[2] );
        BAIL_OUT(0);
    }

    my $tn = "docu_check $resource ";
    my $t = 0;
    my ( $docustr, $docustr_len );
    #
    # - straight 'docu/pod' resource
    my $status = req( $test, 200, 'demo', 'POST', '/docu/pod', "\"$resource\"" );
    is( $status->level, 'OK', $tn . ++$t );
    is( $status->code, 'DISPATCH_ONLINE_DOCUMENTATION', $tn . ++$t );
    if ( exists $status->{'payload'} ) {
        ok( exists $status->payload->{'resource'}, $tn . ++$t );
        is( $status->payload->{'resource'}, $resource, $tn . ++$t );
        ok( exists $status->payload->{'documentation'}, $tn . ++$t );
        $docustr = $status->payload->{'documentation'};
        $docustr_len = length( $docustr );
        ok( $docustr_len > 10, $tn . ++$t );
        isnt( $docustr, 'NOT WRITTEN YET', $tn . ++$t );
    }
    #
    # - not a very thorough examination of the 'docu/html' version
    $status = req( $test, 200, 'demo', 'POST', '/docu/html', "\"$resource\"" );
    is( $status->level, 'OK', $tn . ++$t );
    is( $status->code, 'DISPATCH_ONLINE_DOCUMENTATION', $tn . ++$t );
    if ( exists $status->{'payload'} ) {
        ok( exists $status->payload->{'resource'}, $tn . ++$t );
        is( $status->payload->{'resource'}, $resource, $tn . ++$t );
        ok( exists $status->payload->{'documentation'}, $tn . ++$t );
        $docustr = $status->payload->{'documentation'};
        $docustr_len = length( $docustr );
        ok( $docustr_len > 10, $tn . ++$t );
        isnt( $docustr, 'NOT WRITTEN YET', $tn . ++$t );
    }
}


=head2 create_bare_employee

For use in tests only. Spawns an employee object and inserts it into the
database.

Takes PROPLIST which is passed through unmunged to the employee spawn method.

Returns the new Employee object.

=cut

sub create_bare_employee {
    my ( $PROPS ) = validate_pos( @_,
        { type => HASHREF },
    );

    hash_the_password( $PROPS );

    my $emp = App::Dochazka::REST::Model::Employee->spawn( $PROPS );
    is( ref($emp), 'App::Dochazka::REST::Model::Employee', 'create_bare_employee 1' );

    my $status = $emp->insert( $faux_context );
    if ( $status->not_ok ) {
        diag( "Employee insert method returned NOT_OK status in create_bare_employee" );
        diag( "test automation function, which was called from " . (caller)[1] . " line " . (caller)[2] );
        diag( "with arguments: " . Dumper( $PROPS ) );
        diag( "Full status returned by employee insert method:" );
        diag( Dumper $status );
        BAIL_OUT(0);
    }
    is( $status->level, "OK", 'create_bare_employee 2' );
    my $employee_object = $status->payload;
    is( ref( $employee_object ), 'App::Dochazka::REST::Model::Employee' );

    return $employee_object;
}


=head2 delete_bare_employee

Takes a single argument: the EID.

Loads the EID into a new Employee object and calls that object's delete method.

=cut

sub delete_bare_employee {
    my $eid = shift;  
    note( "delete testing employee with EID $eid" );
    my $status = App::Dochazka::REST::Model::Employee->load_by_eid( $dbix_conn, $eid );
    if ( $status->not_ok ) {
        diag( "Employee load_by_eid method returned NOT_OK status in delete_bare_employee" );
        diag( "test automation function, which was called from " . (caller)[1] . " line " . (caller)[2] );
        diag( "with EID $eid" );
        diag( "Full status returned by Employee load_by_eid method:" );
        diag( Dumper $status );
        BAIL_OUT(0);
    }
    is( $status->level, 'OK', 'delete_bare_employee 1' );
    my $emp = $status->payload;
    $status = $emp->delete( $faux_context );
    if ( $status->not_ok ) {
        diag( Dumper $status );
        BAIL_OUT(0);
    }
    is( $status->level, 'OK', 'delete_bare_employee 2' );
    return;
}


sub _create_employee {
    my ( $test, $privspec ) = @_;

    note("create $privspec employee");
    my $eid = create_bare_employee( { nick => $privspec, password => $privspec } )->eid;
    my $status = req( $test, 201, 'root', 'POST', "priv/history/eid/$eid", 
        "{ \"effective\":\"1892-01-01\", \"priv\":\"$privspec\" }" );
    ok( $status->ok, "Create $privspec employee 2" );
    is( $status->code, 'DOCHAZKA_CUD_OK', "Create $privspec employee 3" );
    return $eid;

}

=head2 create_active_employee

Create a testing employee with 'active' privilege. The employee will get an
'active' privhistory record with date 1892-01-01.

=cut

sub create_active_employee {
    my ( $test ) = @_;
    return _create_employee( $test, "active" );
}


=head2 create_inactive_employee

Create a testing employee with 'inactive' privilege. The employee will get an
'inactive' privhistory record with date 1892-01-01.

=cut

sub create_inactive_employee {
    my ( $test ) = @_;
    return _create_employee( $test, "inactive" );
}


=head2 delete_employee_by_nick

Delete testing employee (takes Plack::Test object and nick)

=cut

sub delete_employee_by_nick {
    my ( $test, $nick ) = @_;
    my ( $res, $status );

    # get and delete privhistory
    $status = get_privhistory( $faux_context, nick => $nick );
    if ( $status->level eq 'OK' and $status->code eq 'DISPATCH_RECORDS_FOUND' ) {
        my $ph = $status->payload->{'history'};
        # delete the privhistory records one by one
        foreach my $phrec ( @$ph ) {
            my $phid = $phrec->{phid};
            $status = req( $test, 200, 'root', 'DELETE', "priv/history/phid/$phid" );
            ok( $status->ok, "Delete employee by nick 2" );
            is( $status->code, 'DOCHAZKA_CUD_OK', "Delete employee by nick 3" );
        }
    } else {
        diag( "Unexpected return value from get_privhistory: " . Dumper( $status ) );
        BAIL_OUT(0);
    }

    # get and delete schedhistory
    $status = get_schedhistory( $faux_context, nick => $nick );
    if ( $status->level eq 'OK' and $status->code eq 'DISPATCH_RECORDS_FOUND' ) {
        my $sh = $status->payload->{'history'};
        # delete the schedhistory records one by one
        foreach my $shrec ( @$sh ) {
            my $shid = $shrec->{shid};
            $status = req( $test, 200, 'root', 'DELETE', "schedule/history/shid/$shid" );
            ok( $status->ok, "Delete employee by nick 5" );
            is( $status->code, 'DOCHAZKA_CUD_OK', "Delete employee by nick 5" );
        }
    } elsif ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
        ok( 1, "$nick has no schedule history" );
    } else {
        diag( "Unexpected return value from get_schedhistory: " . Dumper( $status ) );
        BAIL_OUT(0);
    }

    # delete the employee record
    $status = req( $test, 200, 'root', 'DELETE', "employee/nick/$nick" );
    BAIL_OUT($status->text) unless $status->ok;
    is( $status->level, 'OK', "Delete employee by nick 6" );
    is( $status->code, 'DOCHAZKA_CUD_OK', "Delete employee by nick 7" );

    return;
}


=head2 create_testing_activity

Tests will need to set up and tear down testing activities

=cut

sub create_testing_activity {
    my %PROPS = @_;  # must be at least code

    my $act = App::Dochazka::REST::Model::Activity->spawn( \%PROPS );
    is( ref($act), 'App::Dochazka::REST::Model::Activity', 'create_testing_activity 1' );
    my $status = $act->insert( $faux_context );
    if ( $status->not_ok ) {
        BAIL_OUT( $status->code . " " . $status->text );
    }
    is( $status->level, "OK", 'create_testing_activity 2' );
    return $status->payload;
}


=head2 delete_testing_activity

Tests will need to set up and tear down testing activities

=cut

sub delete_testing_activity {
    my $aid = shift;

    my $status = App::Dochazka::REST::Model::Activity->load_by_aid( $dbix_conn, $aid );
    is( $status->level, 'OK', 'delete_testing_activity 1' );
    my $act = $status->payload;
    $status = $act->delete( $faux_context );
    is( $status->level, 'OK', 'delete_testing_activity 2' );
    return;
}


=head2 create_testing_interval

Tests will need to set up and tear down testing intervals

=cut

sub create_testing_interval {
    my %PROPS = @_;  # must be at least code

    my $act = App::Dochazka::REST::Model::Interval->spawn( \%PROPS );
    is( ref($act), 'App::Dochazka::REST::Model::Interval', 'create_testing_interval 1' );
    my $status = $act->insert( $faux_context );
    if ( $status->not_ok ) {
        BAIL_OUT( $status->code . " " . $status->text );
    }
    is( $status->level, "OK", 'create_testing_interval 2' );
    return $status->payload;
}


=head2 delete_testing_interval

Tests will need to set up and tear down testing intervals

=cut

sub delete_testing_interval {
    my $iid = shift;

    my $status = App::Dochazka::REST::Model::Interval->load_by_iid( $dbix_conn, $iid );
    is( $status->level, 'OK', 'delete_testing_interval 1' );
    my $int = $status->payload;
    $status = $int->delete( $faux_context );
    is( $status->level, 'OK', 'delete_testing_interval 2' );
    return;
}


=head2 create_testing_component

Tests will need to set up and tear down testing components

=cut

sub create_testing_component {
    my %PROPS = @_;  # must be at least path

    my $comp = App::Dochazka::REST::Model::Component->spawn( \%PROPS );
    is( ref($comp), 'App::Dochazka::REST::Model::Component', 'create_testing_component 1' );
    my $status = $comp->insert( $faux_context );
    if ( $status->not_ok ) {
        BAIL_OUT( $status->code . " " . $status->text );
    }
    is( $status->level, "OK", 'create_testing_component 2' );
    return $status->payload;
}


=head2 delete_testing_component

Tests will need to set up and tear down testing components

=cut

sub delete_testing_component {
    my $cid = shift;

    my $status = App::Dochazka::REST::Model::Component->load_by_cid( $dbix_conn, $cid );
    is( $status->level, 'OK', 'delete_testing_component 1' );
    my $act = $status->payload;
    $status = $act->delete( $faux_context );
    is( $status->level, 'OK', 'delete_testing_component 2' );
    return;
}


=head2 test_schedule_model

Creates and returns a testing schedule without needing a L<Plack::Test> object.

=cut

sub test_schedule_model {
    my $intvls = shift;

    note('create an arbitrary schedule' );
    note('at the beginning, count of schedintvls should be 0');
    is( noof( $dbix_conn, 'schedintvls' ), 0 );

    note('spawn a schedintvls ("scratch schedule") object');
    my $schedintvls = App::Dochazka::REST::Model::Schedintvls->spawn;
    ok( ref($schedintvls), "object is a reference" );
    isa_ok( $schedintvls, 'App::Dochazka::REST::Model::Schedintvls' );
    ok( defined( $schedintvls->{ssid} ), "Scratch SID is defined" ); 
    ok( $schedintvls->{ssid} > 0, "Scratch SID is > 0" ); 

    note('insert a schedule (i.e. a list of schedintvls)');
    $schedintvls->{intvls} = $intvls; 

    note('insert all the schedintvls in one go');
    my $status = $schedintvls->insert( $dbix_conn );
    diag( $status->text ) unless $status->ok;
    ok( $status->ok, "OK scratch intervals inserted OK" );
    ok( $schedintvls->ssid, "OK there is a scratch SID" );
    my $count = scalar @{ $schedintvls->{intvls} };
    ok( $count );

    note("after insert, count of schedintvls should be $count");
    is( noof( $dbix_conn, 'schedintvls' ), $count );

    note('load the schedintvls, translating them as we go');
    $status = $schedintvls->load( $dbix_conn );
    ok( $status->ok, "OK scratch intervals translated OK" );
    is( scalar @{ $schedintvls->{intvls} }, $count, "Still have $count intervals" );
    is( scalar @{ $schedintvls->{schedule} }, $count, "And now have $count translated intervals as well" );
    like( $status->code, qr/$count rows/, "status code says $count rows" );
    like( $status->text, qr/$count rows/, "status code says $count rows" );
    ok( exists $schedintvls->{schedule}->[0]->{high_time}, "Conversion to hash OK" );
    is_valid_json( $schedintvls->json );

    note('insert the JSON into the schedules table');
    my $schedule = App::Dochazka::REST::Model::Schedule->spawn(
        schedule => $schedintvls->json,
        scode => 'test1',
        remark => 'TESTING',
    );
    $status = $schedule->insert( $faux_context );
    ok( $status->ok, "Schedule insert OK" );
    ok( $schedule->sid > 0, "There is an SID" );
    is( $schedule->scode, 'test1', "scode accessor returns correct value" );
    is_valid_json( $schedule->schedule );
    is( $schedule->remark, 'TESTING' );

    note( 'delete the schedintvls' );
    $status = $schedintvls->delete( $dbix_conn );
    ok( $status->ok, "scratch intervals deleted" );
    like( $status->text, qr/$count record/, "$count records deleted" );
    is( noof( $dbix_conn, 'schedintvls' ), 0 );

    return $schedule;
}


=head2 create_testing_schedule

Tests will need to set up and tear down testing schedules. Takes a Plack::Test
object as its only argument.

=cut

sub create_testing_schedule {
    my ( $test ) = @_;

    note( "Create a testing schedule" );

    my $intvls = { "schedule" => [
        "[2000-01-02 12:30, 2000-01-02 16:30)",
        "[2000-01-02 08:00, 2000-01-02 12:00)",
        "[2000-01-01 12:30, 2000-01-01 16:30)",
        "[2000-01-01 08:00, 2000-01-01 12:00)",
        "[1999-12-31 12:30, 1999-12-31 16:30)",
        "[1999-12-31 08:00, 1999-12-31 12:00)",
    ], "scode" => 'KOBOLD' };
    my $intvls_json = JSON->new->utf8->canonical(1)->encode( $intvls );
    #
    # - request as root 
    my $status = req( $test, 201, 'root', 'POST', "schedule/new", $intvls_json );
    is( $status->level, 'OK', 'POST schedule/new returned OK status' );
    is( $status->code, 'DISPATCH_SCHEDULE_INSERT_OK', "POST schedule/new code " . $status->code );
    ok( exists $status->{'payload'} );
    ok( exists $status->payload->{'sid'}, 'there is a SID' );
    ok( exists $status->payload->{'scode'}, 'there is an scode' );

    return $status->payload->{'sid'};
}


=head2 delete_testing_schedule

Tests will need to set up and tear down testing schedule. Takes a SID as its
only argument.

=cut

sub delete_testing_schedule {
    my ( $sid ) = @_;

    note( "delete testing schedule (SID $sid)" );

    my $status = App::Dochazka::REST::Model::Schedule->load_by_sid( $dbix_conn, $sid );
    is( $status->level, 'OK', 'delete_testing_schedule: load OK' );
    if ( $status->not_ok ) {
        diag( Dumper $status );
        BAIL_OUT(0);
    }

    my $sched = $status->payload;
    $status = $sched->delete( $faux_context );
    is( $status->level, 'OK', 'delete_testing_schedule: delete OK' );
    if ( $status->not_ok ) {
        diag( Dumper $status );
        BAIL_OUT(0);
    }
    return;
}


=head2 delete_all_attendance_data

Wipe out all attendance data by deleting all rows from all tables (in the correct
order).

To be called like this:

    $status = delete_all_attendance_data();
    BAIL_OUT(0) unless $status->ok;

=cut

sub delete_all_attendance_data {

    note( 'delete locks' );
    my $status = cud_generic(
        conn => $dbix_conn, 
        eid => $site->DOCHAZKA_EID_OF_ROOT,
        sql => 'DELETE FROM locks',
    );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    return $status unless $status->ok;

    note( 'delete intervals' );
    $status = cud_generic(
        conn => $dbix_conn, 
        eid => $site->DOCHAZKA_EID_OF_ROOT,
        sql => 'DELETE FROM intervals',
    );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    return $status unless $status->ok;

    note( 'delete activities' );
    $status = cud_generic(
        conn => $dbix_conn, 
        eid => $site->DOCHAZKA_EID_OF_ROOT,
        sql => 'DELETE FROM activities',
    );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    return $status unless $status->ok;

    note( 're-initialize activities table' );
    $status = App::Dochazka::REST::initialize_activities_table( $dbix_conn );
    return $status unless $status->ok;

    note( 'delete schedhistory' );
    $status = cud_generic(
        conn => $dbix_conn, 
        eid => $site->DOCHAZKA_EID_OF_ROOT,
        sql => 'DELETE FROM schedhistory',
    );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    return $status unless $status->ok;

    note( 'delete privhistory' );
    $status = cud_generic(
        conn => $dbix_conn, 
        eid => $site->DOCHAZKA_EID_OF_ROOT,
        sql => 'DELETE FROM privhistory WHERE eid != ?',
        bind_params => [ $site->DOCHAZKA_EID_OF_ROOT ],
    );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    return $status unless $status->ok;

    note( 'delete schedules' );
    $status = cud_generic(
        conn => $dbix_conn, 
        eid => $site->DOCHAZKA_EID_OF_ROOT,
        sql => 'DELETE FROM schedules',
    );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    return $status unless $status->ok;

    note( 'delete tempintvls' );
    $status = cud_generic(
        conn => $dbix_conn, 
        eid => $site->DOCHAZKA_EID_OF_ROOT,
        sql => 'DELETE FROM tempintvls',
    );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );
    return $status unless $status->ok;

    note( 'delete employees' );
    $status = cud_generic(
        conn => $dbix_conn, 
        eid => $site->DOCHAZKA_EID_OF_ROOT,
        sql => 'DELETE FROM employees WHERE eid != ? AND eid != ?',
        bind_params => [ $site->DOCHAZKA_EID_OF_ROOT, $site->DOCHAZKA_EID_OF_DEMO ],
    );
    is( $status->level, 'OK' );
    is( $status->code, 'DOCHAZKA_CUD_OK' );

    return $status;
}


#
# functions to perform class-specific 'create', 'retrieve', 'delete', etc. actions
#

sub gen_activity {
    my $dis = shift;
    my $code = 'FOOBAR';

    if ( $dis eq 'create' ) {

        # create 'FOOBAR' activity
        my $act = App::Dochazka::REST::Model::Activity->spawn( code => $code );
        my $status = $act->insert( $faux_context );
        if( $status->level ne 'OK' ) {
            diag( Dumper $status );
            BAIL_OUT(0);
        }
        is( $status->level, 'OK' );
        $act = $status->payload;
        is( $act->code, $code );
        ok( $act->aid > 5 );
        return $act;

    } elsif ( $dis eq 'retrieve' ) {

        my $status = App::Dochazka::REST::Model::Activity->load_by_code( $dbix_conn, $code );
        return $status;

    } elsif ( $dis eq 'delete' ) {

        my $status = App::Dochazka::REST::Model::Activity->load_by_code( $dbix_conn, $code );
        is( $status->level, 'OK' );
        my $act = $status->payload;
        $status = $act->delete( $faux_context );
        is( $status->level, 'OK' );
        return;
        
    }
    diag( "gen_activity: AAAAAAHHHHH@@@!! \$dis " . Dumper( $dis ) );
    BAIL_OUT(0);
}


sub gen_employee {
    my $dis = shift;
    my $nick = 'bubbaTheCat';

    if ( $dis eq 'create' ) {

        # create bubbaTheCat employee
        my $emp = App::Dochazka::REST::Model::Employee->spawn( nick => $nick );
        my $status = $emp->insert( $faux_context );
        is( $status->level, 'OK' );
        $emp = $status->payload;
        is( $emp->nick, $nick );
        ok( $emp->eid > 2 );  # root is 1, demo is 2
        return $emp;

    } elsif ( $dis eq 'retrieve' ) {

        my $status = App::Dochazka::REST::Model::Employee->load_by_nick( $dbix_conn, $nick );
        return $status;

    } elsif ( $dis eq 'delete' ) {

        my $status = App::Dochazka::REST::Model::Employee->load_by_nick( $dbix_conn, $nick );
        is( $status->level, 'OK' );
        my $emp = $status->payload;
        $status = $emp->delete( $faux_context );
        is( $status->level, 'OK' );
        return;
        
    }
    diag( "gen_employee: AAAAAAHHHHH@@@!! \$dis " . Dumper( $dis ) );
    BAIL_OUT(0);
}


sub gen_interval {
    my $dis = shift;
    my $eid = $site->DOCHAZKA_EID_OF_ROOT;
    my $aid = App::Dochazka::REST::Model::Activity->load_by_code( $dbix_conn, 'WORK' )->aid;
    if ( $dis eq 'create' ) {

        # create an interval
        my $int = App::Dochazka::REST::Model::Interval->spawn(
            eid => $eid,
            aid => $aid,
            intvl => "['1950-06-30 09:00', '1950-06-30 10:00')",
        );
        my $status = $int->insert( $faux_context );
        is( $status->level, 'OK' );
        $int = $status->payload;
        is( $int->eid, $eid );
        is( $int->aid, $aid );
        ok( $int->iid > 0 );
        # FIXME: use "state" variable to store iid for use in retrieve
        return $int;

    } elsif ( $dis eq 'retrieve' ) {

#        my $status = App::Dochazka::REST::Model::Interval->load_by_iid( $dbix_conn, $iid );
#        return $status;

    } elsif ( $dis eq 'delete' ) {

    }
    diag( "gen_interval: AAAAAAHHHHH@@@!! \$dis " . Dumper( $dis ) );
    BAIL_OUT(0);
}


sub gen_lock {
    my $dis = shift;
    if ( $dis eq 'create' ) {

    } elsif ( $dis eq 'retrieve' ) {

    } elsif ( $dis eq 'delete' ) {
    
    }
    diag( "gen_lock: AAAAAAHHHHH@@@!! \$dis " . Dumper( $dis ) );
    BAIL_OUT(0);
}


sub gen_privhistory {
    my $dis = shift;
    if ( $dis eq 'create' ) {

    } elsif ( $dis eq 'retrieve' ) {

    } elsif ( $dis eq 'delete' ) {
    
    }
    diag( "gen_privhistory: AAAAAAHHHHH@@@!! \$dis " . Dumper( $dis ) );
    BAIL_OUT(0);
}

sub gen_schedhistory {
    my $dis = shift;
    if ( $dis eq 'create' ) {

    } elsif ( $dis eq 'retrieve' ) {
    
    } elsif ( $dis eq 'delete' ) {
    
    }
    diag( "gen_schedhistory: AAAAAAHHHHH@@@!! \$dis " . Dumper( $dis ) );
    BAIL_OUT(0);
}

sub gen_schedule {
    my $dis = shift;
    if ( $dis eq 'create' ) {

    } elsif ( $dis eq 'retrieve' ) {

    } elsif ( $dis eq 'delete' ) {
    
    }
    diag( "gen_schedule: AAAAAAHHHHH@@@!! \$dis " . Dumper( $dis ) );
    BAIL_OUT(0);
}

sub test_sql_success {
    my ( $conn, $expected_rv, $sql ) = @_;
    my ( $rv, $errstr );
    try {
        $conn->run( fixup => sub {
            $rv = $_->do($sql);
        });
    } catch {
        $errstr = $_;
    };
    if ( $errstr ) {
        diag( "Unexpected error in test_sql_success: $errstr" );
        diag( "Called from " . (caller)[1] . " line " . (caller)[2] );
        BAIL_OUT(0);
    }
    is( $rv, $expected_rv, "successfully executed $sql" );
}

sub test_sql_failure {
    my ( $conn, $expected_err, $sql ) = @_;
    my ( $rv, $errstr );
    try {
        $conn->run( fixup => sub {
            $rv = $_->do($sql);
        });
    } catch {
        $errstr = $_;
    };
    is( $rv, undef, "DBI returned undef" );
    like( $errstr, $expected_err, "DBI errstr is as expected" );
}

sub do_select_single {
    my ( $conn, $sql, @keys ) = @_;
    #diag( "do_select_single: connection OK" ) if ref( $conn ) eq 'DBIx::Connector';
    #diag( "do_select_single: SQL statement is $sql" ) if $sql;
    #diag( "do_select_single: keys are ", join(', ', @keys) ) if @keys;
    my $status = select_single( conn => $conn, sql => $sql, keys => \@keys );
    #diag( Dumper $status );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_RECORDS_FOUND' );
    ok( $status->payload );
    is( ref( $status->payload ), 'ARRAY' );
    return @{ $status->payload };
}
    
sub test_employee_list {
    my ( $status, $nicks ) = @_;
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_LIST_EMPLOYEE_NICKS' );
    is_deeply( $status->payload, $nicks );
}

sub get_aid_by_code {
    my ( $test, $code ) = @_;
    my $status = req( $test, 200, 'root', 'GET', "activity/code/$code" );
    is( $status->level, 'OK' );
    is( $status->code, 'DISPATCH_ACTIVITY_FOUND' );
    ok( $status->{'payload'} );
    ok( $status->{'payload'}->{'aid'} );
    is( $status->{'payload'}->{'code'}, uc( $code ) );
    return $status->{'payload'}->{'aid'};
}

1;
