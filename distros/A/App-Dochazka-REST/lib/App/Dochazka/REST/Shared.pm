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
# Shared dispatch functions
# ------------------------

package App::Dochazka::REST::Shared;

use strict;
use warnings;

use App::CELL qw( $CELL $log $site );
use App::Dochazka::REST::ACL qw( acl_check_is_me acl_check_is_my_report );
use App::Dochazka::REST::ConnBank qw( conn_status );
use App::Dochazka::REST::Model::Activity;
use App::Dochazka::REST::Model::Employee;
use App::Dochazka::REST::Model::Interval;
use App::Dochazka::REST::Model::Lock;
use App::Dochazka::REST::Model::Privhistory;
use App::Dochazka::REST::Model::Schedhistory;
use App::Dochazka::REST::Model::Schedule;
use App::Dochazka::REST::Model::Shared qw( priv_by_eid schedule_by_eid );
use App::Dochazka::REST::Util qw( hash_the_password pre_update_comparison );
use Data::Dumper;
use Params::Validate qw( :all );
use Try::Tiny;

my $fail = $CELL->status_not_ok;


=head1 NAME

App::Dochazka::REST::Dispatch::Shared - Shared dispatch functions




=head1 DESCRIPTION

This module provides code that is, or may be, used by more than one resource
handler method.




=head1 EXPORTS

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( 
    shared_first_pass_lookup
    shared_entity_check
    shared_get_employee
    shared_get_employee_pass1
    shared_insert_employee
    shared_update_employee
    shared_update_schedule
    shared_get_class_prop_id
    shared_history_init
    shared_get_privsched
    shared_employee_acl_part1
    shared_employee_acl_part2
    shared_update_activity
    shared_update_component
    shared_update_history
    shared_insert_activity
    shared_insert_component
    shared_insert_interval
    shared_insert_lock
    shared_update_intlock
    shared_process_quals
);
our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ] );


=head1 PACKAGE VARIABLES

The package variable C<%f_dispatch> is used in C<fetch_by_eid>, C<fetch_by_nick>,
and C<fetch_own>.

=cut

my %f_dispatch = (
    "attendance" => \&App::Dochazka::REST::Model::Interval::fetch_by_eid_and_tsrange,
    "lock" => \&App::Dochazka::REST::Model::Lock::fetch_by_eid_and_tsrange,
);
my %id_dispatch = (
    "attendance" => "App::Dochazka::REST::Model::Interval",
    "lock" => "App::Dochazka::REST::Model::Lock",
);


=head1 FUNCTIONS

=cut

=head2 shared_first_pass_lookup

Takes two scalar arguments, "key" and "value" and determines whether or not the
database contains an object answering to that description.

This should be used only for resources that require an exact match.

=cut

sub shared_first_pass_lookup {
    my ( $d_obj, $key, $value ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::shared_first_pass_lookup with key $key, value $value" );

    my $conn = $d_obj->context->{'dbix_conn'};
    my ( $status, $thing );

    if ( uc($key) eq 'AID' ) {
        $thing = 'activity';
        $status = App::Dochazka::REST::Model::Activity->load_by_aid( $conn, $value );
    } elsif ( $key eq 'code' ) {
        $thing = 'activity';
        $status = App::Dochazka::REST::Model::Activity->load_by_code( $conn, $value );
    } elsif ( uc($key) eq 'CID' ) {
        $thing = 'component';
        $status = App::Dochazka::REST::Model::Component->load_by_cid( $conn, $value );
    } elsif ( $key eq 'path' ) {
        $thing = 'component';
        $status = App::Dochazka::REST::Model::Component->load_by_path( $conn, $value );
    } elsif ( uc($key) eq 'EID' ) {
        $thing = 'employee';
        $status = App::Dochazka::REST::Model::Employee->load_by_eid( $conn, $value );
    } elsif ( $key eq 'nick' ) {
        $thing = 'employee';
        $status = App::Dochazka::REST::Model::Employee->load_by_nick( $conn, $value );
    } elsif ( $key eq 'sec_id' ) {
        $thing = 'employee';
        $status = App::Dochazka::REST::Model::Employee->load_by_sec_id( $conn, $value );
    } elsif ( uc($key) eq 'IID' ) {
        $thing = 'interval';
        $status = App::Dochazka::REST::Model::Interval->load_by_iid( $conn, $value );
    } elsif ( uc($key) eq 'LID' ) {
        $thing = 'lock';
        $status = App::Dochazka::REST::Model::Lock->load_by_lid( $conn, $value );
    } elsif ( uc($key) eq 'PHID' ) {
        $thing = 'privilege history record';
        $status = App::Dochazka::REST::Model::Privhistory->load_by_phid( $conn, $value );
    } elsif ( uc($key) eq 'SHID' ) {
        $thing = 'schedule history record';
        $status = App::Dochazka::REST::Model::Schedhistory->load_by_shid( $conn, $value );
    } elsif ( uc($key) eq 'SID' ) {
        $thing = 'schedule';
        $status = App::Dochazka::REST::Model::Schedule->load_by_sid( $conn, $value );
    } elsif ( $key eq 'scode' ) {
        $thing = 'schedule';
        $status = App::Dochazka::REST::Model::Schedule->load_by_scode( $conn, $value );
    } else {
        die "shared_first_pass_lookup could not do anything with key $key!";
    }

    if ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
        $d_obj->mrest_declare_status( code => 404,
            explanation => 'DISPATCH_SEARCH_EMPTY',
            args => [ $thing, "$key equals $value" ],
        );
        return;
    }
    if ( $status->not_ok ) {
        $d_obj->mrest_declare_status( code => 500, explanation => $status->code,
            args => $status->args 
        );
        return;
    }
    return $status->payload;
}


