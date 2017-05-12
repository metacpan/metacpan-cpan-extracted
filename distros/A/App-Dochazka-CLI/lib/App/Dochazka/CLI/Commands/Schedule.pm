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
# Schedule commands
package App::Dochazka::CLI::Commands::Schedule;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL );
use App::Dochazka::CLI qw( $debug_mode );
use App::Dochazka::CLI::Shared qw( print_schedule_object show_as_at );
use App::Dochazka::CLI::Util qw( parse_test );
use App::Dochazka::Common::Model::Schedule;
use Data::Dumper;
use Exporter 'import';
use JSON;
use Web::MREST::CLI qw( send_req );




=head1 NAME

App::Dochazka::CLI::Commands::Schedule - Schedule commands




=head1 PACKAGE VARIABLES

=cut

our @EXPORT_OK = qw( 
    $memsched 
    %dow_map 
    add_memsched_entry 
    assign_memsched_scode
    clear_memsched_entries
    dump_memsched_entries 
    fetch_all_schedules
    replicate_memsched_entry 
    schedule_all
    schedule_new
    schedulespec
    schedulespec_remark
    schedulespec_scode
    show_schedule_as_at
);

# in-memory storage for working schedule
our $memsched;
our $memsched_scode;

our %dow_map = (
    'MON' => '2015-03-23',
    'TUE' => '2015-03-24',
    'WED' => '2015-03-25',
    'THU' => '2015-03-26',
    'FRI' => '2015-03-27',
    'SAT' => '2015-03-28',
    'SUN' => '2015-03-29',
);

our %date_map = (
    '2015-03-23' => 'MON',
    '2015-03-24' => 'TUE',
    '2015-03-25' => 'WED',
    '2015-03-26' => 'THU',
    '2015-03-27' => 'FRI',
    '2015-03-28' => 'SAT',
    '2015-03-29' => 'SUN',
);




=head1 FUNCTIONS

The functions in this module are called from the parser when it recognizes a command.

=cut


=head2 Command handlers

The routines in this section are called as command handlers.


=head3 schedule_all

    SCHEDULE ALL
    SCHEDULE ALL DISABLED

=cut

sub schedule_all {
    print "Entering " . __PACKAGE__ . "::schedule_all\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    return $CELL->status_ok( 'UNDER_CONSTRUCTION' );    
}


=head3 show_schedule_as_at

    SCHEDULE
    EMPLOYEE_SPEC SCHEDULE
    SCHEDULE _DATE
    EMPLOYEE_SPEC SCHEDULE _DATE

=cut

sub show_schedule_as_at {
    print "Entering " . __PACKAGE__ . "::show_schedule_as_at\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    return show_as_at( 'schedule', $th );
}


=head3 add_memsched_entry

    SCHEDULE _DOW _TIME _DOW1 _TIME1
    SCHEDULE _DOW _TIME _HYPHEN _DOW1 _TIME1
    SCHEDULE _DOW _TIMERANGE

=cut

sub add_memsched_entry {
    print "Entering " . __PACKAGE__ . "::add_memsched_entry\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    my ( $dow_begin, $dow_end, $time_begin, $time_end ) = _canonicalize_th( $th );
    my ( $date_begin, $date_end ) = ( $dow_map{$dow_begin}, $dow_map{$dow_end} );

    if ( exists( $memsched->{"$date_begin $time_begin"} ) ) {
        push @{ $memsched->{"$date_begin $time_begin"} }, "$date_end $time_end"
            unless grep { $_ eq "$date_end $time_end" } @{ $memsched->{"$date_begin $time_begin"} };
    } else {
        $memsched->{"$date_begin $time_begin"} = [ "$date_end $time_end" ];
    }

    print Dumper( $memsched ) if $debug_mode;

    return _dump_memsched_entries();
}


=head3 replicate_memsched_entry

    SCHEDULE ALL _TIMERANGE

Apply timerange to all five days MON-FRI

=cut

sub replicate_memsched_entry {
    print "Entering " . __PACKAGE__ . "::add_memsched_entry\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    foreach my $dow ( qw( MON TUE WED THU FRI ) ) {
        $th->{_DOW} = $dow;
        add_memsched_entry( $ts, $th );
    }

    return _dump_memsched_entries();
}


=head3 clear_memsched_entries

    SCHEDULE CLEAR

=cut

sub clear_memsched_entries {
    print "Entering " . __PACKAGE__ . "::clear_memsched_entries\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    $memsched = {};
    $memsched_scode = '';
    return $CELL->status_ok( 'DOCHAZKA_CLI_MEMSCHED_EMPTY' );
}


=head3 fetch_all_schedules

    SCHEDULES FETCH ALL 
    SCHEDULES FETCH ALL DISABLED

Get all schedules and dump them to the screen.

=cut

