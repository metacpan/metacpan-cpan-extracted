package Chandra::Window;

use strict;
use warnings;

use Chandra;  # Loads XS which includes Window functions

our $VERSION = '0.24';

# All methods are implemented in XS (xs/window.xs)
# See POD below for API documentation

1;

__END__

=head1 NAME

Chandra::Window - Multi-window management for Chandra applications

=head1 SYNOPSIS

    use Chandra::Window;

    # Create a child window
    my $settings = Chandra::Window->new(
        title   => 'Settings',
        width   => 400,
        height  => 300,
        content => '<h1>Settings</h1>',
    );

    # Window operations
    $settings->set_title('Preferences');
    $settings->set_content('<h1>Updated</h1>');
    $settings->set_size(500, 400);
    $settings->set_position(200, 200);
    $settings->show;
    $settings->hide;
    $settings->focus;
    $settings->close;

    # Lifecycle hooks
    $settings->on_close(sub {
        my ($win) = @_;
        return 1;  # Allow close (return 0 to prevent)
    });

    # Cross-window communication
    $settings->on('save', sub {
        my ($data) = @_;
        print "Settings saved\n";
    });
    $settings->emit('save', { theme => 'dark' });

=head1 DESCRIPTION

Chandra::Window provides multi-window support for Chandra applications.
Each window is a separate native window with its own WKWebView (on macOS).

This module is implemented entirely in XS for maximum performance.

=head1 CONSTRUCTOR

=head2 new

    my $win = Chandra::Window->new(%options);

Creates a new window. Options:

=over 4

=item title

Window title (default: "Window")

=item width, height

Window dimensions in pixels (default: 400x300)

=item x, y

Window position (-1 for system default)

=item resizable

Whether window can be resized (default: 1)

=item frameless

Borderless window (default: 0)

=item content

Initial HTML content

=item url

Initial URL to navigate to

=item modal

Modal window mode (default: 0)

=item parent

Parent window for modal

=item id

Custom window identifier

=back

=head1 METHODS

=head2 Content

=over 4

=item set_content($html)

Set HTML content

=item navigate($url)

Navigate to URL

=item eval($js)

Execute JavaScript

=back

=head2 Properties

=over 4

=item set_title($title)

=item set_size($width, $height)

=item set_position($x, $y)

=item get_size()

Returns ($width, $height)

=item get_position()

Returns ($x, $y)

=back

=head2 State

=over 4

=item show(), hide(), focus(), minimize(), maximize(), close()

=item is_visible(), is_modal(), is_closed()

=back

=head2 Modal

=over 4

=item set_modal($parent)

=item end_modal()

=back

=head2 Callbacks

=over 4

=item on_close($coderef)

=item on_resize($coderef)

=item on_focus($coderef)

=item on_blur($coderef)

=back

=head2 Events

=over 4

=item on($event, $coderef)

Register event handler

=item emit($event, @args)

Emit event to handlers

=back

=head2 Class Methods

=over 4

=item windows()

Returns all active windows

=item window_by_id($id)

Find window by custom ID

=item window_by_wid($wid)

Find window by native window ID

=item window_count()

Number of active windows

=back

=head2 Accessors

=over 4

=item wid()

Native window ID

=item id()

Custom window identifier

=item parent()

Parent window (if any)

=item children()

Child windows

=back

=head1 AUTHOR

Robert Acock

=head1 LICENSE

Same as Perl itself.

=cut

=head2 Chandra::Window->windows

Returns all active window instances.

=head2 Chandra::Window->window_by_id($id)

Find a window by its custom ID.

=head2 Chandra::Window->window_count

Returns the number of active windows.

=head1 SEE ALSO

L<Chandra>, L<Chandra::App>

=cut
