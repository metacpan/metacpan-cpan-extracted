package Dancer2::Plugin::Menu ;
$Dancer2::Plugin::Menu::VERSION = '0.006';
use 5.010; use strict; use warnings;

# ABSTRACT: Automatically generate an HTML menu for your Dancer2 app

use Storable     'dclone';
use List::Util   'first';
use Data::Dumper 'Dumper';
use HTML::Element;
use Dancer2::Plugin;
use Dancer2::Core::Hook;

plugin_keywords qw ( menu_item );

### ATTRIBUTES ###
# tree is the current active tree with "active" tags
# clean_tree is tree without "active" tags, used to easily reset tree
# html contains HTML generated from the tree

# Separting the HTML from a logical data structure is probably slightly more
# expensive but makes the code cleaner and easier to follow.

has 'tree'       => ( is => 'rw', default => sub { { '/' => { children => {} } } } );
has 'clean_tree' => ( is => 'rw', predicate => 1,);
has 'html'       => ( is => 'rw');
###################

# set up before_template hook to make the menu dynamic using "active" property
sub BUILD {
  my $s = shift;

  $s->app->add_hook (Dancer2::Core::Hook->new (
    name => 'before_template',
    code => sub {

      # reset or init the trees
      $s->has_clean_tree ? $s->tree(dclone $s->clean_tree)
                         : $s->clean_tree(dclone $s->tree);

      # set active menu items
      my $tokens = shift;
      my @segments = split /\//, $tokens->{request}->route->spec_route;
      shift @segments; # get rid of blank segment
      my $tree = $s->tree->{'/'};
      foreach my $segment (@segments) {
        $tree->{children}{$segment}{active} = 1;
        $tree = $tree->{children}{$segment};
      }

      # tear down and regenerate html and send to template
      $s->html( HTML::Element->new('ul') );
      _get_menu($s->tree->{'/'}, $s->html);
      $tokens->{menu} = $s->html->as_HTML('', "\t", {});
    }
  ));
}

# init the tree; called for each route wrapped in the menu_item keyword
sub menu_item {
  my ($s, $xt_data, $route) = @_;
  my @segments = split /\//, $route->spec_route;
  my $tree = $s->tree;
  $segments[0] = '/'; # replace blank segment with root segment

  # add the path segments and associated data to our tree
  while (my $segment = shift @segments) {
    my $title = ucfirst($segment);
    my $weight = 5;
    $xt_data->{title} //= $title;
    print Dumper $xt_data->{title};
    $xt_data->{weight} //= $weight;

    # add xt_data to existig terminal segments, grow the tree otherwise
    if (!@segments && ($s->tree->{$segment} || !$tree->{$segment}{children})) {
      $tree->{$segment} = $xt_data;
      $tree->{$segment}{protected} = 1;  # cannot be changed by a different route
    } elsif (!$s->tree->{$segment} && !$tree->{$segment}{children}) {
      $tree->{$segment}{children} = {};
    }

    # add menu item data to non-protected items
    if (!$tree->{$segment}{protected}) {
      ($title, $weight) = ($xt_data->{title}, $xt_data->{weight}) if !@segments;
      $tree->{$segment}{title} = $title;
      $tree->{$segment}{weight} = $weight;
      $tree->{$segment}{protected} = !@segments;
    }
    $tree = $tree->{$segment}{children};
  }
}

# generate the HTML based on the contents of the tree
sub _get_menu {
  my ($tree, $element) = @_;

  # sort sibling children menu items by weight and then by name
  foreach my $child (
    sort { ( $tree->{children}{$a}{weight} <=> $tree->{children}{$b}{weight} )
      ||   ( $tree->{children}{$a}{title}  cmp $tree->{children}{$b}{title}  )
         } keys %{$tree->{children}} ) {

    # create menu item list element with classes for css styling
    my $li_this = HTML::Element->new('li');
    $li_this->attr(class => $tree->{children}{$child}{active} ? 'active' : '');

    # add HTML elements for menu item; recurse if menu item has children itself
    $li_this->push_content($tree->{children}{$child}{title});
    if ($tree->{children}{$child}{children}) {
      my $ul      = HTML::Element->new('ul');
      $li_this->push_content($ul);
      $element->push_content($li_this);
      _get_menu($tree->{children}{$child}, $ul)
    } else {
      $element->push_content($li_this);
    }
  }
  return $element;
}

