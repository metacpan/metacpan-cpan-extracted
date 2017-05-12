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
# Component commands
package App::Dochazka::CLI::Commands::Component;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL );
use App::Dochazka::CLI qw( $debug_mode );
use App::Dochazka::CLI::Shared qw( shared_generate_report );
use App::Dochazka::CLI::Util qw( parse_test rest_error );
use Data::Dumper;
use Exporter 'import';
use Web::MREST::CLI qw( send_req );




=head1 NAME

App::Dochazka::CLI::Commands::Component - Component commands




=head1 PACKAGE VARIABLES

=cut

our @EXPORT_OK = qw( 
    component_path
    generate_report
);




=head1 FUNCTIONS

The functions in this module are called from the parser when it recognizes a command.

=cut

=head2 component_path

    COMPONENT PATH

    N.B. Work In Progress, unclear whether it will ever be useful

=cut

sub component_path {
    print "Entering " . __PACKAGE__ . "::component_path\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    # print debug info
    if ( $debug_mode ) {
        print "Entering " . __PACKAGE__ . "::component_path\n";
        print Dumper( $th );
    }

    my $status = send_req( 'POST', 'component/path', $th->{_REST} );
    return rest_error( $status, "COMPONENT PATH" ) unless $status->ok;

    return $CELL->status_ok( 'DOCHAZKA_CLI_NORMAL_COMPLETION', payload => $status->payload );
}


=head2 generate_report

    GENERATE REPORT _PATH $PARAMETERS_JSON

    Example $PARAMETERS_JSON: { "name" : "John Doe" }

=cut

sub generate_report {
    print "Entering " . __PACKAGE__ . "::generate_report\n" if $debug_mode;
    my ( $ts, $th ) = @_;

    # parse test
    return parse_test( $ts, $th ) if $ts eq 'PARSE_TEST';

    # print debug info
    if ( $debug_mode ) {
        print "Entering " . __PACKAGE__ . "::generate_report\n";
        print Dumper( $th );
    }

    my $path = $th->{_PATH};
    my $entity = "{ \"path\": \"$path\"";
    $entity .= ", \"parameters\": " . $th->{_JSON} if $th->{_JSON};
    $entity .= " }";
    return shared_generate_report( $entity );
}


1;
