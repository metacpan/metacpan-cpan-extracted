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
# Activity commands
package App::Dochazka::CLI::Commands::Activity;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL );
use App::Dochazka::CLI qw( $debug_mode );
use App::Dochazka::CLI::Util qw( parse_test rest_error );
use Data::Dumper;
use Exporter 'import';
use Web::MREST::CLI qw( send_req );




=head1 NAME

App::Dochazka::CLI::Commands::Activity - Activity commands




=head1 PACKAGE VARIABLES

=cut

our @EXPORT_OK = qw( activity_all );




=head1 FUNCTIONS

The functions in this module are called from the parser when it recognizes a command.

=cut

=head2 activity_all

    ACTIVITY
    ACTIVITY ALL
    ACTIVITY ALL DISABLED

=cut

sub activity_all {
    print "Entering " . __PACKAGE__ . "::activity_all\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    # print debug info
    if ( $debug_mode ) {
        print "Entering " . __PACKAGE__ . "::activity_all\n";
        print Dumper( $th );
    }

    my $disabled = $th->{'DISABLED'};  # boolean
    my $uri = $disabled
        ? "activity/all/disabled"
        : "activity/all";

    my $status = send_req( 'GET', $uri );
    return rest_error( $status, "Retrieve activity list" ) unless $status->ok;
    if ( $status->{'count'} == 0 ) {
        my $message = "No activities in database (maybe try SHOW ACTIVITY ALL DISABLED)";
        return $CELL->status_ok( 'DOCHAZKA_CLI_NORMAL_COMPLETION', payload => $message );
    }

    # 1st pass, determine maximum length of each field
    my ( $max_aid, $max_code, $max_desc ) = ( 0, 0, 0 );
    foreach my $act_h ( @{ $status->payload } ) {
        my ( $l_aid, $l_code, $l_desc ) = (
            length( $act_h->{'aid'} ),
            length( $act_h->{'code'} ),
            length( $act_h->{'long_desc'} ),
        );
        $max_aid = $l_aid if $l_aid > $max_aid;
        $max_code = $l_code if $l_code > $max_code;
        if ( defined $l_desc ) {
            $max_desc = $l_desc if $l_desc > $max_desc;
        } else {
            $max_desc = 0;
        }
    }

    # 2nd pass: assemble the table
    my $r = "\n";
    foreach my $act_h ( @{ $status->payload } ) {
        my $format = $disabled ? '%1s' : '';
        $format .=
            "%" . ($max_aid + 1) . "s " . 
            "%-" . ($max_code) . "s " .
            "%-" . ($max_desc) . "s\n";
        if ( $disabled ) {
            my $d = ( $act_h->{'disabled'} ) ? '*' : ' ';
            $r .= sprintf $format, $d, $act_h->{'aid'}, $act_h->{'code'}, 
                ( $act_h->{'long_desc'} || '(not set)' );
        } else {
            $r .= sprintf $format, $act_h->{'aid'}, $act_h->{'code'}, 
                ( $act_h->{'long_desc'} || '(not set)' );
        }
    }
    $r .= "\nActivities marked with an asterisk (*) in the first column are disabled\n" 
        if $disabled;

    return $CELL->status_ok( 'DOCHAZKA_CLI_NORMAL_COMPLETION', payload => $r );
}


1;
