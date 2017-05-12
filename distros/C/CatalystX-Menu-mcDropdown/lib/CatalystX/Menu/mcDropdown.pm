package CatalystX::Menu::mcDropdown;

use 5.008000;

use strict;
use warnings;
use Carp qw(croak);

use base 'CatalystX::Menu::Tree';

use HTML::Entities;
use HTML::Element;
use MRO::Compat;

use vars qw($VERSION);
$VERSION = '0.01';

=head1 NAME

CatalystX::Menu::mcDropdown - Generate HTML UL for a mcDropdown menu

=head1 SYNOPSIS

 package MyApp::Controller::Whatever;

 sub someaction :Local
 :MenuPath('Electronics/Computers')
 :MenuTitle('Computers')
 { ... }

 sub begin :Private {
     my ($self, $c) = @_;

     my $menu = CatalystX::Menu::mcDropdown->new(
        context => $c,
        menupath_attr => 'MenuPath',    # action attribute used to determin menu tree
        menutitle_attr => 'MenuTitle',  # action attribute that supplies menu text
        ul_id => 'menudata',            # <ul id="menudata"> ... </ul>
        ul_class => 'mcdropdown_menu',  # <ul id="menudata" class="mcdropdown_menu"> ... </ul>
                                        # NOTE: mcDropdown expects class="mcdropdown_menu" !
        top_order => [qw(Home * About)],    # Put Home and About on the ends,
                                            #  everything else in-between
        filter => sub {                     # Filter out actions we don't want in menu
            my ($c, %actions) = @_;
            return
                map {$_, $actions{$_}}
                grep {$actions{$_}->can_visit($c)}
                grep {UNIVERSAL::isa($actions{$_}, 'Catalyst::Action::Role::ACL')}
                keys %actions;
        },
        add_nodes => [      # add a menu node manually
            {
                menupath => '/Bargains',
                menutitle => 'Cheap stuff',
                uri => '/products/cheap',
            },
        ],
     );

     $c->session->{navmenu} = $menu->output;
     # include the UL element in your Template: [% c.session.navmenu %]
 }

 # include the required styles (CSS) for the mcDropdown plugin in your markup

=head1 DESCRIPTION

Builds nested HTML UL element with links to your Catalyst application's public
actions for use as a mcDropdown menu.

mcDropdown menus: L<http://www.givainc.com/labs/mcdropdown_jquery_plugin.htm>

=head1 METHODS

=cut

=head2 C<new( $tree, %params )>

Takes a menu tree produced by Catalyst::Controller::Menutree (CatalystX::MenuTree)
and a list of key/value parameter pairs.

Params

=over

=item menupath_attr

Required (no validation)

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

Required

The mcDropdown menu plugin populates the menu options from the values of
the list itmes (for example: <li>Menu Option</li>).

=item ul_id

Required

The ID attribute to be applied to the outer HTML UL element.

=item ul_class

Required

The class attribute to be applied to the outer HTML UL element. mcDropdown requires
class = mcdropdown_menu.

=item top_order

A list of top level menu item labels. Menu items are sorted alphabetically by
default. top_order allows you to specify the order of one or more items. The
asterisk (*) inserts any menu items not listed in top_order.

=item add_nodes

Optional

A reference to an array of hash references. See the L</SYNOPSIS>.

=back

=cut

sub new {
    my $class = shift;
    if (@_ && @_ % 2 != 0) {
        die 'expected list of key/value pairs';
    }
    my %p = @_;
    unless ($p{ul_class}) {
        croak("ul_class parameter is required");
    }
    unless ($p{ul_id}) {
        croak("ul_id parameter is required");
    }

    my $self = $class->next::method(@_);

    return $self;
}

=head2 C<output>

Return HTML UL markup.

=cut

sub output {
    my ( $self ) = @_;

    my @ord = $self->_get_top_level_order;

    my $tree = $self->{tree};

    local %HTML::Tagset::optionalEndTag;  # we want NO optional end tags

    my %opts;
    $opts{id} = $self->{ul_id};
    $opts{class} = $self->{ul_class};
    my $h = HTML::Element->new('ul', %opts);

    # process one top-level chunk of the tree at a time
    for my $item (@ord) {
        next unless $tree->{$item};
        $self->_gen_menu($h, {$item, $tree->{$item}})
    }

    my $indent = ' ' x 4;

    return $h->as_HTML(undef, $indent, {});
}

=head1 INTERNAL METHODS

=cut

=head2 C<_get_top_level_order()>

Return hash keys for top level menu items. Order is determined by the top_order param.
Items not explicitly referenced in the top_order param are sorted lexically and inserted
where the asterisk (*) appears in the top_order param string.

=cut

sub _get_top_level_order {
    my ($self) = @_;

    my @ord;

    if ($self->{top_order}) {
        my %menukeys = map {$_, 1} keys %{$self->{tree}};
        for my $top (@{$self->{top_order}}) {
            if ($top eq '*') {
                push @ord, '*';
            }
            else {
                push @ord, $top;
                delete $menukeys{$top};
            }
        }
        my $n = @ord;
        for (my $i = 0; $i < $n; ++$i) {
            if ($ord[$i] eq '*') {
                splice @ord, $i, 1, sort keys %menukeys;
                last;
            }
        }
    }
    else {
        @ord = sort keys %{$self->{tree}};
    }

    return @ord;
}

=head2 C<_gen_menu($self, $h, $tree)>

Recursively construct a (possibly) nested HTML UL element.

$h is an HTML::Element object.
$tree is a node in the tree created in the parent class.

=cut

sub _gen_menu {
    my ($self, $h, $tree) = @_;

    # <li rel="<uri>">menutitle</li>
    for my $label (sort keys %$tree) {
        my $rel;
        if ($tree->{$label}{uri}) {
            $rel = $tree->{$label}{uri};
        }
        else {
            $rel = $label;
        }
        my $li = $h->new('li', rel => $rel);
        $li->push_content($label);

        #
        #  Recurse to process nested menu items
        #
        if (keys %{$tree->{$label}{children}}) {
            my $ul = $h->new('ul');
            $self->_gen_menu($ul, $tree->{$label}{children});
            $li->push_content($ul);
        }

        $h->push_content($li);
    }

    return;
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

