package Chandra::Tray;

use strict;
use warnings;

our $VERSION = '0.19';

use Chandra;
use Cpanel::JSON::XS ();

# All methods now in XS via Chandra's XSLoader (xs/tray.xs)

1;

__END__

=head1 NAME

Chandra::Tray - System tray icon with context menu

=head1 SYNOPSIS

    use Chandra::Tray;

    my $tray = Chandra::Tray->new(
        app     => $app,
        icon    => '/path/to/icon.png',
        tooltip => 'My App',
    );

    $tray->add_item('Show Window' => sub { $app->show });
    $tray->add_separator;
    $tray->add_item('Quit' => sub { $app->terminate });
    $tray->show;

=head1 DESCRIPTION

Creates a native system tray icon with a context menu.  Uses
C<NSStatusBar> on macOS, C<GtkStatusIcon> on Linux, and
C<Shell_NotifyIcon> on Windows.

=head1 CONSTRUCTOR

=head2 new(%args)

    my $tray = Chandra::Tray->new(
        app     => $app,       # Chandra::App instance (required for show)
        icon    => 'icon.png', # path to icon file
        tooltip => 'My App',   # hover tooltip
    );

=head1 METHODS

=head2 add_item($label, \&handler)

Add a menu item.  Returns C<$self> for chaining.

=head2 add_separator()

Add a menu separator.  Returns C<$self>.

=head2 add_submenu($label, \@items)

Add a submenu.  Each item in C<@items> is a hashref with C<label> and
C<handler> keys.

=head2 set_icon($path)

Change the tray icon.  Returns C<$self>.

=head2 set_tooltip($text)

Change the tooltip.  Returns C<$self>.

=head2 update_item($id_or_label, %opts)

Update an existing menu item.  Options: C<label>, C<disabled>,
C<checked>, C<handler>.

=head2 on_click(\&handler)

Set a handler for left-clicking the tray icon.

=head2 show()

Display the tray icon.  Requires C<app> to be set.

=head2 remove()

Remove the tray icon.

=head2 is_active()

Returns true if the tray icon is currently displayed.

=head2 items()

Returns an arrayref of the current menu items.

=head2 item_count()

Returns the number of menu items.

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Dialog>

=cut
