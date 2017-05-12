package CatalystX::NavigationMenu;

use strict;
use warnings;

use Moose;
use CatalystX::NavigationMenuItem;
use namespace::autoclean;

=head1 NAME

CatalystX::NavigationMenu

=head1 SYNOPSIS

	my $nm = CatalystX::NavigationMenu->new();
	$nm->popupate($c);

	my $menu = $nm->get_navigation($c, {level => 0});

=head1 DESCRIPTION

CatalystX::NavigationMenu provides a menu object to be used when creating and
managing menus in Catalyst based on attribute data. For details of the Catalyst
attributes see the L(Catalyst::Plugin::Navigation) documentation.

=cut 

has items => (
	traits => ['Array'],
	is => 'rw',
	isa => 'ArrayRef[CatalystX::NavigationMenuItem]',
	default => sub{[]},
	handles    => {
		all_items    => 'elements',
		insert_item  => 'push',
		shift_item   => 'shift',
		find_item    => 'first',
		count_items  => 'count',
		has_items    => 'is_empty',
		sort_items   => 'sort',
	},
);

=head1 METHODS

=head2 populate($c)

Populates the menu based on the controllers found in the Catalyst object.

=cut

sub populate {
	my ($self, $c) = @_;

	my $dispatcher = $c->dispatcher;
	foreach my $c_name ($c->controllers(qr//)) {
		my $controller = $c->controller($c_name);
		my @actions = $dispatcher->get_containers($controller->action_namespace($c));
		$c->log->debug("Looking at Controller $c_name for navigation entries") if $c->debug;

		foreach my $ac (@actions) {
			my $acts = $ac->actions;
			foreach my $key (keys(%$acts)) {
				my $action = $acts->{$key};
				if ($action->attributes->{Menu}) {
					# And get the menu to insert it into the right location.
					$c->log->debug("Adding action item for path: " . ($action->namespace || '') . '/' . ($action->name || '') . " with parent: " . 
						($action->attributes->{MenuParent}->[0] || '') ) if $c->debug;
					$self->add_action($action);
				}
			}
		}
	}
}

=head2 add_action($action)

Adds an element into the menu based on the Catalyst action provided.

=cut

sub add_action {
	my ($self, $action) = @_;

	# Create the items needed to build the item.
	my $parent = $action->attributes->{MenuParent}->[0] || '';
	my $action_args = $action->attributes->{MenuArgs} || [];
	my $conditions = $action->attributes->{MenuCond} || [];
	my $order = $action->attributes->{MenuOrder}->[0] || 0;
	my $roles = $action->attributes->{MenuRoles} || [];
	my $title = $action->attributes->{MenuTitle}->[0] || '';

	my $item = CatalystX::NavigationMenuItem->new(
		label => $action->attributes->{Menu}->[0],
		title => $title,
		action => $action, 
		path => $action->namespace . '/' . $action->name,
		parent => $parent,
		action_args => $action_args,
		conditions => $conditions,
		order => $order,
		required_roles => $roles,
	);

	$self->add_item($item);
}

=head2 get_child_with_path($path)

Returns a child NavigationMenu item that contains the given path. If no child is found
then undef is returned.

=cut

sub get_child_with_path {
	my ($self, $path) = @_;

	return $self->find_item(sub {$_->contains_path($path)});
}

=head2 add_item($item)

Adds the given menu item to this tree under the appropriate path entry. If the path
entry isn't found then it is added to this tree.

=cut

sub add_item {
	my ($self, $item) = @_;

	# Check to see if we have already added this item.
	my $path = $item->path;
	my $d_item = $self->get_child_with_path($path);
	if ($d_item) {
		return;
	};


	# See if we have an item with 
	my $p_item = $self->get_child_with_path($item->parent);
	if ($p_item) {
		$p_item->add_item($item);
	}
	else {
		if ($item->parent =~ /#/) {
			my @path_parts = split(/(?=#)/, $item->parent);

			my $parent_path = shift(@path_parts);
			# See if we can find the parent for the first part of the path.
			$p_item = $self->get_child_with_path($parent_path);
			if ($p_item) {
				# We have a parent.
				$item->_set_parent(join('', @path_parts));
			}
			else {
				if ($parent_path =~ /^#/) {
					# The parent path is just a label. so create a dummy item.
					$p_item = CatalystX::NavigationMenuItem->new(
						label => $', #The label is everything after the # in the path.
						parent => '', # No parent item.
						path => $parent_path,
					);
				}
				else {
					# We need to create a new container item
					my $label = $path_parts[0];
					$label =~ s/^#//;
					$p_item = CatalystX::NavigationMenuItem->new(
						label => $label, 
						parent => $parent_path,
						path => $label,
					);
				}
				$item->_set_parent(join('', @path_parts));
				$self->add_item($p_item);
			}
			$p_item->add_item($item);
		}
		else {
			# Add the parent item to this menu.
			$self->insert_item($item);
		}
	}

	# Now check to see if there are any children in this menu that need to be
	# added as children of this new item.
	my $child_count = $self->count_items;
	for (my $i = 0; $i < $child_count; $i++) {
		my $child = $self->shift_item;
		if ($child->parent eq $item->path) {
			$item->add_item($child);
		}
		else {
			$self->insert_item($child);
		}
	}
}

=head2 get_navigation($c, $attrs)

Returns an array reference to a menu entry. This will only show one level of a
menu. The values of the array are the values returned by the L(NavigationMenuItem)
nav_entry() method.

=cut

sub get_navigation {
	my ($self, $c, $attrs) = @_;

	my $nav = [];

	# see if we need to get a particular level of menu or not.
	if ($attrs && exists($attrs->{level}) && $attrs->{level} =~ /^\d+$/) {
		if ($attrs->{level} == '0') {
			# We want this menu only.
			foreach my $i ($self->sorted_items) {
				my $entry = $i->nav_entry($c, 0);
				push(@$nav, $entry) if ($entry);
			}
		}
		else {
			my $path = $c->action->namespace . '/' . $c->action->name;
			my $active = $self->get_child_with_path($path);
			if ($active && $active->has_children) {
				$attrs->{level}--;
				return $active->children->get_navigation($c, $attrs);
			}
		}
	}
	else {
		foreach my $i ($self->sorted_items) {
			my $entry = $i->nav_entry($c, 1);
			push(@$nav, $entry) if ($entry);
		}
	}

	return $nav;
}

=head2 sorted_items

Returns the menu items found at this level in sorted order. The sort order is
based on their order value and an alphanumeric sort of the menu label.

=cut

sub sorted_items {
	my ($self) = @_;

	return $self->sort_items(sub {
		if ($_[0]->order == $_[1]->order) {
			# We need to do a name sort on the label then.
			return $_[0]->path cmp $_[1]->path;
		}
		
		return $_[0]->order <=> $_[1]->order;
	});
}

=head2 get_hierarchy([$indent])

Returns a string containing the hierachy of the complete menu found here. This is 
mostly used for debugging that menus are setup correctly.

=cut

sub get_hierarchy {
	my ($self, $indent) = @_;

	my $str = '';
	$indent = '' if (!$indent);

	foreach my $item ($self->all_items) {
		$str .= $indent . $item->path . "\n";
		if ($item->has_children) {
			$str .= $item->children->get_hierarchy($indent . "\t");
		}
	}

	return $str;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DEPENDENCIES

L<Catalyst>

=head1 SEE ALSO 

L<CatalystX::NavigationMenuItem>

=head1 AUTHORS

Derek Wueppelmann <derek@roaringpenguin.com>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
