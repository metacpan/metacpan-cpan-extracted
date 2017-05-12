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
# History commands
package App::Dochazka::CLI::Commands::History;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL );
use App::Dochazka::CLI qw( $current_emp $debug_mode );
use App::Dochazka::CLI::Util qw( lookup_employee parse_test rest_error truncate_to );
use Data::Dumper;
use Exporter 'import';
use Text::Table;
use Web::MREST::CLI qw( send_req );




=head1 NAME

App::Dochazka::CLI::Commands::History - History commands




=head1 PACKAGE VARIABLES

=cut

our @EXPORT_OK = qw( 
    add_priv_history
    add_schedule_history
    dump_priv_history
    dump_schedule_history
    set_history_remark
);




=head1 FUNCTIONS

The functions in this module are called from the parser when it recognizes a command.


=head2 Command handlers

Command handler functions are called from the parser.


=head3 dump_priv_history

    PRIV HISTORY
    EMPLOYEE_SPEC PRIV HISTORY

=cut

sub dump_priv_history {
    print "Entering " . __PACKAGE__ . "::dump_priv_history\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    my $emp_spec = ( $th->{'EMPLOYEE_SPEC'} )
        ? $th->{'EMPLOYEE_SPEC'}
        : $current_emp;

    return _dump_history(
        emp_spec => $emp_spec,
        type => 'priv',
    );
}


=head3 dump_schedule_history

    SCHEDULE HISTORY
    EMPLOYEE_SPEC SCHEDULE HISTORY

=cut

sub dump_schedule_history {
    print "Entering " . __PACKAGE__ . "::dump_schedule_history\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    my $emp_spec = ( $th->{'EMPLOYEE_SPEC'} )
        ? $th->{'EMPLOYEE_SPEC'}
        : $current_emp;

    return _dump_history(
        emp_spec => $emp_spec,
        type => 'schedule',
    );
}


=head3 add_priv_history

Add privilege history record.

    EMPLOYEE_SPEC PRIV_SPEC _DATE
    EMPLOYEE_SPEC PRIV_SPEC EFFECTIVE _DATE
    EMPLOYEE_SPEC SET PRIV_SPEC _DATE
    EMPLOYEE_SPEC SET PRIV_SPEC EFFECTIVE _DATE

=cut

sub add_priv_history {
    print "Entering " . __PACKAGE__ . "::add_priv_history\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    my $emp_spec = ( $th->{'EMPLOYEE_SPEC'} )
        ? $th->{'EMPLOYEE_SPEC'}
        : $current_emp;

    return _add_history(
        emp_spec => $emp_spec,
        type => 'priv',
        effective => $th->{'_DATE'},
        priv => $th->{'PRIV_SPEC'},
    );
}


=head3 add_schedule_history

Add schedule history record.

    EMPLOYEE_SPEC SCHEDULE_SPEC _DATE
    EMPLOYEE_SPEC SCHEDULE_SPEC EFFECTIVE _DATE
    EMPLOYEE_SPEC SET SCHEDULE_SPEC _DATE
    EMPLOYEE_SPEC SET SCHEDULE_SPEC EFFECTIVE _DATE

=cut 

sub add_schedule_history {
    print "Entering " . __PACKAGE__ . "::add_schedule_history\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    my $emp_spec = ( $th->{'EMPLOYEE_SPEC'} )
        ? $th->{'EMPLOYEE_SPEC'}
        : $current_emp;

    my ( $key_spec, $key ) = $th->{'SCHEDULE_SPEC'} =~ m/^(.*)\=(.*)$/;
    $key_spec = lc $key_spec;

    return _add_history(
        emp_spec => $emp_spec,
        type => 'schedule',
        effective => $th->{'_DATE'},
        $key_spec => $key,
    );
}


=head3 set_history_remark

    PHISTORY_SPEC REMARK
    PHISTORY_SPEC SET REMARK
    SHISTORY_SPEC REMARK
    SHISTORY_SPEC SET REMARK

=cut

