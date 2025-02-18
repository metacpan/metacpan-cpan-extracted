package AnyEvent::Filesys::Watcher::KQueue;

use strict;

our $VERSION = 'v0.1.1'; # VERSION

use Locale::TextDomain ('AnyEvent-Filesys-Watcher');

use AnyEvent;
use IO::KQueue;
use Errno qw(:POSIX);
use Scalar::Util qw(weaken);

use base qw(AnyEvent::Filesys::Watcher);

# Arbitrary default limit on open filehandles before we issue a warning.
our $WARN_FILEHANDLE_LIMIT = 128;

# And now try to be more accurate.
eval {
	require BSD::Resource;

	my $rlimits = BSD::Resource::get_rlimits();
	foreach my $resource (qw(RLIMIT_NOFILE RLIMIT_OFILE RLIMIT_OPEN_MAX)) {
		if (exists $rlimits->{$resource}) {
			my ($limit) = BSD::Resource::getrlimit($resource);
			$WARN_FILEHANDLE_LIMIT = $limit >> 1;
			last;
		}
	}
};

sub new {
	my ($class, %args) = @_;

	my $self = $class->SUPER::_new(%args);

	my $kqueue = IO::KQueue->new;
	if (!$kqueue) {
		require Carp;
		Carp::croak(
			__x("Unable to create new IO::KQueue object: {error}",
			    error => $!)
		);
	}
	$self->_filesystemMonitor($kqueue);

	# Need to add all the subdirs to the watch list, this will catch
	# modifications to files too.
	my $old_fs = $self->_oldFilesystem;
	my @paths  = keys %$old_fs;

	my $fhs = {};
	my $watcher = {
		fhs => $fhs,
	};
	$self->_watcher($watcher);

	# Add each file and each directory to a hash of path => fh
	for my $path (@paths) {
		my $fh = $self->__watch($path);
		$fhs->{$path} = $fh if defined $fh;
	}

	# Now use AE to watch the KQueue.
	my $w;
	my $alter_ego = $self;
	$w = AE::io $$kqueue, 0, sub {
		if (my @events = $kqueue->kevent) {
			$alter_ego->_processEvents(@events);
		}
	};
	weaken $alter_ego;
	$watcher->{w} = $w;

	$self->_checkFilehandleCount;

	return $self;
}

# Need to add newly created items (directories and files) or remove deleted
# items.  This isn't going to be perfect. If the path is not canonical then we
# won't deleted it.  This is done after filtering. So entire dirs can be
# ignored efficiently.
sub _postProcessEvents {
	my ($self, @events) = @_;

	for my $event (@events) {
		if ($event->isCreated) {
			my $fh = $self->__watch($event->path);
			$self->{fhs}->{$event->path} = $fh if defined $fh;
		} elsif ($event->isDeleted) {
			delete $self->{fhs}->{$event->path};
		}
	}

	$self->_checkFilehandleCount;

	return;
}

sub __watch {
	my ($self, $path) = @_;

	open my $fh, '<', $path or do {
		if ($! == EMFILE) {
			warn __(<<'EOF');
KQueue requires a filehandle for each watched file and directory.
You have exceeded the number of filehandles permitted by the OS.
EOF
			return;
		}

		require Carp;
		Carp::confess(
			__x("Cannot open file '{path}': {error}",
			    path => $path, error => $!)
		);
	};

	$self->_filesystemMonitor->EV_SET(
		fileno($fh),
		EVFILT_VNODE,
		EV_ADD | EV_ENABLE | EV_CLEAR,
		NOTE_DELETE | NOTE_WRITE | NOTE_EXTEND | NOTE_ATTRIB | NOTE_LINK |
			NOTE_RENAME | NOTE_REVOKE,
	);

	return $fh;
}

sub _checkFilehandleCount {
	my ($self) = @_;

	my $count = $self->_watcherCount;
	if ($count > $WARN_FILEHANDLE_LIMIT) {
		require Carp;
		Carp::confess(__x(<<'EOF', count => $count));
KQueue requires a filehandle for each watched file and directory.
You currently have {count} filehandles for this AnyEvent::Filesys::Watcher object.
The use of the KQueue backend is not recommended.
EOF
	}

	return $count;
}

sub _watcherCount {
	my ($self) = @_;

	my $fhs = $self->_watcher->{fhs};

	return scalar keys %$fhs;
}

1;
