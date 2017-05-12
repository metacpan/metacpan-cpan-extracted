package Compress::BraceExpansion;

use warnings;
use strict;

use Data::Dumper;

our $VERSION = '0.1.7';


use Class::Std::Utils;
{
    my %strings_of;
    my %tree_of;
    my %pointers_of;
    my %pointer_id_of;
    my %debug_of;

    sub new {
        my ($class, $arg_ref, @strings ) = @_;

        my $new_object = bless anon_scalar( ), $class;

        # initialize arguments
        if ( $arg_ref && ref $arg_ref eq "HASH" ) {
            # initialized with a hash of config options
            $strings_of{ident $new_object} = $arg_ref->{strings};
        }
        elsif ( $arg_ref && ref $arg_ref eq "ARRAY" ) {
            # initialized with an array of strings
            $strings_of{ident $new_object} = $arg_ref;
        }
        elsif ( @strings ) {
            # initialized with an array
            $strings_of{ident $new_object} = [ $arg_ref, @strings ];
        }
        else {
            die "ERROR: No strings specified - call new() with a hash ref or array ref";
        }

        # initial pointer id
        $pointer_id_of{ident $new_object} = 1000;
        $pointers_of{ident $new_object} = {};

        return $new_object;
    }

    # attempt compression
    sub shrink {
        my ( $self ) = @_;

        unless ( $strings_of{ident $self} ) {
            die "Error: No strings - define strings in new()";
        }
        my @strings = @{ $strings_of{ident $self} };

        if ( $debug_of{ident $self} ) {
            print "STRINGS: ", join ( " ", @strings ), "\n";
            print Dumper \@strings;
            print "\n";
        }

        # build the tree
        $self->_build_tree( );
        if ( $debug_of{ident $self} ) {
            print "TREE BUILT:\n";
            print Dumper $tree_of{ident $self};
            print "\n";
        }

        # merge the main tree
        $tree_of{ident $self} = $self->_merge_tree_recurse( $tree_of{ident $self} );

        # merge the pointers
        for my $branch ( keys %{ $pointers_of{ident $self} } ) {
            $pointers_of{ident $self}->{$branch} = $self->_merge_tree_recurse( $pointers_of{ident $self}->{$branch} );
        }
        if ( $debug_of{ident $self} ) {
            print "TREE MERGED:\n";
            print Dumper $tree_of{ident $self};
            print Dumper $pointers_of{ident $self};
            print "\n";
        }

        return scalar $self->_print_tree_recurse( $tree_of{ident $self}->{'ROOT'} );

    }

    # given an array of strings, walk through a build a data tree to
    # represent the strings.  Each string will be split into a hash where
    # each layer of the hash represents one character in the string.  For
    # example, abc will be represented as:
    #
    #     { a => { b => { c => { end => 1 } } } }
    #
    sub _build_tree {
        my ( $self ) = @_;
        my $tree_h = { ROOT => {} };
        for my $text ( @{ $strings_of{ident $self} } ) {
            my $pointer = $tree_h->{'ROOT'};
            for my $character_count ( 0 .. length( $text )-1 ) {
                my $character = substr( $text, $character_count, 1 );
                $pointer->{ $character } = {} unless $pointer->{ $character };
                # if leaf node
                if ( $character_count == length( $text ) - 1 ) {
                    $pointer->{ $character }->{'end'} = 1;
                }
                $pointer = $pointer->{ $character };
            }
            $pointer = $text;
        }
        $tree_of{ident $self} = $tree_h;
    }

    # given a data tree, recurse through and print the structure.
    sub _print_tree_recurse {
        #my ( $buffer, $tree_h, $main_tree ) = @_;
        my ( $self, $tree_h, $buffer ) = @_;
        return unless ref $tree_h eq 'HASH';

        my @nodes = sort keys %{ $tree_h };
        return ( $buffer ) if @nodes == 0;
        my $pointer;

        if ( @nodes == 1 ) {
            if ( $nodes[0] eq 'POINTER' ) {
                return ( $buffer, $tree_h->{ $nodes[0] } );
            } else {
                for my $node ( @nodes ) {
                    if ( $node eq 'end' ) {
                        $buffer .= "";
                    } else {
                        $buffer .= $node;
                        my $lbuffer;
                        ( $lbuffer, $pointer ) = $self->_print_tree_recurse( $tree_h->{$node} );
                         if ( defined $lbuffer ) {
                             $buffer .= "$lbuffer";
                         }
                    }
                }
            }
        } elsif ( @nodes > 1 ) {
            $buffer .= "{";
            my ( @bits );
            for my $node ( @nodes ) {
                next if $node eq 'POINTERS';
                if ( $node eq 'POINTER' ) {
                    $pointer = $tree_h->{$node};
                } elsif ( $node eq 'end' ) {
                    push @bits, "";
                } else {
                    my $lbuffer;
                    ( $lbuffer, $pointer ) = $self->_print_tree_recurse( $tree_h->{$node}, $node );
                    push @bits, $lbuffer;
                }
            }
            $buffer .= join ",", @bits;
            $buffer .= "}";

            if ( $pointer && $pointers_of{ident $self}->{ $pointer }  ) {
                my $output = $self->_print_tree_recurse( $pointers_of{ident $self}->{ $pointer } );
                $buffer .= $output;
                delete $tree_of{ident $self}->{ $pointer };
                $pointer = undef;
            }
        }
        if (wantarray( )) {
            # list context - only really useful when being called from within
            # a recursion.
            return ( $buffer, $pointer );
        }

        return $buffer;
    }

    # walk through the tree looking for ends that are identical.  If
    # identical ends are found on all branches, copy the branch off to a
    # temporary branch location and replace the originals with a link to
    # the new location.  Currently this only handles the cases where all
    # branches are identical from some point until the end of the strings.
    sub _merge_tree_recurse {
        my ( $self, $tree, $root ) = @_;

        unless ( $root ) { $root = $tree };

        my @nodes = keys %{ $tree };
        if ( @nodes == 1 ) {
            return ( $tree, $root ) if $nodes[0] eq 'end';
            ( $tree ) = $self->_merge_tree_recurse( $tree->{ $nodes[0] }, $root );
        } elsif ( @nodes > 1 ) {
            my @paths;
            for my $node ( @nodes ) {
                my $text = $self->_print_tree_recurse( $tree->{$node} );
                return ( $tree, $root ) unless $text;
                push @paths, $text;
            }

            # check for merge points in the tree.  if they exist,
            # transplant them.
            my $depth = _check_merge_point( @paths );
            if ( defined( $depth ) ) {
                #print "\n\n";
                #print "Merging at depth: $depth\n";
                #print Dumper @paths;
                #print "\n\n";
                $tree = $self->_transplant( $tree, $depth||1 );
            }
        }

        if (wantarray( )) {
            # list context - only really useful when being called
            # within a recursion
            return( $tree, $root );
        }

        return $root;
    }


    # given a data tree, a set of paths within that tree, and the depth
    # beyond which they are all identical, clone the paths and relocate
    # the identical branches on the POINTERS node.  Remove the specified
    # paths and replace them with a link to the new location.
    sub _transplant {
        my ( $self, $tree_h, $depth ) = @_;

        my @nodes = keys %{ $tree_h };

        my $id = $self->_get_new_pointer_id();
        #print "\nID: $id\n";
        my $pruned;

        for my $node ( @nodes ) {
            my ( $depth_pointer, $next_node );
            if ( $depth > 1 ) {
                $depth_pointer = $tree_h->{ $node };
                $next_node = (keys %{ $depth_pointer })[0];
                die "tried to transplant past end of tree" if $next_node eq 'end';
                if ( $depth > 2 ) {
                    for my $depth ( 2 .. $depth - 1) {
                        $depth_pointer = $depth_pointer->{ $next_node };
                        $next_node = (keys %{ $depth_pointer })[0];
                        die "tried to transplant past end of tree" if $next_node eq 'end';
                        #print "DEPTH:\n";
                        #print Dumper $depth_pointer;
                    }
                }
            } else {
                $depth_pointer = $tree_h;
                $next_node = $node;
            }

            # if this is the end of the tree, give up trying
            my $child_node = $depth_pointer->{ $next_node };
            my $child_node_name = (keys %{ $depth_pointer->{ $next_node } })[0];
            if ( $child_node_name eq 'end' ) {
                die "Error: Tried to transplant end of tree";
            }

            unless ( $pruned ) {
                $pruned = $depth_pointer->{ $next_node };
                #print "PRUNED:\n";
                #print Dumper $pruned;
            }
            $depth_pointer->{ $next_node } = { POINTER => $id };
        }
        $pointers_of{ident $self}->{ $id } = $pruned;

        return ( $tree_h );
    }

    # given a series of strings, determine the longest number of
    # characters that all strings have in common beginning from the tail
    # end.  Return the number of characters from the current location
    # (which will represent the number of hash levels deep) where the
    # similar strings begin.
    sub _check_merge_point {
        my ( @strings ) = @_;

        # search for the longest substring from the end that all strings
        # match.
        my $base = $strings[0];
        my $base_length = length( $base );
        my $length = $base_length;
        while ( $length ) {
            my @ends;
            for my $string ( @strings ) {
                return unless length( $string ) eq $base_length;
                my $end = substr( $string, $base_length - $length, $length );
                push @ends, $end;
            }
            if ( _check_array_values_equal( @ends ) ) {
                return $base_length - $length + 1;
            }
            $length--;
        }
        return;
    }

    # given an array of strings, check that if strings are the same.
    sub _check_array_values_equal {
        my ( @array ) = @_;

        my $base = $array[0];
        for my $array ( @array ) {
            return unless $array eq $base;
        }
        return 1;
    }

    sub _get_root {
        my ( $self ) = @_;
        return $tree_of{ident $self};
    }

    sub _get_new_pointer_id {
        my ( $self ) = @_;
        $pointer_id_of{ident $self}++;
        return "PID:" . $pointer_id_of{ident $self};
    }

    sub _get_pointers {
        my ( $self ) = @_;
        if ( keys %{ $pointers_of{ident $self} } ) {
            return $pointers_of{ident $self};
        }
        return;
    }

    sub enable_debug {
        my ( $self ) = @_;
        $debug_of{ident $self} = 1;
    }

}

