package Crop::Object::Warehouse::Lang::SQL::Query::Select::Node::Root;
use base qw/ Crop::Object::Warehouse::Lang::SQL::Query::Select::Node /;

=begin nd
Class: Crop::Object::Warehouse::Lang::SQL::Query::Select::Node::Root
	Root node.
=cut

use v5.14;
use warnings;

use Crop::Error;
use Crop::Object::Constants;
use Crop::Object::Collection;

use Crop::Debug;

=begin nd
Variable: our %Attributes
	Class members:

	object - Collection of root items; is the result of entire work of the 'All()' method.
=cut
our %Attributes = (
	object => {mode => 'read'},
);

=begin
Constructor: new (%in)
	Initiate object store.
	
Returns:
	$self - if ok
	undef - otherwise
=cut
sub new {
	my ($class, %in) = @_;
	
	my $self = $class->SUPER::new(%in) or return warn "OBJECT|CRIT: Constructor of Node::Root fails";
	
	$self->{object} = Crop::Object::Collection->new($in{class});
	
	$self;
}

=begin nd
	Make a collection for $view.
	
Parameters:
	$view       - name of attribute
	$item_class - collection class
=cut
sub make_collection {
	my ($self, $view, $item_class) = @_;
 	
	$self->{current}{$view} = Crop::Object::Collection->new($item_class) unless $self->{current}{$view};
}

=begin nd
Method: parse_row ($row)
	Handle row of the raw data from database and put object to the right place.
	
Parameters:
	$row - hashref to the entire row
=cut
sub parse_row {
	my ($self, $row) = @_;
	
	my $item = $self->{class}->new($row->{$self->{table_effective}})->Set_state(DWHLINK);
	$item->_Is_key_defined or return;

	my $found_in_cache = $self->see_cache($item);
	
	if ($found_in_cache) {
		$item = $found_in_cache;
	} else {
		$self->{object}->Push($item);
	}

	$self->{current} = $item;
}

1;
