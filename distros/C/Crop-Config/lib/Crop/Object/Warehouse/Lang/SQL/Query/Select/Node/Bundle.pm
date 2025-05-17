package Crop::Object::Warehouse::Lang::SQL::Query::Select::Node::Bundle;
use base qw/ Crop::Object::Warehouse::Lang::SQL::Query::Select::Node /;

=begin nd
Class: Crop::Object::Warehouse::Lang::SQL::Query::Select::Node::Bundle
	Bundle node.
=cut

use v5.14;
use warnings;

use Crop::Object::Constants;
use Crop::Object::Collection;

use Crop::Debug;

=begin nd
Method: init_parent_view ( )
	Initialize parent view.

	Set up <Crop::Object::Collection> in parent view.
Returns:
	$self
=cut
sub _init_parent_view {
	my $self = shift;

	$self->{parent}{current}{$self->{parent_view}} //= Crop::Object::Collection->new($self->{class});
}

=begin nd
Method: parse_row ($row)
	Handle row of the raw data from database and put object to the right place.
	
Parameters:
	$row - hashref to the entire row
	
Returns:
	new node - default action
=cut
sub parse_row {
	my ($self, $row) = @_;
	
	$self->_init_parent_view;
	
	my $item = $self->{class}->new($row->{$self->{table_effective}})->Set_state(DWHLINK);
	$item->_Is_key_defined or return;
	
	# my $found_in_cache = $self->see_cache($item);
	# $item = $found_in_cache if $found_in_cache;

	$self->{parent}{current}{$self->{parent_view}}->Push($item);
	$self->{current} = $item;
}

1;
