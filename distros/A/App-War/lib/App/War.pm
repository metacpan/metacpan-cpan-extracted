package App::War;
use strict;
use warnings FATAL => 'all';
use Graph;
use List::Util 'shuffle';

our $VERSION = 0.05;

=pod

=head1 NAME

App::War - turn one big decision into many small decisions

=head1 SYNOPSIS

    use App::War;
    my $war = App::War->new;
    $war->items(qw/ this that the-other that-too /);
    $war->init;
    $war->rank;
    print $war->report;

=head1 DESCRIPTION

How do you go about ranking a number of items?  One way to do it is to
compare the objects two at a time until a clear winner can be established.

This module does just that, using a topological sort to establish a unique
ordering of all the "combatants" in the "war".

This module is modeled loosely after L<http://kittenwar.com/>, a
crowdsourced web application for determining the cutest kitten in the
universe.

=head1 METHODS

=head2 App::War->new()

Constructs a new war object.

=cut

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    return $self;
}

=head2 $war->run

Starts the war.

=cut

sub run {
    my $self = shift;
    $self->init;
    $self->rank;
}

=head2 $war->init

Uses the content of C<< $self->items >> to initialize a graph containing
only vertices, one per item.

=cut

# NOTE: calling '$self->graph->add_vertex' breaks in strange
# and mysterious ways.  Why does this fix it?

sub init {
    my $self = shift;
    my @items = $self->items;
    $self->_info("Ranking items: @items");
    my $g = $self->graph;
    for my $i (0 .. $#items) {
        # Why does this not work?
        # $self->graph->add_vertex($i);
        $g->add_vertex($i);
    }
    return $self;
}

=head2 $war->report

Returns the current state of the war graph as a multiline string.

=cut

sub report {
    my $self = shift;
    my @out;
    push @out, "graph: @{[ $self->graph ]}\n";
    my @items = $self->items;
    my @ts = map { $items[$_] } $self->graph->topological_sort;
    push @out, "sort: @ts\n";
    return join q(), @out;
}

=head2 $war->graph

Returns the graph object that stores the user choices.

=cut

sub graph {
    my $self = shift;
    unless (exists $self->{graph}) {
        $self->{graph} = Graph->new(directed => 1);
    }
    return $self->{graph};
}

=head2 $war->items

Get/set the items to be ranked.  It's a bad idea to modify this once the
war has started.

=cut

sub items {
    my $self = shift;
    $self->{items} ||= [];
    if (@_) {
        $self->{items} = [shuffle @_];
    }
    return @{ $self->{items} };
}

=head2 $war->rank

Starts the process of uniquely ordering the graph vertices.  This method
calls method C<tsort_not_unique> until it returns false, I<i.e.> we have a
unique topo sort.

=cut

sub rank {
    my $self = shift;
    while (my $v = $self->tsort_not_unique) {
        $self->compare($v->[0], $v->[1]);
    }
    return $self;
}

=head2 $war->tsort_not_unique

This method returns a true value (more on this later) if the graph
currently lacks a unique topo sort.  If the graph B<has> a unique sort, the
"war" is over, and results should be reported.

If the graph B<lacks> a unique topological sort, this method returns an
arrayref containing a pair of vertices that have an ambiguous ordering.
From L<http://en.wikipedia.org/wiki/Topological_sorting>:

=over 4

If a topological sort has the property that all pairs of consecutive
vertices in the sorted order are connected by edges, then these edges form
a directed Hamiltonian path in the DAG. If a Hamiltonian path exists, the
topological sort order is unique; no other order respects the edges of the
path.

=back

This property of the topological sort is used to ensure that we have a
unique ordering of the "combatants" in our "war".

=cut

sub tsort_not_unique {
    my $self = shift;

    # search for unordered items by calculating the topological sort and
    # verifying that adjacent items are connected by a directed edge

    my @ts = $self->graph->topological_sort;

    for my $i (0 .. $#ts - 1) {
        my ($u,$v) = @ts[$i,$i+1];
        if (!$self->graph->has_edge($u,$v)) {
            return [$u,$v];
        }
    }
    return 0;
}

=head2 $war->compare($index1,$index2)

Handles user interaction choosing one of two alternatives.  Arguments
C<$index1> and C<$index2> are indexes into the internal array of items to
be ranked, and indicate the two items that need to have their rank
disambiguated.

=cut

sub compare {
    my ($self,@x) = @_;
    my @items = $self->items;
    my $response = $self->_get_response(@items[@x]);
    if ($response =~ /1/) {
        $self->graph->add_edge($x[0],$x[1]);
    }
    else {
        $self->graph->add_edge($x[1],$x[0]);
    }
}

sub _get_response {
    my ($self,@items) = @_;
    print "Choose one of the following:\n";
    print "<1> $items[0]\n";
    print "<2> $items[1]\n";
    (my $resp = <STDIN>) =~ y/12//cd;
    return $resp;
}

sub _info {
    my $self = shift;
    if ($self->{verbose}) {
        warn "@_\n";
    }
}

=head1 AUTHOR

John Trammell, C<< <johntrammell@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-war at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-War>.  I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::War

Your operating system may also have installed a manual page for this
module; it would likely be available via the command

    man war

You can also look for information at:

=over 4

=item * GitHub

L<http://github.com/trammell/app-war>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-War>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-War>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-War>

=item * Search CPAN

L<http://search.cpan.org/dist/App-War/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 John Trammell, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

'BOOYA!';

