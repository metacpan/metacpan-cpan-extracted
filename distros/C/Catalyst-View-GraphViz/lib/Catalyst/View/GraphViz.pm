package Catalyst::View::GraphViz;

use strict;
use base qw/Catalyst::Base/;
use GraphViz;
use NEXT;

our $VERSION = '0.05';

=head1 NAME

Catalyst::View::GraphViz - GraphViz View Class

=head1 SYNOPSIS

=head2 Use the helper to create a View class

    script/myapp_create.pl view GraphViz GraphViz

This creates the MyApp::View::GraphViz class.


=head2 Build the GraphViz object

    #In some method (some View method, since
    #that's where the View code should go. See below.)
    use GraphViz;
    $graph = GraphViz->new();
    $graph->add_node("Hello", shape => 'box');
    $graph->add_node("world", shape => 'box');
    $graph->add_edge("Hello", "world");
    
    $c->stash->{graphviz}->{graph} = $graph;
    $c->stash->{graphviz}->{format} = "cmapx"; #HTML image map (default: png)
    


=head2 Forward to the View

    #Meanwhile, maybe in a private end action
    if(!$c->res->body) {
        if($c->stash->{template}) {
            $c->forward('MyApp::View::TT');
        } elsif($c->stash->{graphviz}->{graph}) {
            $c->forward('MyApp::View::GraphViz');
        } else {
            die("No output method!\n");
        }
    }


=head1 DESCRIPTION

This is the Catalyst view class for L<GraphViz>. Your application
subclass should inherit from this class.

This plugin renders the GraphViz object specified in
C<$c-E<gt>stash-E<gt>{graphviz}-E<gt>{graph}> into the
C<$c-E<gt>stash-E<gt>{graphviz}-E<gt>{format}> (one of e.g. png
gif, or one of the other as_* methods described in the
L<GraphViz> module. PNG is the default format.

The output is stored in C<$c-E<gt>response-E<gt>output>.

The normal way of using this is to render a PNG image for a request
and let Catalyst serve it.

Another use of this View is to let it generate the text of a client
side imagemap (using a SubRequest) which you then put into the web
page currently being rendered. See below for an example.


=head1 BUILD THE GRAPHVIZ OBJECT IN A VIEW

The Catalyst::View::GraphViz takes a pre-built GraphViz object to
render.

But where should this GraphViz object be constructed?  Preferrably in
a View class, since the GraphViz graph contains nodes with different
colors, shapes, etc.

Consider how the GraphViz View relates to templating systems:

                     Templating System      GraphViz
                     -----------------      --------
  Model            | Model object(s)        Model object(s) (a graph)
  Output           | Rendered HTML          Rendered graph image/imagemap
  View             | TT/Mason/?             View::GraphViz
  View code        | Custom template file   Custom View class
  Set "look"       | $c->stash->{template}  $c->stash->{graphview}->{view}
  Set model object | varies                 $c->stash->{graphview}->{object}
  E.g. "look"      | update.thtml           MyApp::View::OddEvenGraph

So when using TT as a rendering engine, the template contains the
instructions for how to display the Model object. You have many
templates for displaying the same model object in different ways.

And when using GraphViz as a rendering engine, the View class contains
the instructions for how to display the Model object. You have many
View classes for displaying the same model object in different ways.

Here's how to create a specific View class for each type of graph.


=head2 MyApp::View::OddEvenGraph

As an example, let's create a view to render a graph of numbers, where
the odd number nodes are boxes, and the even are ellipses.

Our model object is set like this somewhere (for a quick demo, just
put it in the MyApp::default sub):

    $c->stash->{graphview}->{object} = {
        3 => 2,
        4 => 3,
        1 => 3,
        2 => 1,
    };

This can of course be anything that you can interpret as a graph and
would like to visualize using GraphViz, not necessarily a single deep
data structure like this. It could equally well be an array ref with
model objects which together form a graph.

After setting up the model object, we assign the correct View class to
render it.

    $c->stash->{graphview}->{view} = "MyApp::View::OddEvenGraph";
    $c->stash->{graphviz}->{format} = "cmapx";  #Optionally override the format


And, maybe in a private C<end> action, we forward to the view if it's
set, like this:

    sub end : Private {
        my ( $self, $c ) = @_;

        if(!$c->res->body) {
            if($c->stash->{template}) {
                $c->forward('MyApp::View::TT');
            } elsif(my $view = $c->stash->{graphview}->{view}) {
                $c->forward($view);
            } else {
                die("No output method!\n");
            }
        }
    }


That's what your application looks like. Now we need to create the
actual View class MyApp::View::OddEvenGraph. Use the helper GraphView:

  script/myapp_create.pl view OddEvenGraph GraphView


In the class MyApp::View::OddEvenGraph you can modify the process sub
to suit your needs.

    sub process {
        my ($self, $c) = @_;

        my $graph = $c->stash->{graphview}->{object} or
                die('No object specified in $c->stash->{graphview}->{object} for rendering');

        my $graphviz = GraphViz->new(node => {
            name => "oddeven",
        });

        $graphviz->add_node($_, shape => ($_ % 2) ? "box" : "ellipse") for(keys %$graph);
        while(my ($from, $to) = each %$graph) {
            $graphviz->add_edge($from, $to);
        }


        $c->stash->{graphviz}->{graph} = $graphviz;
        $c->forward('MyApp::View::GraphViz');

        return 1;
    }

As you can see, the purpose of this method is to transform the model
graph object into a GraphViz object, which is then forwarded to the
GraphViz View.



=head1 MAKE A SUBREQUEST TO GENERATE AN IMAGEMAP

Together with the ability to render a GraphViz image soon comes the
need to generate a client-side imagemap which can be inserted in the
web page showing the image.

You need a) an action that renders the GraphViz object in the cmapx
format, and b) to call that action from within another action so you
can assign the resulting HTML text to your stash and then put it in
the template.