=head2 shared_entity_check

Check request entity for presence of properties

=cut

sub shared_entity_check {
    my ( $d_obj, @props ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::shared_entity_check with properties " . 
        join( ' ', @props ) . " and entity: " . Dumper( $d_obj->context->{'request_entity'} ) );

    my $entity = $d_obj->context->{'request_entity'};
    if ( not $entity ) {
        $d_obj->mrest_declare_status( code => 400, 
            explanation => 'DISPATCH_ENTITY_MISSING'
        );
        return $fail;
    }
    if ( ref( $entity ) ne 'HASH' ) {
        $d_obj->mrest_declare_status( code => 400, 
            explanation => 'DISPATCH_ENTITY_NOT_KEY_VALUE'
        );
        return $fail;
    }
    foreach my $p ( @props ) {
        if ( not $entity->{$p} ) {
            $d_obj->mrest_declare_status( code => 400, 
                explanation => 'DISPATCH_PROP_MISSING_IN_ENTITY', args => [ $p ] 
            );
            return $fail;
        }
    }
    return $CELL->status_ok;
}


=head2 shared_get_employee_pass1

=cut

sub shared_get_employee_pass1 {
    my ( $d_obj, $pass, $key, $value ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::shared_get_employee_pass1" ); 

    #
    # ACL checks
    #
    if (
            ! acl_check_is_my_report( $d_obj, ( lc $key ) => $value ) and
            ! acl_check_is_me( $d_obj, ( lc $key ) => $value )
       )
    {
        $d_obj->mrest_declare_status( code => 403, explanation => "DISPATCH_KEEP_TO_YOURSELF" );
        return 0;
    }
    #
    # 404 check
    #
    my $emp = shared_first_pass_lookup( $d_obj, $key, $value );
    return 0 unless $emp;
    $d_obj->context->{'stashed_employee_object'} = $emp;
    return 1;
}


=head2 shared_get_employee

=cut

sub shared_get_employee {
    my ( $d_obj, $pass, $key, $value ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::shared_get_employee" ); 

    # first pass
    if ( $pass == 1 ) {
        return shared_get_employee_pass1(
            $d_obj, $pass, $key, $value
        );
    }

    # second pass
    return $CELL->status_ok( 'DISPATCH_EMPLOYEE_FOUND',
        payload => $d_obj->context->{'stashed_employee_object'},
    );
}


=head2 shared_update_employee

Takes three arguments:

    - $d_obj is the App::Dochazka::REST::Dispatch object
    - $emp is an employee object (blessed hashref)
    - $over is a hashref with zero or more employee properties and new values

The values from $over replace those in $emp

=cut

sub shared_update_employee {
    my ( $d_obj, $emp, $over ) = @_;
    $log->debug("Entering " . __PACKAGE__ . "::shared_update_employee" );
    $log->debug("Updating employee: " . Dumper( $emp ) );
    $log->debug("With key:value pairs " . Dumper( $over ) );

    ACL: {
        my $explanation = "Update operations require at least one key:value pair in the request entity";
        if ( ref( $over ) ne 'HASH' ) {
            $d_obj->mrest_declare_status( code => 400, explanation => $explanation );
            return $fail;
        }
        delete $over->{'eid'};
        if ( $over == {} ) {
            $d_obj->mrest_declare_status( code => 400, explanation => $explanation );
            return $fail;
        } 
    }

    # for password hashing, we will assume that $over might contain
    # a 'password' property, which is converted into 'passhash' + 'salt' via 
    # Authen::Passphrase
    hash_the_password( $over );

    return $emp->update( $d_obj->context ) if pre_update_comparison( $emp, $over );
    $d_obj->mrest_declare_status( code => 400, explanation => "DISPATCH_ILLEGAL_ENTITY" );
    return $fail;
}


=head2 shared_insert_employee

Called from handlers in L<App::Dochazka::REST::Dispatch>. Takes three arguments:

    - $d_obj is the App::Dochazka::REST::Dispatch object
    - $ignore_me will be undef
    - $new_emp_props is a hashref with employee properties and their values (guaranteed to contain 'nick')

=cut

sub shared_insert_employee {
    $log->debug( "Entered " . __PACKAGE__ . "::shared_insert_employee" );
    my ( $d_obj, $ignore_me, $new_emp_props ) = validate_pos( @_,
        { isa => 'App::Dochazka::REST::Dispatch' },
        { type => UNDEF },
        { type => HASHREF },
    );
    $log->debug( "Arguments are OK, about to insert new employee: " . Dumper( $new_emp_props ) );

    # If there is a "password" property, transform it into "passhash" + "salt"
    hash_the_password( $new_emp_props );

    # spawn an object, filtering the properties first
    my @filtered_args = App::Dochazka::Common::Model::Employee::filter( %$new_emp_props );
    my %proplist_after = @filtered_args;
    $log->debug( "Properties after filter: " . join( ' ', keys %proplist_after ) );
    my $emp = App::Dochazka::REST::Model::Employee->spawn( @filtered_args );

    # execute the INSERT db operation
    return $emp->insert( $d_obj->context );
}


=head2 shared_update_schedule

Takes three arguments:

    - $d_obj is the dispatch (App::Dochazka::REST::Dispatch) object
    - $sched is a schedule object (blessed hashref)
    - $over is a hashref with zero or more schedule properties and new values

The values from C<$over> replace those in C<$emp>.

=cut

sub shared_update_schedule {
    my ( $d_obj, $sched, $over ) = validate_pos( @_,
        { isa => 'App::Dochazka::REST::Dispatch' },
        { isa => 'App::Dochazka::REST::Model::Schedule' },
        { type => HASHREF },
    );
    $log->debug("Entering " . __PACKAGE__ . "::shared_update_schedule" );

    delete $over->{'sid'} if exists $over->{'sid'};
    delete $over->{'schedule'} if exists $over->{'schedule'};
    if ( pre_update_comparison( $sched, $over ) ) {
        $log->debug( "After pre_update_comparison: " . Dumper $sched );
        return $sched->update( $d_obj->context );
    }

    $d_obj->mrest_declare_status( 
        code => 400, 
        explanation => "Cannot update schedule due to invalid input",
    );
    return $fail;
}


=head2 shared_get_class_prop_id

For 'priv' and 'schedule' resources. Given the request context, extract the
first component, which will always be either 'priv' or 'schedule'. Based on
that, generate the object class, property name, and ID property name for 
use in the resource handler.

=cut

sub shared_get_class_prop_id {
    my ( $context ) = @_;
    my $class = 'App::Dochazka::REST::Model::';
    my ( $prop, $id );
    if ( $context->{'components'}->[0] eq 'priv' ) {
        $class .= 'Privhistory';
        $prop = 'priv';
        $id = 'phid';
    } elsif ( $context->{'components'}->[0] eq 'schedule' ) {
        $class .= 'Schedhistory';
        $prop = 'sid';
        $id = 'shid';
    } else {
        die "AGAGAGAGGAGGGGGAAAAAAAHHHH!!!!!";
    }
    return ( $class, $prop, $id );
}


=head2 shared_history_init

For 'priv/history' and 'schedule/history' resources. Given the request context, 
extract or generate values needed by the resource handler.

=cut

sub shared_history_init {
    my $context = shift;

    my $method = $context->{'method'};
    $log->debug( "Method is $method" );

    my $mapping = $context->{'mapping'};
    my $tsrange = $mapping->{'tsrange'};
    my $ts = $mapping->{'ts'};
    my ( $key, $value );
    if ( defined( my $nick = $mapping->{'nick'} ) ) {
        $key = 'nick';
        $value = $nick;
    } elsif ( defined ( my $eid = $mapping->{'eid'} ) ) {
        $key = 'EID';
        $value = $eid;
    } else {
        die "AAFAAAGAGAGGAGAGGGGGGH! mapping contains neither nick nor eid property: " . Dumper( $mapping );
    }

    return ( $context, $method, $mapping, $tsrange, $ts, $key, $value );
}


=head2 shared_get_privsched

Shared GET handler for 'priv' and 'schedule' lookups. Takes four arguments:

=over

=item C<$d_obj> - dispatch object

=item C<$t> - either 'priv' or 'schedule'

=item C<$pass> - either 1 or 2

=item C<$key> - either 'EID' or 'nick'

=item C<$value> - EID or nick value to lookup

=over

=cut

sub shared_get_privsched {
    my ( $d_obj, $t, $pass, $key, $value ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . ":shared_get_privsched" ); 

    # first pass
    if ( $pass == 1 ) {
        #
        # 403 (ACL) check - passerby can only look up him- or herself
        #
        if ( ! acl_check_is_me( $d_obj, ( lc $key ) => $value ) ) {
            $d_obj->mrest_declare_status( code => 403, explanation => "DISPATCH_KEEP_TO_YOURSELF" );
            return 0;
        }
        # 
        # 404 check
        #
        my $emp = shared_first_pass_lookup( $d_obj, $key => $value );
        return 0 unless $emp;
        $d_obj->context->{'stashed_employee_object'} = $emp;
        return 1;
    }
    
    # second pass

    # - initialization
    my $status;
    my %dispatch = (
        'priv' => \&priv_by_eid,
        'schedule' => \&schedule_by_eid,
    );
    my $emp = $d_obj->context->{'stashed_employee_object'};
    my $eid = $emp->eid;
    my $nick = $emp->nick;
    my $ts = $d_obj->context->{'mapping'}->{'ts'};
    my $conn = $d_obj->context->{'dbix_conn'};

    # - run priv_by_eid or schedule_by_eid, as appropriate
    my $return_value = $dispatch{$t}->( $conn, $eid, $ts );

    # on success, $return_value will be a SCALAR like 'inactive' (priv) or 8 (SID of schedule)
    if ( ref( $return_value ) ne 'App::CELL::Status' ) {

        if ( $return_value and $t eq 'schedule' ) {
            # $return_value is SID of the schedule, but we want the schedule itself
            my $status = App::Dochazka::REST::Model::Schedule->load_by_sid( $conn, $return_value );
            $return_value = $status->payload;
        }

        my @privsched = ( $t, $return_value );
        if ( $ts ) {
            if ( ! $return_value ) {
                $d_obj->mrest_declare_status( 
                    code => 404, 
                    explanation => "Employee $nick (EID $eid) has no $t assigned as of $ts" 
                );
                return $CELL->status_not_ok;
            }
            my $code;
            if ( 'PRIV' eq uc( $t ) ) {
                $code = 'DISPATCH_EMPLOYEE_PRIV_AS_AT';
            } elsif ( 'SCHEDULE' eq uc( $t ) ) {
                $code = 'DISPATCH_EMPLOYEE_SCHEDULE_AS_AT';
            } else {
                die "AGHNEVERNEVERNEVERPRIVSCHED1";
            }
            return $CELL->status_ok( $code,
                args => [ $ts, $emp->nick, $return_value ],
                payload => {
                    eid => $eid += 0,  # "numify"
                    nick => $emp->nick,
                    timestamp => $ts,
                    @privsched,
                },
            );
        } else {
            if ( ! $return_value ) {
                $d_obj->mrest_declare_status( 
                    code => 404, 
                    explanation => "Employee $nick (EID $eid) has no $t assigned"
                );
                return $CELL->status_not_ok;
            }
            my $code;
            if ( 'PRIV' eq uc( $t ) ) {
                $code = 'DISPATCH_EMPLOYEE_PRIV';
            } elsif ( 'SCHEDULE' eq uc( $t ) ) {
                $code = 'DISPATCH_EMPLOYEE_SCHEDULE';
            } else {
                die "AGHNEVERNEVERNEVERPRIVSCHED2";
            }
            return $CELL->status_ok( $code,
                args => [ $emp->nick, $return_value ],
                payload => {
                    eid => $eid += 0,  # "numify"
                    nick => $emp->nick,
                    @privsched,
                },
            );
        }
    }

    # There was a DBI error
    return $return_value;
}


=head2 shared_employee_acl_part1

ACL check -- 'inactive' and 'active' employees can only operate on their own
EID. Returns boolean 1 or 0, where 1 means "ACL check passed".

=cut

sub shared_employee_acl_part1 {
    my ( $d_obj, $this_emp ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::shared_employee_acl_part1" );

    my $context = $d_obj->context;
    my $cp = $context->{'current_priv'} || "none";

    # insert
    if ( ! defined( $this_emp ) ) {
        if ( $cp ne 'admin' ) {
            $d_obj->mrest_declare_status( code => 403,
                explanation => "Only administrators can insert new employee records"
            );
            return 0;
        }
    }

    # update
    if ( $cp eq 'admin' ) {
        return 1;
    } else {
        if ( $this_emp->eid == $context->{'current'}->{'eid'} ) {
            return 1;
        }
    }
    $d_obj->mrest_declare_status( code => 403, explanation => "DISPATCH_KEEP_TO_YOURSELF" );
    return 0;
}


=head2 shared_employee_acl_part2

Apply ACL rules on which fields can be updated.
If privlevel is inactive or active, analyze which fields the user wants to update
(passerbies will be rejected earlier in Resource.pm, and admins can edit any field)

Returns boolean 1 or 0, where 1 means "ACL check passed".

=cut

sub shared_employee_acl_part2 {
    my ( $d_obj ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::shared_employee_acl_part2" );

    my $context = $d_obj->context;
    my $cp = $context->{'current_priv'} || 'none';

    if ( $cp eq 'admin' ) {
        return 1;
    } elsif ( $cp =~ m/^(inactive)|(active)$/i ) {
        delete $context->{'request_entity'}->{'eid'};
        my %lut;
        map { $lut{$_} = ''; } @{ $site->DOCHAZKA_PROFILE_EDITABLE_FIELDS->{$cp} };
        foreach my $prop ( keys %{ $context->{'request_entity'} } ) {
            next if exists $lut{$prop};
            $d_obj->mrest_declare_status(
                $CELL->status_err( 
                    'DISPATCH_ACL_VIOLATION', 
                    args => [ $cp, "update $prop property" ],
                    http_code => 403,
                    uri_path => $context->{'uri_path'},
                )
            );
            return 0;
        }
        return 1;
    }
    $d_obj->mrest_declare_status(
        $CELL->status_err( 
            'DISPATCH_ACL_VIOLATION', 
            args => [ $cp, "update employee profiles" ],
            http_code => 403,
        )
    );
    return 0;
}


=head2 shared_update_activity

Takes three arguments:

  - $d_obj is the dispatch object
  - $act is an activity object (blessed hashref)
  - $over is a hashref with zero or more activity properties and new values

The values from $over replace those in $act

=cut

sub shared_update_activity {
    my ( $d_obj, $act, $over ) = @_;
    $log->debug("Entering " . __PACKAGE__ . "::shared_update_activity" );
    delete $over->{'aid'} if exists $over->{'aid'};
    return $act->update( $d_obj->context ) if pre_update_comparison( $act, $over );
    $d_obj->mrest_declare_status( code => 400, explanation => "DISPATCH_ILLEGAL_ENTITY" );
    return $fail;
}


=head2 shared_update_component

Takes three arguments:

  - $d_obj is the dispatch object
  - $comp is a component object (blessed hashref)
  - $over is a hashref with zero or more component properties and new values

The values from $over replace those in $comp

=cut

sub shared_update_component {
    my ( $d_obj, $comp, $over ) = @_;
    $log->debug("Entering " . __PACKAGE__ . "::shared_update_component" );
    delete $over->{'cid'} if exists $over->{'cid'};
    if ( pre_update_comparison( $comp, $over ) ) {
        my $status = $comp->update( $d_obj->context );
        return $status unless $status->level eq 'ERR' and $status->code eq 'DOCHAZKA_MALFORMED_400';
    }
    $d_obj->mrest_declare_status( code => 400, explanation => "DISPATCH_ILLEGAL_ENTITY" );
    return $fail;
}


=head2 shared_update_history

Takes three arguments:

  - $d_obj is the dispatch object
  - $obj is a (priv/schedule) history object (blessed hashref)
  - $over is a hashref with zero or more history properties and new values

The values from $over replace those in $obj

=cut

sub shared_update_history {
    my ( $d_obj, $obj, $over ) = @_;
    $log->debug("Entering " . __PACKAGE__ . "::shared_update_history" );
    delete $over->{'eid'} if exists $over->{'eid'};
    return $obj->update( $d_obj->context ) if pre_update_comparison( $obj, $over );
    $d_obj->mrest_declare_status( code => 400, explanation => "DISPATCH_ILLEGAL_ENTITY" );
    return $fail;
}


=head2 shared_insert_activity

Takes two arguments: the dispatch object and the properties that are supposed
to be an activity object to be inserted.

=cut

sub shared_insert_activity {
    my ( $d_obj, $code, $props ) = validate_pos( @_,
        { isa => 'App::Dochazka::REST::Dispatch' },
        { type => SCALAR },
        { type => HASHREF },
    );
    $log->debug("Reached " . __PACKAGE__ . "::shared_insert_activity" );

    my %proplist_before = %$props;
    $proplist_before{'code'} = $code; # overwrite whatever might have been there
    $log->debug( "Properties before filter: " . join( ' ', keys %proplist_before ) );
        
    # spawn an object, filtering the properties first
    my @filtered_args = App::Dochazka::Common::Model::Activity::filter( %proplist_before );
    my %proplist_after = @filtered_args;
    $log->debug( "Properties after filter: " . join( ' ', keys %proplist_after ) );
    my $act = App::Dochazka::REST::Model::Activity->spawn( @filtered_args );

    # execute the INSERT db operation
    return $act->insert( $d_obj->context );
}


=head2 shared_insert_component

Takes two arguments: the dispatch object and the properties that are supposed
to be a component object to be inserted.

=cut

sub shared_insert_component {
    my ( $d_obj, $path, $props ) = validate_pos( @_,
        { isa => 'App::Dochazka::REST::Dispatch' },
        { type => SCALAR },
        { type => HASHREF },
    );
    $log->debug("Reached " . __PACKAGE__ . "::shared_insert_component" );

    my %proplist_before = %$props;
    $proplist_before{'path'} = $path; # overwrite whatever might have been there
    $log->debug( "Properties before filter: " . join( ' ', keys %proplist_before ) );

    # spawn an object, filtering the properties first
    my @filtered_args = App::Dochazka::Common::Model::Component::filter( %proplist_before );
    my %proplist_after = @filtered_args;
    $log->debug( "Properties after filter: " . join( ' ', keys %proplist_after ) );
    my $comp = App::Dochazka::REST::Model::Component->spawn( @filtered_args );

    # execute the INSERT db operation
    my $status = $comp->insert( $d_obj->context );
    return $status unless $status->level eq 'ERR' and $status->code eq 'DOCHAZKA_MALFORMED_400';
    $d_obj->mrest_declare_status( code => 400, explanation => 'DISPATCH_ILLEGAL_ENTITY' );
    return $fail;
}


=head2 shared_insert_interval

Shared routine for inserting attendance intervals.

=cut

sub shared_insert_interval {
    my ( $d_obj ) = @_;
    $log->debug("Reached " . __PACKAGE__ . "::shared_insert_interval" );

    return shared_insert_intlock( $d_obj, 'Interval' );
}


=head2 shared_insert_lock

Shared routine for inserting lock intervals.

=cut

sub shared_insert_lock {
    my ( $d_obj ) = @_;
    $log->debug("Reached " . __PACKAGE__ . "::shared_insert_lock" );

    return shared_insert_intlock( $d_obj, 'Lock' );
}


=head2 shared_insert_intlock

=cut

sub shared_insert_intlock {
    my ( $d_obj, $intlock ) = @_;
    $log->debug("Reached " . __PACKAGE__ . "::shared_insert_intlock with $intlock" );

    my $context = $d_obj->context;

    my %proplist_before = %{ $context->{'request_entity'} };
    $log->debug( "Properties before filter: " . join( ' ', keys %proplist_before ) );

    # dispatch
    my %dispatch = (
        'Interval' => \&App::Dochazka::Common::Model::Interval::filter,
        'Lock' => \&App::Dochazka::Common::Model::Lock::filter,
    );

    # spawn an object, filtering the properties first
    my @filtered_args = $dispatch{$intlock}->( %proplist_before );
    my %proplist_after = @filtered_args;
    $log->debug( "Properties after filter: " . join( ' ', keys %proplist_after ) );

    my $obj;
    if ( $intlock eq 'Interval' ) {
        $obj = App::Dochazka::REST::Model::Interval->spawn( @filtered_args );
    } elsif ( $intlock eq 'Lock' ) {
        $obj = App::Dochazka::REST::Model::Lock->spawn( @filtered_args );
    } else {
        die "Dying a horrible death";
    }

    # execute the INSERT db operation
    return $obj->insert( $context );
}


=head2 shared_update_intlock

Takes three arguments:

  - $d_obj is the dispatch object
  - $int is an interval or lock object (blessed hashref)
  - $over is a hashref with zero or more interval properties and new values

The values from $over replace those in $int

=cut

sub shared_update_intlock {
    my ( $d_obj, $int, $over ) = @_;
    $log->debug("Entering " . __PACKAGE__ . "::shared_update_intlock" );

    my $context = $d_obj->context;

    # determine whether we have been passed an interval or lock and set $idv accordingly
    my $class = ref( $int );
    my $idv;
    if ( $class eq 'App::Dochazka::REST::Model::Interval' ) {
        $idv = 'iid';
    } elsif ( $class eq 'App::Dochazka::REST::Model::Lock' ) {
        $idv = 'lid';
    } else {
        $log->crit( "Bad interval class! " . Dumper( $class ) );
        die "Bad interval class";
    }

    delete $over->{$idv} if exists $over->{$idv}; # IID/LID cannot be changed, so get rid of it

    # make sure $over does not contain any non-kosher fields, and merge
    # $over into $int
    return $int->update( $context ) if pre_update_comparison( $int, $over );
    $log->notice( "Failed pre_update_comparison" );
    $d_obj->mrest_declare_status( code => 400, explanation => 'Check request entity syntax' );
    return $fail;
}


# generalized dispatch target for
#    'interval/eid/:eid/:tsrange'
#    'lock/eid/:eid/:tsrange'
sub fetch_by_eid {
    my ( $context ) = validate_pos( @_, 
        { type => HASHREF },
    );
    $log->debug( "Entering " . __PACKAGE__ . "::_fetch_by_eid" ); 
    my $conn = $context->{'dbix_conn'},
    my ( $eid, $tsrange ) = ( $context->{'mapping'}->{'eid'}, $context->{'mapping'}->{'tsrange'} );

    my $type = _determine_interval_or_lock( $context->{'path'} );
    $log->debug("About to fetch $type intervals for EID $eid in tsrange $tsrange" );

    my $status = $f_dispatch{$type}->( $conn, $eid, $tsrange );
    if ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
        return $CELL->status_err( 'DOCHAZKA_NOT_FOUND_404' );
    }
    return $status;
}

# generalized dispatch target for
#    'interval/nick/:nick/:tsrange'
#    'lock/nick/:nick/:tsrange'
sub fetch_by_nick {
    my ( $context ) = validate_pos( @_, 
        { type => HASHREF } 
    );
    $log->debug( "Entering " . __PACKAGE__ . "::_fetch_by_nick" ); 
    my $conn = $context->{'dbix_conn'},
    my ( $nick, $tsrange ) = ( $context->{'mapping'}->{'nick'}, $context->{'mapping'}->{'tsrange'} );
    $log->debug("About to fetch intervals for nick $nick in tsrange $tsrange" );

    my $type = _determine_interval_or_lock( $context->{'path'} );
    $log->debug("About to fetch $type intervals for nick $nick in tsrange $tsrange" );

    # get EID
    my $status = App::Dochazka::REST::Model::Employee->load_by_nick( $conn, $nick );
    if ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
        return $CELL->status_err( 'DOCHAZKA_NOT_FOUND_404' );
    } elsif ( $status->not_ok ) {
        return $status;
    }
    my $eid = $status->payload->{'eid'};
    
    $status = $f_dispatch{$type}->( $conn, $eid, $tsrange );
    if ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
        return $CELL->status_err( 'DOCHAZKA_NOT_FOUND_404' );
    }
    return $status;
}

# generalized dispatch target for
#    'interval/self/:tsrange'
#    'lock/self/:tsrange'
sub fetch_own {
    my ( $context ) = validate_pos( @_, { type => HASHREF } );
    $log->debug( "Entering " . __PACKAGE__ . "::_fetch_own" ); 
    my $conn = $context->{'dbix_conn'};
    my ( $eid, $tsrange ) = ( $context->{'current'}->{'eid'}, $context->{'mapping'}->{'tsrange'} );

    my $type = _determine_interval_or_lock( $context->{'path'} );
    $log->debug("About to fetch $type intervals for EID $eid (current employee) in tsrange $tsrange" );

    my $status = $f_dispatch{$type}->( $conn, $eid, $tsrange );
    if ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
        return $CELL->status_err( 'DOCHAZKA_NOT_FOUND_404' );
    }
    return $status;
}


