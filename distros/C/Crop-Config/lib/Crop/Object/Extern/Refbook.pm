package Crop::Object::Extern::Refbook;
use base qw / Crop::Object::Extern /;

=begin nd
Class: Crop::Object::Extern::Refbook
	Link one-to-many in 'many' side.
	
	For example: User is borned in City. Many Users could have one City.
	Bob & Alice is born in London, so a selected user Bob is from London.
	
	Is assumed the record in Refbook is always presences. 
	
	(start code)
	our %Attributes = (
		#user name
		name    => undef,
		id_city => {key => 'extern'},
		city    => {type => 'cache'},
		EXT => {
			city => {
				type  => 'refbook',
				class => 'City',
				xattr => {id_city => 'id'},
				view  => 'city',
			},
		},
	);
	(end code)
=cut

use v5.14;
use warnings;

use Crop::Error;
use Crop::Util 'load_class';
use Crop::Object::Constants;
use Crop::Object::Warehouse::Lang::SQL::Query::Select::Node;

=begin nd
Variable: our %Attributes
	Class attributes:
	
	class - class of extended object
	view  - cached attribute where reuslt goes to
	xattr - hash of corresponding attributes of extern key base=>ext
=cut
our %Attributes = (
	class => {mode => 'read'},
	view  => {mode => 'read'},
	xattr => {mode => 'read'},
);

=begin nd
Method: make_link ($parent)
	Create node and link it to the $parent.
	
	The 'clause' attribute of new node will not be established. Calling code musth to do that work.
	
Parameters:
	$parent - parent node
	
Returns:
	new node - if ok
	undef    - otherwise
=cut
sub make_link {
	my ($self, $parent) = @_;

	my $class = $self->{class};
	load_class($class) or return warn "OBJECT|CRIT: Can not parse declaration for non-existing class $class";

	my $node = Crop::Object::Warehouse::Lang::SQL::Query::Select::Node->new(
		class           => $class,
		table           => $class->Table,
		table_effective => $class->Table,
		attr            => $class->Attributes(STORED),
# 		clause          => $clause,  # should be calculated by calling code
		parent          => $parent,
		parent_link     => $self->{xattr},
		parent_view     => $self->{view},
	);
	
	$parent->child->Push($node);
	
	$node;
}

1;
