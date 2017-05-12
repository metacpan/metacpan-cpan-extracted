# ************************************************************************* 
# Copyright (c) 2014-2016, SUSE LLC
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
#
# employee command targets
package App::Dochazka::CLI::Commands::Employee;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log );
use App::Dochazka::CLI qw( $current_emp $current_priv $debug_mode );
use App::Dochazka::CLI::Util qw( 
    determine_employee
    lookup_employee
    parse_test 
    refresh_current_emp 
    rest_error 
);
use App::Dochazka::Common::Model::Employee;
use Data::Dumper;
use Exporter 'import';
use Term::ReadKey;
use Web::MREST::CLI qw( send_req );




=head1 NAME

App::Dochazka::CLI::Commands::Employee - Employee commands




=head1 PACKAGE VARIABLES AND EXPORTS

=cut

our @EXPORT_OK = qw( 
    employee_ldap
    employee_ldap_import
    employee_list
    employee_profile
    employee_team
    set_employee_self_sec_id 
    set_employee_other_sec_id
    set_employee_self_fullname 
    set_employee_other_fullname
    set_employee_self_password 
    set_employee_other_password
    set_employee_supervisor
);


=head1 FUNCTIONS

=head2 Command handlers

=head3 employee_profile

    EMPLOYEE
    EMPLOYEE_SPEC
    EMPLOYEE PROFILE
    EMPLOYEE_SPEC PROFILE
    EMPLOYEE SHOW
    EMPLOYEE_SPEC SHOW

=cut

sub employee_profile {
    print "Entering " . __PACKAGE__ . "::employee_profile\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    # determine employee
    my $status = determine_employee( $th->{'EMPLOYEE_SPEC'} );
    return $status unless $status->ok;
    my $emp = $status->payload;

    return _display_employee_ok( $emp );
}


=head3 employee_ldap

    EMPLOYEE LDAP
    EMPLOYEE_SPEC LDAP

=cut

sub employee_ldap {
    print "Entering " . __PACKAGE__ . "::employee_ldap\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    # determine nick
    my $nick;
    if ( my $spec = $th->{'EMPLOYEE_SPEC'} ) {
        # other; just take whatever is after the '='
        ( $nick ) = $spec =~ m/=(.+)$/;
    } else {
        # self; get $nick from $current_emp
        $nick = $current_emp->nick;
    }

    # send the request 
    my $status = send_req( 'GET', "employee/nick/$nick/ldap" );
    return $status unless $status->ok;

    # success: spawn and populate object
    my $emp = App::Dochazka::Common::Model::Employee->spawn(
        %{ $status->payload }
    );

    my $message = "\n";
    $message .= "Nick:              " . $emp->nick . "\n";
    $message .= "LDAP full name:    " . ( $emp->fullname ? $emp->fullname : "(not set)" ) . "\n";
    $message .= "LDAP email:        " . ( $emp->email || "(not set)" ) . "\n";
    $message .= "LDAP secondary ID: " . ( $emp->sec_id ? $emp->sec_id : "(not set)" ) . "\n";
    
    if ( $current_priv eq 'admin' ) {
        # determine if employee already exists in Dochazka database
        my $status = send_req( 'GET', "employee/nick/" . $emp->nick . "/minimal" );
        if ( $status->level eq 'OK' and $status->code eq 'DOCHAZKA_EMPLOYEE_MINIMAL' ) {
            my $nick = $status->payload->{'nick'};
            my $eid = $status->payload->{'eid'};
            $message .= "\nEmployee $nick already exists in Dochazka with EID $eid\n";
        } else {
            my $nick = $emp->nick;
            $message .= "\nEmployee $nick is missing in Dochazka; to import, do \"EMPL=$nick LDAP IMPORT\"\n";
        }
    }

    return $CELL->status_ok( 'DOCHAZKA_CLI_NORMAL_COMPLETION', payload => $message );
}


=head3 employee_ldap_import

    EMPLOYEE_SPEC LDAP IMPORT

=cut

sub employee_ldap_import {
    print "Entering " . __PACKAGE__ . "::employee_ldap_import\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    # determine nick
    my ( $nick ) = $th->{'EMPLOYEE_SPEC'} =~ m/=(.+)$/;

    # send the request
    my $status = send_req( 'PUT', "employee/nick/$nick/ldap" );
    if ( $status->level eq 'OK' and $status->code eq 'DOCHAZKA_CUD_OK' ) {
        return employee_profile( $ts, $th );
    } else {
        return $status;
    }
}

    
=head3 employee_list

EMPLOYEE LIST
EMPLOYEE LIST _TERM

=cut