sub fetch_all_schedules {
    print "Entering " . __PACKAGE__ . "::fetch_all_schedules\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    my $status = ( $th->{DISABLED} )
        ? send_req( 'GET', 'schedule/all/disabled' )
        : send_req( 'GET', 'schedule/all' );
    if ( $status->ok ) {
        my $pl = '';
        foreach my $sch_hash ( @{ $status->payload } ) {
            my $sch_obj = App::Dochazka::Common::Model::Schedule->spawn( %$sch_hash );
            $pl .= print_schedule_object( $sch_obj );
            $pl .= "\n";
        }
        return $CELL->status_ok( 'DOCHAZKA_CLI_NORMAL_COMPLETION', payload => $pl );
    }
    return $status;
}


=head3 dump_memsched_entries

Dumps "memsched" (i.e. working schedule stored in memory) to the screen.

Note that L<App::Dochazka::CLI> will happily let you build up a completely
illegal and nonsensical schedule in memory, and submit it to the REST
server. Data integrity controls for new schedule records are performed
on server-side.

    SCHEDULE DUMP
    SCHEDULE MEMORY

=cut

sub dump_memsched_entries {
    print "Entering " . __PACKAGE__ . "::dump_memsched_entries\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';
    
    my $pl = '';

    if ( $memsched_scode ) {
        $pl .= "Schedule code: $memsched_scode\n\n";
    }

    # sort entries by beginning and ending timestamp
    foreach my $start_str ( sort keys %$memsched ) {
        my ( $start_date, $start_time ) = $start_str =~ m/(.*) (.*)/;
        my $start_converted = $date_map{$start_date} . " " . $start_time;
        foreach my $end_str ( sort @{ $memsched->{$start_str} } ) {
            my ( $end_date, $end_time ) = $end_str =~ m/(.*) (.*)/;
            my $end_converted = $date_map{$end_date} . " " . $end_time;
            $pl .= "[ $start_converted, $end_converted )\n";
        }
    }

    my $code = $pl ? 'DOCHAZKA_CLI_MEMSCHED' : 'DOCHAZKA_CLI_MEMSCHED_EMPTY';
    return $CELL->status_ok( $code, payload => $pl );
}


=head3 schedule_new

Submits the "memsched" (i.e. working schedule stored in memory) to the REST
server via 'POST submit/new'.

    SCHEDULE NEW

=cut

sub schedule_new {
    print "Entering " . __PACKAGE__ . "::schedule_new\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    my @pl;

    # make sure there are some memsched entries to begin with
    if ( ! $memsched ) {
        return $CELL->status_err( 'DOCHAZKA_CLI_NO_SCHEDULE_ENTRIES_IN_MEMORY' );
    }

    # sort entries by beginning and ending timestamp
    foreach my $start_str ( sort keys %$memsched ) {
        foreach my $end_str ( sort @{ $memsched->{$start_str} } ) {
            push @pl, "[ $start_str, $end_str )";
        }
    }

    my $sched = { "schedule" => \@pl };
    $sched->{'scode'} = $memsched_scode if $memsched_scode;
    my $json = encode_json $sched;

    my $status = send_req( 'POST', 'schedule/new', $json );
    if ( $status->ok ) {
        my $sch_obj = App::Dochazka::Common::Model::Schedule->spawn( %{ $status->payload } );
        my $pl = '';
        if ( my $http_status = $status->{'http_status'} ) {
            $pl .= "HTTP status: $http_status\n";
        }
        $pl .= print_schedule_object( $sch_obj );
        _clear_memsched_entries();
        return $CELL->status_ok( 
            'DOCHAZKA_CLI_NORMAL_COMPLETION', 
            http_status => '200 OK',
            payload => $pl 
        );
    }
    return $status;
}


=head3 assign_memsched_scode

    SCHEDULE SCODE _TERM

Assign an 'scode' value to the "memsched" (local memory buffer) schedule.

=cut

sub assign_memsched_scode {
    print "Entering " . __PACKAGE__ . "::assign_memsched_scode\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    $memsched_scode = $th->{_TERM};

    return _dump_memsched_entries();
}


=head3 schedulespec

    SCHEDULE_SPEC
    SCHEDULE_SPEC SHOW

=cut

sub schedulespec {
    print "Entering " . __PACKAGE__ . "::schedulespec\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    my ( $key_spec, $key ) = $th->{'SCHEDULE_SPEC'} =~ m/^(.*)\=(.*)$/;

    my ( $status, $pl );
    if ( $key_spec =~ m/^sco/i ) {
        $status = send_req( 'GET', "schedule/scode/$key" );
    } elsif ( $key_spec =~ m/^sid/ ) {
        $status = send_req( 'GET', "schedule/sid/$key" );
    } else {
        die "AAAHAAAHHH!!! Invalid schedule lookup key " . ( defined( $key_spec ) ? $key_spec : "undefined" )
    }

    if ( $status->ok ) {
        my $sch_obj = App::Dochazka::Common::Model::Schedule->spawn( %{ $status->payload } );
        $pl = print_schedule_object( $sch_obj );
        return $CELL->status_ok( "DOCHAZKA_CLI_NORMAL_COMPLETION", payload => $pl );
    }

    return $status;
}


