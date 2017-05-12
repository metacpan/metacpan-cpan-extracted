# $Id: Graph.pm,v 1.5 2007/08/14 15:45:51 ajk Exp $

use strict;
use warnings;

package Data::Passphrase::Graph; {
    use Object::InsideOut qw(Exporter);

    # export utility routines and configuration directive names
    BEGIN {
        our @EXPORT_OK = qw(build_graph graph_check);
    }

    # object attributes
    my @debug :Field(Std => 'debug', Type => 'numeric' );
    my @graph :Field(Std => 'graph', Type => 'hash_ref');

    my %init_args :InitArgs = (
        debug  => {Def => 0,  Field => \@debug, Type => 'numeric'},
        graph  => {Def => {}, Field => \@graph, Type => 'HASH'   },
    );

    # is a word on the graph?
    sub has {
        my ($self, $word) = @_;
        while ($word =~ s/(.)(.)/$2/) {
            return 0 if !exists $self->get_graph()->{$1}{$2};
        }
        return 1;
    }

    # procedural interface
    sub build_graph {
        my ($type) = @_;

        my $class = __PACKAGE__;
        if (defined $type) {
            $class .= ucfirst $type;
        }

        return $class->new();
    }

    # is the word contained by the graph?
    sub graph_check {
        my ($graph, $word) = @_;
        return $graph->has($word);
    }
}

1;
__END__

=head1 NAME

Data::Passphrase::Graph - directed graphs for passphrase strength checking

=head1 SYNOPSIS

Object-oriented interface:

 use Data::Passphrase::Qwerty;

 my $graph = Data::Passphrase::Qwerty->new();
 print $graph->has('qwerty');          # prints 1
 print $graph->has('ytrewq');          # prints 1
 print $graph->has('qazxdr');          # prints 1
 print $graph->has('qwerfvgtrdxz');    # prints 1

 use Data::Passphrase::Roman;

 $graph = Data::Passphrase::Roman->new();
 print $graph->has('abcdef');          # prints 1
 print $graph->has('fedcba');          # prints 1
 print $graph->has('xyzabc');          # prints 1
 print $graph->has('cbazyx');          # prints 1

Procedural interface:

 use Data::Passphrase qw(build_graph graph_check);

 my $graph = build_graph 'qwerty';
 print graph_check $graph, 'qwerty';          # prints 1
 print graph_check $graph, 'ytrewq';          # prints 1
 print graph_check $graph, 'qazxdr';          # prints 1
 print graph_check $graph, 'qwerfvgtrdxz';    # prints 1

 $graph = build_graph 'roman';
 print graph_check $graph, 'abcdef';          # prints 1
 print graph_check $graph, 'fedcba';          # prints 1
 print graph_check $graph, 'xyzabc';          # prints 1
 print graph_check $graph, 'cbazyx';          # prints 1

=head1 DESCRIPTION

This module provides a simple interface for using directed graphs with
L<Data::Passphrase|Data::Passphrase> to find trivial patterns in
passphrases.

=head2 Graph Format

Graphs are represented by hashes.  Each node on the graph is a key
whose value is a hash of adjacent nodes.  So a bidirectional graph of
the alphabet would contain the element

 b => {a => 1, c => 1}

because each letter (C<b> in this case) should be linked to both the
previous letter (C<a>) and the next letter (C<c>).  See L</SYNOPSIS>
and L</EXAMPLES> for more examples.

=head1 OBJECT-ORIENTED INTERFACE

This module provides a constructor C<new>, which takes a reference to
a hash of initial attribute settings, and accessor methods of the form
get_I<attribute>() and set_I<attribute>().  See L</Attributes>.

Normally, the OO interface is accessed via subclasses.  For example,
you'd call Data::Passphrase::Graph::Roman->new() to construct a graph
of the alphabet.  The inherited methods and attributes are documented
here.

=head2 Methods

In addition to the constructor and accessor methods, the following
special methods are available.

=head3 has()

 $value = $self->has($word)

Returns TRUE if C<$word> is contained by the graph, FALSE if it isn't.

=head2 Attributes

The following attributes may be accessed via methods of the form
get_I<attribute>() and set_I<attribute>().

=head3 debug

If TRUE, enable debugging to the Apache error log.

=head3 graph

The graph itself (see L<"Graph Format">).

=head1 PROCEDURAL INTERFACE

Unlike the object-oriented interface, the procedural interface can
create any type of graph, specified as the argument to
L<build_graph()|/build_graph()>.  Then,
L<graph_check()|/graph_check()> is used to determine if a word is
contained by the graph.

=head3 build_graph()

 $graph = build_graph $type

Build a graph of type C<$type>.  This subroutine will essentially
construct a new object of the type

 "Data::Passphrase::Graph::" . ucfirst $type

and return the graph itself for use with
L<graph_check()|/graph_check()>.

=head3 graph_check()

 $value = graph_check $graph, $word

Returns TRUE if C<$word> is contained by C<$graph>, FALSE if it isn't.

=head1 EXAMPLES

The graph

   a -> b -> c
   ^         |
   `---------'

would be represented as

 %graph = (
     a => { b => 1 },
     b => { c => 1 },
     c => { a => 1 },
 );

Here's how to use it:

 $graph = Data::Passphrase::Graph->new({graph => \%graph});
 print $graph->has('abc');    # prints 1
 print $graph->has('cba');    # prints 0
 print $graph->has('cab');    # prints 1

=head1 AUTHOR

Andrew J. Korty <ajk@iu.edu>

=head1 SEE ALSO

Data::Passphrase(3)
