package CatalystX::Menu::Tree;

use 5.008000;

use strict;
use warnings;
use MRO::Compat;

use vars qw($VERSION);
$VERSION = '0.02';

=head1 NAME

CatalystX::Menu::Tree - Generate Catalyst application menus

=head1 SYNOPSIS

 my $tree = CatalystX::Menu::Tree->new(
    context => $c,
    namespaces => [ $c->namespace ],
    filter => sub {
        my ($c, %action) = @_;
        # return the list of k/v pairs that meet criteria
    },
    menupath_attr => 'MenuPath',
    menutitle_attr => 'MenuTitle',
    add_nodes => [
        {
            menupath => '/Bargains',
            menutitle => 'Cheap stuff',
            uri => '/products/cheap',
        },
        {
            menupath => '/Returns',
            menutitle => 'Return a product',
            uri => '/products/returns',
        },
    ],
 );

=head1 DESCRIPTION

Builds the tree used by CatalystX::Menu::Suckerfish to construct an HTML UL
element for use as a degradable, CSS-styled menu or horizontal navbar.

Catalyst actions with the Private attribute are excluded from the tree.

=head2 Menu Attributes

=over

=item menupath_attr

Names the action attribute that contains the menu path:

 menupath_attr => 'MenuPath'

 # and in your controller:

 sub foobar :Local
 :MenuPath(/Foo/Bar)
 :MenuTitle('Foobar and stuff')
 { ... }

Only actions with the menupath_attr attribute are processed. This attribute's
value determines where the action's menu item is placed in the menu structure
(HTML UL).

Depending on the attribute values collected from the processed actions, there
may be menu items containing only text.  If you want a link to a landing page,
for example, instead of text, include an action for the landing page with the
appropriate MenuPath attribute in your controller, or add an entry manually
with the add_nodes parameter.

=item menutitle_attr

The menutitle_attr attribute will be used to add the HTML title attribute to
each list item. This should result in a balloon text with the title when the
pointing device hovers over each list item.

=back

Suckerfish menus: http://www.alistapart.com/articles/dropdowns

Superfish jQuery menu plugin: http://users.tpg.com.au/j_birch/plugins/superfish/ 

=head1 METHODS

=cut

=head2 C<new( %params )>

Return an instance of this class.

Params

=over

=item context

The Catalyst application context (usually $c or $ctx in your controller).

=item menupath_attr

The action attribute that contains the menu tree path to the menu item
to be inserted for each action.

=item menutitle_attr

The action attribute that contains text describing each action. This
text is applied as a "title" attribute to the menu item's HTML container
so that a tooltip will be displayed when the pointer hovers over the
menu item.

This text can be used anywhere in your application where a description
of an action is useful.

=item namespaces

A reference to an array of action namespaces from which actions with the
menupath_attr attribute should be collected.

=item filter

A reference to a subroutine that takes the Catalyst context and a hash of
action name/action object and returns the name/action pairs that meet certain
criteria.

=item add_nodes

A list of hash references containing data defining arbitrary menu items to
be merged into the menu tree.

=back

=cut

sub new {
    my $class = shift;
    if (@_ && @_ % 2 != 0) {
        die 'expected list of key/value pairs';
    }

    my $self = { @_ };

    bless $self, $class;

    $self->_build_tree;

    return $self;
}

=head1 INTERNAL METHODS

=head2 C<_build_tree()>

Create and store a reference to a hash containing a tree of menu data.

=cut

sub _build_tree {
    my ($self) = @_;

    my $c = $self->{context};
    $self->_get_actions;
    my $actions = $self->{action_hash};

    my @data;

    my $menpattr = $self->{menupath_attr};
    my $mentattr = $self->{menutitle_attr};

    for my $namespace (keys %$actions) {
        for my $name (keys %{$actions->{$namespace}}) {
            my $action = $actions->{$namespace}{$name};
            my %data = (
                menupath => $action->attributes->{$menpattr}[0],
                uri => $c->uri_for($action),
            );
            if ($mentattr) {
                $data{menutitle} = $action->attributes->{$mentattr}[0];
            }
            push @data, { %data };
        }
    }

    # mix in any nodes the user wants to add
    if ($self->{add_nodes}) {
        for my $node (@{$self->{add_nodes}}) {
            push @data, $node;
        }
    }

    my @sorted =
        sort { $b->[0] cmp $a->[0] }
        map { $_->[0] =~ s!^/!!; $_ }
        map { [ $_->{menupath}, $_ ] }
        @data;

    my %tree;

    for my $obj (@sorted) {
        my $mpath = $obj->[1]{menupath};
        my $mtitle = $obj->[1]{menutitle} || '';
        $mpath =~ s!^/!!;
        my $uri = $obj->[1]{uri};
        my @path = split m!/!, $mpath;
        my $str = join ', ' => @path;
        my $node = pop @path;
        my $ref = \%tree;
        while (@path) {
            my $key = shift @path;
            if (exists $ref->{$key}) {
                unless (exists $ref->{$key}{children}) {
                    $ref->{$key}{children} = {};
                }
                $ref = $ref->{$key}{children};
            }
            else {
                $ref->{$key} = {
                    children => {},
                };
                $ref = $ref->{$key}{children};
            }
        }

        # this addresses the case where a top level node is added
        # with add_node to attach a URI or title to a label
        if (exists $ref->{$node}) {
            $ref->{$node}{uri} = $uri;
            if ($mtitle) {
                $ref->{$node}{menutitle} = $mtitle;
            }
        }
        else {
            my %data = (
                children => {},
                uri => $uri,
            );
            if ($mtitle) {
                $data{menutitle} = $mtitle;
            }
            $ref->{$node} = { %data };
        }
    }

    $self->{tree} = {%tree};
}

=head2 C<_get_actions()>

Build a hash of Catalyst::Action objects.

=cut

sub _get_actions {
    my ($self) = @_;

    my $c = $self->{context};
    my $d = $c->dispatcher;

    my @namespace;
    my @container;
    my %actionhash;

    my @controller =
        map {$c->controller($_)}
        $c->controllers;
    push @namespace, $_->action_namespace($c) for @controller;
    if ($self->{namespaces}) {
        my %wanted = map {$_,1} @{$self->{namespaces}};
        @namespace = grep {$wanted{$_}} @namespace;
    }
    push @container, $d->get_containers($_) for @namespace;
    my $menpattr = $self->{menupath_attr};

    for my $ctr (@container) {
        my $acthash = $ctr->actions;
        for my $name (keys %{$acthash}) {
            next if exists $acthash->{$name}->attributes->{Private};
            next unless $acthash->{$name}->attributes->{$menpattr};
            my $actname = $acthash->{$name}->name;
            my $namespace = $acthash->{$name}->namespace;
            $actionhash{$namespace}{$actname} = $acthash->{$name};
        }
    }
    if ($self->{filter}) {
        for my $namespace (keys %actionhash) {
            my %hash = $self->{filter}->($c, %{$actionhash{$namespace}});
            $actionhash{$namespace} = {%hash};
        }
    }

    $self->{action_hash} = {%actionhash};
}

1;

=head1 AUTHOR

David P.C. Wollmann E<lt>converter42@gmail.comE<gt>

=head1 BUGS

This is brand new code, so use at your own risk.

=head1 COPYRIGHT & LICENSE

Copyright 2009 by David P.C. Wollmann

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

