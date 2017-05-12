package Catalyst::ActionRole::Tabs;

use Moose::Role;
use namespace::autoclean;

use Catalyst::Exception;

our $VERSION = '0.003000';

=head1 NAME

Catalyst::ActionRole::Tabs - Add tabs to Catalyst controller actions

=head1 SYNOPSIS

  package MyApp::Controller::Foo;

  use Moose::Role;
  use namespace::autoclean;

  BEGIN { extends 'Catalyst::Controller::ActionRole' }

  # view action has a tab
  sub view : Local Does(Tabs) Tab {
    ...
  }

  # edit action has a tab
  sub edit : Local Does(Tabs) Tab {
    ...
    $form->action($c->uri_for('update'));
    ...
  }

  # update action uses same tab as edit action
  sub update : Local Does(Tabs) TabAlias(edit) {
    ...
    if ($form->result->has_errors) {
      $stash->{template} = 'edit.tt2';
    }
    else {
      $c->response->redirect($c->uri_for('view'));
  }


  [% # Tab template %]
  [% # Assuming tab_navigation to be an array reference %]
  [% # See below under CALLBACK METHODS %]
  [% # For applicable CSS see below under SAMPLE CSS -%]
  <ul class="tabs">
  [% FOR tab IN tab_navigation %]
      <li[% IF tab.selected %] class="selected"[% END %]>
          <a href="[% tab.uri %]">[% tab.label %]</a>
      </li>
  [% END %]
  </ul>

=head1 DESCRIPTION

This module allows to add 'Tab' attributes to action endpoints, and it
will automatically build a data structure suitable for rendering 'tabs'
to switch between the methods that share the same tab structure.

Although this was originally built to help with making tabbed interfaces,
it isn't limited to creating tabs, as it simply collects the information
about the related actions.  Actions are considered to be related if they
share a namespace and the same captures from chained actions.

For examples of usage, please have a look in the test directory F<./t>
and its subdirectories.

=head1 ATTRIBUTES

=head2 Does

  Does(Tabs)

Activate C<Catalyst::ActionRole::Tabs> for the action.

=head2 Tab

  Tab
  Tab(Labeltext)

Assign a Tab to the action. The optional argument specifies the label text.
Without an explicite label text the action name is used, with the first
letter uppercased and the rest lowercased.

=head2 TabAlias

  TabAlias(Aliasaction)

In some cases it is usefull to assign one tab to many actions. E.g. an
action with a form to update some data, might be called initially as
action C<edit> where data is read from the database and filled into the
form fields and then point the form's action to C<update>, where the
actual input processing happens. In case of an error, the same form
(decorated with some error messages) would be shown again, but this time
under C<.../update>. With C<TabAlias> C<update> shows the same tab as
C<edit>:

  # action 'edit' has a Tab with label "Edit"
  sub edit : Local Does(Tabs) Tab { ... }

  # action 'update' has a Tab with label "Edit" too
  sub update : Local Does(Tabs) TabAlias(edit) { ... }

=head1 METHODS

Normaly you never have to touch the following two methods.
They are documented here to reveal their purpose.

=head2 BUILD

C<BUILD> is a standard L<Moose|Moose> method, that is called at the end of
the object construction process.

=over 2

=item * Asserts that not both C<Tab> and C<TabAlias> exist for the same action.

=item * The C<TabAlias> attribute is checked to have an argument.

=back

=cut

sub BUILD {}

after BUILD => sub {
    my $self = shift;
    my $args = $_[0];
    my $attr = $args->{attributes};
    my ($t, $value);

    if (exists $attr->{TabAlias}) {
	Catalyst::Exception->throw(
	    "Action '$args->{reverse}': Attributes 'Tab' and 'TabAlias' must not be specified together."
	)
	    if exists $attr->{Tab};
	Catalyst::Exception->throw(
	    "Action '$args->{reverse}': Attribute 'TabAlias' requires an argument."
	)
	    unless defined $attr->{TabAlias}[0];
    }

};

=head2 execute

Called before the actual action code to build the tabs for the current
controller.

Makes use of
L<< Catalyst::ActionRole::ACL->can_visit()|Catalyst::ActionRole::ACL/can_visit( $c ) >>
if available for the particular action and removes those tabs, whose
actions are not allowed for the current user.

The final result is a hash, where the keys are the action names and the
values are references to hashes that describe the actual tabs:

=over

=item name

The action name. Same as the key of the main hash.

=item label

The tab label text.

=item selected

A boolean that is true for the tab of the currently executed action.

=item uri

An L<URI|URI> object of this tab's action.

=item alias

This exists only in the tab for the current action (where C<selected>
is C<true>) and if the action has a C<TabAlias> attribute. Contains the
actual action name.

=back

A dump of the controller's tab hash might look like this:

  {
    view => {
      name => "view",
      label => "View",
      selected => 1,
      uri => bless(
          do{\(my $o = "http://example.com/admin/user/id/1337")},
          "URI::http"
        ),
    },
    edit => {
      name => "edit",
      label => "Edit",
      selected => "",
      uri => bless(
          do{\(my $o = "http://example.com/admin/user/id/1337/edit")},
          "URI::http"
        ),
    },
  }

=head3 Compatibility notice:

In the first public release of this module query parameters from the current
request were appended to the tab URIs. The idea behind it was to easily
pass a session id. This turned out to be a bad idea, because all kinds of
paramaters were passed to pages, where they might introduce complications.
Therefore beginning with this release no query parameters are appended to
the tab URIs automatically, and the desired query parameters must be passed
manually in the L</BUILD_TABS> callback method.
See L<below|/BUILD_TABS> how this can be done.

=cut

before execute => sub {
    my ($self, $controller, $c) = @_;
    my $dispatcher = $c->dispatcher;
    my $action_name = $self->name;
    my $namespace = $self->namespace;
    my $request = $c->request;
    my $request_captures = $request->captures;
    my $request_arguments = $request->arguments;
    my ($name, $action, $alias, $attrs, $tab, $uri, $selected, $has_selected);
    my (%t, %ta, %tabs);

    for my $container ($dispatcher->get_containers($namespace)) {
	while (($name, $action) = each %{$container->actions}) {
	    next
		unless $action->namespace eq $namespace;

	    $attrs = $action->attributes;

	    if (defined($tab = $attrs->{Tab})) {
		$t{$name} = [$action, $tab->[0] || ucfirst(lc $name)];
	    }
	    elsif (defined($tab = $attrs->{TabAlias})) {
		$ta{$name} = $tab->[0];
	    }
	    else {
		next;
	    }
	}
    }
    for (keys %t) {
	($action, $name) = @{$t{$_}};
	# get all URIs for the current namespace and request captures
	$uri = $c->uri_for(
	    $action,
	    $request_captures,
	    @$request_arguments
	)
	    or next;
	# if $action Does(ACL)
	next
	    if $action->does('Catalyst::ActionRole::ACL')
		and not $action->can_visit($c);

	$selected = $action_name eq $_
	    and $has_selected = 1;
	$tabs{$_} = {
	    name => $_,
	    label => $name,
	    selected => $selected,
	    uri => $uri,
	};
    }
    unless ($has_selected) {
	while (($name, $alias) = each %ta) {
	    if ($action_name eq $name and exists $tabs{$alias}) {
		$tabs{$alias}{selected} = 1;
		$tabs{$alias}{alias} = $name;
		last;
	    }
	}
    }

    if ($controller->can('BUILD_TABS')) {
	$controller->BUILD_TABS($c, \%tabs);
    }
    else {
	$c->stash->{tabs} = \%tabs;
    }
};

1;

__END__

=head1 CALLBACK METHODS

=head2 BUILD_TABS

If method C<BUILD_TABS()> exists in the controller class, it is called as

  $controller->BUILD_TABS($c, $tabs)

else the tabs hash as described in L</execute> is stored at
C<< $c->stash->{tabs} >>.

If it exists C<BUILD_TABS()> has to store the tabs data wherever
appropriate. It can also be used to convert the incomig hash into an array
with the desired order of tabs. Finally is is a place to apply further
modifications to the tabs, like adding or removing tabs.

Here is an example for a C<BUILD_TABS()>. It

=over

=item * turns tab data into an array with the desired order;

=item * adds the query parameter C<session_id> to all tab urls;

=item * stores it onto the stash under the name C<tab_navigation>:

=back

  sub BUILD_TABS {
    my ($self, $c, $tabs) = @_;
    my (@tabs, $tab);
    my $session_id = $c->request->param('session_id');

    for (qw(browse add view edit remove)) {
      $tab = $tabs->{$_} or next;
      $tab->{uri}->query("session_id=$session_id")
        if $session_id;
      push @tabs, $tab;
    }

    $c->stash->{tab_navigation} = \@tabs;
  }


=head1 SAMPLE CSS

Here is some CSS that works with the template included in the synopsis.
It's probably not exactly what you need, but it should give a decent
starting point...

  ul.tabs {
    text-align: left;
    margin: 1em 0 1em 0;
    border-bottom: 1px solid #6c6;
    list-style-type: none;
    padding: 3px 10px 3px 10px;
  }
      
  ul.tabs li {
    display: inline;
  }
  
  ul.tabs li.selected {
    border-bottom: 1px solid #fff;
    background-color: #fff;
  }
  
  ul.tabs li.selected a {
    background-color: #fff;
    color: #000;
    position: relative;
    top: 1px;
    padding-top: 4px;
  }
  
  ul.tabs li a {
    padding: 3px 4px;
    border: 1px solid #6c6;
    background-color: #cfc;
    color: #666;
    margin-right: 0px;
    text-decoration: none;
    border-bottom: none;
  }
  
  ul.tabs a:hover {
    background: #fff;
}

=head1 AUTHOR

Bernhard Graf C<< <graf(a)cpan.org> >>,

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::ActionRole::Tabs


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-ActionRole-Tabs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-ActionRole-Tabs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-ActionRole-Tabs>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-ActionRole-Tabs/>

=back

=head1 ACKNOWLEDGEMENTS

Inspired by and parts of code and documentation used from
L<CatalystX::Controller::Tabs|CatalystX::Controller::Tabs>.

L<Catalyst::ActionRole::ACL|Catalyst::ActionRole::ACL> to be the first
released module to use ...

... the wonderful
L<Catalyst::Controller::ActionRole|Catalyst::Controller::ActionRole>.

And of course L<Catalyst|Catalyst>.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Bernhard Graf.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
