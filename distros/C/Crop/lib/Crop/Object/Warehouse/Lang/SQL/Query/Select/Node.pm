package Crop::Object::Warehouse::Lang::SQL::Query::Select::Node;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::Object::Warehouse::Lang::SQL::Query::Select::Node
	Node of parsed tree for a SELECT query.
	
	Node presents an object-table.
=cut

use v5.14;
use warnings;

use Crop::Object::Constants;
use Crop::Object::Collection;
use Crop::Util qw/ load_class /;
use Crop::Error;

use Crop::Debug;

=begin nd
Variable: our %Attributes
	Class members:

	attr            - array of stored attributes of a table
	cache           - exemplars of 'class'
	child           - Collection of childs in the tree
	class           - object class name
	clause          - <Crop::Object::Warehouse::Lang::SQL::Clause> or undef
	current         - last item from current table;
	object          - either result blessed or Collection for root
	parent          - parent node or undef for root
	parent_link     - hash of parent=>child fields to link parent table
	parent_view     - parent attribute to hold extended object
	pkey            - array of ordered attributes names that consist the primary key
	row_action      - special action at data-handle stage; PARENTINIT only initialize parent view
	table           - original table name
	table_effective - table name to used in JOIN
=cut
our %Attributes = (
	attr            => {mode => 'read'},
	cache           => {mode => 'read', default => {}},
	child           => {mode => 'read'},
	class           => {mode => 'read'},
	clause          => {mode => 'read/write'},
	current         => {mode => 'read/write'},
	object          => {mode => 'read/write'},
	parent          => {mode => 'read/write'},
	parent_link     => {mode => 'read'},
	parent_view     => {mode => 'read'},
	pkey            => {mode => 'read'},
	row_action      => {mode => 'read/write'},
	table           => {mode => 'read'},
	table_effective => {mode => 'read'},
);

=begin nd
Constructor: new (%attr)
	Calculate shared attributes.
	
Returns:
	$self - if ok
	undef - otherwise
=cut
sub new {
	my ($class, %attr) = @_;
	
	exists $attr{class} or return warn "OBJECT|CRIT: Constructor of Node requires a 'class'";
	
	$class->SUPER::new(
		class           => $attr{class},
		pkey            => [sort map $_->name, @{$attr{class}->Attributes(KEY)}],
		table           => $attr{class}->Table,
		table_effective => $attr{class}->Table,
		attr            => $attr{class}->Attributes(STORED),
		child           => Crop::Object::Collection->new(__PACKAGE__),
		%attr,
	);
}

=begin nd
Method: add_current ($item, $attrname)
	Add object from database to the node resulting set.
	
Parameters:
	$item     - object to add
	$attrname - target attribute
=cut
sub add_current {
	my ($self, $item, $attrname) = @_;
	
	$self->{current}{$attrname} = $item;
}

=begin nd
Method: fields ( )
	Get arrayref of each attribute prepended with table_effective.
	
Returns:
	string such 'mytab$attr_1'
=cut
sub fields {
	my $self = shift;
	
	[
		map "$self->{table_effective}." . $_->name . " AS $self->{table_effective}\$" . $_->name, @{$self->{attr}}
		
	];
}

=begin nd
Method: init_parent_view ( )
	Initialize parent view.

	Pure virtual.

Returns:
	error - in here
	$self - in subclass
=cut
sub init_parent_view {
	my $self = shift;
	my $class = ref $self;
	
	warn "DBASE: init_parent_view() must be redefined by subclass '$class'";
}

=begin nd
Method: make_collection ($view)
	Make a collection for $view.
	
	Pure virtual.
	
Parameters:
	$view - name of attribute
=cut
sub make_collection {
	my ($self, $view) = @_;
	my $class = ref $self;
	
	warn "OBJECT|CRIT: make_collection($view) for class '$class' is not implemented";
}

=begin nd
Method: parse_row ($row)
	Handle row of the raw data from database and put object to the right place.
	
	Virtual. Subclass could redefine this method.
	
Parameters:
	$row - hashref to the entire row
=cut
sub parse_row {
	my ($self, $row) = @_;
	my $class = ref $self;
	
	if ($class eq __PACKAGE__) {
		my $item = $self->{class}->new($row->{$self->{table_effective}})->Set_state(DWHLINK);
		$item->_Is_key_defined or return;

		# my $found_in_cache = $self->see_cache($item);
		
		# if ($found_in_cache) {
		# 	$item = $found_in_cache;
		# }

		$self->{current} = $item;
		$self->{parent}->add_current($item, $self->{parent_view});
	} else {
		warn "OBJECT|CRIT: parse_row() NOT IMPLEMENTED for class $class";
	}
}

=begin nd
Method: see_cache ($item)
	Look up cache for $item.
	
	If $item isn't in the cache, cache it.
	
Parameters:
	$item - item to lookup
	
Returns:
	cached item - if found
	undef       - otherwise
=cut
sub see_cache {
	my ($self, $item) = @_;

	my $found;

	my $cur = $self->{cache};
	for (my $i = 0; $i < @{$self->{pkey}}; ++$i) {
		my $val = $item->{$self->{pkey}[$i]};
		
		if ($i + 1 == @{$self->{pkey}}) {  # last index
			if (exists $cur->{$val}) {
				$found = $cur->{$val};  # Found!
			} else {
				$cur->{$val} = $item;  # put to cache
			}
		} else {
			if (exists $cur->{$val}) {
				$cur = $cur->{$val};
			} else {
				$cur->{$val} = {};
				$cur = $cur->{$val}
			}
		}
	}
	
	$found;
}

1;
