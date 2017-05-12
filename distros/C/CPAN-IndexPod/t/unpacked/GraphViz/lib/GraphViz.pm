package GraphViz;

use strict;
use vars qw($AUTOLOAD $VERSION);

use Carp;
use Graph::Directed;
use Math::Bezier;
use IPC::Run qw(run binary);

# This is incremented every time there is a change to the API
$VERSION = '1.8';


=head1 NAME

GraphViz - Interface to the GraphViz graphing tool

=head1 SYNOPSIS

  use GraphViz;

  my $g = GraphViz->new();

  $g->add_node('London');
  $g->add_node('Paris', label => 'City of\nlurve');
  $g->add_node('New York');

  $g->add_edge('London' => 'Paris');
  $g->add_edge('London' => 'New York', label => 'Far');
  $g->add_edge('Paris' => 'London');

  print $g->as_png;


=head1 DESCRIPTION

This module provides an interface to layout and image generation of
directed and undirected graphs in a variety of formats (PostScript,
PNG, etc.) using the "dot", "neato" and "twopi" programs from the
GraphViz project (http://www.graphviz.org/ or
http://www.research.att.com/sw/tools/graphviz/).

=head2 What is a graph?

A (undirected) graph is a collection of nodes linked together with
edges.

A directed graph is the same as a graph, but the edges have a
direction.

=head2 What is GraphViz?

This module is an interface to the GraphViz toolset
(http://www.graphviz.org/). The GraphViz tools provide automatic graph
layout and drawing. This module simplifies the creation of graphs and
hides some of the complexity of the GraphViz module.

Laying out graphs in an aesthetically-pleasing way is a hard problem -
there may be multiple ways to lay out the same graph, each with their
own quirks. GraphViz luckily takes part of this hard problem and does
a pretty good job in a couple of seconds for most graphs.

=head2 Why should I use this module?

Observation aids comprehension. That is a fancy way of expressing
that popular faux-Chinese proverb: "a picture is worth a thousand
words".

Text is not always the best way to represent anything and everything
to do with a computer programs. Pictures and images are easier to
assimilate than text. The ability to show a particular thing
graphically can aid a great deal in comprehending what that thing
really represents.

Diagrams are computationally efficient, because information can be
indexed by location; they group related information in the same
area. They also allow relations to be expressed between elements
without labeling the elements.

A friend of mine used this to his advantage when trying to remember
important dates in computer history. Instead of sitting down and
trying to remember everything, he printed over a hundred posters (each
with a date and event) and plastered these throughout his house. His
spatial memory is still so good that asked last week (more than a year
since the experiment) when Lisp was invented, he replied that it was
upstairs, around the corner from the toilet, so must have been around
1958.

Spreadsheets are also a wonderfully simple graphical representation of
computational models.

=head2 Applications

Bundled with this module are several modules to help graph data
structures (GraphViz::Data::Dumper), XML (GraphViz::XML), and
Parse::RecDescent, Parse::Yapp, and yacc grammars
(GraphViz::Parse::RecDescent, GraphViz::Parse::Yapp, and
GraphViz::Parse::Yacc).

Note that Marcel Grunauer has released some modules on CPAN to graph
various other structures. See GraphViz::DBI and GraphViz::ISA for
example.

brian d foy has written an article about Devel::GraphVizProf for
Dr. Dobb's Journal:
http://www.ddj.com/columns/perl/2001/0104pl002/0104pl002.htm

=head2 Award winning!

I presented a paper and talk on "Graphing Perl" using GraphViz at the
3rd German Perl Workshop and received the "Best Knowledge Transfer"
prize.

    Talk: http://www.astray.com/graphing_perl/graphing_perl.pdf
  Slides: http://www.astray.com/graphing_perl/

=head1 METHODS

=head2 new

This is the constructor. It accepts several attributes.

The most two important attributes are 'layout' and 'directed'. The
'layout' attribute determines which layout algorithm GraphViz.pm will
use. Possible values are: 'dot' (the default GraphViz layout for
directed graph layouts), 'neato' (for undirected graph layouts -
spring model) or 'twopi' (for undirected graph layouts - circular).

The 'directed' attribute, which defaults to 1 (true) specifies
directed (edges have arrows) graphs. Setting this to zero produces
undirected graphs (edges do not have arrows).

Another attribute 'rankdir' controls the direction the nodes are linked
together. If true it will do left->right linking rather than the
default up-down linking.

The 'width' and 'height' attributes control the size of the bounding
box of the drawing in inches. This is more useful for PostScript
output as for raster graphic (such as PNG) the pixel dimensions
can not be set, although there are generally 96 pixels per inch.

The 'pagewidth' and 'pageheight' attributes set the PostScript
pagination size in inches. That is, if the image is larger than the
page then the resulting PostScript image is a sequence of pages that
can be tiled or assembled into a mosaic of the full image. (This only
works for PostScript output).

  my $g = GraphViz->new();
  my $g = GraphViz->new(directed => 0);
  my $g = GraphViz->new(layout => 'neato');
  my $g = GraphViz->new(rankdir  => 1);
  my $g = GraphViz->new(width => 8.5, height => 11);
  my $g = GraphViz->new(width => 30, height => 20,
			pagewidth => 8.5, pageheight => 11);

The 'concentrate' attribute controls enables an edge merging technique
to reduce clutter in dense layouts of directed graphs. The default is
not to merge edges.

For undirected graphs, the 'random_start' attribute requests an
initial random placement for the graph, which may give a better
result. The default is not random.

For undirected graphs, the 'epsilon' attribute decides how long the
graph solver tries before finding a graph layout. Lower numbers allow
the solver to fun longer and potentially give a better layout. Larger
values can decrease the running time but with a reduction in layout
quality. The default is 0.1.

The 'no_overlap' overlap option, if set, tells the graph solver to not
overlap the nodes.

The 'bgcolor' option sets the background colour. A colour value may be
"h,s,v" (hue, saturation, brightness) floating point numbers between 0
and 1, or an X11 color name such as 'white', 'black', 'red', 'green',
'blue', 'yellow', 'magenta', 'cyan', or 'burlywood'.

The 'node', 'edge' and 'graph' attributes allow you to specify global
node, edge and graph attributes (in addition to those controlled by
the special attributes described above). The value should be a hash
reference containing the corresponding key-value pairs. For example,
to make all nodes box-shaped (unless explicity given another shape):

  my $g = GraphViz->new(node => {shape => 'box'});

=cut


sub new {
  my $proto = shift;
  my $config = shift;
  my $class = ref($proto) || $proto;
  my $self = {};

  # Cope with the old hashref format
  if (ref($config) ne 'HASH') {
    my %config;
    %config = ($config, @_) if @_;
    $config = \%config;
  }

  $self->{NODES} = {};
  $self->{NODELIST} = [];
  $self->{EDGES} = [];
  $self->{GRAPH} = Graph::Directed->new();

  if (exists $config->{directed}) {
      $self->{DIRECTED} = $config->{directed};
  } else {
      $self->{DIRECTED} = 1; # default to directed
  }

  if (exists $config->{layout}) {
      $self->{LAYOUT} = $config->{layout};
  } else {
      $self->{LAYOUT} = "dot"; # default layout
  }

  if (exists $config->{bgcolor}) {
      $self->{BGCOLOR} = $config->{bgcolor};
  }

  $self->{RANK_DIR} = $config->{rankdir} if (exists $config->{rankdir});

  $self->{WIDTH} = $config->{width} if (exists $config->{width});
  $self->{HEIGHT} = $config->{height} if (exists $config->{height});

  $self->{PAGEWIDTH} = $config->{pagewidth} if (exists $config->{pagewidth});
  $self->{PAGEHEIGHT} = $config->{pageheight} if (exists $config->{pageheight});

  $self->{CONCENTRATE} = $config->{concentrate} if (exists $config->{concentrate});

  $self->{RANDOM_START} = $config->{random_start} if (exists $config->{random_start});

  $self->{EPSILON} = $config->{epsilon} if (exists $config->{epsilon});

  $self->{SORT} = $config->{sort} if (exists $config->{sort});

  $self->{NO_OVERLAP} = $config->{no_overlap} if (exists $config->{no_overlap});

  # Global node, edge and graph attributes
  $self->{NODE_ATTRS} = $config->{node} if (exists $config->{node});
  $self->{EDGE_ATTRS} = $config->{edge} if (exists $config->{edge});
  $self->{GRAPH_ATTRS} = $config->{graph} if (exists $config->{graph});

  bless($self, $class);
  return $self;
}


=head2 add_node

A graph consists of at least one node. All nodes have a name attached
which uniquely represents that node.

The add_node method creates a new node and optionally assigns it
attributes.

The simplest form is used when no attributes are required, in which
the string represents the name of the node:

  $g->add_node('Paris');

Various attributes are possible: "label" provides a label for the node
(the label defaults to the name if none is specified). The label can
contain embedded newlines with '\n', as well as '\c', '\l', '\r' for
center, left, and right justified lines:

  $g->add_node('Paris', label => 'City of\nlurve');

Attributes need not all be specified in the one line: successive
declarations of the same node have a cumulative effect, in that any
later attributes are just added to the existing ones. For example, the
following two lines are equivalent to the one above:

  $g->add_node('Paris');
  $g->add_node('Paris', label => 'City of\nlurve');

Note that multiple attributes can be specified. Other attributes
include:

=over 4

=item height, width

sets the minimum height or width

=item shape

sets the node shape. This can be one of: 'record', 'plaintext',
'ellipse', 'circle', 'egg', 'triangle', 'box', 'diamond', 'trapezium',
'parallelogram', 'house', 'hexagon', 'octagon'

=item fontsize

sets the label size in points

=item fontname

sets the label font family name

=item color

sets the outline colour, and the default fill colour if the 'style' is
'filled' and 'fillcolor' is not specified

A colour value may be "h,s,v" (hue, saturation, brightness) floating
point numbers between 0 and 1, or an X11 color name such as 'white',
'black', 'red', 'green', 'blue', 'yellow', 'magenta', 'cyan', or
'burlywood'

=item fillcolor

sets the fill colour when the style is 'filled'. If not specified, the
'fillcolor' when the 'style' is 'filled' defaults to be the same as
the outline color

=item style

sets the style of the node. Can be one of: 'filled', 'solid',
'dashed', 'dotted', 'bold', 'invis'

=item URL

sets the url for the node in image map and PostScript files. The
string '\N' value will be replaced by the node name. In PostScript
files, URL information is embedded in such a way that Acrobat
Distiller creates PDF files with active hyperlinks

=back

If you wish to add an anonymous node, that is a node for which you do
not wish to generate a name, you may use the following form, where the
GraphViz module generates a name and returns it for you. You may then
use this name later on to refer to this node:

  my $nodename = $g->add_node('label' => 'Roman city');

Nodes can be clustered together with the "cluster" attribute, which is
drawn by having a labelled rectangle around all the nodes in a
cluster. An empty string means not clustered.

  $g->add_node('London', cluster => 'Europe');
  $g->add_node('Amsterdam', cluster => 'Europe');

Nodes can be located in the same rank (that is, at the same level in
the graph) with the "rank" attribute. Nodes with the same rank value
are ranked together.

  $g->add_node('Paris', rank => 'top');
  $g->add_node('Boston', rank => 'top');

Also, nodes can consist of multiple parts (known as ports). This is
implemented by passing an array reference as the label, and the parts
are displayed as a label. GraphViz has a much more complete port
system, this is just a simple interface to it. See the 'from_port' and
'to_port' attributes of add_edge:

  $g->add_node('London', label => ['Heathrow', 'Gatwick']);

=cut

sub add_node {
  my $self = shift;
  my $node = shift;

  # Cope with the new simple notation
  if (ref($node) ne 'HASH') {
    my $name = $node;
    my %node;
    if (@_ % 2 == 1) {
      # No name passed
      %node = ($name, @_);
    } else {
      # Name passed
      %node = (@_, name => $name);
    }
    $node = \%node;
  }

  $self->add_node_munge($node) if $self->can('add_node_munge');

  # The _code attribute is our internal name for the node
  $node->{_code} = $self->_quote_name($node->{name});

  if (not exists $node->{name}) {
    $node->{name} = $node->{_code};
  }

  if (not exists $node->{label})  {
    if (exists $self->{NODES}->{$node->{name}} and defined $self->{NODES}->{$node->{name}}->{label}) {
      # keep our old label if we already exist
      $node->{label} = $self->{NODES}->{$node->{name}}->{label};
    } else {
      $node->{label} = $node->{name};
    }
  }

  delete $node->{cluster}
    if exists $node->{cluster} && !length $node->{cluster} ;

  $node->{_label} =  $node->{label};

  # Deal with ports
  if (ref($node->{label}) eq 'ARRAY') {
    $node->{shape} = 'record'; # force a record
    my $nports = 0;
    $node->{label} = join '|', map
      { $_ =~ s#([|<>\[\]{}"])#\\$1#g; '<port' . $nports++ . '>' . $_ }
      (@{$node->{label}});
  }

  # Save ourselves
  if (!exists($self->{NODES}->{$node->{name}})) {
    $self->{NODES}->{$node->{name}} = $node;
  } else {
    # If the node already exists, add or overwrite attributes.
    foreach (keys %$node) {
      $self->{NODES}->{$node->{name}}->{$_} = $node->{$_};
    }
  }

  $self->{CODES}->{$node->{_code}} = $node->{name};
  $self->{GRAPH}->add_vertex($node->{name});

  foreach my $key (keys %$node) {
    $self->{GRAPH}->set_attribute($key, $node->{name}, $node->{$key});
  }

  # Add the node to the nodelist, which contains the names of
  # all the nodes in the order that they were inserted (but only
  # if it's not already there)
  push @{$self->{NODELIST}}, $node->{name} unless
    grep { $_ eq $node->{name} } @{$self->{NODELIST}};

  return $node->{name};
}


=head2 add_edge

Edges are directed (or undirected) links between nodes. This method
creates a new edge between two nodes and optionally assigns it
attributes.

The simplest form is when now attributes are required, in which case
the nodes from and to which the edge should be are specified. This
works well visually in the program code:

  $g->add_edge('London' => 'Paris');

Attributes such as 'label' can also be used. This specifies a label
for the edge.  The label can contain embedded newlines with '\n', as
well as '\c', '\l', '\r' for center, left, and right justified lines.

  $g->add_edge('London' => 'New York', label => 'Far');

Note that multiple attributes can be specified. Other attributes
include:

=over 4

=item minlen

sets an integer factor that applies to the edge length (ranks for
normal edges, or minimum node separation for flat edges)

=item weight

sets the integer cost of the edge. Values greater than 1 tend to
shorten the edge. Weight 0 flat edges are ignored for ordering
nodes

=item fontsize

sets the label type size in points

=item fontname

sets the label font family name

=item fontcolor

sets the label text colour

=item color

sets the line colour for the edge

A colour value may be "h,s,v" (hue, saturation, brightness) floating
point numbers between 0 and 1, or an X11 color name such as 'white',
'black', 'red', 'green', 'blue', 'yellow', 'magenta', 'cyan', or
'burlywood'

=item style

sets the style of the node. Can be one of: 'filled', 'solid',
'dashed', 'dotted', 'bold', 'invis'


=item dir

sets the arrow direction. Can be one of: 'forward', 'back', 'both',  'none'

=item tailclip, headclip

when set to false disables endpoint shape clipping

=item arrowhead, arrowtail

sets the type for the arrow head or tail. Can be one of: 'none',
'normal', 'inv', 'dot', 'odot', 'invdot', 'invodot.'

=item arrowsize

sets the arrow size: (norm_length=10,norm_width=5,
inv_length=6,inv_width=7,dot_radius=2)

=item headlabel, taillabel

sets the text for port labels. Note that labelfontcolor,
labelfontname, labelfontsize are also allowed

=item labeldistance, port_label_distance

sets the distance from the edge / port to the label. Also labelangle

=item decorateP

if set, draws a line from the edge to the label

=item samehead, sametail

if set aim edges having the same value to the same port, using the
average landing point

=item constraint

if set to false causes an edge to be ignored for rank assignment

=back

Additionally, adding edges between ports of a node is done via the
'from_port' and 'to_port' parameters, which currently takes in the
offset of the port (ie 0, 1, 2...).

  $g->add_edge('London' => 'Paris', from_port => 0);

=cut

sub add_edge {
  my $self = shift;
  my $edge = shift;

  # Also cope with simple $from => $to
  if (ref($edge) ne 'HASH') {
    my $from = $edge;
    my %edge = (from => $from, to => shift, @_);
    $edge = \%edge;
  }

  $self->add_edge_munge($edge) if $self->can('add_edge_munge');

  if (not exists $edge->{from} or not exists $edge->{to}) {
    carp("GraphViz add_edge: 'from' or 'to' parameter missing!");
    return;
  }

  push @{$self->{EDGES}}, $edge; # should remove!

  # The Graph module is strict about the nodes existing before we add
  # edges, but graphviz is not, so we check. Any nodes that don't
  # exist, we create with all the default attributes.
  unless ($self->{GRAPH}->has_vertex($edge->{from})) {
    $self->add_node($edge->{from});
  }
  unless ($self->{GRAPH}->has_vertex($edge->{to})) {
    $self->add_node($edge->{to});
  }

  $self->{GRAPH}->add_edge($edge->{from} => $edge->{to});

  foreach my $key (keys %$edge) {
    $self->{GRAPH}->set_attribute($key, $edge->{from}, $edge->{to}, $edge->{$key});
  }

}


=head2 as_canon, as_text, as_gif etc. methods

There are a number of methods which generate input for dot / neato /
twopi or output the graph in a variety of formats.

Note that if you pass a filename, the data is written to that
filename. If you pass a filehandle, the data will be streamed to the
filehandle. If you pass a scalar reference, then the data will be
stored in that scalar. If you pass it a code reference, then it is
called with the data (note that the coderef may be called multiple
times if the image is large). Otherwise, the data is returned:

B<Win32 Note:> you will probably want to binmode any filehandles you write
the output to if you want your application to be portable to Win32.

  my $png_image = $g->as_png;
  # or
  $g->as_png("pretty.png"); # save image
  # or
  $g->as_png(\*STDOUT); # stream image to a filehandle
  # or
  #g->as_png(\$text); # save data in a scalar
  # or
  $g->as_png(sub { $png_image .= shift });

=over 4

=item as_canon

The as_canon method returns the canonical dot / neato / twopi file
which corresponds to the graph. It does not layout the graph - every
other as_* method does.

  print $g->as_canon;


  # prints out something like:
  digraph test {
      node [	label = "\N" ];
      London [label=London];
      Paris [label="City of\nlurve"];
      New_York [label="New York"];
      London -> Paris;
      London -> New_York [label=Far];
      Paris -> London;
  }

=item as_text

The as_text method returns text which is a layed-out dot / neato /
twopi format file.

  print $g->as_text;

  # prints out something like:
  digraph test {
      node [	label = "\N" ];
      graph [bb= "0,0,162,134"];
      London [label=London, pos="33,116", width="0.89", height="0.50"];
      Paris [label="City of\nlurve", pos="33,23", width="0.92", height="0.62"];
      New_York [label="New York", pos="123,23", width="1.08", height="0.50"];
      London -> Paris [pos="e,27,45 28,98 26,86 26,70 27,55"];
      London -> New_York [label=Far, pos="e,107,40 49,100 63,85 84,63 101,46", lp="99,72"];
      Paris -> London [pos="s,38,98 39,92 40,78 40,60 39,45"];
  }

=item as_ps

Returns a string which contains a layed-out PostScript-format file.

  print $g->as_ps;

=item as_hpgl

Returns a string which contains a layed-out HP pen plotter-format file.

  print $g->as_hpgl;

=item as_pcl

Returns a string which contains a layed-out Laserjet printer-format file.

  print $g->as_pcl;

=item as_mif

Returns a string which contains a layed-out FrameMaker graphics-format file.

  print $g->as_mif;

=item as_pic

Returns a string which contains a layed-out PIC-format file.

  print $g->as_pic;

=item as_gd

Returns a string which contains a layed-out GD-format file.

  print $g->as_gd;

=item as_gd2

Returns a string which contains a layed-out GD2-format file.

  print $g->as_gd2;

=item as_gif

Returns a string which contains a layed-out GIF-format file.

  print $g->as_gif;

=item as_jpeg

Returns a string which contains a layed-out JPEG-format file.

  print $g->as_jpeg;

=item as_png

Returns a string which contains a layed-out PNG-format file.

  print $g->as_png;
  $g->as_png("pretty.png"); # save image


=item as_wbmp

Returns a string which contains a layed-out Windows BMP-format file.

  print $g->as_wbmp;

=item as_cmap

Returns a string which contains a layed-out HTML client-side image map
format file.

  print $g->as_cmap;

=item as_ismap

Returns a string which contains a layed-out old-style server-side
image map format file.

  print $g->as_ismap;

=item as_imap

Returns a string which contains a layed-out HTML new-style server-side
image map format file.

  print $g->as_imap;

=item as_vrml

Returns a string which contains a layed-out VRML-format file.

  print $g->as_vrml;

=item as_vtx

Returns a string which contains a layed-out VTX (Visual Thought)
format file.

  print $g->as_vtx;

=item as_mp

Returns a string which contains a layed-out MetaPost-format file.

  print $g->as_mp;

=item as_fig

Returns a string which contains a layed-out FIG-format file.

  print $g->as_fig;

=item as_svg

Returns a string which contains a layed-out SVG-format file.

  print $g->as_svg;

=item as_plain

Returns a string which contains a layed-out simple-format file.

  print $g->as_plain;

=back

=cut

# Generate magic methods to save typing

sub AUTOLOAD {
  my $self = shift;
  my $type = ref($self)
    or croak("$self is not an object");
  my $output = shift;

  my $name = $AUTOLOAD;
  $name =~ s/.*://;   # strip fully-qualified portion

  return if $name =~ /DESTROY/;

  if ($name eq 'as_text') {
    $name = "as_dot";
  }

  if ($name =~ /^as_(ps|hpgl|pcl|mif|pic|gd|gd2|gif|jpeg|png|wbmp|cmap|ismap|imap|vrml|vtx|mp|fig|svg|dot|canon|plain)$/) {
    my $data = $self->_as_generic('-T' . $1, $self->_as_debug, $output);
    return $data;
  }

  croak "Method $name not defined!";
}


# Undocumented feature: return a Graph object
sub as_graph {
  my($self, $conf) = @_;
  my $graph = $self->{GRAPH};

  return $self->_parse_dot($self->_as_debug);
}


sub _parse_dot {
  my($self, $dot) = @_;
  my $graph = $self->{GRAPH};

  my $out;
  my $program = $self->{LAYOUT};

  run [$program, '-Tplain'], \$dot, \$out;

  my($aspect, $bbw, $bbh);

  foreach my $line (split /\n/, $out) {
#    print "# $line\n";

    my($type, @values) = split /\s+/, $line;
    if ($type eq 'graph') {
      ($aspect, $bbw, $bbh) = @values;
    } elsif ($type eq 'node') {
      my($node, $x, $y, $w, $h) = @values;
      $x /= $bbw;
      $y /= $bbh;
      $w /= $bbw;
      $h /= $bbh;
      $node = $self->{CODES}->{$node};
#      print "#  $node  ($x, $y) x ($w, $h)\n";
      $graph->set_attribute('x', $node, $x);
      $graph->set_attribute('y', $node, $y);
      $graph->set_attribute('w', $node, $w);
      $graph->set_attribute('h', $node, $h);
    } elsif ($type eq 'edge') {
      my($from, $to, $n, @points) = @values;

      $from = $self->{CODES}->{$from};
        $to = $self->{CODES}->{$to};

      @points = splice(@points, 0, $n * 2);

      my @newpoints;

      while (@points) {
	my ($x, $y) = splice(@points, 0, 2);
	$x /= $bbw;
	$y /= $bbh;
	push @newpoints, $x, $y;
      }

      my $bezier = Math::Bezier->new(@newpoints);
#      print "#  $from->$to: @newpoints\n";
      $graph->set_attribute('bezier', $from, $to, $bezier);
    }
#    next unless $type eq 'node';
  }

  return $graph;
}


# Return the main dot text
sub _as_debug {
  my $self = shift;

  my $dot;

  my $graph_type = $self->{DIRECTED} ? 'digraph' : 'graph';

  $dot .= "$graph_type test {\n";

  # the direction of the graph
  $dot .= "\trankdir=LR;\n" if $self->{RANK_DIR};

  # the size of the graph
  $dot .= "\tsize=\"" . $self->{WIDTH} . "," . $self->{HEIGHT} ."\";\n\tratio=fill\n" if $self->{WIDTH} && $self->{HEIGHT};
  $dot .= "\tpage=\"" . $self->{PAGEWIDTH} . "," . $self->{PAGEHEIGHT} ."\";\n" if $self->{PAGEWIDTH} && $self->{PAGEHEIGHT};

  # edge merging
  $dot .= "\tconcentrate=true;\n" if $self->{CONCENTRATE};

  # epsilon
  $dot .= "\tepsilon=" . $self->{EPSILON} . ";\n" if $self->{EPSILON};

  # random start
  $dot .= "\tstart=rand;\n" if $self->{RANDOM_START};

  # no_overlap
  $dot .= "\toverlap=false;\n" if $self->{NO_OVERLAP};

  # color, bgcolor
  $dot .= "\tbgcolor=\"" . $self->{BGCOLOR} . "\";\n" if $self->{BGCOLOR};

  # Global node, edge and graph attributes
  $dot .= "\tnode" . _attributes($self->{NODE_ATTRS}) . ";\n"
    if exists($self->{NODE_ATTRS});
  $dot .= "\tedge" . _attributes($self->{EDGE_ATTRS}) . ";\n"
    if exists($self->{EDGE_ATTRS});
  $dot .= "\tgraph" . _attributes($self->{GRAPH_ATTRS}) . ";\n"
    if exists($self->{GRAPH_ATTRS});

  my %clusters = ();
  my %clusters_edge = ();

  my $arrow = $self->{DIRECTED} ? ' -> ' : ' -- ';

  # Add all the nodes
  my @nodelist = @{$self->{NODELIST}};
  @nodelist = sort @nodelist if $self->{SORT};

  foreach my $name (@nodelist) {
    my $node = $self->{NODES}->{$name};

    # Note all the clusters
    if (exists $node->{cluster} && $node->{cluster}) {
      push @{$clusters{$node->{cluster}}}, $name;
      next;
    }

    $dot .= "\t" . $node->{_code} . _attributes($node) . ";\n";
  }

  # Add all the edges
  foreach my $edge (sort { $a->{from} cmp $b->{from} || $a->{to} cmp $b->{to} } @{$self->{EDGES}}) {

    my $from = $self->{NODES}->{$edge->{from}}->{_code};
    my $to = $self->{NODES}->{$edge->{to}}->{_code};

    # Deal with ports
    if (exists $edge->{from_port}) {
      $from = '"' . $from . '"' . ':port' . $edge->{from_port};
    }
    if (exists $edge->{to_port}) {
      $to = '"' . $to . '"' . ':port' . $edge->{to_port};
    }

    if (exists $self->{NODES}->{$from} && exists $self->{NODES}->{$from}->{cluster}
        && exists $self->{NODES}->{$to} && exists $self->{NODES}->{$to}->{cluster} &&
	$self->{NODES}->{$from}->{cluster} eq $self->{NODES}->{$to}->{cluster}) {

      $clusters_edge{$self->{NODES}->{$from}->{cluster}} .= "\t\t" . $from . $arrow . $to . _attributes($edge) . ";\n";
    } else {
      $dot .= "\t" . $from . $arrow . $to . _attributes($edge) . ";\n";
    }
  }

  foreach my $cluster (sort keys %clusters) {
    my $label = _attributes({ label => $cluster});
    $label =~ s/^\s\[//;
    $label =~ s/\]$//;

    $dot .= "\tsubgraph cluster_" . $self->_quote_name($cluster) . " {\n";
    $dot .= "\t\t$label;\n";
    $dot .= join "", map { "\t\t" . $self->{NODES}->{$_}->{_code} . _attributes($self->{NODES}->{$_}) . ";\n"; } (@{$clusters{$cluster}});
    $dot .= $clusters_edge{$cluster} if exists $clusters_edge{$cluster};
    $dot .= "\t}\n";
  }

  # Deal with ranks
  my %ranks;
  foreach my $name (@nodelist) {
    my $node = $self->{NODES}->{$name};
    next unless exists $node->{rank};
    push @{$ranks{$node->{rank}}}, $name;
  }

  foreach my $rank (keys %ranks) {
    $dot .= qq|\t{rank=same; |;
    $dot .= join '; ', map { $self->_quote_name($_) } @{$ranks{$rank}};
    $dot .= qq|}\n|;
  }
# {rank=same; Paris; Boston}


  $dot .= "}\n";

  return $dot;
}


# Call dot / neato / twopi with the input text and any parameters

sub _as_generic {
  my($self, $type, $dot, $output) = @_;

  my $buffer;
  my $out;
  if ( ref $output || UNIVERSAL::isa(\$output, 'GLOB') ) {
      # $output is a filehandle or a scalar reference or something.
      # have to take a reference to a bare filehandle or run will
      # complain
      $out = ref $output ? $output : \$output;
  } elsif (defined $output) {
      # if it's defined it must be a filename so we'll write to it.
      $out = $output;
  } else {
      # but otherwise we capture output in a scalar
      $out = \$buffer;
  }

  my $program = $self->{LAYOUT};

  run [$program, $type], \$dot, ">", binary(), $out;

  return $buffer unless defined $output;
}


# Quote a node/edge name using dot / neato / twopi's quoting rules

sub _quote_name {
  my($self, $name) = @_;
  my $realname = $name;

  return $self->{_QUOTE_NAME_CACHE}->{$name} if exists $self->{_QUOTE_NAME_CACHE}->{$name};

  if (defined $name && $name =~ /^[a-zA-Z]\w*$/ && $name ne "graph") {
    # name is fine
  } elsif (defined $name && $name =~ /^[a-zA-Z](\w| )*$/) {
    # name contains spaces, so quote it
    $name = '"' . $name . '"';
  } else {
    # name contains weird characters - let's make up a name for it
    $name = 'node' . ++$self->{_NAME_COUNTER};
  }

  $self->{_QUOTE_NAME_CACHE}->{$realname} = $name if defined $realname;

#  warn "# $realname -> $name\n";

  return $name;
}


# Return the attributes of a node or edge as a dot / neato / twopi attribute
# string

sub _attributes {
  my $thing = shift;

  my @attributes;

  foreach my $key (keys %$thing) {
    next if $key =~ /^_/;
    next if $key =~ /^(to|from|name|cluster|from_port|to_port)$/;

    my $value = $thing->{$key};
    $value =~ s|"|\"|g;
    $value = '"' . $value . '"';
    $value =~ s|\n|\\n|g;

    $value = '""' if not defined $value;
    push @attributes, "$key=$value";
  }

  if (@attributes) {
    return ' [' . (join ', ', sort @attributes) . "]";
  } else {
    return "";
  }
}


=head1 NOTES

Older versions of GraphViz used a slightly different syntax for node
and edge adding (with hash references). The new format is slightly
clearer, although for the moment we support both. Use the new, clear
syntax, please.

=head1 SEE ALSO

GraphViz::XML, GraphViz::Regex

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2000-1, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;
