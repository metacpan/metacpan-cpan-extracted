use strict;
use warnings;

package Data::ZPath::_Ctx;

use Data::ZPath::Node;
use Scalar::Util qw(blessed);

our $VERSION = '0.001000';

sub new {
	my ( $class, $root ) = @_;

	my $root_node;
	if ( blessed($root) and $root->isa('Data::ZPath::Node') ) {
		$root_node = $root;
	}
	else {
		$root_node = Data::ZPath::Node->from_root($root);
	}

	return bless {
		root      => $root_node,
		nodeset   => [$root_node],
		parentset => undef,
	}, $class;
}

sub with_nodeset {
	my ( $self, $nodeset, $parentset ) = @_;
	return bless {
		%$self,
		nodeset   => $nodeset,
		parentset => $parentset,
	}, ref($self);
}

sub root      { $_[0]->{root} }
sub nodeset   { $_[0]->{nodeset} }
sub parentset { $_[0]->{parentset} }

1;
