# Data::Hopen::G::DAG - hopen build graph
package Data::Hopen::G::DAG;
use Data::Hopen::Base;

our $VERSION = '0.000012';

use parent 'Data::Hopen::G::Op';
use Class::Tiny {
    goals   => sub { [] },
    default_goal => undef,

    # Private attributes with simple defaults
    #_node_by_name => sub { +{} },   # map from node names to nodes in either
    #                                # _init_graph or _graph

    # Private attributes - initialized by BUILD()
    _graph  => undef,   # L<Graph> instance
    _final   => undef,  # The graph sink - all goals have edges to this

    #Initialization operations
    _init_graph => undef,   # L<Graph> for initializations
    _init_first => undef,   # Graph node for initialization - the first
                            # init operation to be performed.

    # TODO? also support fini to run operations after _graph runs?
};

use Data::Hopen qw(hlog getparameters $QUIET);
use Data::Hopen::G::Goal;
use Data::Hopen::G::Link;
use Data::Hopen::G::Node;
use Data::Hopen::G::CollectOp;
use Data::Hopen::Util::Data qw(forward_opts);
use Graph;
use Storable ();

# Class data {{{1

use constant {
    LINKS => 'link_list',    # Graph edge attr: array of BHG::Link instances
};

# A counter used for making unique names
my $_id_counter = 0;    # threads: make shared

# }}}1
# Docs {{{1

=head1 NAME

Data::Hopen::G::DAG - A hopen build graph

=head1 SYNOPSIS

This class encapsulates the DAG for a particular set of one or more goals.
It is itself a L<Data::Hopen::G::Op> so that it can be composed into
other DAGs.

=head1 ATTRIBUTES

=head2 goals

Arrayref of the goals for this DAG.

=head2 default_goal

The default goal for this DAG.

=head2 _graph

The actual L<Graph>.  If you find that you have to use it, please open an
issue so we can see about providing a documented API for your use case!

=head2 _final

The node to which all goals are connected.

=head2 _init_graph

A separate L<Graph> of operations that will run before all the operations
in L</_graph>.  This is because I don't want to add an edge to every
single node just to force the topological sort to work out.

=head2 _init_first

The first node to be run in _init_graph.

=head1 FUNCTIONS

=cut

# }}}1

=head2 _run

Traverses the graph.  The DAG is similar to a subroutine in this respect.
The outputs from all the goals
of the DAG are aggregated and provided as the outputs of the DAG.
The output is a hash keyed by the name of each goal, with each goal's outputs
as the values under that name.  Usage:

    my $hrOutputs = $dag->run([-context=>$scope][, other options])

C<$scope> must be a L<Data::Hopen::Scope> or subclass if provided.
Other options are as L<Data::Hopen::Runnable/run>.

=cut

