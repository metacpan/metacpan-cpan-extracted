package CatalystX::NavigationMenuItem;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

=head1 NAME

CatalystX::NavigationMenuItem

=head1 SYNOPSIS

  my $mi = CatalystX::NavigationMenuItem->new(
  	...
  );

  my $entry = $mi->nav_entry($c);
  my $link = $mi->get_link($c);

=head1 DESCRIPTION

CatalystX::NavigationMenuItem represents a menu item in a L(CatalystX::NavigationMenu).
This object does all the work of determining if the menu item can be displayed, what
link to use and if there are sub menus.

=cut

has label => (
	is => 'rw',
	isa => 'Str',
);

has title => (
	is => 'rw',
	isa => 'Str',
);

has action => (
	is => 'ro',
	isa => 'Catalyst::Action',
	predicate => 'has_action',
);

has path => (
	is => 'ro',
	isa => 'Str',
);

has parent => (
	is => 'ro',
	writer => '_set_parent',
	isa => 'Str',
);

has action_args => (
	traits => ['Array'],
	is => 'rw',
	isa => 'ArrayRef[Str]',
	default => sub{ [] },
	handles => {
		count_args => 'count',
		all_args => 'elements',
	},
);

has conditions => (
	traits => ['Array'],
	is => 'rw',
	isa => 'ArrayRef[Str]',
	default => sub{ [] },
	handles => {
		condition_count => 'count',
		all_conditions => 'elements',
	},
);

has order => (
	is => 'ro',
	isa => 'Int',
	default => 0
);

has required_roles => (
	traits => ['Array'],
	is => 'ro',
	isa => 'ArrayRef[Str]',
	default => sub{ [] },
	handles => {
		count_roles => 'count',
		all_roles => 'elements',
	},
);

has children => (
	is => 'rw',
	isa => 'CatalystX::NavigationMenu',
	predicate => 'has_children'
);

=head1 METHODS

=head2 contains_path($path)

Returns true if this menu item or any of its children contain the given
path.

=cut

sub contains_path {
	my ($self, $path) = @_;

	# If this is the path, we obviously contain the path.
	return 1 if ($self->path eq $path);

	# Now check all the children:
	if ($self->has_children) {
		# For each child element see if it contains the path.
		foreach my $i ($self->children->all_items) {
			return 1 if ($i->contains_path($path));
		}
	}

	return 0;
}

=head2 nav_entry($c, $with_subs)

Returns a hash reference that contains the navigation entry for this item. If
there is no link associated with item it will return an undef value. If $with_subs 
is true then the sub navigation to this item is also include in the hash with a key 
of: subnav. The other keys are:

=over 4

=item label

The label to use for the actual link. The text to show between a tags.

=item title

An optional title of the link. To be used as the title attribute of the a tag.

=item link

The actual link. This contains the actual URI string, not an object.

=item active

True if the given entry is currently active (part of the path to the currently
viewed page).

=back

=cut

sub nav_entry {
	my ($self, $c, $with_subs) = @_;

	# Check to see if we can display this item or not.
	if ($self->count_roles > 0 && $c->can('check_user_roles')) {
		# Check each roles.
		foreach my $role ($self->all_roles) {
			if ($role =~ /\|/) {
				my @roles = split(/\|/, $role);
				return undef if (!$c->check_any_user_role(@roles));
			}
			else {
				return undef if (!$c->check_user_roles($role));
			}
		}
	}

	# We can show this entry.
	my $link = $self->get_link($c);

	# Don't show this item if there is no link possible.
	return undef if (!$link);

	my $entry = {
		label => $self->label,
		title => $self->title,
		link => $link, 
		active => $self->contains_path($c->action->namespace . '/' . $c->action->name),
	};

	if ($with_subs && $self->has_children) {
		my $sub_nav = $self->children->get_navigation($c);
		if (scalar(@$sub_nav) > 0) {
			$entry->{subnav} = $sub_nav;
		}
	}

	return $entry;
}

=head2 add_item($item)

Add the given item to the sub tree for this item. If no subtree exists create one.

=cut

sub add_item {
	my ($self, $item) = @_;

	if (!$self->has_children) {
		$self->children(CatalystX::NavigationMenu->new());
	}
	if ($item->parent eq $self->path) {
		$self->children->insert_item($item);
	}
	else {
		$self->children->add_item($item);
	}
}

=head2 get_link($c)

Using the given Catalyst object determine if this link should be displayed or 
not. It will use the Catalyst object to fill in any missing values it needs 
to complete an action link, it will also use the object to determine any 
conditions that require it.

=cut

sub get_link {
	my ($self, $c) = @_;

	# Check the conditions if we have any.
	if ($self->condition_count > 0) {
		# Test each conditions
		foreach my $cond ($self->all_conditions) {
			return undef if (!eval($cond));
		}
	}

	my $link;
	if ($self->has_action) {
		my @capture_args;
		my @url_args;
		foreach my $arg ($self->all_args) {
			# Select which array we are to be added to.
			my $array = \@capture_args;
			if ($arg =~ /^\@/) {
				$arg =~ s/^\@//;
				$array = \@url_args;
			}

			# Now process the arg.
			if ($arg =~ /^\$/) {
				$arg =~ s/^\$//;
				return undef if (!exists($c->stash->{$arg}));
				push(@$array, $c->stash->{$arg});
			}
			else {
				push(@$array, $arg);
			}	
		}
		my @args = ($self->action);
		push(@args, \@capture_args) if (scalar(@capture_args) > 0);
		push(@args, @url_args);
		$link = $c->uri_for(@args);
		if ($link) {
			$link = $link->as_string;
		}
	}
	elsif ($self->has_children) {
		# We don't have a link but maybe one of our children does.
		foreach my $child ($self->children->sorted_items) {
			my $entry = $child->nav_entry($c, 0);
			if ($entry) {
				$link = $entry->{link};
				last if ($link);
			}
		}
	}

	return $link;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DEPENDENCIES

L<Catalyst>

=head1 SEE ALSO 

L<CatalystX::NavigationMenu>

=head1 AUTHORS

Derek Wueppelmann <derek@roaringpenguin.com>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