=head2 Render as an Imagemap

If your ordinary png action looks like this:

    sub png : Local {
        my ( $self, $c ) = @_;
        $c->stash->{graphview}->{view} = "MyApp::View::OddEvenGraph";
        $c->stash->{graphview}->{object} = ...;
    }

then your imap action should look like this:

    sub imap : Local {
        my ( $self, $c ) = @_;
        $c->stash->{graphview}->{view} = "MyApp::View::OddEvenGraph";
        $c->stash->{graphview}->{object} = ...;
        $c->stash->{graphviz}->{format} = "cmapx";
    }


=head2 Call the Imagemap Action

First make sure you have the SubRequest plugin loaded:

    use Catalyst qw/SubRequest/;  

This is how to perform the SubRequest. Let's assume these actions are
in the Controller "Graph":

    $c->stash->{html_imagemap} = $c->subreq("/graph/imap");

    #Reset after subreq (until this bug is fixed: http://rt.cpan.org/NoAuth/Bug.html?id=15790 )
    $c->response->content_type("text/html");

Now you can simply output the imagemap text in the template

    [% html_imagemap %]
    <img name="graph" src="/graph/png" USEMAP="#oddeven" border=0>

Note 1: The name "oddeven" is the same as the one set in the

    GraphViz->new(name => "oddeven");

Note 1a: Unfortunately this isn't quite true. The name of the GraphViz
image is always hardcoded to "test". Bug that needs to be fixed:
http://rt.cpan.org/NoAuth/Bug.html?id=14882

Note 2: The nodes will not be clickable unless they have a URL property,
so you need to specify that for each

    $graphviz->add_node(URL => "/graph/node/select?name=$name");

in the View class. Actually, there is a clever shortcut in GraphViz
for this, so instead of specifying it for each node, you can set a
default when calling

    my $graphviz = GraphViz->new(node => { URL => '/graph/node/select?name=\N' });

The \N is a placeholder for the name of each node.

 


=head1 METHODS

=head2 new($c)

The constructor for the GraphViz view. Sets up the template provider, 
and reads the application config.

=cut
sub new {
    my $self = shift;
    my $c    = shift;

    $self = $self->NEXT::new(@_);

    return $self;
}

=head2 process($c)

Render the GraphViz object specified in
C<$c-E<gt>stash-E<gt>{graphviz}>.

Output is stored in C<$c-E<gt>response-E<gt>output>.

=cut
my $plain = 'text/plain; charset=utf-8';
my $html = 'text/html; charset=utf-8';
my %hExtType = (
    ps => 'application/postscript',
    hpgl => $plain,
    pcl => $plain,
    mif => 'application/x-mif',
    pic => 'image/x-pict',
    gd => $plain,
    gd2 => $plain,
    gif => 'image/gif',
    jpeg => 'image/jpeg',
    png => 'image/x-png',
    wbmp => 'image/x-ms-bmp',
    cmap => $plain,
    cmapx => $plain,
    ismap => $plain,
    imap => $plain,
    vrml => 'x-world/x-vrml',
    vtx => $plain, #?
    mp => $plain,  #?
    fig => $plain, #?
    svg => 'image/svg+xml',
    svgz => 'image/svg+xml',
    dot => $plain,
    canon => $plain,
    plain => $plain,
);
sub process {
    my ($self, $c) = @_;

    my $oGv = $c->stash->{graphviz}->{graph};
    if(!$oGv) {
        $c->log->debug('No GraphViz object specified in $c->stash->{graphviz}->{graph} for rendering') if $c->debug;
        return 0;
    }

    my $format = $c->stash->{graphviz}->{format} || $c->config->{graphviz}->{format} || $self->config->{format} || "png";
    my $contentType;
    my $output;
    eval {
        $c->log->debug(qq/Rendering GraphViz object as ($format)/) if $c->debug;
        $contentType = $hExtType{$format} or die("Unknown format ($format). Known formats are (" . join("|", sort keys %hExtType) . ")\n");

        my $methodRender = "as_$format";
        $output = $oGv->$methodRender() or die("Could not render GraphViz obejct as ($format)\n");
    };
    if($@) {
        my $error = $@;
        $c->log->error($error);
        $c->error($error);
        return 0;
    }
    
    $c->response->content_type or $c->response->content_type($contentType);

    $c->response->body($output);

    return 1;
}





=head1 SEE ALSO

L<Catalyst>, L<GraphViz>


=head1 CHANGES




=head2 0.05

Docs


=head2 0.01 - 0.04

Makefile and Windows/Unix stuff


=head1 AUTHOR

Johan Lindstrom, C<johanl@cpan.org>



=head1 CREDITS

Largely based on the TT view.

Obviosly uses Acme's L<GraphViz> module, which in turn uses the
brilliant GraphViz package (http://www.graphviz.org/).

Quick link to a useful, but obscure, doc page:
http://www.graphviz.org/pub/scm/graphviz2/doc/info/shapes.html



=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