# The implementation of run().  $self->scope has already been linked to the context.
sub _run {
    my ($self, %args) = getparameters('self', [qw(; phase generator)], @_);
    my $retval = {};

    # --- Get the initialization ops ---

    my @init_order = eval { $self->_init_graph->toposort };
    die "Initializations contain a cycle!" if $@;
    @init_order = () if $self->_init_graph->vertices == 1;  # no init nodes => skip

    # --- Get the runtime ops ---

    my @order = eval { $self->_graph->toposort };
        # TODO someday support multi-core-friendly topo-sort, so nodes can run
        # in parallel until they block each other.
    die "Graph contains a cycle!" if $@;

    # Remove _final from the order for now - I don't yet know what it means
    # to traverse _final.
    die "Last item in order isn't _final!  This might indicate a bug in hopen."
        unless $order[$#order] == $self->_final;
    pop @order;

    # --- Traverse ---

    # Note: while hacking, please make sure Goal nodes can appear
    # anywhere in the graph.

    hlog { my $x = 'Traversing DAG ' . $self->name; $x, '*' x (78-length($x)) };
    my $graph = $self->_init_graph;
    foreach my $node (@init_order, undef, @order) {

        if(!defined($node)) {   # undef is the marker between init and run
            $graph = $self->_graph;
            next;
        }

        # Inputs to this node.  These are different from the DAG's inputs.
        # The scope stack is (outer to inner) DAG's inputs, DAG's overrides,
        # then $node_inputs, then the individual node's overrides.
        my $node_inputs = Data::Hopen::Scope::Hash->new;
            # TODO make this a BH::Scope::Inputs once it's implemented
        $node_inputs->outer($self->scope);
            # Data specifically being provided to the current node, e.g.,
            # on input edges, beats the scope of the DAG as a whole.
        $node_inputs->local(true);
            # A CollectOp won't reach above the node's inputs by default.

        # Iterate over each node's edges and process any Links
        foreach my $pred ($graph->predecessors($node)) {
            hlog { ('From', $pred->name, 'to', $node->name) };

            # Goals do not feed outputs to other Goals.  This is so you can
            # add edges between Goals to set their order while keeping the
            # data for each Goal separate.
            # TODO add tests for this.  Also TODO decide whether this is
            # actually the Right Thing!
            next if eval { $pred->DOES('Data::Hopen::G::Goal') };

            my $links = $graph->get_edge_attribute($pred, $node, LINKS);

            unless($links) {    # Simple case: predecessor's outputs become our inputs
                $node_inputs->add(%{$pred->outputs});
                next;
            }

            # More complex case: Process all the links
            my $hrPredOutputs = $pred->outputs;
                # In one test, outputs was undef if not on its own line.
            my $link_inputs = Data::Hopen::Scope::Hash->new->add(%{$hrPredOutputs});
                # All links get the same outer scope --- they are parallel,
                # not in series.
            $link_inputs->outer($self->scope);
                # The links run at the same scope level as the node.
            $link_inputs->local(true);

            # Run the links in series - not parallel!
            my $link_outputs = $link_inputs->as_hashref(-levels=>'local');
            foreach my $link (@$links) {
                hlog { ('From', $pred->name, 'via', $link->name, 'to', $node->name) };

                $link_outputs = $link->run(
                    -context=>$link_inputs,
                    forward_opts(\%args, {'-'=>1}, 'phase')
                    # Generator not passed to links.
                );
            } #foreach incoming link

            $node_inputs->add(%{$link_outputs});
                # TODO specify which set these are.
        } #foreach predecessor node

        my $step_output = $node->run(-context=>$node_inputs,
            forward_opts(\%args, {'-'=>1}, 'phase', 'generator')
        );
        $node->outputs($step_output);

        # Give the Generator a chance, and stash the results if necessary.
        if(eval { $node->DOES('Data::Hopen::G::Goal') }) {
            $args{generator}->visit_goal($node) if $args{generator};

            # Save the result if there is one.  Don't save {}.
            # use $node->outputs, not $step_output, since the generator may
            # alter $node->outputs.
            $retval->{$node->name} = $node->outputs if keys %{$node->outputs};
        } else {
            $args{generator}->visit_node($node) if $args{generator};
        }

    } #foreach node in topo-sort order

    return $retval;
} #run()

=head1 ADDING DATA

=head2 goal

Creates a goal of the DAG.  Goals are names for sequences of operations,
akin to top-level Makefile targets.  Usage:

    my $goalOp = $dag->goal('name')

Returns a passthrough operation representing the goal.  Any inputs passed into
that operation are provided as outputs of the DAG under the corresponding name.

The first call to C<goal()> also sets L</default_goal>.

=cut

sub goal {
    my $self = shift or croak 'Need an instance';
    my $name = shift or croak 'Need a goal name';
    my $goal = Data::Hopen::G::Goal->new(name => $name);
    $self->_graph->add_vertex($goal);
    #$self->_node_by_name->{$name} = $goal;
    $self->_graph->add_edge($goal, $self->_final);
    $self->default_goal($goal) unless $self->default_goal;
    return $goal;
} #goal()

=head2 connect

   - C<DAG:connect(<op1>, <out-edge>, <in-edge>, <op2>)>:
     connects output C<< out-edge >> of operation C<< op1 >> as input C<< in-edge >> of
     operation C<< op2 >>.  No processing is done between output and input.
     - C<< out-edge >> and C<< in-edge >> can be anything usable as a table index,
       provided that table index appears in the corresponding operation's
       descriptor.
   - C<DAG:connect(<op1>, <op2>)>: creates a dependency edge from C<< op1 >> to
     C<< op2 >>, indicating that C<< op1 >> must be run before C<< op2 >>.
     Does not transfer any data from C<< op1 >> to C<< op2 >>.
   - C<DAG:connect(<op1>, <Link>, <op2>)>: Connects C<< op1 >> to
     C<< op2 >> via L<Data::Hopen::G::Link> C<< Link >>.

TODO return the name of the edge?  The edge instance itself?  Maybe a
fluent interface to the DAG for chaining C<connect> calls?

=cut

sub connect {
    my $self = shift or croak 'Need an instance';
    my ($op1, $out_edge, $in_edge, $op2) = @_;

    my $link;
    if(!defined($in_edge)) {    # dependency edge
        $op2 = $out_edge;
        $out_edge = false;      # No outputs
        $in_edge = false;       # No inputs
    } elsif(!defined($op2)) {
        $op2 = $in_edge;
        $link = $out_edge;
        $out_edge = false;      # No outputs TODO
        $in_edge = false;       # No inputs TODO
    }

#    # Create the link
#    unless($link) {
#        $link = Data::Hopen::G::Link->new(
#            name => 'link_' . $op1->name . '_' . $op2->name,
#            in => [$out_edge],      # Output of op1
#            out => [$in_edge],      # Input to op2
#        );
#    }

    hlog { 'DAG::connect(): Edge from', $op1->name,
            'via', $link ? $link->name : '(no link)',
            'to', $op2->name };

    # Add it to the graph (idempotent)
    $self->_graph->add_edge($op1, $op2);
    #$self->_node_by_name->{$_->name} = $_ foreach ($op1, $op2);

    # Save the BHG::Link as an edge attribute (not idempotent!)
    my $attrs = $self->_graph->get_edge_attribute($op1, $op2, LINKS) || [];
    push @$attrs, $link if $link;
    $self->_graph->set_edge_attribute($op1, $op2, LINKS, $attrs);

    return undef;   # TODO decide what to return
} #connect()

=head2 add

Add a regular node to the graph.  An attempt to add the same node twice will be
ignored.  Usage:

    my $node = Data::Hopen::G::Op->new(name=>"whatever");
    $dag->add($node);

Returns the node, for the sake of chaining.

=cut

sub add {
    my $self = shift or croak 'Need an instance';
    my $node = shift or croak 'Need a node';
    return if $self->_graph->has_vertex($node);
    hlog { __PACKAGE__, 'adding', Dumper($node) } 2;

    $self->_graph->add_vertex($node);
    #$self->_node_by_name->{$node->name} = $node if $node->name;

    return $node;
} #add()

=head2 init

Add an initialization operation to the graph.  Initialization operations run
before all other operations.  An attempt to add the same initialization
operation twice will be ignored.  Usage:

    my $op = Data::Hopen::G::Op->new(name=>"whatever");
    $dag->init($op[, $first]);

If C<$first> is truthy, the op will be run before anything already in the
graph.  However, later calls to C<init()> with C<$first> set will push
operations even before C<$op>.

Returns the node, for the sake of chaining.

=cut

sub init {
    my $self = shift or croak 'Need an instance';
    my $op = shift or croak 'Need an op';
    my $first = shift;
    return if $self->_init_graph->has_vertex($op);

    $self->_init_graph->add_vertex($op);
    #$self->_node_by_name->{$op->name} = $op;

    if($first) {    # $op becomes the new _init_first node
        $self->_init_graph->add_edge($op, $self->_init_first);
        $self->_init_first($op);
    } else {    # Not first, so can happen anytime.  Add it after the
                # current first node.
        $self->_init_graph->add_edge($self->_init_first, $op);
    }

    return $op;
} #init()

=head1 ACCESSORS

=head2 empty

Returns truthy if the only nodes in the graph are internal nodes.
Intended for use by hopen files.

=cut

sub empty {
    my $self = shift or croak 'Need an instance';
    return ($self->_graph->vertices == 1);
        # _final is the node in an empty() graph.
        # We don't check the _init_graph since empty() is intended
        # for use by hopen files, not toolsets.
} #empty()

=head1 OTHER

=head2 BUILD

Initialize the instance.

=cut

sub BUILD {
    #use Data::Dumper;
    #say Dumper(\@_);
    my $self = shift or croak 'Need an instance';
    my $hrArgs = shift;

    # DAGs always have names
    $self->name('__R_DAG_' . $_id_counter++) unless $self->has_custom_name;

    # Graph of normal operations
    my $graph = Graph->new( directed => true,
                            refvertexed => true);
    my $final = Data::Hopen::G::Node->new(
                                    name => '__R_DAG_ROOT' . $_id_counter++);
    $graph->add_vertex($final);
    $self->_graph($graph);
    $self->_final($final);

    # Graph of initialization operations
    my $init_graph = Graph->new( directed => true,
                            refvertexed => true);
    my $init = Data::Hopen::G::CollectOp->new(
                                    name => '__R_DAG_INIT' . $_id_counter++);
    $init_graph->add_vertex($init);

    $self->_init_graph($init_graph);
    $self->_init_first($init);
} #BUILD()

1;
# Rest of the docs {{{1
__END__

=head1 IMPLEMENTATION

Each DAG has a hidden "root" node.  All outputs have edges from the root node.
The traversal order is reverse topological from the root node, but is not
constrained beyond that.  Generators can ask for the nodes in root-first or
root-last order.

The DAG is built backwards from the outputs toward the inputs, although calls
to L</output> and L</connect> can appear in any order in the C<hopen> file as
long as everything is hooked in by the end of the file.

The following is in flux:

 - C<DAG>: A class representing a DAG.  An instance called C<main> represents
   what will be generated.

   - C<DAG:set_default(<goal>)>: make C<< goal >> the default goal of this DAG
     (default target).
   - C<DAG:inject(<op1>,<op2>[, after/before'])>: Returns an operation that
     lives on the edge between C<op1> and C<op2>.  If the third parameter is
     false, C<'before'>, or omitted, the new operation will be the first
     operation on that edge.  If the third parameter is true or C<'after'>,
     the new operation will be the last operation on that edge.  Any number
     of operations can be injected on any edge.

=cut

# }}}1
# vi: set fdm=marker: #
