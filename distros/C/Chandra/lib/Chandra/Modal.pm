package Chandra::Modal;

use strict;
use warnings;

our $VERSION = '0.29';

use Chandra;

1;

__END__

=head1 NAME

Chandra::Modal - Custom modal dialogs

=head1 SYNOPSIS

    use Chandra::Modal;

    # Confirmation dialog
    Chandra::Modal->confirm($app,
        title   => 'Delete Item',
        message => 'This action cannot be undone.',
        on_ok   => sub { delete_item() },
    );

    # Text prompt
    Chandra::Modal->prompt($app,
        title     => 'Rename',
        label     => 'New name:',
        value     => $current_name,
        on_submit => sub { my ($value) = @_; rename_item($value) },
    );

    # Custom modal
    my $id = Chandra::Modal->show($app,
        title   => 'Settings',
        content => '<p>Custom HTML content here</p>',
        width   => 500,
        buttons => [
            { label => 'Cancel', class => 'secondary', action => 'close' },
            { label => 'Save',   class => 'primary',   action => sub { save() } },
        ],
    );

    # Close programmatically
    Chandra::Modal->close($app, $id);

=head1 DESCRIPTION

HTML-based modal dialogs with backdrop, buttons, and optional text input.
All methods are implemented in XS.

=head1 METHODS

=head2 show($app, %opts)

Show a custom modal. Options:

=over 4

=item title - dialog title

=item content - raw HTML for the body

=item message - plain text message (alternative to content)

=item width - max width in pixels (default 400)

=item closable - show X button (default true)

=item backdrop - click backdrop to close (default true)

=item buttons - arrayref of button definitions

=item input - hashref with C<label> and C<value> for text input

=back

Returns modal ID string.

=head2 close($app, $id)

Close a modal by ID.

=head2 confirm($app, %opts)

Convenience for OK/Cancel confirmation. Options: title, message, on_ok, on_cancel.

=head2 prompt($app, %opts)

Convenience for text input. Options: title, label, value, on_submit.
The on_submit handler receives the input value.

=head2 reset()

Reset internal state (for testing).

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Dialog>, L<Chandra::Toast>

=cut