#
# next generation idea
#
# 1. add weights to each node in graph based on how many strings pass
#    through each node
# 2. test collapses around nodes with highest weights
# 3. develop an api of collapsing strategies
# 4. autogenerated test cases - expand in shell - compare efficiency
#
#


1;

__END__

=head1 NAME

Compress::BraceExpansion - create a human-readable compressed string suitable for shell brace expansion


=head1 VERSION

This document describes Compress::BraceExpansion version 0.1.5.  This
is a beta release.


=head1 SYNOPSIS

    use Compress::BraceExpansion;

    # output: ab{c,d}
    print Compress::BraceExpansion->new( qw( abc abd ) )->shrink();

    # output: aabb{cc,dd}
    print Compress::BraceExpansion->new( qw( aabbcc aabbdd ) )->shrink();

    # output: aa{bb{cc,dd},eeff}
    print Compress::BraceExpansion->new( qw( aabbcc aabbdd aaeeff ) )->shrink();


=head1 DESCRIPTION

Shells such as bash and zsh have a feature call brace expansion.
These allow users to specify an expression to generate a series of
strings that contain similar patterns.  For example:

  $ echo a{b,c}
  ab ac

  $ echo aa{bb,xx}cc
  aabbcc aaxxcc

  $ echo a{b,x}c{d,y}e
  abcde abcye axcde axcye

  $ echo a{b,x{y,z}}c
  abc axyc axzc

