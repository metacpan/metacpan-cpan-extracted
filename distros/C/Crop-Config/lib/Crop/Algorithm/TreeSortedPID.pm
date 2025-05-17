package Crop::Algorithm::TreeSortedPID;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::Algorithm::TreeSortedPID
	Tree based on pid-n structure.
=cut

use v5.14;
use warnings;

use Crop::Debug;
use Crop::Error;
use Crop::Util 'load_class';
use Crop::Object::Collection;

=begin nd
Constant: ROOT
	ID of Root of directory tree
=cut
use constant {
	ROOT => 0,  # Root of directory tree
};

=begin nd
Variable: our %Attributes
	Class attributes:

	item - is NOT a node, but an item with useful data
	tree - the tree storage
=cut
our %Attributes = (
	item => undef,  # My::Doc::Dir
	tree => undef,  # My::Doc::Tree::SortedPID
);

=begin nd
Constructor: new ( )
	Load required classes for tree-class and item-class.

Returns:
	$self - if ok
	undef - otherwise
=cut
sub new {
	my $class = shift;
	
	my $self = $class->SUPER::new(@_);
	
	load_class $self->{$_} or return warn "OBJECT|CRIT: Can not load class $self->{$_}" for qw/ tree item /;
	
	$self;
}

=begin nd
Method: childs ($parent)
	Get the childs of $pid sorted by 'n' with item data.
	
Parameters:
	$parent - parent node of tree; or ROOT unless exists
	
Returns:
	Collection of nodes with items extended
=cut
sub childs {
	my ($self, $parent) = @_;
	my $pid = $parent ? $parent->id : ROOT;
	
	my $dir = $self->{tree}->All(pid => $pid, SORT => ['n']);

	my $node_method = $self->{tree}->node_attr->name;
	
	my $itemdir = $self->{item}->All(id => [keys %{$dir->Hash($node_method)}]);
	
	my $dir_sorted = Crop::Object::Collection->new($self->{item});
	for ($dir->List) {
		my $item = $itemdir->First(id => $_->$node_method);
		$dir_sorted->Push($item) if $item->visible;
	}
	
	$dir_sorted;
}

=begin nd
Method: path (@path)
	Get List of tree items that present a @path.
	
Parameters:
	@path - array of strings where string is a name of node (directory)
	
Returns:
	list of objects that present path - if Ok
	undef                             - in case of error
=cut
sub path {
	my ($self, @path) = @_;
	
	my $breadcrumbs = Crop::Object::Collection->new($self->{item});
	my $pid = ROOT;
	for (@path) {
		my $childs = $self->{tree}->All(pid => $pid, SORT => ['n']);
		my $hash = $childs->Hash($self->{tree}->node_attr->name);
		my @content_ids = keys %$hash;
		my $inner_dirs = $self->{item}->All(id => \@content_ids, visible => 1);
		my $next = $inner_dirs->First(href => $_) or return warn "NODIR: Document directory not found";
		
		$breadcrumbs->Push($next);
		
		$pid = $next->id;
	}
	
	$breadcrumbs;
}

1;
