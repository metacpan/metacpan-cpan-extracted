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
# custom completion module
#
package App::Dochazka::CLI::Completion;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $log );
use App::Dochazka::CLI::Parser qw( parse possible_words );
use App::Dochazka::CLI::TokenMap qw( $completion_map $token_map );
use Data::Dumper;
use Exporter 'import';


=head1 NAME

App::Dochazka::CLI::Completion - Completion module

=cut

our @EXPORT_OK = qw( 
    dochazka_cli_completion
);

sub dochazka_cli_completion {
    my ( $text, $line, $start ) = @_;
    #
    # $text is the current token
    # $line is the entire line of user input
    # $start is offset of $text within $line
    #
    $log->debug( "text $text line ->$line<- start $start" );

    my $rv = parse( $line );
    #
    # $rv->{ts} is the token stack
    # $rv->{th} is hash of user-entered strings for each token
    # $rv->{th}->{_REST} is the unrecognized part
    # $rv->{nc} is the normalized command
    # 
    #$log->debug( Dumper $rv );

    # if _REST contains more than one token, nothing to do
    if ( split( ' ', $rv->{th}->{_REST} ) > 1 ) {
        #$log->debug( "Command not recognized: do nothing" );
        return; 
    }

    # if $line ends in '=', do nothing
    if ( $line =~ m/=$/ ) {
        return;
    }

    # if there is no $text, match everything
    $text = '.*' unless $text;

    # get matching words
    my @matches = grep( /^$text/i, keys %$completion_map );
    #$log->debug( "Matches: " . Dumper( \@matches ) );

    # possibly adjust token stack
    my @ts = @{ $rv->{ts} };
    pop( @ts ) unless $rv->{th}->{_REST} or $line =~ m/ $/;
    #$log->debug( "Token stack: " . Dumper( \@ts ) );

    # get permissible tokens in this position
    my $permissibles = possible_words( \@ts );
    #$log->debug( "Permissibles: " . Dumper( $permissibles ) );
    
    # construct list of regexes
    my @regexes_of_permissibles = ();
    foreach my $permissible ( @$permissibles ) {
        if ( exists( $token_map->{$permissible} ) ) {
            push @regexes_of_permissibles, $token_map->{$permissible};
        }
    }
    #$log->debug( "Regexes of permissibles: " . Dumper( \@regexes_of_permissibles ) );

    # return only those words that match 
    my @result = ();
    foreach my $match ( @matches ) {
        # does it match one of the permissibles?
        #$log->debug( "Considering $match" );
        if ( grep { $match =~ $_; } ( @regexes_of_permissibles ) ) {
            #$log->debug( "Matches one of the permissible regexes!" );
            push( @result, $match ) 
        } else {
            #$log->debug( "(no match)" );
        }
    }
    $log->debug( "Result: " . Dumper( \@result ) );

    return @result;
}

1;
