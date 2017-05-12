package ArangoDB2::Traversal;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use Data::Dumper;
use JSON::XS;

my $JSON = JSON::XS->new->utf8;

my @PARAMS = qw(
    direction edgeCollection expander filter graphName init itemOrder maxDepth
    maxIterations minDepth order sort startVertex strategy uniqueness visitor
);

# direction
#
# get/ set direction
sub direction { shift->_get_set('direction', @_) }

# edgeCollection
#
# get/ set edgeCollection
sub edgeCollection { shift->_get_set('edgeCollection', @_) }

# execute
#
# POST /_api/traversal
sub execute
{
    my($self, $args) = @_;
    # process request args
    $args = $self->_build_args($args, \@PARAMS);
    # if neither edgeCollection or graphName is set then
    # use the current graph name
    $args->{graphName} = $self->graph->name
        unless defined $args->{graphName}
        or defined $args->{edgeCollection};
    # make request
    return $self->arango->http->post(
        $self->api_path('traversal'),
        undef,
        $JSON->encode($args),
    );
}

# expander
#
# get/ set expander
sub expander { shift->_get_set('expander', @_) }

# filter
#
# get/ set filter
sub filter { shift->_get_set('filter', @_) }

# graphName
#
# get/ set graphName
sub graphName { shift->_get_set('graphName', @_) }

# init
#
# get/ set init
sub init { shift->_get_set('init', @_) }

# itemOrder
#
# get/ set itemOrder
sub itemOrder { shift->_get_set('itemOrder', @_) }

# maxDepth
#
# get/ set maxDepth
sub maxDepth { shift->_get_set('maxDepth', @_) }

# maxIterations
#
# get/ set maxIterations
sub maxIterations { shift->_get_set('maxIterations', @_) }

# minDepth
#
# get/ set minDepth
sub minDepth { shift->_get_set('minDepth', @_) }

# order
#
# get/ set order
sub order { shift->_get_set('order', @_) }

# sort
#
# get/ set sort
sub sort { shift->_get_set('sort', @_) }

# startVertex
#
# get/ set startVertex
sub startVertex { shift->_get_set_id('startVertex', @_) }

# strategy
#
# get/ set strategy
sub strategy { shift->_get_set('strategy', @_) }

# uniqueness
#
# get/ set uniqueness
sub uniqueness { shift->_get_set('uniqueness', @_) }

# visitor
#
# get/ set visitor
sub visitor { shift->_get_set('visitor', @_) }

1;

__END__

=head1 NAME

ArangoDB2::Traversal - ArangoDB traversal API methods

=head1 DESCRIPTION

=head1 API METHODS

=over 4

=item execute

POST /_api/traversal

Perform traversal.  Returns API response.

=back

=head1 PROPERTY METHODS

=over 4

=item direction

Direction for traversal.
If set, must be either "outbound", "inbound", or "any.
If not set, the expander attribute must be specified

=item edgeCollection

(optional) name of the collection that contains the edges.

=item expander

body (JavaScript) code of custom expander function must be set if direction attribute is not set function signature: (config, vertex, path) -> array expander must return an array

=item filter

(optional, default is to include all nodes): body (JavaScript code) of custom filter function function signature: (config, vertex, path) -> mixed can return four different string values:

"exclude" -> this vertex will not be visited.

"prune" -> the edges of this vertex will not be followed.

"" or undefined -> visit the vertex and follow it's edges.

Array -> containing any combination of the above. If there is at least one "exclude" or "prune" respectivly is contained, it's effect will occur.

=item graphName

(optional) name of the graph that contains the edges. Either edgeCollection or graphName has to be given. In case both values are set the graphName is prefered.

=item init

body (JavaScript) code of custom result initialisation function function signature: (config, result) -> void initialise any values in result with what is required

=item itemOrder

(optional): item iteration order can be "forward" or "backward"

=item maxDepth

(optional, ANDed with any existing filters): visits only nodes in at most the given depth

=item maxIterations

(optional): Maximum number of iterations in each traversal. This number can be set to prevent endless loops in traversal of cyclic graphs. When a traversal performs as many iterations as the maxIterations value, the traversal will abort with an error. If maxIterations is not set, a server-defined value may be used.

=item minDepth

(optional, ANDed with any existing filters): visits only nodes in at least the given depth

=item order

(optional): traversal order can be "preorder" or "postorder"

=item sort

(optional): body (JavaScript) code of a custom comparison function for the edges. The signature of this function is (l, r) -> integer (where l and r are edges) and must return -1 if l is smaller than, +1 if l is greater than, and 0 if l and r are equal. The reason for this is the following: The order of edges returned for a certain vertex is undefined. This is because there is no natural order of edges for a vertex with multiple connected edges. To explicitly define the order in which edges on the vertex are followed, you can specify an edge comparator function with this attribute. Note that the value here has to be a string to conform to the JSON standard, which in turn is parsed as function body on the server side. Furthermore note that this attribute is only used for the standard expanders. If you use your custom expander you have to do the sorting yourself within the expander code.

=item startVertex

id of the startVertex, e.g. "users/foo".  You can pass either string or an ArangoDB2 object with an id attribute.

=item strategy

(optional): traversal strategy can be "depthfirst" or "breadthfirst"

=item uniqueness

(optional): specifies uniqueness for vertices and edges visited if set, must be an object like this: "uniqueness": {"vertices": "none"|"global"|path", "edges": "none"|"global"|"path"}

=item visitor

(optional): body (JavaScript) code of custom visitor function function signature: (config, result, vertex, path) -> void visitor function can do anything, but its return value is ignored. To populate a result, use the result variable by reference

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
