use 5.014;
use strict;
use warnings;

package Test::MyObject;
use base qw(Business::cXML::Object);

use XML::LibXML::Ferry;

use constant NODENAME => 'MyObject';
use constant PROPERTIES => (
	mandatorystring => 'default',
	optionalstring  => undef,
	items           => [],
	inside          => undef,
);
use constant OBJ_PROPERTIES => (
	inside => 'Business::cXML::Object',
);

sub from_node {
	my ($self, $el) = @_;
	$el->ferry($self, {});
}

sub to_node {
	my ($self, $doc) = @_;
	my $node = $doc->create($self->{_nodeName}, undef,
		mandatoryString => $self->{mandatoryString},
		optionalString  => $self->{optionalString},
	);
	$node->add('Item', $_) foreach (@{ $self->{items} });
	# don't use inside here
	return $node;
}

1;
