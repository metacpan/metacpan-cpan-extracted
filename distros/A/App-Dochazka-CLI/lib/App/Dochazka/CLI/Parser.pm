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
# parser module
#
package App::Dochazka::CLI::Parser;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL );
use App::Dochazka::CLI qw( $debug_mode );
use App::Dochazka::CLI::TokenMap qw( $token_map );
use App::Dochazka::CLI::CommandMap;
use Data::Dumper;
use Exporter 'import';
use Web::MREST::CLI qw( send_req );


=head1 NAME

App::Dochazka::CLI::Parser - Parser module



=head1 PACKAGE VARIABLES AND EXPORTS

=over

=item C<< generate_semantic_tree >>

Populate the C<< $semantic_tree >> package variable.

=item C<< lookup_command >>

=item C<< parse >>

Parse the command string entered by the user.

=item C<< possible_words >>

Given a state expressed as a stack of tokens, return list of possible tokens.

=item C<< process_command >>

Given a command string, process it (by parsing, calling the handler, etc.) and
return the result.

=item C<< $semantic_tree >>

The semantic tree is a traversable tree representation of the CLI commands,
i.e. the keys of the dispatch map C<< $App::Dochazka::CLI::CommandMap::dispatch_map >>

=back

=cut

our @EXPORT_OK = qw( 
    generate_semantic_tree 
    look_up_command 
    parse 
    possible_words 
    process_command 
    $semantic_tree 
);
our $semantic_tree;




=head1 FUNCTIONS

=head2 generate_semantic_tree

Generate the semantic context tree.

The set of keys of C<< %$dispatch_map >> contains all the possible commands,
each expressed as a sequence of tokens. The semantic context tree is generated
from the dispatch map keys. Each node of the tree represents a possible token
and the set of nodes at depth n of the tree is the set of possible tokens in
the nth position within the command. 

Taking, for example, a dispatch map consisting of the following two commands:

    ABE BABEL CAROL
    DALE EARL JENSEN PARLOR
    DALE TWIT

The semantic tree would be:

    (root)
    |
    +-----------+
    |           |
    ABE        DALE
    |           |
    |           +------+
    |           |      |
    BABEL      EARL   TWIT
    |           |
    CAROL      JENSEN
                |
               PARLOR

The point of this exercise is to facilitate command completion. If two a single
token ABE has been entered by the user and <TAB> is pressed, finding out that
BABEL is the only possible command in this position is a simple matter of
traversing the above semantic tree. (And this is exactly what is done by the
C<possible_words> routine in L<App::Dochazka::CLI::Parser>.)

This routine takes an optional argument which, if provided, is assumed to be a
reference to a dispatch map. In the absence of this argument, the
C<$dispatch_map> package variable (initialized above) is used.

For this and more examples, see C<t/parser/semantic_tree.t>.

=cut

sub generate_semantic_tree {
    my ( $dm ) = @_;
    #
    # ( if $dm is given -- e.g., for testing --, then use it. Otherwise, use
    # the $dispatch_map package variable )
    #
    if ( ! $dm ) {
        $dm = $App::Dochazka::CLI::CommandMap::dispatch_map;
    }

    my $tree = {};

    foreach my $cmd ( keys %$dm ) {
        
        # split the command into tokens
        my @tokens = split( ' ', $cmd );
        
        # walk the tokens - $subtree is a pointer into $tree
        my $subtree = $tree;
        for ( my $i = 0; $i < @tokens; $i += 1 ) {
            my $token = $tokens[$i];
            if ( ! exists( $subtree->{ $token } ) ) {
                # create new node
                $subtree->{ $token } = {};
            }
            # add child to existing node
            $subtree = $subtree->{ $token };
        }
        
    }

    # return the tree we built
    #print Dumper( $tree ), "\n";
    return $tree;
}


=head2 look_up_command

Given a normalized command string such as "GET BUGREPORT", look it up in the
dispatch map and return the corresponding coderef, or nothing if the lookup
fails.

=cut

sub look_up_command {
    my ( $cmd ) = @_;

    # check for undef and empty string
    return unless defined( $cmd ) and $cmd =~ m/\S/;

    # check for a match
    if ( my $coderef = $App::Dochazka::CLI::CommandMap::dispatch_map->{ uc( $cmd ) } ) {
        return $coderef;
    }

    # failure - return nothing
    return;
}


=head2 parse

Parse command string entered by the user. Takes the command string, and returns:

=over

=item C<< $nc >>

The normalized command - suitable for lookup via C<look_up_command>

=item C<< $ts >>

The token stack - a reference to the list of normalized tokens

=item C<< $th >>

