package Chandra::Shortcut;

use strict;
use warnings;
use Cpanel::JSON::XS ();

our $VERSION = '0.17';

# XS methods are registered under the Chandra bootstrap.
# Ensure the shared object is loaded.
require Chandra;

our $_xs_json = Cpanel::JSON::XS->new->utf8->allow_nonref->allow_blessed->convert_blessed;

# XS methods: new, bind, unbind, list, is_bound, disable, enable,
#             disable_all, enable_all, inject, js_code, _normalize_combo

1;

__END__

=head1 NAME

Chandra::Shortcut - Keyboard shortcuts and global hotkeys for Chandra applications

=head1 SYNOPSIS

	use Chandra::App;

	my $app = Chandra::App->new(title => 'Editor');

	# Direct binding on app
	$app->shortcut('mod+s', sub { save() });

	# Access Shortcut instance
	my $sc = $app->shortcuts;

	$sc->bind('ctrl+s', sub {
	    my ($event) = @_;
	    save_document();
	});

	$sc->bind('ctrl+shift+p', sub {
	    open_command_palette();
	});

	# Platform-aware modifier (Cmd on macOS, Ctrl on Linux/Windows)
	$sc->bind('mod+z', sub { undo() });
	$sc->bind('mod+shift+z', sub { redo() });

	# Unbind
	$sc->unbind('ctrl+s');

	# List registered shortcuts
	my @bindings = $sc->list;

	# Check if combo is bound
	my $bound = $sc->is_bound('ctrl+s');

	# Disable/enable
	$sc->disable('ctrl+s');
	$sc->enable('ctrl+s');
	$sc->disable_all;
	$sc->enable_all;

	# Key sequence (chord) support
	$sc->bind('ctrl+k ctrl+c', sub { comment_selection() });

	# Prevent default browser behavior
	$sc->bind('ctrl+p', sub { custom_print() }, prevent_default => 1);

	# Shortcut map (bulk registration)
	$app->shortcut_map({
	    'mod+s'       => \&save,
	    'mod+o'       => \&open_file,
	    'mod+shift+s' => \&save_as,
	    'mod+q'       => sub { $app->terminate },
	    'f11'         => sub { $app->fullscreen },
	});

	$app->run;

=head1 DESCRIPTION

Chandra::Shortcut registers app-level keyboard shortcuts from Perl.
It handles key combos like Ctrl+S, Cmd+K, etc. without raw JS event
listeners.  A C<keydown> listener is injected via the existing Bridge
mechanism, and key events are normalised and dispatched to registered
Perl handlers.

=head1 CONSTRUCTOR

=head2 new(%args)

Create a new Shortcut instance.  Usually accessed via C<< $app->shortcuts >>.

=head1 METHODS

=head2 bind($combo, $handler, %opts)

Register a keyboard shortcut.  C<$combo> is a string like C<ctrl+s>,
C<mod+shift+p>, or C<ctrl+k ctrl+c> (chord).  C<$handler> receives a
L<Chandra::Event> object.

Options:

=over

=item prevent_default => 1

Prevent the browser's default action for this key combo.

=back

=head2 unbind($combo)

Remove a previously registered shortcut.

=head2 list()

Return a list of hashrefs describing registered shortcuts:

	({ combo => 'ctrl+s', handler => $sub, enabled => 1, prevent_default => 0 }, ...)

=head2 is_bound($combo)

Returns true if the combo is registered.

=head2 disable($combo)

Temporarily disable a specific shortcut without removing it.

=head2 enable($combo)

Re-enable a previously disabled shortcut.

=head2 disable_all()

Disable all shortcuts globally.

=head2 enable_all()

Re-enable all shortcuts after a global disable.

=head2 inject()

Inject the shortcut listener JavaScript into the webview.  Called
automatically by C<< Chandra::App->run() >>.

=head2 js_code()

Return the JavaScript source for manual injection.

=head1 KEY NORMALIZATION

=over

=item *

Key names are case-insensitive.

=item *

C<mod> maps to C<meta> (Cmd) on macOS, C<ctrl> on Linux/Windows.

=item *

Aliases: C<space>, C<enter>, C<escape>, C<tab>, C<backspace>, C<delete>,
C<up>, C<down>, C<left>, C<right>, C<plus>, C<minus>, C<equal>.

=item *

Function keys C<f1>E<ndash>C<f12> are supported.

=item *

Modifiers are canonically ordered: ctrl, shift, alt, meta.

=back

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Event>, L<Chandra::Bridge>

=cut