sub employee_list {
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    my $priv;
    my $status = ( $priv = $th->{'_TERM'} )
        ? send_req( 'GET', "employee/list/$priv" )
        : send_req( 'GET', "employee/list" );

    $priv = $priv || 'all';

    return $status unless $status->ok;
    return $CELL->status_ok( 'DOCHAZKA_CLI_NORMAL_COMPLETION',
        payload => "\nList of employees with priv level ->$priv<-\n    " .
                   join( "\n    ", @{ $status->payload } ) .  "\n" );
}


=head3 employee_team

EMPLOYEE TEAM

=cut

sub employee_team {
    my ( $ts, $th ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::employee_team" );

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    # determine employee
    my $status = determine_employee( $th->{'EMPLOYEE_SPEC'} );
    return $status unless $status->ok;
    my $emp = $status->payload;
    my $eid = $emp->eid;
    my $nick = $emp->nick;

    $status = ( $eid == $current_emp->eid )
        ? send_req( 'GET', "employee/team" )
        : send_req( 'GET', "employee/eid/$eid/team" );
    return $status unless $status->ok;

    my $message = "\nList of employees in the team of ->$nick<-\n    ";
    $message .= ( $status->payload )
        ? ( join( "\n    ", @{ $status->payload } ) .  "\n" )
        : "(none)\n";

    return $CELL->status_ok( 'DOCHAZKA_CLI_NORMAL_COMPLETION',
        payload => $message);
}


=head3 set_employee_self_sec_id

SET EMPLOYEE SEC_ID _TERM

=cut

sub set_employee_self_sec_id {
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    return _set_employee( 
        emp_obj => $current_emp,
        prop => 'sec_id', 
        val => $th->{'_TERM'},
    );
}


=head3 set_employee_self_fullname

SET EMPLOYEE FULLNAME

=cut

sub set_employee_self_fullname {
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    return _set_employee( 
        emp_obj => $current_emp,
        prop => 'fullname', 
        val => $th->{'_REST'},
    );
}


=head3 set_employee_other_sec_id

EMPLOYEE_SPEC SET SEC_ID _TERM

=cut

sub set_employee_other_sec_id {
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    return _set_employee( 
        emp_spec => $th->{'EMPLOYEE_SPEC'},
        prop => 'sec_id', 
        val => $th->{'_TERM'},
    );
}


=head3 set_employee_other_fullname

EMPLOYEE_SPEC SET FULLNAME

=cut

sub set_employee_other_fullname {
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    return _set_employee( 
        emp_spec => $th->{'EMPLOYEE_SPEC'},
        prop => 'fullname', 
        val => $th->{'_REST'},
    );
}


=head3 set_employee_self_password

Reset one's own password

    EMPLOYEE PASSWORD
    EMPLOYEE SET PASSWORD

=cut

sub set_employee_self_password {
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    return _set_password( 
        eid => $current_emp->eid,
        password => $th->{'_REST'},
    ); 
}


=head3 set_employee_other_password

Reset password of an arbitrary employee

    EMPLOYEE_SPEC PASSWORD
    EMPLOYEE_SPEC SET PASSWORD

=cut

sub set_employee_other_password {
    print "Entering " . __PACKAGE__ . "::set_employee_other_password\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    my $status = determine_employee( $th->{EMPLOYEE_SPEC} );
    return $status unless $status->ok;
    my $emp = $status->payload;

    return _set_password( 
        eid => $emp->eid,
        password => $th->{'_REST'},
    ); 
}


=head3 set_employee_supervisor

Set supervisor of an arbitrary employee

    EMPLOYEE_SPEC SUPERVISOR _TERM
    EMPLOYEE_SPEC SET SUPERVISOR _TERM

=cut

sub set_employee_supervisor {
    print "Entering " . __PACKAGE__ . "::set_employee_supervisor\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    # get employee object
    my $status = determine_employee( $th->{EMPLOYEE_SPEC} );
    return $status unless $status->ok;
    my $emp = $status->payload;
    my $emp_eid = $emp->eid;

    # get supervisor employee object
    $status = determine_employee( 'EMPL=' . $th->{_TERM} );
    return $status unless $status->ok;
    my $supervisor = $status->payload;
    my $supervisor_eid = $supervisor->eid;

    # send the HTTP request
    $status = send_req( 'POST', "employee/eid", <<"EOS" );
{ "eid" : $emp_eid, "supervisor" : $supervisor_eid }
EOS
    return $status unless $status->ok;

    # display the employee profile -> it will include the new supervisor
    $emp->reset( $status->payload );
    return _display_employee_ok( $emp );
}



=head2 Helper functions

Functions used by multiple handlers


=head3 determine_priv

Given an employee object, return the current priv level of that employee.
If the employee doesn't exist, the return value will be undef.

=cut

sub determine_priv {
    my ( $emp ) = @_;

    return undef unless ref( $emp ) eq 'App::Dochazka::REST::Model::Employee';
    return undef unless $emp->eid and $emp->nick;

    # GET priv/eid/:eid
    my $status = send_req( 'GET', 'priv/eid/' . $emp->eid );
    if ( $status->not_ok ) {
        $log->error( "Could not determine priv level of employee -> " . $emp->nick .
                     "<- because: " . $status->text );
        return undef;
    }
    return $status->payload->{'priv'};
}


=head3 determine_supervisor

Given an employee object, return supervisor employee object.
If no supervisor can be determined, the 'eid' and 'nick' attributes of the
resulting supervisor object will be undefined.

=cut

sub determine_supervisor {
    my ( $emp ) = @_;
    my $supervisor = App::Dochazka::Common::Model::Employee->spawn();
    if ( my $supervisor_eid = $emp->supervisor ) {
        my $status = determine_employee( "EMPL=$supervisor_eid" );
        if ( $status->ok ) {
            $supervisor = $status->payload;
        } else {
            $log->warn( "Failed to look up supervisor by EID $supervisor_eid; error was " . $status->text );
        }
    }
    return $supervisor;
}


=head3 _set_employee

Function that the handlers are wrappers of

=cut

sub _set_employee {
    my %PROPLIST = @_;
    my $status;
    my $emp_obj;
    if ( my $e_spec = $PROPLIST{'emp_spec'} ) {
        $status = determine_employee( $e_spec );
        return $status unless $status->ok;
        $emp_obj = $status->payload;
    } elsif ( $emp_obj = $PROPLIST{'emp_obj'} ) {
    } else {
        die "AAAAAAAAAAAAAHHHHH!";
    }
    my $eid = $emp_obj->eid;
    my $prop = $PROPLIST{'prop'};
    my $val = $PROPLIST{'val'};
    $val =~ s/['"]//g;
    $status = send_req( 'POST', "employee/eid", <<"EOS" );
{ "eid" : $eid, "$prop" : "$val" }
EOS
    return rest_error( $status, "Modify employee profile" ) unless $status->ok;

    my $message = "Profile of employee " . $emp_obj->nick . 
        " has been modified ($prop -> $val)\n";

    return $CELL->status_ok( 'DOCHAZKA_CLI_NORMAL_COMPLETION', payload => $message );
}


=head3 _set_password

Takes PARAMHASH with following properties:

     eid => EID of employee
     password => the new password (*optional*)

=cut

sub _set_password {
    my %PH = @_;
    my $eid = $PH{'eid'};
    my $newpass = $PH{'password'};

    print "It is important that the new password really be what you intended.\n";
    print "Therefore, we are going to ask you to enter the desired password\n";
    print "twice, so you have a chance to double-check. ";
    print "\n\n";

    # prompt for new password and ask nicely for confirmation
    if ( ! $newpass ) {
        ReadMode ('noecho');
        print "New password      : ";
        chomp( $newpass = <> );
        ReadMode ('restore');
        print "\n";
    }
    ReadMode ('noecho');
    print "New password again: ";
    chomp( my $confirm = <> );
    ReadMode ('restore');
    print "\n";
    return $CELL->status_err( 'DOCHAZKA_CLI_NO_MATCH' ) unless $newpass eq $confirm;

    # send REST request
    my $status = send_req( 'PUT', "employee/eid/$eid", <<"EOS" );
{ "password" : "$newpass" }
EOS

    return $status unless $status->ok;
    return $CELL->status_ok( 'DOCHAZKA_CLI_NORMAL_COMPLETION', 
        payload => "Password changed" );
}


=head3 _display_employee_ok

Given an employee object, prepare OK return status intended for EMPLOYEE PROFILE
but usable also for other commands.

=cut

sub _display_employee_ok {
    my ( $emp ) = @_;

    # determine supervisor
    my $supervisor = determine_supervisor( $emp );

    my $message = "\n";
    $message .= "Full name:    " . ( $emp->fullname ? $emp->fullname : "(not set)" ) . "\n";
    $message .= "Nick:         " . $emp->nick . "\n";
    $message .= "Email:        " . ( $emp->email || "(not set)" ) . "\n";
    $message .= "Secondary ID: " . ( $emp->sec_id ? $emp->sec_id : "(not set)" ) . "\n";
    $message .= "Dochazka EID: " . $emp->eid . "\n";
    $message .= "Reports to:   " . ( $supervisor->nick || "(not set)" ) . "\n";

    return $CELL->status_ok( 'DOCHAZKA_CLI_NORMAL_COMPLETION', payload => $message );
}


1;
