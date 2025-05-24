package Crop::Algorithm::TreeSortedPID::Tree;
use base qw/ Crop::Object::Sequence /;

=begin nd
Class: Crop::Algorithm::TreeSortedPID::Tree
=cut

use v5.14;
use warnings;

use Crop::Error;

=begin nd
Method: node_attr ( )
	Get attribute that presents node in tree.
	
	Pure virtual.
	
Returns:
	An error  - since has not redefined in subclass
	Attribute - if Ok
=cut
sub node_attr {
	my $self = shift;
	
	$self->Attributes->first(tree => 'node') or return warn 'ALGORITHM|ERR: No node for tree found';
}

1;