# generalized dispatch target for
#    'interval/iid' and 'interval/iid/:iid'
#    'lock/lid' and 'lock/lid/:lid'
sub iid_lid {
    my ( $context ) = validate_pos( @_, { type => HASHREF } );
    $log->debug( "Entering " . __PACKAGE__ . "::iid_lid" ); 

    my $conn = $context->{'dbix_conn'};

    my $type = _determine_interval_or_lock( $context->{'path'} );
    $log->debug( "Type is $type" );
    my %idmap = (
        "attendance" => 'iid',
        "lock" => 'lid',
    );

    my $id;
    if ( $context->{'method'} eq 'POST' ) {
        return $CELL->status_err('DOCHAZKA_MALFORMED_400') 
            unless exists $context->{'request_entity'}->{ $idmap{$type} };
        $id = $context->{'request_entity'}->{ $idmap{$type} };
        return $CELL->status_err( 'DISPATCH_PARAMETER_BAD_OR_MISSING', 
            args => [ $idmap{$type} ] ) unless $id;
        delete $context->{'request_entity'}->{ $idmap{$type} };
    } else {
        $id = $context->{'mapping'}->{ $idmap{$type} };
    }

    # does the ID exist? (load the whole record into $status->payload)
    my $fn = "load_by_" . $idmap{$type};
    my $status = $id_dispatch{$type}->$fn( $conn, $id );
    return $status unless $status->level eq 'OK' or $status->level eq 'NOTICE';
    return $CELL->status_err( 'DOCHAZKA_NOT_FOUND_404' ) if $status->code eq 'DISPATCH_NO_RECORDS_FOUND';
    my $belongs_eid = $status->payload->{'eid'};

    # this target requires special ACL handling
    my $current_eid = $context->{'current'}->{'eid'};
    my $current_priv = $context->{'current_priv'};
    if (   ( $current_priv eq 'passerby' ) or 
           ( $current_priv eq 'inactive' ) or
           ( $current_priv eq 'active' and $current_eid != $belongs_eid )
    ) {
        return $CELL->status_err( 'DOCHAZKA_FORBIDDEN_403' );
    }

    # it exists and we passed the ACL check, so go ahead and do what we need to do
    die "Bad interval!" unless exists( $status->payload->{'intvl'} ) and 
        defined( $status->payload->{'intvl'} );
    my $method = $context->{'method'}; 
    if ( $method eq 'GET' ) {
        return $status if $status->code eq 'DISPATCH_RECORDS_FOUND';
    } elsif ( $method =~ m/^(PUT)|(POST)$/ ) {
        return _update_interval( $context, $status->payload, $context->{'request_entity'} );
    } elsif ( $method eq 'DELETE' ) {
        $log->notice( "Attempting to delete $type interval " . $status->payload->{ $idmap{$type} } );
        return $status->payload->delete( $context );
    }
    return $CELL->status_crit("Aaaaaaaaaaahhh! Swallowed by the abyss" );
}


