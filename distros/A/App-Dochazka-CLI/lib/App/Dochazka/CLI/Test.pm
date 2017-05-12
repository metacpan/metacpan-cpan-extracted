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
# Test module - reusable components
#
package App::Dochazka::CLI::Test;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::CLI::Parser qw( look_up_command process_command );
use App::Dochazka::CLI::Util qw( init_prompt );
use Exporter qw( import );
use Test::More;
use Web::MREST::CLI qw( init_cli_client );




=head1 NAME

App::Dochazka::CLI::Test - Reusable test routines




=head1 PACKAGE VARIABLES AND EXPORTS

=cut

our @EXPORT_OK = qw( 
    delete_interval_test
    do_parse_test
    fetch_interval_test
    init_unit
);




=head1 FUNCTIONS


=head2 init_unit

=cut

sub init_unit {
    init_prompt();
    my $status = init_cli_client( distro => 'App-Dochazka-CLI', );
    return $status;
}


=head2 delete_interval

=cut

sub delete_interval_test {
    my ( $iid ) = @_;
    note( 'delete the interval we just created' );
    note( my $cmd = "DELETE INTERVAL IID $iid" );
    my $rv = process_command( $cmd );
    is( ref( $rv ), 'App::CELL::Status' );
    is( $rv->level, 'OK' );
    is( $rv->code, 'DOCHAZKA_CUD_OK', "IID $iid deleted" );
}


=head2 do_parse_test

A piece of testing code we run for entries in CommandMap.pm 

Takes the "normalized command", i.e. the C<nc> property returned by C<parse()>;
especially do not send it the raw command entered by the user!

For usage, see C<< t/parser/parse_test.t >>

=cut

sub do_parse_test {
    my ( $nc, $handler ) = @_;
    my $coderef = look_up_command( $nc );
    is( ref( $coderef ), 'CODE', "look_up_command( $nc ) returns a code reference" );
    my $status = $coderef->( 'PARSE_TEST' => 1 );
    ok( $status->ok );
    is( $status->payload, $handler, "handler of $nc is $handler" );
}


=head2 fetch_interval_test

Takes a "command component" and a search string to look for. The command
component is inserted into 

    INTERVAL FETCH $cmd_component

and the search string is looked for in the response.

Returns the response (payload) string for (optional) further testing.

=cut

sub fetch_interval_test {
    my ( $cmd_component, $search_str ) = @_;

    note( my $cmd = "INTERVAL FETCH $cmd_component" );
    my $rv = process_command( $cmd );
    is( ref( $rv ), 'App::CELL::Status' );
    is( $rv->level, 'OK' );
    is( $rv->code, 'DOCHAZKA_CLI_NORMAL_COMPLETION' );
    like( $rv->payload, qr/Attendance intervals of worker.+$search_str/ms );

    return $rv->payload;
}


1;
