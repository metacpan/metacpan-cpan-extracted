package Chandra::ContextMenu;

use strict;
use warnings;

use Chandra ();

our $VERSION = '0.22';

1;

__END__

=head1 NAME

Chandra::ContextMenu - Context menus for Chandra applications

=head1 SYNOPSIS

    use Chandra::App;

    my $app = Chandra::App->new(title => 'My App');

    # Quick static context menu
    $app->context_menu('#editor', [
        { label => 'Cut',   action => sub { cut() },   shortcut => 'Ctrl+X' },
        { label => 'Copy',  action => sub { copy() },  shortcut => 'Ctrl+C' },
        { label => 'Paste', action => sub { paste() }, shortcut => 'Ctrl+V' },
        { separator => 1 },
        { label => 'Select All', action => sub { select_all() }, shortcut => 'Ctrl+A' },
    ]);

    # Dynamic context menu (items generated per right-click)
    $app->context_menu('.file-item', sub {
        my ($target) = @_;
        return [
            { label => "Open",   action => sub { open_file($target) } },
            { label => 'Rename', action => sub { rename_file($target) } },
            { label => 'Delete', action => sub { delete_file($target) } },
        ];
    });

    # Advanced usage via instance
    my $menu = $app->context_menu_instance;
    $menu->attach_global;
    $menu->add_item({ label => 'About', action => sub { show_about() } });

    $app->run;

=head1 DESCRIPTION

Chandra::ContextMenu provides HTML-based right-click context menus for
Chandra applications. Menus support nested submenus, separators, disabled
items, checkable items, icons, and keyboard shortcut hints.

Menus can be attached to specific CSS selectors or globally to the
entire document. Items can be static (defined at creation) or dynamic
(generated per right-click via a callback).

=head1 METHODS

=head2 new

    my $menu = Chandra::ContextMenu->new(
        app   => $app,
        items => \@items,
    );

Create a new context menu. C<items> is an arrayref of item hashrefs.

=head2 attach

    $menu->attach('#selector');
    $menu->attach('.class', sub { my ($target) = @_; return \@items });

Attach the menu to elements matching the CSS selector. An optional
coderef generates items dynamically on each right-click.

=head2 detach

    $menu->detach('#selector');

Remove the menu from a selector.

=head2 attach_global

    $menu->attach_global;
    $menu->attach_global(sub { ... });

Attach the menu to the entire document.

=head2 detach_global

    $menu->detach_global;

Remove the global attachment.

=head2 show_at

    $menu->show_at($x, $y);

Programmatically show the menu at the given coordinates.

=head2 set_item

    $menu->set_item('Delete', disabled => 0);

Update properties of an item by label.

=head2 add_item

    $menu->add_item({ label => 'New', action => sub { ... } });

Append an item to the menu.

=head2 remove_item

    $menu->remove_item('New');

Remove an item by label.

=head2 items

    my $items = $menu->items;

Return the items arrayref.

=head2 attachments

    my @sels = $menu->attachments;

Return the list of attached selectors.

=head2 enable / disable / is_enabled

    $menu->disable;
    $menu->enable;
    my $on = $menu->is_enabled;

Toggle or query the enabled state.

=head1 ITEM FORMAT

Each item is a hashref with these keys:

    { label     => 'Cut',           # Display text
      action    => sub { ... },     # Click handler
      shortcut  => 'Ctrl+X',       # Shortcut hint (display only)
      icon      => "\x{1f4cb}",    # Emoji or text icon
      disabled  => 1,              # Greyed out
      checkable => 1,              # Toggle item
      checked   => 1,              # Initial check state
      separator => 1,              # Separator line (no other keys needed)
      submenu   => [ ... ],        # Nested items
    }

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Shortcut>

=cut
