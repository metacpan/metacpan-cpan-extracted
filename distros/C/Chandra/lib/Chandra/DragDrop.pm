package Chandra::DragDrop;

use strict;
use warnings;

use Chandra ();

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Chandra::DragDrop - Drag and drop support for Chandra applications

=head1 SYNOPSIS

    use Chandra::App;

    my $app = Chandra::App->new(title => 'My App');

    # File drops on entire window
    $app->on_file_drop(sub {
        my ($files) = @_;
        print "Dropped: $_\n" for @$files;
    });

    # Drop zone specific
    $app->drop_zone('#upload-area', sub {
        my ($files, $target) = @_;
        upload_files(@$files);
    });

    # Text drops
    my $dd = $app->drag_drop;
    $dd->on_text_drop(sub {
        my ($text, $target) = @_;
        print "Dropped text: $text\n";
    });

    # Drag feedback
    $dd->on_drag_enter(sub {
        my ($target) = @_;
        return 'drag-highlight';   # CSS class added during drag-over
    });

    $dd->on_drag_leave(sub {
        my ($target) = @_;
    });

    # Intra-app draggable elements
    $dd->make_draggable('#item-1', data => { id => 1, type => 'task' });
    $dd->make_draggable('.card', data_from => 'data-item-id');

    $dd->on_internal_drop(sub {
        my ($data, $source, $target) = @_;
        move_item($data->{id}, $target->{id});
    });

    # Enable/disable
    $dd->disable;
    $dd->enable;

    # Remove specific handlers
    $dd->remove_drop_zone('#upload-area');
    $dd->remove_draggable('.card');

=head1 DESCRIPTION

Chandra::DragDrop handles file drops and intra-app drag-and-drop with
Perl callbacks.  It injects JavaScript event listeners into the webview
that intercept drag events and forward them to registered Perl handlers
via the C<window.chandra.invoke()> bridge.

File drops from the OS, text drops, and intra-app element dragging are
all supported.  Drop zones restrict where drops are accepted using CSS
selectors.

=head1 METHODS

=head2 new

    my $dd = Chandra::DragDrop->new(app => $app);

Create a new DragDrop instance.  Usually accessed via C<< $app->drag_drop >>.

=head2 on_file_drop

    $dd->on_file_drop(sub {
        my ($files, $target) = @_;
        # $files = ['/path/to/file1.txt', ...]
        # $target = { id => '...', class => '...', tag => '...' }
    });

Register a global handler for files dragged from the OS into the
webview.  Called for any drop not handled by a zone-specific handler.

=head2 on_text_drop

    $dd->on_text_drop(sub {
        my ($text, $target) = @_;
    });

Register a handler for text/plain drops.

=head2 on_drag_enter

    $dd->on_drag_enter(sub {
        my ($target) = @_;
        return 'highlight-css-class';
    });

Called when a drag enters an element.  Return a CSS class name to add
visual feedback (the class is added to the target element by id).

=head2 on_drag_leave

    $dd->on_drag_leave(sub { my ($target) = @_ });

Called when a drag leaves an element.

=head2 on_internal_drop

    $dd->on_internal_drop(sub {
        my ($data, $source, $target) = @_;
    });

Called when a draggable element is dropped on another element within
the same webview.

=head2 add_drop_zone

    $dd->add_drop_zone('#upload-area', sub {
        my ($files, $target) = @_;
    });

Register a zone-specific file drop handler.  The CSS selector is
matched on the JS side via C<el.closest()>.

=head2 remove_drop_zone

    $dd->remove_drop_zone('#upload-area');

=head2 drop_zones

    my @selectors = $dd->drop_zones;

List registered drop zone selectors.

=head2 make_draggable

    $dd->make_draggable('.card', data => { id => 1 });
    $dd->make_draggable('.row',  data_from => 'data-item-id');

Mark elements matching the selector as draggable.  Use C<data> for
static drag payloads or C<data_from> to read from a DOM attribute.

=head2 remove_draggable

    $dd->remove_draggable('.card');

=head2 enable / disable / is_enabled

    $dd->disable;
    $dd->enable;
    say $dd->is_enabled;

Toggle drag-and-drop event processing.

=head2 inject

    $dd->inject;

Inject the drag-and-drop JavaScript.  Called automatically by
C<< Chandra::App->run() >> when handlers are registered.

=head2 js_code

    my $js = $dd->js_code;

Return the JavaScript source for manual injection.

=head1 SEE ALSO

L<Chandra::App>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