1; # Magic true value

__END__

=pod

=head1 NAME

Dancer2::Plugin::Menu - Automatically generate an HTML menu for your Dancer2 app

=head1 VERSION

version 0.006

=head1 SYNOPSIS

In your app:

  use Dancer2;
  use Dancer2::Plugin::Menu;

  menu_item(
    { title => 'My Parent Item', weight => 3 },
    get 'path' => sub { template },
  );

  menu_item(
    { title => 'My Child1 Item', weight => 3 },
    get 'path/menu1' => sub { template },
  );

  menu_item(
    { title => 'My Child2 Item', weight => 4 },
    get 'path/menu2' => sub { template },
  );

In your template file:

  <% menu %>

This will generate a hierarchical menu that will look like this when the
C<path/menu1> route is visted:

  <ul><li class="active">Path
      <ul><li class="active">My Child1 Item</li>
          <li>My Child2 Item</li>
      </ul>
  </ul>

=head1 DESCRIPTION

This module generates HTML for routes wrapped in the C<menu_item> keyword. Menu
items will be injected into the template wherever the C<E<lt>% menu %E<gt>> tag
is located. Child menu items are wrapped in C<E<lt>li%E<gt>> HTML tags which are
themselves wrapped in a C<E<lt>ul%E<gt>> tag associated with the parent menu
item. Menu items within the current route are given the C<active> class so they
can be styled.

The module is in early development stages and currently has few options. It has
not been heavily tested and there are likely bugs especially with dynaimc paths
which are completely untested at this time. The module should work and be
adqueate for simple menu structures, however.

=head1 CONFIGURATION

Add a C<E<lt>% menu %E<gt>> tag in the appropriate location withing your Dancer2
template files. If desired, add css for C<E<lt>li%E<gt>> tags in the C<active>
class.

=head1 KEYWORDS

=head2 menu_item( { [title => $str], [weight => $num] }, C<ROUTE METHOD> C<REGEXP>, C<CODE>)

Wraps a conventional route handler preceded by a required hash reference
containing data that will be applied to the route's endpoint.

Two keys can be supplied in the hash reference: a C<title> for the menu item and
a C<weight>. The C<title> will be used as the content for the menu items. The
C<weight> will determine the order of the menu items. Heavier items (with larger
values) will "sink" to the bottom compared to sibling menu items sharing the
same level within the hierarchy. If two sibling menu items have the same weight,
the menu items will be ordered alphabetically.

Menu items that are not endpoints in the route or that don't have a C<title>,
will automatically generate a title according to the path segment's name. For
example, this route:

  /categories/fun food/desserts

Will be converted to a hierachy of menu items entitled C<Categories>, C<Fun
food>, and C<Desserts>. Note that captialization is automatically added.
Automatic titles will be overridden with endpoint specific titles if they are
supplied in a later C<menu_item> call.

If the C<weight> is not supplied it will default to a value of C<5>.

=head1 REQUIRES

=over 4

=item * L<Dancer2::Core::Hook|Dancer2::Core::Hook>

=item * L<Dancer2::Plugin|Dancer2::Plugin>

=item * L<Data::Dumper|Data::Dumper>

=item * L<HTML::Element|HTML::Element>

=item * L<List::Util|List::Util>

=item * L<Storable|Storable>

=item * L<strict|strict>

=item * L<warnings|warnings>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dancer2::Plugin::Menu

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Dancer2-Plugin-Menu>

=back

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/sdondley/Dancer2-Plugin-Menu>

  git clone git://github.com/sdondley/Dancer2-Plugin-Menu.git

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/sdondley/Dancer2-Plugin-Menu/issues>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 SEE ALSO

L<Dancer2>

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