The token hash - a hash where the keys are the normalized tokens and the values
are the raw values extracted from the command string. Whatever is left after
command string parsing completes will be placed in the '_REMAINDER' key.

=back

=cut

sub parse {
    my $cmd = shift;  # command string entered by user
    my $w_cmd = $cmd; # working copy of command string
    my $ts = [];      # resulting token stack
    my $th = {};      # resulting token hash

    $w_cmd =~ s/^\s+//;
    WHILE1: while ( length( $w_cmd ) > 0 ) {
        
        # get list of possible tokens
        my $poss = possible_words( $ts );
        #print( "Possible words are " . join( ' ', @$poss ) . "\n" );

        # match against remaining command string
        foreach my $key ( @$poss ) {

            # the key might be, e.g., _TIMESTAMP1 - strip any trailing numerals
            my $stripped_key = $key;
            $stripped_key =~ s/\d\z//;
            #print "Stripped key is $stripped_key\n";

            # look up the regular expression and apply it to the remaining 
            # command text $w_cmd
            my $re = $token_map->{ $stripped_key };
            if ( ! $re ) {
                die "AGH! Possible token $key has no regular expression assigned";
            }
            $re = '\A' . $re . '((\s)|(\z))';
            #print "Remaining command text: $w_cmd\n";
            my ( $match ) = $w_cmd =~ m/$re/i;

            if ( $match ) {
                # the key might already exist in the token hash
                # e.g. for commands like SCHEDULE _DOW _TIME _DOW _TIME
                my $safe_key = _get_safe_key( $key, $th );
                push @$ts, $safe_key;
                $th->{ $safe_key } = $match;
                # chomp it off
                $w_cmd =~ s/$re//i;
                $w_cmd =~ s/^\s+//;
                # we have a match for this token - go on to the next
                next WHILE1;
            } 
        }
        # no match found - whatever tokens are in the stack, that is our command
        # and the rest is the rest
        $w_cmd =~ s/^\s+//;
        $th->{ '_REST' } = $w_cmd;
        last WHILE1;
    }
    $th->{'_REST'} = '' unless exists( $th->{'_REST'} );

    return { ts => $ts, th => $th, nc => join( ' ', @$ts ) };
}

sub _get_safe_key {
    my ( $key, $th ) = @_;
    my $safe_key;
    
    if ( exists( $th->{$key} ) ) {
        # cannot put the key into the hash under this name,
        # because doing so would clobber an existing key

        # successively try up to nine alternative names
        BREAK_OUT: {
            for ( my $i = 1; $i < 10; $i += 1 ) {
                $safe_key = $key . $i;
                last BREAK_OUT unless exists( $th->{$safe_key} );
            }
            die "AAH! Exceeded nine alternative keys in _get_safe_keys"
        }
    } else {
        $safe_key = $key;
    }

    # key is safe
    return $safe_key;
}


=head2 possible_words

Given a token stack, return the list of possible tokens.

=cut

sub possible_words {
   my ( $ts ) = @_;

   $semantic_tree = generate_semantic_tree() unless defined( $semantic_tree ) and %$semantic_tree;

   my $pointer = $semantic_tree;
   for ( my $i = 0 ; $i < @$ts ; $i += 1 ) {
       if ( my $subtree = $pointer->{ $ts->[$i] } ) {
           $pointer = $subtree;
       } else {
           # no possibilities
           return [];
       }
   }

   return [ keys( %$pointer ) ];
}


=head2 process_command

Given a command entered by the user, process it and return the result.

=cut

sub process_command {
    my ( $cmd ) = @_;
   
    my $r = parse( $cmd );                        # parse the command string
    # if debug mode, dump parser state
    if ( $debug_mode ) {
        print "Recognized command: " . $r->{nc} . "\n";
        print "Token hash: " . Dumper( $r->{th} ) . "\n";
    }
    if ( not @{ $r->{ts} } ) {
        return $CELL->status_err( 'DOCHAZKA_CLI_PARSE_ERROR' );
    }

    my $cmdspec = look_up_command( $r->{nc} );   # get the handler coderef
    if ( ref( $cmdspec ) eq 'CODE' ) {
        my $rv = $cmdspec->( $r->{ts}, $r->{th} );   # call the handler
        if ( ref( $rv ) eq 'ARRAY' ) {
            my $pl;
            my $status = send_req( @$rv );             # call send_req with the args
            if ( ref( $status ) eq 'App::CELL::Status' ) {
                $status->{'rest_test'} = 1;
                return $status;
            } else {
                die "AAAAGGGHGHGHGHGHHHH! \$status is not a status object " . Dumper( $status );
            }
        } else {
            return $rv;
        }
    }
    return $CELL->status_err( 'DOCHAZKA_CLI_PARSE_ERROR' );

}

1;
