package Chart::Sequence;

$VERSION = 0.002;

=head1 NAME

Chart::Sequence - A sequence class

=head1 SYNOPSIS

    use Chart::Sequence;
    my $s = Chart::Sequence->new(
        Nodes    => [qw( A B C )],
        Messages => [
            [ A => B => "Message 1" ],
            [ B => A => "Ack 1"     ],
            [ B => C => "Message 2" ],
        ],
    );

    # or #
    my $s = Chart::Sequence->new(
        SeqMLInput => "foo.seqml",
    );


    my $r = Chart::Sequence::Imager->new;
    my $png => $r->render( $s => "png" );
    $r->render_to_file( $s => "foo.png" );

=head1 DESCRIPTION

    ALPHA CODE ALERT: This is alpha code and the API will be
    changing.  For instance, I need to generalize "messages"
    in to "events". Feedback wanted.

A sequence chart portrays a sequence of events occuring among
a set of objects or, as we refer to them, nodes.

So far, this class only supports portrayal of messages between
nodes (and then not even from a node to itself).  More events
are planned.

So, a Chart::Sequence has a list of nodes and a list of messages.
Nodes will be instantiated automatically from the messages destinations
(an option to disable this will be forthcoming).

A sequence may created and populated in one or more of 3 ways:

=over

=item 1

Messages and, optionally, nodes may be passed in to new()

=item 2

Messages and, optionally, nodes may be added or removed en masse
using the appropriate methods.

=item 3

"SeqML" files may be parsed using Chart::Sequence::SAXBuilder.
See the test scripts for examples

=back

A small example (example_sequence_chart.png) is included in the
tarball.

Once built, charts may be layed out using a pluggable layout and
rendering system for which only one pixel-graphics oriented layout
(L<Chart::Sequence::Layout>) and one renderer
(L<Chart::Sequence::Renderer::Imager>) exist.

More docs forthcoming; feel free to ask.

=cut

require Chart::Sequence::Object;

@ISA = qw( Chart::Sequence::Object );

use strict;
use Chart::Sequence::Node ();
use Chart::Sequence::Message ();

=head1 METHODS

=over

=cut

=item new

    my $s = Chart::Sequence->new;

=cut

sub new {
    my $proto = shift;
    my $seqml;

    for ( my $i = 0; $i <= $#_; $i += 2 ) {
        if ( $_[$i] eq "SeqML" ) {
            ( undef, $seqml ) = splice @_, $i, 2;
            last;
        }
    }

    my $self = $proto->SUPER::new( @_ );

    $self->read_seqml( $seqml ) if defined $seqml;

    return $self;
}

__PACKAGE__->make_methods((
    '@nodes', => {
        set_pre => <<'END_SET_PRE',
            $_ = Chart::Sequence::Node->new( $_ )
                unless UNIVERSAL::isa( $_, "Chart::Sequence::Node" );
            $_->number( int @{$self->{Nodes}} );
END_SET_PRE

        get_pre => <<'END_GET_POST',
my %seen = map { ( $_->name => 1 ) } @{$self->{Nodes}};
        $self->push_nodes(
            map {
                $seen{$_}++ ? ()
                : Chart::Sequence::Node->new( Name => $_ );
            }
            map { ( $_->from, $_->to ) } $self->messages
        );
END_GET_POST

    },

    '@messages' => {
        set_pre => <<'END_SET_PRE',
            $_ = Chart::Sequence::Message->new( $_ )
                unless UNIVERSAL::isa( $_, "Chart::Sequence::Message" );
            $_->number( int $self->messages );
END_SET_PRE
    },


    '_layout_info',
));

=item name

Sets/gets the name of this sequence

=item nodes 

A node is something that sends or receives a message.

    $s->nodes( $node1, $node2, ... );
    my @nodes = $s->nodes;

Sets / gets the list of nodes.  If any messages refer to non-existent nodes,
the missing nodes are created.

=item nodes_ref

Sets/gets an ARRAY reference to an array containing nodes.

=item push_nodes

Appends one or more nodes to the end of the current list.

=item node_named

Gets a node by name.

=cut

sub node_named {
    my $self = shift;
    my ( $name ) = @_;

    ## TODO: maintain an index
    return (grep $_->name eq $name, $self->nodes)[0];
}

=item messages

    $s->messages( $msg1, $msg2, ... );
    my @messages = $s->messages;

Returns or sets the list of messages.

=item messages_ref

Returns or sets the list of messages as an ARRAY reference.

=item push_messages

Adds messages to the end of the sequence.

=cut

=item read_seqml

    my $s = Chart::Sequence->read_seqml( "some.seqml" );
    $s = Chart::Sequence->read_seqml( "more.seqml" );

Reads XML from a filehandle, a SCALAR reference, or a named file.

When called as a class method, returns a new Chart::Sequence object.
When called as an instance method add additional events to the
instance.

Requirese the optional prerequisite XML::SAX.

=cut

sub read_seqml {
    my $self = shift;
    my ( $input ) = @_;

    require XML::SAX::ParserFactory;
# TODO: Remove this.
    $XML::SAX::ParserPackage = "XML::SAX::PurePerl";
    require Chart::Sequence::SAXBuilder;
    my $p = XML::SAX::ParserFactory->parser(
        Handler => Chart::Sequence::SAXBuilder->new(
            ref $self ? ( Sequence => $self ) : (),
        ),
    );

    my $type = ref $input;
    if ( $type eq "SCALAR" ) {
        return $p->parse_string( $$input )->[0];
    }
    elsif ( $type eq "GLOB" || UNIVERSAL::isa( $type, "IO::Handle" ) ) {
        return $p->parse_file( $input )->[0];
    }
    elsif ( ! $type ) {
        return $p->parse_uri( $input )->[0];
    }
    else {
        require Carp;
        Carp::croak(
            __PACKAGE__,
            ": don't know how to read SeqML from a ", $type
        );
    }
}

=back

=head1 LIMITATIONS

Requires XML::SAX::PurePurl for now.  The latest XML::LibXML::SAX
seems to not notice <foo xmlns"http://bar/...">
declarations.

=head1 SEE ALSO

L<Chart::Sequence::SAXBuilder>

=head1 COPYRIGHT

    Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