sub set_history_remark {
    print "Entering " . __PACKAGE__ . "::dump_schedule_history\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    my ( $type, $id_spec, $id );
    if ( $th->{'PHISTORY_SPEC'} ) {
        $type = 'priv';
        $id_spec = 'phid';
        $id = $th->{'PHISTORY_SPEC'};
    } elsif ( $th->{'SHISTORY_SPEC'} ) {
        $type = 'schedule';
        $id_spec = 'shid';
        $id = $th->{'SHISTORY_SPEC'};
    } else {
        die "Agh~! neither PHISTORY_SPEC nor SHISTORY_SPEC given";
    }

    my $remark = $th->{'_REST'} || '';
    $remark =~ s/[\"\']//g;

    my $status = send_req( 'POST', "$type/history/$id_spec/$id", <<"EOS" );
{ "remark" : "$remark" }
EOS

    return $status;
}


=head2 Helper functions

Functions called from multiple command handlers.


=head3 _add_history

Add a history record

=cut

sub _add_history {
    my %ARGS = @_;

    # get type
    my $type = $ARGS{'type'};

    # get EID
    my ( $emp_obj, $status ); 
    $status = _process_employee_spec( $ARGS{'emp_spec'} );
    return $status unless $status->ok;
    my $eid = $status->payload->{'eid'};

    # get key_spec and key
    my ( $key_spec, $key );
    if ( exists( $ARGS{'priv'} ) ) {
        $key_spec = 'priv';
        $key = $ARGS{'priv'};
    } elsif ( exists( $ARGS{'scode'} ) ) {
        # special case - since the underlying App::Dochazka::REST resource
        # only takes a 'sid', we have to look up the scode to determine the sid
        my $status = send_req( 'GET', "schedule/scode/$ARGS{'scode'}" );
        my $sid;
        if ( $status->ok and $status->code eq 'DISPATCH_SCHEDULE_FOUND' ) {
            $sid = $status->payload->{'sid'};
        } else {
            return $status;
        }
        $key_spec = 'sid';
        $key = $sid;
    } elsif ( exists( $ARGS{'sid'} ) ) {
        $key_spec = 'sid';
        $key = $ARGS{'sid'};
    } else {
        die "AHAAHHA!! bad key_spec " . ( $key_spec || "undefined" );
    }

    # get effective
    my $effective = $ARGS{'effective'} || "undefined";

    # send REST request
    $status = send_req( 'POST', "$type/history/eid/$eid", <<"EOS" );
{ "$key_spec" : "$key", "effective" : "$effective" }
EOS

    if ( $status->ok and $status->code eq 'DOCHAZKA_CUD_OK' ) {
        if ( $type eq 'priv' ) {
            $status = $CELL->status_ok( "DOCHAZKA_CLI_PRIV_HISTORY_ADD",
                args => [ $status->payload->{'phid'} ] );
        } elsif ( $type eq 'schedule' ) {
            $status = $CELL->status_ok( "DOCHAZKA_CLI_SCHEDULE_HISTORY_ADD",
                args => [ $status->payload->{'shid'} ] );
        } else {
            die "AH!@! bad type " . ( $type || "undefined" );
        }
    }

    return $status;
}


=head3 _dump_history

=cut

sub _dump_history {
    my %ARGS = @_;

    # get type
    my $type = $ARGS{'type'};

    # get EID
    my ( $emp_obj, $status ); 
    $status = _process_employee_spec( $ARGS{'emp_spec'} );
    return $status unless $status->ok;
    my $eid = $status->payload->{'eid'};
    die "AAHQ! Could not extract EID from payload: " . Dumper( $status ) unless $eid;

    # get $type history for that EID
    $status = send_req( 'GET', "$type/history/eid/$eid" );
    if ( $status->ok ) {
        my $pl;
        if ( $type eq 'priv' ) {
            $pl .= _print_priv_history( $status->payload );
        } elsif ( $type eq 'schedule' ) {
            $pl .= _print_schedule_history( $status->payload );
        } else {
            die "AH! bad type " . $type || "undefined";
        }
        return $CELL->status_ok( 'DOCHAZKA_CLI_NORMAL_COMPLETION', payload => $pl );
    }

    return $status;
}


=head3 _print_priv_history

Take a privhistory and print it

=cut

sub _print_priv_history {
    my $props = shift;
    my $eid = $props->{'eid'};
    my $nick = $props->{'nick'};

    my $pl = '';
    $pl .= "Privilege history of $nick (EID $eid):\n\n";

    my $t = Text::Table->new( 'PHID', 'Effective date', 'Privlevel', 'Remark' );
    foreach my $entry ( @{ $props->{'history'} } ) {
        my ( $effective ) = $entry->{'effective'} =~ m/(\S+)\s/;
        $t->add(
            $entry->{'phid'},
            $effective,
            $entry->{'priv'},
            truncate_to( $entry->{'remark'} ),
        );
    }

    $pl .= $t;

    return $pl;
}


=head3 _print_schedule_history

Take a schedhistory and print it

=cut

sub _print_schedule_history {
    my $props = shift;
    my $eid = $props->{'eid'};
    my $nick = $props->{'nick'};

    my $pl = '';
    $pl .= "Schedule history of $nick (EID $eid):\n\n";

    my $t = Text::Table->new( 'SHID', 'Effective date', 'SID', 'scode', 'Remark' );
    foreach my $entry ( @{ $props->{'history'} } ) {
        my ( $effective ) = $entry->{'effective'} =~ m/(\S+)\s/;
        my $status = send_req( 'GET', 'schedule/sid/' . $entry->{'sid'} );
        my ( $scode, $remark );
        if ( $status->ok ) {
            $scode = $status->payload->{'scode'} || '';
        } else {
            $scode = '';
        }
        $t->add(
            $entry->{'shid'},
            $effective,
            $entry->{'sid'},
            $scode,
            truncate_to( $entry->{'remark'} ),
        );
    }

    $pl .= $t;

    return $pl;
}


=head3 _process_employee_spec

Given EMPLOYEE_SPEC, return a status object that can either be OK with
employee object in payload or NOT_OK with mrest_declare_status already
called.

=cut

sub _process_employee_spec {
    my $emp_spec = shift;

    my ( $eid, $status );
    if ( $emp_spec->can('eid') ) {
        $status = $CELL->status_ok( 'DUMMY', payload => $emp_spec->TO_JSON );
    } elsif ( ref( $emp_spec ) eq '' ) {
        $status = lookup_employee( key => $emp_spec );
        return rest_error( $status, "Employee lookup" ) unless $status->ok;
    } else {
        die "AGHHAH! bad employee specifier";
    }

    return $status;
}
    

1;
