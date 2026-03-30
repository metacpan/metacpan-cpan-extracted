package Chandra::HotReload;

use strict;
use warnings;
use File::Find ();

our $VERSION = '0.06';

sub new {
	my ($class, %args) = @_;
	return bless {
		watches     => [],
		interval    => $args{interval} // 1.0,
		_last_check => 0,
	}, $class;
}

sub watch {
	my ($self, $path, $callback) = @_;

	die "watch() requires a path" unless defined $path;
	die "watch() requires a callback" unless ref $callback eq 'CODE';
	die "watch() path does not exist: $path" unless -e $path;

	my $files = $self->_scan_files($path);

	push @{$self->{watches}}, {
		path     => $path,
		callback => $callback,
		files    => $files,
	};

	return $self;
}

sub poll {
	my ($self) = @_;

	my $now = time();
	return 0 if ($now - $self->{_last_check}) < $self->{interval};
	$self->{_last_check} = $now;

	my $total_changed = 0;

	for my $watch (@{$self->{watches}}) {
		my @changed;
		my $current = $self->_scan_files($watch->{path});

		# Modified or new files
		for my $file (keys %$current) {
			if (!exists $watch->{files}{$file}
				|| $watch->{files}{$file} != $current->{$file}) {
				push @changed, $file;
			}
		}

		# Deleted files
		for my $file (keys %{$watch->{files}}) {
			if (!exists $current->{$file}) {
				push @changed, $file;
			}
		}

		if (@changed) {
			$watch->{files} = $current;
			eval { $watch->{callback}->(\@changed) };
			if ($@) {
				warn "Chandra::HotReload: callback error: $@";
			}
			$total_changed += scalar @changed;
		}
	}

	return $total_changed;
}

sub clear {
	my ($self) = @_;
	$self->{watches} = [];
	return $self;
}

sub watched_paths {
	my ($self) = @_;
	return map { $_->{path} } @{$self->{watches}};
}

sub interval {
	my ($self, $val) = @_;
	$self->{interval} = $val if defined $val;
	return $self->{interval};
}

sub _scan_files {
	my ($self, $path) = @_;
	my %files;

	if (-f $path) {
		my @stat = stat($path);
		$files{$path} = $stat[9] if @stat;
	} elsif (-d $path) {
		File::Find::find({
				wanted => sub {
					return unless -f $_;
					my @stat = stat($_);
					$files{$File::Find::name} = $stat[9] if @stat;
				},
				no_chdir => 1,
			}, $path);
	}

	return \%files;
}

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