This module was designed to take a list of strings with similar
patterns (e.g. the output of a shell expansion) and generate an
un-expanded expression.  Given a reasonably sized array of similar
strings, this module will generate a single compressed string that can
be comfortably parsed by a human.

The current algorithm only works for groups of input strings that
start with and/or end with similar characters.  See BUGS AND
LIMITATIONS section for more details.


=head1 WHY?

My initial motivation to write this module was to compress the number
of characters that are necessary to display a list of server names,
e.g. to send in the subject of a text message to a pager/mobile phone.
If I start with a long list of servers that follow a standard naming
convention, e.g.:

    app-dc-srv01 app-dc-srv02 app-dc-srv03 app-dc-srv04 app-dc-srv05
    app-dc-srv06 app-dc-srv07 app-dc-srv08 app-dc-srv09 app-dc-srv10

After running through this module, they can be displayed much more
efficiently on a pager as:

    app-dc-srv{0{1,2,3,4,5,6,7,8,9},10}

The algorithm can also be useful for directories:

    /usr/local/{bin,etc,lib,man,sbin}


=head1 BRACE EXPANSION?

Despite the name, this module does not perform brace expansion.  If it
did, it probably should have been located in the Shell:: heirarchy.
It attempts to do the opposite which might be referred to as 'brace
compression', hence the location it in the Compress:: heirarchy.  The
strings it generates could be used in a shell, but are more likely
useful to make a (potentially) human-readable compressed string.  I
chose the name BraceExpansion since that's the common term, so
hopefully it will be more recognizable than if it were named
BraceCompression.


