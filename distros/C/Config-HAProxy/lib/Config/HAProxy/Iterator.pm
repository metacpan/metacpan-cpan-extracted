package Config::HAProxy::Iterator;
use strict;
use warnings;
use Config::HAProxy::Node;
use Carp;

use constant {
    NO_RECURSION => 0,
    INORDER => 1,
    POSTORDER => 2
};

sub new {
    my $class = shift;
    my $node = shift;
    my $self = bless { }, $class;
    if ($node->is_section) {
	$self->{_list} = [ $node->tree() ];
    } else {
	$self->{_list} = [ $node ];
    }
    local %_ = @_;
    if (defined($_{recursive})) {
	$self->{_recursive} = $_{recursive};
    } elsif ($_{inorder}) {
	$self->{_recursive} = INORDER;
    } elsif ($_{postorder}) {
	$self->{_recursive} = POSTORDER;
    } else {
	$self->{_recursive} = NO_RECURSION;
    }
    return $self;
}

sub recursive  { shift->{_recursive} }
sub inorder  { shift->{_recursive} == INORDER }
sub postorder { shift->{_recursive} == POSTORDER } 

sub next {
    my $self = shift;

    if ($self->{_itr}) {
	if (defined(my $v = $self->{_itr}->next())) {
	    return $v;
	} else {
	    delete $self->{_itr};
	    return $self->{_cur} if $self->postorder;
	}
    }

    if (defined($self->{_cur} = shift @{$self->{_list}})) {
	if ($self->recursive && $self->{_cur}->is_section) {
	    $self->{_itr} = $self->{_cur}->iterator(recursive => $self->recursive);
	    if ($self->inorder) {
		return $self->{_cur};
	    } else {
		return $self->next();
	    }
	}
    }

    return $self->{_cur};
}

1;
__END__
    
=head1 NAME

Config::HAProxy::Iterator - Iterate over objects in the parse tree

=head1 SYNOPSIS

    $cfg = Config::HAProxy->new->parse;    
    $itr = $cfg->iterator(inorder => 1);
    while (defined(my $node = $itr->next)) {
        # Do something with $node
    }

=head1 DESCRIPTION

The iterator object provides a method for iterating over all nodes in the
HAProxy parse tree. The object is returned by the B<iterator> method of
B<Config::HAProxy> and B<Config::HAProxy::Node> objects. The method takes
as optional argument the keyword specifying the order in which the tree nodes
should be traversed. This keyword can be one of the following:

=over 4

=item B<recursive =E<gt> 0>

No recursion. The traversal will not descend into section nodes. This is the
default.    
    
=item B<inorder =E<gt> 1>

The nodes will be traversed in the inorder manner, i.e. the section node
will be visited first, and all its sub-nodes after it.    

=item B<postorder =E<gt> 1>

The nodes will be traversed in the postorder manner, i.e. for each section
node, its sub-nodes will be visited first, and the node itself afterward.

=back

=head1 CONSTRUCTOR

Note: This section is informative. You never need to create
B<Config::HAProxy::Iterator> objects explicitly. Please use the B<iterator>
method of B<Config::HAProxy> or B<Config::HAProxy::Node> class objects.

    $itr = new Config::HAProxy::Iterator($node, %rec);

Returns new iterator object for traversing the tree starting from B<$node>,
which must be a B<Config::HAProxy::Node> object. Optional B<%rec> is one of
the keywords discussed above, in section B<DESCRIPTION>.    
    
=head1 METHODS

=head2 next

    $node = $itr->next;

Returns next node in the traversal sequence. If all nodes were visited, returns
B<undef>.

=head1 SEE ALSO

B<HAProxy::Config>, B<HAProxy::Config::Node>.

=cut    
    

	    

	
