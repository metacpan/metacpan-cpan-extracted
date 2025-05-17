package Crop::Object::Extern::Content;
use base qw / Crop::Object::Extern /;

=begin nd
Class: Crop::Object::Extern::Content
	Link many-to-many.
	
	Class that contains 'Content' declaration has a semantics 'main'. And this class presents 'table' content
	with multiple strings.
	
	(start code)
	# Product has the order schema My::Order, My::Product, My::Order::Product
	# Order class has EXT
	product => {
		cross => [
			type  => 'content',
			'My::Order::Product' => {id         => 'id_order'},
			'My::Product'        => {id_product => 'id'}
		],
		view  => 'product',
	},
	(end code)
=cut

use v5.14;
use warnings;

use Crop::Error;
use Crop::Util 'load_class';
use Crop::Object::Constants;
use Crop::Object::Warehouse::Lang::SQL::Query::Select::Node::Cross;
use Crop::Object::Warehouse::Lang::SQL::Query::Select::Node::Content;

use Crop::Debug;

=begin nd
Variable: our %Attributes
	Class attributes:
	
	cross - link definition
	view  - cached attribute where reuslt goes to
=cut
our %Attributes = (
	cross => undef,
	view  => {mode => 'read'},
);

=begin nd
Method: make_link ($parent)
	Create node and link it to the $parent.

	The 'clause' attribute of new node will not be established. Calling code musth to do that work.
	
	Returns the 'content' node since calling code could set the 'clause' attribute for it. And the 'content'
	attribute is the 'bottom' child of two new nodes.
	
Parameters:
	$parent - parent node
	
Returns:
	'content' node - if ok
	undef          - otherwise

=cut
sub make_link {
	my ($self, $parent) = @_;
	
	my ($cross_class, $cross_bind, $content_class, $content_bind) = @{$self->{cross}};
	
	load_class $cross_class   or return warn "OBJECT|CRIT: Can not parse declaration for non-existing class $cross_class";
	load_class $content_class or return warn "OBJECT|CRIT: Can not parse declaration for non-existing class $content_class";

	my $cross_node = Crop::Object::Warehouse::Lang::SQL::Query::Select::Node::Cross->new(
		class       => $cross_class,
		parent      => $parent,
		parent_link => $cross_bind,
	);
	
	$parent->child->Push($cross_node);
	
	$parent = $cross_node;
	my $content_node = Crop::Object::Warehouse::Lang::SQL::Query::Select::Node::Content->new(
		class           => $content_class,
		parent          => $parent,
		parent_link     => $content_bind,
		parent_view     => $self->{view},
	);
	$parent->child->Push($content_node);

	$content_node;
}

1;
