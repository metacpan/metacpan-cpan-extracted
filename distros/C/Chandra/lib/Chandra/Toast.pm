package Chandra::Toast;

use strict;
use warnings;

our $VERSION = '0.25';

use Chandra;

1;

__END__

=head1 NAME

Chandra::Toast - In-app toast notifications

=head1 SYNOPSIS

    use Chandra::Toast;

    # Simple
    Chandra::Toast->show($app, 'Settings saved');

    # Typed
    Chandra::Toast->show($app, 'File uploaded', type => 'success');
    Chandra::Toast->show($app, 'Connection lost', type => 'error', duration => 0);

    # With action
    Chandra::Toast->show($app, 'Item deleted', type => 'info', action => {
        label   => 'Undo',
        handler => sub { undo_delete() },
    });

    # Or via App convenience method
    $app->toast('Saved!', type => 'success');

    # Dismiss programmatically
    my $id = $app->toast('Processing...', type => 'info', duration => 0);
    $app->dismiss_toast($id);

=head1 DESCRIPTION

In-app notification toasts with auto-dismiss, action buttons, and stacking.
All methods are implemented in XS for performance.

=head1 METHODS

=head2 show($app, $message, %opts)

Show a toast notification. Options:

=over 4

=item type - 'success', 'error', 'warning', 'info' (default)

=item duration - milliseconds before auto-dismiss (default 3000, 0 = persistent)

=item action - hashref with C<label> and C<handler> (coderef)

=back

Returns the toast ID string for programmatic dismissal.

=head2 dismiss($app, $id)

Dismiss a toast by ID.

=head2 reset()

Reset internal state (for testing).

=head1 TOAST TYPES

=over 4

=item success - green accent with checkmark

=item error - red accent with X

=item warning - orange accent with warning sign

=item info - blue accent with info symbol (default)

=back

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Theme>

=cut
