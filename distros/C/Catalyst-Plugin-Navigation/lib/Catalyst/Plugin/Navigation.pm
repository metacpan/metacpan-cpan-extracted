package Catalyst::Plugin::Navigation;

use strict;
use warnings;

use Moose::Role;
use CatalystX::NavigationMenu;
use namespace::autoclean;

use vars qw($VERSION);
$VERSION = '1.002';

after setup_finalize => sub {
	my ($self, @args) = @_;

	$self->mk_classdata('navigation');
	$self->navigation(CatalystX::NavigationMenu->new());
	$self->navigation->populate($self);
};

1;

__END__

=head1 NAME

Catalyst::Plugin::Navigation - A navigation plugin for Catalyst

=head1 SYNOPSIS

  use Catalyst(qw/
    Navigation
  /);

  # When navigation needed.
  my $menu = $c->navigation->get_navigation($c, {level => 0});

  ...

  # When defining an action.
  sub new_action : Local Menu('Menu Title') MenuTitle('Menu Mouse Over Title')
                   MenuParent('#Menu Parent') MenuArgs('$stash_arg') {
    # Do action items.
    ...
  }

=head1 DESCRIPTION

The Catalyst::Plugin::Navigation plugin provides a way to define the navigation elements 
and hierarchy within the Catalyst controllers. By defining the menu structure from the
controller attributes a controller can then ask for any level of menu and be presented
with the current chain to the active page as well as all other visable menus from the
hirearchy. Instead of having to define the menu structure and navigation elements and links
in an external source this can be done from the infomation available from the controllers
themselves.

=head1 METHODS

When using the Catalyst::Plugin::Navigation plugin the following methods are added to the
base Catalyst object.

=head2 navigation()

Returns the CatalystX::NavigationMenu object that relates to the existing menu structure
defined through the controller attributes. See the L(CatalystX::MenuNavigation) man page 
for more details.

=head1 Attributes

The following attributes are understood by the Catalyst::Plugin::Navigation plugin. The 
Menu() attribute is the only required attribute. Without this attribute the action element
will not be included in the navigation tree.

=head2 Menu('Label')

This provides the label to be used for the menu link. This is the actual text of the href.
This item is required in order to have the action appear in the menu navigation.

=head2 MenuParent('Path')

Provides the path to the parent item. If the parent doesn't exist then it will be created
in the tree structure so that the child can be accessed even if the parent is never 
defined. For more information on the Path value that can be passed see the PATHS section 
below.

=head2 MenuArgs('Arg')

Provides informaiton on what to use to populate arguments and URI placeholders for the current 
action. If the current action is chained or requires arguments then these are used to populate 
the URI accordingly. The arguments are passed in the order they appear in the attribute list. 
More than one MenuArgs attribute can be attached to a single action. If the argument is preceeded
by a $ symbol then the name of the argument is pulled from the stash variable. Otherwise the 
argument is included as plain text. For example the following entry MenuArgs('$stash_value') will
call out and get the stash value for the keyword 'stash_value' ($c->stash->{'stash_value'}). 

URL arguments are also handled with the MenuArgs() attribute. These are defined by preceeding
the argument with the @ symbol. The same rules above apply, so the argument @$var will use the var
value from the stash as a URL argument and @var will use the literal string var as the URL 
argument.

=head2 MenuCond('Cond')

In order for the menu item to be included in the navigation display the condition provided must
evaluate to a true value. The argument ('Cond') value passed in is evaluated in an eval, allowing
complex conditions to be executed. More than one condition can be passed as an attribute, in which 
case all conditions must evaluate to true.

=head2 MenuOrder(int)

Defines the order in which the menu elements shoudl be displayed. If you would like your menu 
items to show up in a particular order you can define that order using the MenuOrder attribute.
In the event that more than one action has the same order value then they are sorted alphabetically
by their Menu label value.

=head2 MenuRoles('Role')

If you are using the Authentication::Roles plugin then you can define which roles must be
provided in order to display the given action in the navigation tree. If more than one 
MenuRoles are included in the attributes list all those roles must be found. If you want 
to show the menu item depending on one of several roles then you can separate those roles
with a | character. So the following attribute: MenuRoles('role1|role2|role3') will allow 
the action to be included in the navigation tree if the logged in user has a role of either
role1, role2 or role3.

=head2 MenuTitle('Title')

Provides the value to use for the title attribute of the a link.

=head1 PATHS

The Catalyst::Pugin::Navigation plugin defines the navigation menu structure using a path
system. This allows you to define a complex path to reach a particular action. There are
a few ways to define path elements. In most instances you will just want to use the 
path to the controller item as the path to an action (ie; controller_name/action_name).

In some instances you may want to provide a parent that is just a place holder for a label.
In this case you can prepend the path value with a # symbol. This is used to define a label
instead of an action. If you provide a path of #Parent#Child/controller/entry, then the 
current action will be found in this chain:

  #Parent
    #Child
	   /controller/entry
		  new_entry

When items are added into the navigation tree their defined by their namespace and action
name. This defines the private path to the entry. So future elements can be added into the
tree under an item by referring to the path of the entry it shoudl appear under.

There should be no need to include multiple path details in the MenuPath variable unless you 
are defining Labels to be used. A Label can occur anywhere in the navigation entry. So both 
of these paths are valid: #Label/path/to/action or /path/to/action/#Label.

=head1 DEPENDENCIES

L<Catalyst>

=head1 SEE ALSO

L<CatalystX::NavigationMenu>, L<CatalystX::NavigationMenuItem>

=head1 AUTHORS

Derek Wueppelmann <derek@roaringpenguin.com>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
