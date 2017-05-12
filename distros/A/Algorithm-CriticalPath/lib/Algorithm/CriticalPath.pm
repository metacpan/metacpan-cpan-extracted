package Algorithm::CriticalPath;

use 5.010;
use Mouse;



=head1 NAME

Algorithm::CriticalPath - Perform a critical path analysis over a Graph Object, by Ded MedVed

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


use Graph;
use Carp;
use Data::Dumper;

has 'graph' => (
    is              => 'ro'
,   isa             => 'Graph'
,   required        => 1
);

has 'vertices' => (
    is  => 'rw'
,   isa => 'ArrayRef[Str]'
);
has 'cost' => (
    is  => 'rw'
,   isa => 'Num'
);


sub BUILD {
    
    my ($self) = @_;

    if (  ! defined $self->graph()
       || $self->graph()->has_a_cycle()
       || $self->graph()->is_pseudo_graph()
       || $self->graph()->is_refvertexed()
       || $self->graph()->is_undirected()
       || $self->graph()->is_multiedged()
       || $self->graph()->is_multivertexed()
       ) 
       {
        croak 'Invalid graph type for critical path analysis' ;
       } ;

    # this is ropey - should use guaranteed unique names
    my $start = 'GCP::dummyStart';
    my $end   = 'GCP::dummyEnd';


    # this is ropey, should use a BFS search method to return the depth-ordered rankings of vertices.
    my $g = $self->graph()->deep_copy();
    my @rank;
    my $i = 0 ;
    while ( $g->vertices() > 0 ) {

        @{$rank[$i]} = $g->source_vertices();
        push @{$rank[$i]}, $g->isolated_vertices();

        for my $s (@{$rank[$i]})  {
            $g->delete_vertex($s);
        }
        $i++;
    }

    # $copy adds in the dummy start and end nodes, so we don't destroy the original.
    my $copy = $self->graph()->deep_copy();
    $copy->add_weighted_vertex($start,0);
    $copy->add_weighted_vertex($end,0);

    for my $n ($copy->source_vertices()) {
        $copy->add_edge($start, $n);
    }
    for my $n ($copy->sink_vertices()) {
        $copy->add_edge($n,$end);
    }

    for my $n ($copy->isolated_vertices()) {
        $copy->add_edge($start, $n);
        $copy->add_edge($n,$end);
    }

    unshift @rank, [$start];
    push    @rank, [$end];

    my %costToHere = map { $_ => 0 } $copy->vertices();

    my %criticalPathToHere;
    $criticalPathToHere{$start} = [$start];

    for my $row ( @rank ) {
        for my $node ( @$row ) {
            for my $s ( $copy->successors($node) ) {
                if ( $costToHere{$node} + $copy->get_vertex_weight($s) > $costToHere{$s} ) { 
                    $costToHere{$s}                     = $costToHere{$node} + $copy->get_vertex_weight($s);
                    @{$criticalPathToHere{$s}}          = @{$criticalPathToHere{$node}};
                    push @{$criticalPathToHere{$s}}, $s;
                }
            }
        }
    }

    # we don't want to see the dummy nodes on the returned critical path.
    @{$criticalPathToHere{$end}} = grep { $_ ne ${start} && $_ ne ${end} } @{$criticalPathToHere{$end}} ;

    $self->vertices(\@{$criticalPathToHere{$end}});
    $self->cost($costToHere{$end});

        
} ;

__PACKAGE__->meta->make_immutable();


1; 
__DATA__



=head1 SYNOPSIS

Performs a critical path analysis of a DAG where the vertices have costs, and the edges do not.
All costs are assumed positive.  Dummy Start and End nodes are used internally to aid the analysis.

The constructor takes a pre-constructed Graph object with weighted vertices and simple directed edges.  The Graph object is embedded
in the Algorithm::CriticalPath object as a readonly attribute, and cannot be updated once the Algorithm::CriticalPath object has been constructed.  
The two accessor attributes are 'rw', as I haven't found an easy way to default them from the constructor. They should be 'ro', i.e. not modifiable
once set by the constructor.

The module checks that the passed-in Graph object is directed, non-cyclic, and simply connected, without multi-vertices and without multi-edges.

The module has been written on the assumption that no existing CPAN module performs this task.


=head1 METHODS

=head2 C<new>

=over 4

=item * C<< Algorithm::CriticalPath->new() >>

Creates and returns a new Algorithm::CriticalPath object. 

    my $g = Graph->new(directed => 1);
    $g->add_weighted_vertex('Node1', 1);
    $g->add_weighted_vertex('Node2', 2);
    $g->add_edge('Node1','Node2');
    $g->add_weighted_vertex('Node3', 0.5);
    $g->add_edge('Node1','Node3');
    
    my $cp = Algorithm::CriticalPath->new( {graph => $g} );


=back


=head2 C<vertices>

=over 4

=item * C<< $g->vertices() >>

This returns the critical path as an array of node names.

    my $g = Graph->new(directed => 1);
    $g->add_weighted_vertex('Node1', 1);
    $g->add_weighted_vertex('Node2', 2);
    $g->add_edge('Node1','Node2');
    $g->add_weighted_vertex('Node3', 0.5);
    $g->add_edge('Node1','Node3');
    
    my $cp = Algorithm::CriticalPath->new( {graph => $g} );
    my @orderednodes = $cp->vertices();

    
=back    

=head2 C<cost>

=over 4

=item * C<< $g->cost() >>

This returns the critical path cost.

    my $g = Graph->new(directed => 1);
    $g->add_weighted_vertex('Node1', 1);
    $g->add_weighted_vertex('Node2', 2);
    $g->add_edge('Node1','Node2');
    $g->add_weighted_vertex('Node3', 0.5);
    $g->add_edge('Node1','Node3');
    
    my $cp = Algorithm::CriticalPath->new( {graph => $g} );
    my $cost = $cp->cost();

    
=back    


=head1 AUTHOR

Ded MedVed, C<< <dedmedved at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-algorithm-criticalpath at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-CriticalPath>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::CriticalPath


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-CriticalPath>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Algorithm-CriticalPath>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Algorithm-CriticalPath>

=item * Search CPAN

L<http://search.cpan.org/dist/Algorithm-CriticalPath/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Ded MedVed.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Algorithm::CriticalPath
