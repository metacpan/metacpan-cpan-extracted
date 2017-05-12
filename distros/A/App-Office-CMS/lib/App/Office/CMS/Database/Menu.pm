package App::Office::CMS::Database::Menu;

use Any::Moose;
use common::sense;

use Tree::DAG_Node::Persist;

extends 'App::Office::CMS::Database::Base';

has context =>
(
 is       => 'rw',
 isa      => 'Str',
 required => 0,
);

has table_name =>
(
 is       => 'ro',
 isa      => 'Str',
 required => 0,
 default  => 'menus',
);

# If Moose...
#use namespace::autoclean;

our $VERSION = '0.92';

# --------------------------------------------------

sub add
{
	my($self, $design, $tree, $extra) = @_;

	$self -> log(debug => 'add(..., $tree)');

	$self -> context($self -> db -> build_context($$design{site_id}, $$design{id}) );

	return $self -> save_menu_tree('add', $tree, $extra);

} # End of add.

# --------------------------------------------------

sub delete_node_by_id
{
	my($self, $id) = @_;

	$self -> log(debug => "delete_node_by_id($id)");

	return $self -> db -> simple -> delete('menus', {id => $id});

} # End of delete_node_by_id.

# --------------------------------------------------
# Warning: Do not add $self.

sub find_node_by_name
{
	my($node, $opt) = @_;
	my($result)     = 1;

	if ($node -> name eq $$opt{name})
	{
		$$opt{id}   = ${$node -> attribute}{id};
		$$opt{node} = $node;
		$result     = 0; # Short-circuit walking the tree.
	}

	return $result;

} # End of find_node_by_name.

# --------------------------------------------------

sub get_id_of_node
{
	my($self, $tree, $node) = @_;

	$self -> log(debug => 'get_id_of_node($tree, ' . $node -> name . ')');

	my($opt) =
	{
		callback => \&find_node_by_name,
		_depth   => 0,
		id       => 0,
		name     => $node -> name,
		node     => '',
	};

	$tree -> walk_down($opt);

	if (! $$opt{id})
	{
		my($s) = 'Cannot find that name in the tree';

		$self -> log(debug => $s);

		die $s;
	}

	return $$opt{id};

} # End of get_id_of_node.

# --------------------------------------------------

sub get_menu_by_context
{
	my($self, $context)  = @_;

	$self -> log(debug => "get_menu_by_context($context)");

	return
	Tree::DAG_Node::Persist -> new
		(
		 context    => $context,
		 dbh        => $self -> db -> dbh,
		 table_name => $self -> table_name,
		) -> read(['page_id']);

} # End of get_menu_by_context.

# --------------------------------------------------

sub get_node_by_name
{
	my($self, $tree, $name) = @_;

	$self -> log(debug => "get_node_by_name(..., $name)");

	my($opt) =
	{
		callback => \&find_node_by_name,
		_depth   => 0,
		id       => 0,
		name     => $name,
		node     => '',
	};

	$tree -> walk_down($opt);

	if (! $$opt{node})
	{
		my($s) = "Cannot find the name '$name' in the tree";

		$self -> log(debug => $s);

		die $s;
	}

	return $$opt{node};

} # End of get_node_by_name;

# --------------------------------------------------

sub pretty_print
{
	my($self, $message, $tree) = @_;

	$self -> log(debug => "traverse($message, ...)");

	$tree -> walk_down
		({
			callback => \&pretty_print_node,
			_depth   => 0,
			self     => $self,
		});

} # End of pretty_print.

# --------------------------------------------------
# Warning: Do not add $self.

sub pretty_print_node
{
	my($node, $opt) = @_;
	my($id) = ${$node -> attribute}{id} || '';

	$$opt{self} -> log(debug => ' ' x $$opt{_depth} . $node -> name . " ($id)");

	return 1;

} # End of pretty_print_node.

# --------------------------------------------------

sub save_menu_tree
{
	my($self, $context, $tree, $extra) = @_;

	$self -> log(debug => "save_menu_tree($context, ...)");

	my($manager) = Tree::DAG_Node::Persist -> new
		(
			context    => $self -> context, # Not $context.
			dbh        => $self -> db -> dbh,
			table_name => $self -> table_name,
		);

	$manager -> write($tree, $extra);

	$self -> log(debug => "Saved ($context) menu tree");

	# Return the tree so the nodes' ids are available to the caller.

	return $manager -> read;

} # End of save_menu_tree.

# --------------------------------------------------

sub update
{
	my($self, $design, $tree, $extra) = @_;

	$self -> log(debug => 'update(..., $tree, ...)');

	$self -> context($self -> db -> build_context($$design{site_id}, $$design{id}) );

	return $self -> save_menu_tree('update', $tree, $extra);

} # End of update.

# --------------------------------------------------

no Any::Moose;

# If Moose...
#__PACKAGE__ -> meta -> make_immutable;

1;
