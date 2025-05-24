package Crop::Object::Warehouse::Lang::SQL::Query::Select::Node::Content;
use base qw/ Crop::Object::Warehouse::Lang::SQL::Query::Select::Node /;

=begin nd
Class: Crop::Object::Warehouse::Lang::SQL::Query::Select::Node::Content
	Content node.
=cut

use v5.14;
use warnings;

use Crop::Object::Constants;

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
	}
	
	$self->{parent}{parent}{current}{$self->{parent_view}}->Push($item);
	$self->{current} = $item;
}

1;
