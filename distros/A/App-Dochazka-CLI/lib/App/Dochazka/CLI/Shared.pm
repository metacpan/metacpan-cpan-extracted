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
# Shared routines
package App::Dochazka::CLI::Shared;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL );
use App::Dochazka::CLI qw( $current_emp $debug_mode );
use App::Dochazka::CLI::Util qw( lookup_employee rest_error );
use Data::Dumper;
use Exporter 'import';
use File::Slurp;
use File::Temp;
use JSON;
use Web::MREST::CLI qw( send_req );




=head1 NAME

App::Dochazka::CLI::Shared - Shared routines




=head1 PACKAGE VARIABLES

=cut

our @EXPORT_OK = qw(
    print_schedule_object
    shared_generate_report
    show_as_at
);




=head1 FUNCTIONS

The functions in this module are called from handlers.

=cut


=head2 print_schedule_object

Use this function to "print" a schedule object (passed an an argument). The
"printed schedule" (string) is returned.

=cut

sub print_schedule_object {
    my ( $sch, %ARGS ) = @_;
    die "AAGH! Not a schedule object" unless ref( $sch ) eq 'App::Dochazka::Common::Model::Schedule';
    my $ps = '';

    $ps .= ' 'x$ARGS{'indent'} if exists( $ARGS{'indent'} );
    $ps .= "DISABLED | " if $sch->disabled;
    $ps .= "Schedule ID (SID): " . $sch->sid . "\n";
    if ( my $scode = $sch->scode ) {
        $ps .= ' 'x$ARGS{'indent'} if exists( $ARGS{'indent'} );
        $ps .= "DISABLED | " if $sch->disabled;
        $ps .= "Schedule code (scode): " . $scode . "\n";
    }

    # decode the schedule
    my $sch_array = decode_json( $sch->schedule );
    foreach my $entry ( @$sch_array ) {
        $ps .= ' 'x$ARGS{'indent'} if exists( $ARGS{'indent'} );
        $ps .= "DISABLED | " if $sch->disabled;
        # each entry is a hash with properties low_dow, low_time, high_dow, high_time
        $ps .= "[ " . $entry->{'low_dow'} . " " . $entry->{'low_time'} . ", " .
                      $entry->{'high_dow'} . " " . $entry->{'high_time'} . " )\n";
    }

    # remark
    if ( my $remark = $sch->remark ) {
        $ps .= ' 'x$ARGS{'indent'} if exists( $ARGS{'indent'} );
        $ps .= "DISABLED | " if $sch->disabled;
        $ps .= "Remark: " . $sch->remark  . "\n";
    }

    return $ps;
}


=head2 shared_generate_report

Given an entity, call POST genreport and open the results in web browser.

=cut

sub shared_generate_report {
    print "Entering " . __PACKAGE__ . "::shared_generate_report\n" if $debug_mode;
    my ( $entity ) = @_;

    my $status = send_req( 'POST', 'genreport', $entity );
    return rest_error( $status, "GENERATE REPORT" ) unless $status->ok;

    # report output in $status->payload: write it to a file
    my $tmp = File::Temp->new( DIR => '/tmp' );
    write_file( $tmp->filename, $status->payload );
    system( "xdg-open " . $tmp->filename );

    return $CELL->status_ok( 
        'DOCHAZKA_CLI_NORMAL_COMPLETION', 
        payload => "Report written to " . $tmp->filename . " and attempted to open in web browser" 
    );
}


=head2 show_as_at

Given $type (either "priv" or "schedule") and $th hashref from the command
parser, return status object.

=cut

sub show_as_at {
    print "Entering " . __PACKAGE__ . "::show_as_at\n" if $debug_mode;
    my ( $type, $th ) = @_;

    my $emp_spec = ( $th->{'EMPLOYEE_SPEC'} )
        ? $th->{'EMPLOYEE_SPEC'}
        : $current_emp;
    
    my $date = ( $th->{'_DATE'} )
        ? $th->{'_DATE'} . ' 12:00'
        : '';

    my ( $eid, $nick, $status, $resource );
    if ( $emp_spec->can('eid') ) {
        $eid = $emp_spec->eid;
        $nick = $emp_spec->nick;
        $resource = "$type/self";
    } elsif ( ref( $emp_spec ) eq '' ) {
        $status = lookup_employee( key => $emp_spec );
        return rest_error( $status, "Employee lookup" ) unless $status->ok;
        $eid = $status->payload->{'eid'};
        $nick = $status->payload->{'nick'};
        $resource = "$type/eid/$eid";
    } else {
        die "AGHHAH! bad employee specifier";
    }

    my $display_date;
    if ( $date ) {
        $resource .= "/$date";
        $display_date = $th->{'_DATE'};
    } else {
        $display_date = "now";
    }

    $status = send_req( 'GET', $resource );
    if ( $status->ok ) {
        my $pl = '';
        if ( $type eq 'priv' ) {
            $pl .= "Privilege level of $nick (EID $eid) as of $display_date: " . $status->payload->{'priv'} . "\n";
        } elsif ( $type eq 'schedule' ) {
            my $sch_obj = App::Dochazka::Common::Model::Schedule->spawn( %{ $status->payload->{'schedule'} } );
            $pl .= "Schedule of $nick (EID $eid) as of $display_date:\n";
            $pl .= print_schedule_object( $sch_obj, indent => 4 );
        } else {
            die "AGH! bad type " . $type || "undefined";
        }
        return $CELL->status_ok( 'DOCHAZKA_CLI_NORMAL_COMPLETION', payload => $pl );
    }

    return rest_error( $status, "GET $resource" );
}


1;