=head3 schedulespec_remark

    SCHEDULE_SPEC REMARK _TERM

=cut

sub schedulespec_remark {
    print "Entering " . __PACKAGE__ . "::schedulespec_remark\n" if $debug_mode;
    my ( $ts, $th ) = @_;
    
    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    my ( $key_spec, $key ) = $th->{'SCHEDULE_SPEC'} =~ m/^(.*)\=(.*)$/;
    my $remark = $th->{'_REST'};
    $remark =~ s/\"/\'/g;

    my $status;
    if ( $key_spec =~ m/^sco/i ) {
        $status = send_req( 'PUT', "schedule/scode/$key", <<"EOS" );
{ "remark" : "$remark" }
EOS
    } elsif ( $key_spec =~ m/^sid/ ) {
        $status = send_req( 'PUT', "schedule/sid/$key", <<"EOS" );
{ "remark" : "$remark" }
EOS
    } else {
        die "AAAHAAAHHH!!! Invalid schedule lookup key " . ( defined( $key_spec ) ? $key_spec : "undefined" )
    }

    if ( $status->level eq 'OK' and $status->code eq 'DOCHAZKA_CUD_OK' ) {
        my $sch_obj = App::Dochazka::Common::Model::Schedule->spawn( %{ $status->payload } );
        my $pl = print_schedule_object( $sch_obj );
        return $CELL->status_ok( 'DOCHAZKA_CLI_NORMAL_COMPLETION', payload => $pl );
    }

    return $status;
}

=head3 schedulespec_scode

    SCHEDULE_SPEC SCODE _TERM

=cut

sub schedulespec_scode {
    print "Entering " . __PACKAGE__ . "::schedulespec_scode\n" if $debug_mode;
    my ( $ts, $th ) = @_;
    
    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    my ( $key_spec, $key ) = $th->{'SCHEDULE_SPEC'} =~ m/^(.*)\=(.*)$/;
    my $scode = $th->{'_TERM'};

    my $status;
    if ( $key_spec =~ m/^sco/i ) {
        $status = send_req( 'PUT', "schedule/scode/$key", <<"EOS" );
{ "scode" : "$scode" }
EOS
    } elsif ( $key_spec =~ m/^sid/ ) {
        $status = send_req( 'PUT', "schedule/sid/$key", <<"EOS" );
{ "scode" : "$scode" }
EOS
    } else {
        die "AAAHAAAHHH!!! Invalid schedule lookup key " . ( defined( $key_spec ) ? $key_spec : "undefined" )
    }

    if ( $status->level eq 'OK' and $status->code eq 'DOCHAZKA_CUD_OK' ) {
        my $sch_obj = App::Dochazka::Common::Model::Schedule->spawn( %{ $status->payload } );
        my $pl = print_schedule_object( $sch_obj );
        return $CELL->status_ok( 'DOCHAZKA_CLI_NORMAL_COMPLETION', payload => $pl );
    }

    return $status;
}



=head2 Helper functions

Functions called by multiple command handlers


=head3 _canonicalize_th

The canonical form is "SCHEDULE _DOW _TIME _DOW1 _TIME1"
so if we get one of the other forms, we "canonicalize th"

=cut

sub _canonicalize_th {
    my $th = shift;
    print "Entering " . __PACKAGE__ . "::_canonicalize_th with th: " . Dumper( $th ) . "\n" if $debug_mode;

    my ( $dow_begin, $dow_end, $time_begin, $time_end );

    $dow_begin = uc( $th->{'_DOW'} );
    if ( $th->{_TIMERANGE} ) {
        $dow_end = $dow_begin;
        ( $time_begin, $time_end ) = $th->{_TIMERANGE} =~ m/(.*)-(.*)/;
    } else {
        $dow_end = uc( $th->{'_DOW1'} );
        $time_begin = $th->{'_TIME'};
        $time_end = $th->{'_TIME1'};
    }
    my ( $tbh, $tbm ) = $time_begin =~ m/(.*):(.*)/;
    $time_begin = sprintf( "%02d:%02d", $tbh, $tbm );
    my ( $teh, $tem ) = $time_end =~ m/(.*):(.*)/;
    $time_end = sprintf( "%02d:%02d", $teh, $tem );

    return ( $dow_begin, $dow_end, $time_begin, $time_end );
}


=head3 _clear_memsched_entries

Since clear_memsched_entries is a command handler, if we want to call it from
within this module we have to use a special argument. Thus we can have our cake
and eat it, too.

=cut

sub _clear_memsched_entries {
    return clear_memsched_entries( 'DUMMY_ARG' => 0 );
}


=head3 _dump_memsched_entries

Since dump_memsched_entries is a command handler, if we want to call it from
within this module we have to use a special argument. Thus we can have our cake
and eat it, too.

=cut

sub _dump_memsched_entries {
    return dump_memsched_entries( 'DUMMY_ARG' => 0 );
}


1;
