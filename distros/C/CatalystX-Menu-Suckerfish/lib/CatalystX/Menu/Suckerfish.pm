package CatalystX::Menu::Suckerfish;

use 5.008000;

use strict;
use warnings;

use base 'CatalystX::Menu::Tree';

use HTML::Entities;
use HTML::Element;
use MRO::Compat;

use vars qw($VERSION);
$VERSION = '0.03';

=head1 NAME

CatalystX::Menu::Suckerfish - Generate HTML UL for a CSS-enhanced Suckerfish menu

=head1 SYNOPSIS

 package MyApp::Controller::Whatever;

 sub someaction :Local
 :MenuPath('Electronics/Computers')
 :MenuTitle('Computers')
 { ... }

 sub begin :Private {
     my ($self, $c) = @_;

     my $menu = CatalystX::Menu::Suckerfish->new(
        context => $c,
        ul_id => 'navmenu',         # <ul id="navmenu"> ... </ul>
        ul_class => 'sf-menu',      # <ul id="navmenu" class="sf-menu"> ... </ul>
        text_container => {         # wrap plain text nodes in this HTML element
            element => 'span',      #  so that styles can be applied if desired.
            attrs => {
                class => 'myspan',
            },
        },
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

 # include any desired styles (CSS) for the UL element in your markup

=head1 DESCRIPTION

Builds nested HTML UL element with links to your Catalyst application's public
actions for use as a Suckerfish or Superfish menu.

Suckerfish menus: L<http://www.alistapart.com/articles/dropdowns>
Superfish jQuery menu plugin: L<http://users.tpg.com.au/j_birch/plugins/superfish/>

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

Optional

The menutitle_attr attribute will be used to add the HTML title attribute to
each list item. This should result in a balloon text with the title when the
pointing device hovers over each list item.

=item ul_id

The ID attribute to be applied to the outer HTML UL element.

=item ul_class

The class attribute to be applied to the outer HTML UL element.

=item ul_container

Specifies an HTML element (typically a DIV) in which to enclose the UL
element.

=item text_container

Specifies an HTML element (typically a SPAN) in which to enclose menu items
which don't include A elements. This makes it possible to apply similar styles
to both plain text and A elements for consistent appearance.

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
    if ($self->{ul_id}) {
        $opts{id} = $self->{ul_id};
    }
    if ($self->{ul_class}) {
        $opts{class} = $self->{ul_class};
    }
    my $h = HTML::Element->new('ul', %opts);

    # process one top-level chunk of the tree at a time
    for my $item (@ord) {
        next unless $tree->{$item};
        $self->_gen_menu($h, {$item, $tree->{$item}})
    }

    my $indent = ' ' x 4;

    if (my $ctr = $self->{ul_container}) {
        my $el = $ctr->{element};
        my %opts = ( %{$ctr->{attrs}} );
        my $ctr_el = $h->new($el, %opts);
        $ctr_el->push_content($h);
        $h = $ctr_el;
    }

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

    for my $label (sort keys %$tree) {
        my $content;
        if ($tree->{$label}{uri}) {
            $content = $h->new('a', href => $tree->{$label}{uri});
            $content->push_content($label);
        }
        elsif ($self->{text_container}) {
            my $el = $self->{text_container}{element};
            $content = $h->new($el, %{$self->{text_container}{attrs}});
            $content->push_content($label);
        }
        else {
            $content = $label;
        }
        my %opts;
        if ($tree->{$label}{menutitle}) {
            %opts = (title => $tree->{$label}{menutitle});
        }
        my $li = $h->new('li', %opts);
        $li->push_content($content);

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

