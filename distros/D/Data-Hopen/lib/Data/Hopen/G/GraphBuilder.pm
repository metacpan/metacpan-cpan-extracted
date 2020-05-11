# Data::Hopen::G::GraphBuilder - fluent interface for building graphs
package Data::Hopen::G::GraphBuilder;
use Data::Hopen;
use strict;
use Data::Hopen::Base;
use Exporter 'import';

our @EXPORT; BEGIN { @EXPORT=qw(make_GraphBuilder); }

our $VERSION = '0.000017';

use Class::Tiny {
    name => 'ANON',     # Name is optional; it's here so the
                        #   constructor won't croak if you use one.
    dag => undef,       # The current G::DAG instance
    node => undef,      # The last node added
};

use Class::Method::Modifiers qw(install_modifier);
use Getargs::Mixed;
use Scalar::Util qw(refaddr);

# Docs {{{1

=head1 NAME

Data::Hopen::G::GraphBuilder - fluent interface for building graphs

=head1 SYNOPSIS

A GraphBuilder wraps a L<Data::Hopen::G::DAG> and a current
L<Data::Hopen::G::Node>.  It permits building chains of nodes in a
fluent way.  For example, in an L<App::hopen> hopen file:

    # $Build is a Data::Hopen::G::DAG created by App::hopen
    use language 'C';

    my $builder = $Build->C::compile(file => 'foo.c');
        # Now $builder holds $Build (the DAG) and a node created by
        # C::compile().

=head1 ATTRIBUTES

=head2 name

An optional name, in case you want to identify your Builder instances.

=head2 dag

The current L<Data::Hopen::G::DAG> instance, if any.

=head2 node

The current L<Data::Hopen::G::Node> instance, if any.

=head1 INSTANCE FUNCTIONS

=cut

# }}}1

=head2 add

Adds a node to the graph.  Returns the node.  Note that this B<does not>
change the builder's current node (L</node>).

=cut

sub add {
    my ($self, %args) = getparameters('self', ['node'], @_);
    $self->dag->add($args{node});
    return $args{node};
} #add()

=head2 default_goal

Links the most recent node in the chain to the default goal in the DAG.
If the DAG does not have a default goal, adds one called "all".

As a side effect, calling this function clears the builder's record of the
current node and returns C<undef>.  The idea is that this function
will be used at the end of a chain of calls.  Clearing state in this way
reduces the chance of unintentionally connecting nodes.

=cut

sub default_goal {
    my $self = shift or croak 'Need an instance';
    croak "Need a node to link to the goal" unless $self->node;

    my $goal = $self->dag->default_goal // $self->dag->goal('all');
    $self->dag->add($self->node);   # no harm in it - DAG::add() is idempotent
    $self->dag->connect($self->node, $goal);

    $self->node(undef);     # Less likely to leak state between goals.

    return undef;
        # Also, if this is the last thing in an App::hopen hopen file,
        # whatever it returns gets recorded in MY.hopen.pl.  Therefore,
        # return $self would cause a copy of the whole graph to be dropped into
        # MY.hopen.pl, which would be a Bad Thing.
} #default_goal()

=head2 goal

Links the most recent node in the chain to the given goal in the DAG.
Clears the builder's record of the current node and returns undef.

=cut

sub goal {
    my $self = shift or croak 'Need an instance';
    my $goal_name = shift or croak 'Need a goal name';
    croak "Need a node to link to the goal" unless $self->node;

    my $goal = $self->dag->goal($goal_name);
    $self->dag->add($self->node);   # no harm in it - DAG::add() is idempotent
    $self->dag->connect($self->node, $goal);

    $self->node(undef);     # Less likely to leak state between goals.

    return undef;   # undef: See comment in goal()
} #goal()

=head2 to

Connect one node to another, where both are wrapped in C<GraphBuilder>s.
Usage:

    $builder_1->to($builder_2);
        # No $builder_1->node has an edge to $builder_2->node

Returns C<undef>, because chaining would be ambiguous.  For example,
in the snippet above, would the chain continue from C<$builder_1> or
C<$builder_2>?

Does not change the state of either GraphBuilder.

=cut

sub to {
    my ($self, %args) = parameters('self', [qw(dest)], @_);
    croak 'Destination is not a ' . __PACKAGE__
        unless $args{dest}->DOES(__PACKAGE__);
    croak 'Cannot connect nodes from different graphs'
        if refaddr($self->dag) != refaddr($args{dest}->dag);

    $self->dag->connect($self->node, $args{dest}->node);
    return undef;
} #to()

=head1 STATIC FUNCTIONS

=head2 make_GraphBuilder

Given the name of a subroutine, wrap the given subroutine for use in a
GraphBuilder chain such as that shown in the L</SYNOPSIS>.  Usage:

    sub worker {
        my $graphbuilder = shift;
        ...
        return $node;   # Will automatically be linked into the chain
    }

    make_GraphBuilder 'worker';
        # now worker can take a DAG or GraphBuilder, and the
        # return value will be the GraphBuilder.

The C<worker> subroutine is called in scalar context.

=cut

sub _wrapper;

sub make_GraphBuilder {
    my $target = caller;
    my $funcname = shift or croak 'Need the name of the sub to wrap';   # yum

    install_modifier $target, 'around', $funcname, \&_wrapper;
} #make_GraphBuilder()

# The "around" modifier
sub _wrapper {
    my $orig = shift or die 'Need a function to wrap';
    croak "Need a parameter" unless @_;

    # Create the GraphBuilder if we don't have one already.
    my $self = shift;
    $self = __PACKAGE__->new(dag=>$self)
        unless eval { $self->DOES(__PACKAGE__) };
    croak "Parameter must be a DAG or Builder"
        unless eval { $self->dag->DOES('Data::Hopen::G::DAG') };

    unshift @_, $self;     # Put the builder on the arg list

    # Call the worker
    my $worker_retval = &{$orig};   # @_ passed to code

    # If we got a node, remember it.
    if(ref $worker_retval && eval { $worker_retval->DOES('Data::Hopen::G::Node') } ) {
        $self->dag->add($worker_retval);    # Link it into the graph
        $self->dag->connect($self->node, $worker_retval) if $self->node;

        $self->node($worker_retval);        # It's now our current node
    }

    return $self;
}; #_wrapper()

1;
__END__
# vi: set fdm=marker: #
