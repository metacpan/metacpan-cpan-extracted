package Chandra::HotReload;

use strict;
use warnings;
use File::Find ();

our $VERSION = '0.22';

# XS methods are registered under the Chandra bootstrap.
# Ensure the shared object is loaded.
require Chandra;

1;

__END__

=head1 NAME

Chandra::HotReload - File watching and hot reload for Chandra applications

=head1 SYNOPSIS

	use Chandra::HotReload;

	my $watcher = Chandra::HotReload->new(interval => 1.0);

	$watcher->watch('lib/', sub {
	    my ($changed_files) = @_;
	    print "Changed: @$changed_files\n";
	    $app->set_content(build_ui());
	    $app->refresh;
	});

	# In event loop (or via App integration):
	$watcher->poll;

	# Or integrated with App:
	$app->watch('lib/', sub {
	    my ($changed) = @_;
	    $app->set_content(rebuild());
	    $app->refresh;
	});
	$app->run;   # automatically polls during event loop

=head1 DESCRIPTION

Chandra::HotReload provides file-system watching via C<stat()> polling.
Register paths (files or directories) to watch along with callbacks
that are invoked whenever a change is detected.

When integrated with L<Chandra::App> via C<< $app->watch() >>, the
event loop automatically switches to non-blocking mode and polls for
file changes between iterations.

=head1 METHODS

=head2 new(%args)

Create a new watcher.  Options:

=over 4

=item interval - Minimum seconds between polls (default: 1.0)

=back

=head2 watch($path, $coderef)

Register a path to watch.  The callback receives an arrayref of changed
file paths when a modification, addition, or deletion is detected.

=head2 poll()

Check all watched paths for changes.  Returns the number of changed
files (0 if nothing changed or the poll interval has not elapsed).

=head2 clear()

Remove all watches.

=head2 watched_paths()

Return a list of currently watched paths.

=head2 interval($seconds)

Get or set the poll interval.

=head1 SEE ALSO

L<Chandra::App>

=cut
