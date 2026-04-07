package Chandra::Splash;

use strict;
use warnings;

our $VERSION = '0.15';

require Chandra;

1;

__END__

=head1 NAME

Chandra::Splash - Splash screen / loading state for Chandra applications

=head1 SYNOPSIS

    use Chandra::Splash;

    # Simple splash with default progress template
    my $splash = Chandra::Splash->new(
        title    => 'My App',
        width    => 400,
        height   => 200,
        progress => 1,
    );

    $splash->show;
    $splash->update_status('Loading configuration...');
    $splash->update_progress(25);

    load_config();
    $splash->update_status('Connecting...');
    $splash->update_progress(75);

    connect_db();
    $splash->update_progress(100);
    $splash->close;

    # Custom HTML content
    my $splash = Chandra::Splash->new(
        width   => 500,
        height  => 300,
        content => '<h1 style="text-align:center">Welcome</h1>',
    );

    # Auto-dismiss after 3 seconds
    my $splash = Chandra::Splash->new(
        content => '<h1>Starting...</h1>',
        timeout => 3000,
    );

    # Frameless image splash
    my $splash = Chandra::Splash->new(
        image     => 'splash.png',
        width     => 600,
        height    => 400,
        frameless => 1,
    );

    # Via Chandra::App
    my $app = Chandra::App->new(title => 'My App');

    my $splash = $app->splash(
        progress => 1,
        init     => sub {
            my ($s) = @_;
            $s->update_status('Loading...'); load_config();
            $s->update_status('Ready!');     $s->update_progress(100);
        },
    );

=head1 DESCRIPTION

Chandra::Splash creates a lightweight webview window suitable for use as a
loading/splash screen while your application initialises.  It is built on the
same child-window infrastructure as L<Chandra::Window> so all content is
rendered via the system's WebView engine.

The window is centred on screen, always-on-top by default, and destroyed
cleanly when C<close()> is called.  Progress bar and status text can be updated
live via JavaScript eval without blocking the main thread.

=head1 CONSTRUCTOR

=head2 new(%args)

Create a new Splash object (window is not yet shown).

=over 4

=item title => STR

Window title and default heading in the built-in template.  Defaults to
C<"Loading">.

=item width => INT

Window width in pixels.  Defaults to 400.

=item height => INT

Window height in pixels.  Defaults to 200.

=item frameless => BOOL

Remove window chrome (title bar, close button).  Defaults to 0.

=item progress => BOOL

When true and no C<content> is given, render the built-in splash template
with a progress bar and status text area.  Defaults to 0.

=item content => STR

Custom HTML string to display.  Takes precedence over C<progress>.

=item image => STR

Path to an image file (PNG, JPEG, GIF, WebP).  The image is base64-encoded
and embedded in a frameless-friendly template.  Takes precedence over
C<content> and C<progress>.

=item timeout => INT

Milliseconds after which the splash auto-closes.  0 (default) means no
automatic close.  Note: on macOS the close happens via the next run-loop
tick so the caller should still call C<< $splash->close >> if they want
immediate effect.

=back

=head1 METHODS

=head2 show()

Display the splash window.  Returns C<$self> for chaining.  Calling C<show>
more than once is a no-op.

=head2 update_status($text)

Update the status text line in the built-in template.  Non-blocking — uses
C<evaluateJavaScript> under the hood.  Returns C<$self>.

=head2 update_progress($percent)

Update the progress bar to C<$percent> (0–100; clamped automatically).
Returns C<$self>.

=head2 close()

Destroy the splash window.

=head2 is_open()

Returns 1 if the native window still exists, 0 otherwise.

=head2 wid()

Returns the internal native window id (useful for low-level debugging).
Returns -1 before C<show()> or after C<close()>.

=head2 eval_js($js)

Evaluate arbitrary JavaScript in the splash window.  Escape hatch for custom
content animations etc.

=head1 INTEGRATION WITH Chandra::App

C<< $app->splash(%args) >> is a convenience wrapper that:

=over 4

=item 1. Creates and shows a C<Chandra::Splash>.

=item 2. Calls the C<init> coderef (if given) with the splash object.

=item 3. Closes the splash.

=item 4. Returns the (closed) splash object.

=back

    $app->splash(
        progress => 1,
        init     => sub {
            my ($splash) = @_;
            do_slow_work();
            $splash->update_progress(100);
        },
    );

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Window>

=cut