=head2 shared_process_quals

Parses qualifiers string into a hashref. Checks values for sanity; returns a status object.

=cut

sub shared_process_quals {
    my $qualifiers = shift || '';
    $qualifiers =~ s/\s//g;
    $log->debug( "Entering " . __PACKAGE__ . "::shared_process_qualifiers with $qualifiers" );

    my @qtokens = split(',', $qualifiers);
    
    my %pl = ();
    my $status = $CELL->status_ok;
    TOKEN: foreach my $t ( @qtokens ) {
        $log->debug( "Processing token $t\n" );
        foreach my $prop ( qw( nick eid month ) ) {
            if ( $t =~ m/^$prop=/ ) {
                #$log->debug( "Found property $prop" );
                $t =~ s/^$prop=//;
                #$log->debug( "Value is $t" );
                $pl{$prop} = $t;
                next TOKEN;
            }
        }
        $status = $CELL->status_err( 'DOCHAZKA_MALFORMED_400' );
        last TOKEN;
    }
    return $status unless $status->ok;
    my %well_formed = (
        'nick' => qr/^[[:alnum:]_][[:alnum:]_-]+$/,
        'eid' => qr/^\d{1,9}$/,
        'month' => qr/^\d{1,6}$/,
    );
    WELL_FORMED: foreach my $prop ( keys %pl ) {
        if ( ! ( $pl{$prop} =~ $well_formed{$prop} ) ) {
            $status = $CELL->status_err( 'DOCHAZKA_MALFORMED_400' );
            last WELL_FORMED;
        }
    }
    return $status unless $status->ok;
    my $payload = ( %pl ) ? \%pl : undef;
    return $CELL->status_ok( 'DISPATCH_PROCESSED_QUALIFIERS', payload => $payload );
}


1;
