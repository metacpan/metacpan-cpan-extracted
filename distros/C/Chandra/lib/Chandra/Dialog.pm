package Chandra::Dialog;

use strict;
use warnings;

our $VERSION = '0.07';

# XS methods are registered under the Chandra bootstrap.
# Ensure the shared object is loaded.
require Chandra;

1;

__END__

=head1 NAME

Chandra::Dialog - Native dialog boxes for Chandra applications

=head1 SYNOPSIS

	use Chandra::App;

	my $app = Chandra::App->new(title => 'My App');

	# File open dialog
	my $path = $app->dialog->open_file(title => 'Select a file');
	print "Selected: $path\n" if defined $path;

	# Directory picker
	my $dir = $app->dialog->open_directory;

	# Save dialog
	my $save = $app->dialog->save_file(
	    title   => 'Save As',
	    default => 'untitled.txt',
	);

	# Alert dialogs
	$app->dialog->info(title => 'Done', message => 'File saved!');
	$app->dialog->warning(message => 'Unsaved changes');
	$app->dialog->error(message => 'Could not open file');

=head1 DESCRIPTION

Chandra::Dialog provides access to native platform dialog boxes via the
underlying webview-c library.  All dialogs are modal and block until the
user responds.

File open and save dialogs return the selected path, or C<undef> if the
user cancelled.

=head1 METHODS

=head2 new(%args)

Create a new Dialog instance.  Usually accessed via C<< $app->dialog >>.

=head2 open_file(%opts)

Show a file-open dialog.  Options:

=over 4

=item title - Dialog title (default: 'Open File')

=item filter - File filter string (platform-dependent)

=back

Returns the selected file path, or C<undef> if cancelled.

=head2 open_directory(%opts)

Show a directory picker.  Options:

=over 4

=item title - Dialog title (default: 'Open Directory')

=back

Returns the selected directory path, or C<undef> if cancelled.

=head2 save_file(%opts)

Show a file-save dialog.  Options:

=over 4

=item title - Dialog title (default: 'Save File')

=item default - Default filename suggestion

=back

Returns the chosen save path, or C<undef> if cancelled.

=head2 info(%opts)

Show an informational alert.  Options: C<title>, C<message>.

=head2 warning(%opts)

Show a warning alert.  Options: C<title>, C<message>.

=head2 error(%opts)

Show an error alert.  Options: C<title>, C<message>.

=head1 CONSTANTS

=over 4

=item TYPE_OPEN, TYPE_SAVE, TYPE_ALERT

=item FLAG_FILE, FLAG_DIRECTORY, FLAG_INFO, FLAG_WARNING, FLAG_ERROR

=back

These are exported for advanced usage with the low-level
C<< $app->webview->dialog() >> XS method.

=head1 SEE ALSO

L<Chandra::App>

=cut
