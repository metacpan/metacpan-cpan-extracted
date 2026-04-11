package Chandra::Clipboard;

use strict;
use warnings;

use Chandra ();

our $VERSION = '0.21';

1;

__END__

=head1 NAME

Chandra::Clipboard - System clipboard access for Chandra applications

=head1 SYNOPSIS

    use Chandra::Clipboard;

    # Text
    Chandra::Clipboard->set_text('Hello, World!');
    my $text = Chandra::Clipboard->get_text;

    # HTML
    Chandra::Clipboard->set_html('<b>Bold</b>');
    my $html = Chandra::Clipboard->get_html;

    # Image (PNG bytes)
    Chandra::Clipboard->set_image('/path/to/image.png');
    my $png = Chandra::Clipboard->get_image;

    # Query
    print "has text\n"  if Chandra::Clipboard->has_text;
    print "has html\n"  if Chandra::Clipboard->has_html;
    print "has image\n" if Chandra::Clipboard->has_image;

    # Clear
    Chandra::Clipboard->clear;

=head1 DESCRIPTION

Chandra::Clipboard provides cross-platform system clipboard access.
All methods are class methods — no object instantiation needed.

=head2 Platform Support

=over 4

=item macOS — NSPasteboard (Cocoa)

=item Linux — GTK clipboard (gtk_clipboard_*)

=item Windows — stub (not yet implemented)

=back

=head1 METHODS

=over 4

=item get_text()

Returns the current clipboard text, or undef if unavailable.

=item set_text($string)

Sets the clipboard to the given text. Returns 1 on success.

=item has_text()

Returns true if the clipboard contains text.

=item get_html()

Returns clipboard HTML content, or undef.

=item set_html($html)

Sets the clipboard to the given HTML. Returns 1 on success.

=item has_html()

Returns true if the clipboard contains HTML.

=item get_image()

Returns raw PNG bytes from the clipboard, or undef.

=item set_image($path)

Loads an image file and places it on the clipboard. Returns 1 on success.

=item has_image()

Returns true if the clipboard contains an image.

=item clear()

Clears all clipboard contents.

=back

=head1 SEE ALSO

L<Chandra>, L<Chandra::App>

=cut
