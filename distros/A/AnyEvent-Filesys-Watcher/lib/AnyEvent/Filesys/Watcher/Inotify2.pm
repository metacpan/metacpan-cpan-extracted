package AnyEvent::Filesys::Watcher::Inotify2;

use strict;

our $VERSION = 'v0.1.1'; # VERSION

use Locale::TextDomain ('AnyEvent-Filesys-Watcher');

use AnyEvent;
use Linux::Inotify2;
use Carp;
use Path::Iterator::Rule;
use Scalar::Util qw(weaken);

use base qw(AnyEvent::Filesys::Watcher);

sub new {
	my ($class, %args) = @_;

	my $self = $class->SUPER::_new(%args);

	my $inotify = Linux::Inotify2->new
		or croak "Unable to create new Linux::INotify2 object: $!";

	# Need to add all the subdirs to the watch list, this will catch
	# modifications to files too.
	my $old_fs = $self->_oldFilesystem;
	my @dirs = grep { $old_fs->{$_}->{is_directory} } keys %$old_fs;

	my $alter_ego = $self;
	for my $dir (@dirs) {
		$inotify->watch(
			$dir,
			IN_MODIFY | IN_CREATE | IN_DELETE | IN_DELETE_SELF |
				IN_MOVE | IN_MOVE_SELF | IN_ATTRIB,
			sub { my $e = shift; $alter_ego->_processEvents($e); }
		);
	}
	weaken $alter_ego;

	$self->_filesystemMonitor($inotify);

	$self->_watcher([AnyEvent->io(
		fh => $inotify->fileno,
		poll => 'r',
		cb => sub {
			$inotify->poll;
		}
	)]);

	bless $self, $class;
}

# Parse the events returned by Inotify2 instead of rescanning the files.
# There are small changes in behaviour compared to the previous releases
# without parse_events:
#
# 1. `touch test` causes an additional "modified" event after the "created"
# 2. `mv test2 test` if test exists before, event for test would be "modified"
#     in parent code, but is "created" here
#
# Because of these differences, we default to the original behavior unless the
# parse_events flag is true.
sub _parseEvents {
	my ($self, $filter_cb, @raw_events) = @_;

	my @events =
		map { $filter_cb->($_) }
		grep { defined }
		map { $self->__makeEvent($_) } @raw_events;

	# New directories are not automatically watched by inotify.
	$self->__addEventsToWatch(@events);

	# Any entities that were created in new dirs (before the call to
	# _add_events_to_watch) will have been missed. So we walk the filesystem
	# now.
	push @events,
		map { $self->__addEntitiesInSubdir($filter_cb, $_) }
		grep { $_->isDirectory && $_->isCreated }
		@events;

	return @events;
}

sub __addEntitiesInSubdir {
	my ($self, $filter_cb, $e) = @_;
	my @events;

	my $rule = Path::Iterator::Rule->new;
	my $next = $rule->iter($e->path);
	while (my $file = $next->()) {
		next if $file eq $e->path; # $e->path will have already been added

		my $new_event = AnyEvent::Filesys::Watcher::Event->new(
			path => $file,
			type => 'created',
			isDirectory => -d $file,
		);

		next unless $filter_cb->($new_event);
		$self->__addEventsToWatch($new_event);
		push @events, $new_event;
	}

	return @events;
}

sub __makeEvent {
	my ($self, $e) = @_;

	my $type = undef;

	$type = 'modified' if ($e->mask & (IN_MODIFY | IN_ATTRIB));
	$type = 'deleted'
		if ($e->mask &
		(IN_DELETE | IN_DELETE_SELF | IN_MOVED_FROM | IN_MOVE_SELF));
	$type = 'created' if ($e->mask & (IN_CREATE | IN_MOVED_TO));

	return unless $type;
	return AnyEvent::Filesys::Watcher::Event->new(
		path => $e->fullname,
		type => $type,
		is_directory => !!$e->IN_ISDIR,
	);
}

# Needed if `parse_events => 0`
sub _postProcessEvents {
	my ($self, @events) = @_;
	return $self->__addEventsToWatch(@events);
}

sub __addEventsToWatch {
	my ($self, @events) = @_;

	for my $event (@events) {
	next unless $event->isDirectory && $event->isCreated;

	$self->_filesystemMonitor->watch(
		$event->path,
		IN_MODIFY | IN_CREATE | IN_DELETE | IN_DELETE_SELF |
			IN_MOVE | IN_MOVE_SELF | IN_ATTRIB,
		sub { my $e = shift; $self->_processEvents($e); });
	}

	return;
}

1;