=head1 CONSTRUCTOR

=over 8

=item C< new( ) >

Returns a reference to a new Compress::BraceExpansion object.

May be initialized with a hash of options:

    Compress::BraceExpansion->new( { strings => [ qw( abc abd ) ] } );

Or with an array ref:

    Compress::BraceExpansion->new( [ qw( abc abd ) ] );

Or with an array:

    Compress::BraceExpansion->new( qw( abc abd ) );

This is an inside-out perl class.  For more info, see "Perl Best
Practices" by Damian Conway

=back


=head1 METHODS

=over 8

=item C<shrink( )>

Perform brace compression on strings.  Returns a string that is
suitable for brace expansion by the shell.

This method has not been designed being called multiple times on the
same Compress::BraceExpansion object.  If you call shrink() more than
once on the same object, you're on your own.

=item C<enable_debug( )>

Enable various internal data structures to be printed to stdout.

=back


=head1 BUGS AND LIMITATIONS

The current algorithm is pretty ugly, and will only compress strings
that start and/or end with similar text.  I've been working on a new
algorithm that uses a weighted trie.

If multiple identical strings are supplied as input, they will only be
represented once in the resulting compressed string.  For example, if
"aaa aaa aab" was supplied as input to shrink(), then the result would
simply be "aa{a,b}".

This module has reasonably fast performance to at least 1000 inputs
strings.  I've run several tests where I cut a 10k word slice from
/usr/share/dict/words and have consistently achieved around 50%
compression.  However, even for strings that are very similar, the
output rapidly loses human readability beyond a couple hundred
characters.

Please report problems to VVu@geekfarm.org.

Patches and suggestions are welcome!


=head1 SEE ALSO

  - brace-compress - included command line script in scripts/ directory

  - http://www.gnu.org/software/bash/manual/bashref.html#SEC27

  - http://zsh.sourceforge.net/Doc/Release/zsh_13.html#SEC60


=head1 AUTHOR

Alex White  C<< <vvu@geekfarm.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Alex White C<< <vvu@geekfarm.org> >>. All rights reserved.

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

- Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

- Neither the name of the geekfarm.org nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.







