package Crop::Object::Warehouse::Lang::SQL::Query::Select::Node::Cross;
use base qw/ Crop::Object::Warehouse::Lang::SQL::Query::Select::Node /;

=begin nd
Class: Crop::Object::Warehouse::Lang::SQL::Query::Select::Node::Cross
	Cross node.
=cut

use v5.14;
use warnings;

use Crop::Error;

use Crop::Debug;

=begin nd
Method: parse_row ($row)
	Handle row of the raw data from database and put object to the right place.
	
Parameters:
	$row - hashref to the entire row
=cut
sub parse_row {
	my ($self, $row) = @_;
	
	my $content = $self->{child}->First;
	$self->{parent}->make_collection(@{$content}{qw/ parent_view class /});
}

1;
