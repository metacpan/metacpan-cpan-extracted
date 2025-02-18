package AnyEvent::Filesys::Watcher::FSEvents;

use strict;

our $VERSION = 'v0.1.1'; # VERSION

use AnyEvent;
use Mac::FSEvents;
use Scalar::Util qw(weaken);
use Config;

use base qw(AnyEvent::Filesys::Watcher);

# Needed for counting unset bits.
our $THREES = 0x3333_3333;
our $FIVES = 0x5555_5555;
for (my $shift = $Config{ivsize}; $shift -= 4; $shift > 4) {
	$THREES = ($THREES << 8) | 0x3333_3333;
	$FIVES = ($FIVES << 8) | 0x5555_5555;
}

# Watching files and not just directories is a feature introduced in macOS 10.7
# (Lion).
our $has_file_events = eval {
	local $SIG{__WARN__} = 'IGNORE';
	Mac::FSEvents::constant('FILE_EVENTS');
};

# See https://developer.apple.com/documentation/coreservices/1455361-fseventstreameventflags.
my @flags = (
	# 0x00000000
	'kFSEventStreamEventFlagNone',
	# 0x00000001
	'kFSEventStreamEventFlagMustScanSubDirs',
	# 0x00000002
	'kFSEventStreamEventFlagUserDropped',
	# 0x00000004
	'kFSEventStreamEventFlagKernelDropped',
	# 0x00000008
	'kFSEventStreamEventFlagEventIdsWrapped',
	# 0x00000010
	'kFSEventStreamEventFlagHistoryDone',
	# 0x00000020
	'kFSEventStreamEventFlagRootChanged',
	# 0x00000040
	'kFSEventStreamEventFlagMount',
	# 0x00000080
	'kFSEventStreamEventFlagUnmount',
	# 0x00000100
	'kFSEventStreamEventFlagItemCreated',
	# 0x00000200
	'kFSEventStreamEventFlagItemRemoved',
	# 0x00000400
	'FSEventStreamEventFlagItemInodeMetaMod',
	# 0x00000800
	'kFSEventStreamEventFlagItemRenamed',
	# 0x00001000
	'kFSEventStreamEventFlagItemModified',
	# 0x00002000
	'kFSEventStreamEventFlagItemFinderInfoMod',
	# 0x00004000
	'kFSEventStreamEventFlagItemChangeOwner',
	# 0x00008000
	'kFSEventStreamEventFlagItemXattrMod',
	# 0x00010000
	'kFSEventStreamEventFlagItemIsFile',
	# 0x00020000
	'FSEventStreamEventFlagItemIsDir',
	# 0x00040000
	'kFSEventStreamEventFlagItemIsSymlink',
	# 0x00080000
	'kFSEventStreamEventFlagOwnEvent',
	# 0x00100000
	'kFSEventStreamEventFlagItemIsHardlink',
	# 0x00200000
	'kFSEventStreamEventFlagItemIsLastHardlink',
	# 0x00400000
	'kFSEventStreamEventFlagItemCloned',
);

use constant IGNORE => 0;
use constant CREATED => 1;
use constant MODIFIED => 2;
use constant DELETED => 3;
use constant RENAMED => 4;
use constant RESCAN => 5;

my %flag_type = (
	# Cannot happen.
	kFSEventStreamEventFlagNone => IGNORE,

	# Something went wrong.  We use the fallback method and re-scan the file
	# system for changes.
	kFSEventStreamEventFlagMustScanSubDirs => RESCAN,

	# Errors.  A re-scan should recover from them.  They are issued together
	# with kFSEventStreamEventFlagMustScanSubDirs.
	kFSEventStreamEventFlagUserDropped => RESCAN,
	kFSEventStreamEventFlagKernelDropped => RESCAN,

	# Self-explanatory.
	kFSEventStreamEventFlagItemCreated => CREATED,

	# Issued, when the id counter has overflown the 64 bit limit.  We ignore
	# the ids anyhow.
	kFSEventStreamEventFlagEventIdsWrapped => IGNORE,

	# Sentinel event only issued with 'since'.  It marks the end of historical
	# events.  Subsequent events are new.
	kFSEventStreamEventFlagHistoryDone => IGNORE,

	# One of the parent directories of a directory being watched has changed.
	# It could mean that the directory has vanished. Re-scan?
	kFSEventStreamEventFlagRootChanged => RESCAN,

	# Mount/unmount.  FIXME! Is this really necessary? Or does the kernel also
	# send events for all files that vanish/appear because of the mount resp.
	# unmount?
	kFSEventStreamEventFlagMount => RESCAN,
	kFSEventStreamEventFlagUnmount => RESCAN,

	# Self-explanatory.
	kFSEventStreamEventFlagItemCreated => CREATED,
	kFSEventStreamEventFlagItemRemoved => DELETED,

	# Inode meta data has changed.
	FSEventStreamEventFlagItemInodeMetaMod => MODIFIED,

	# Rename events are a pain in the neck because they are issued for the
	# source and the destination file.  We simply check the filesystem in that
	# case and create a 'deleted' or 'created/modified' event.
	kFSEventStreamEventFlagItemRenamed => RENAMED,

	# The regular modification case.
	kFSEventStreamEventFlagItemModified => MODIFIED,

	# The Finder meta data has changed.
	kFSEventStreamEventFlagItemFinderInfoMod => MODIFIED,

	# chown().
	kFSEventStreamEventFlagItemChangeOwner => MODIFIED,

	# chmod().
	kFSEventStreamEventFlagItemXattrMod => MODIFIED,

	# These should be clear.  They are, of course, not ignored, but they don't
	# modify the event type.
	kFSEventStreamEventFlagItemIsFile => IGNORE,
	FSEventStreamEventFlagItemIsDir => IGNORE,
	kFSEventStreamEventFlagItemIsSymlink => IGNORE,

	# You can actually pass a 'MarkSelf' flag to the constructor (currently
	# not supported by Mac::FSEvents).  In that case, this flag will be set,
	# whenever the event was triggered by the own process.
	kFSEventStreamEventFlagOwnEvent => IGNORE,

	# Self-explanatory.
	kFSEventStreamEventFlagItemIsHardlink => IGNORE,

	# When the link count of an inode goes to 0, the inode is removed.  If
	# the directory entry referring to it had been a hard link or was hard
	# linked, then this event is also triggered.
	kFSEventStreamEventFlagItemIsLastHardlink => IGNORE,

	# A clone is a copy on write copy of a file, see clonefile(2).  You can
	# reproduce that by right-clicking on a file in Finder and then create
	# a duplicate of that file.  Since this only accompanies a
	# kFSEventStreamEventFlagItemCreated, we can safely ignore it.
	kFSEventStreamEventFlagItemCloned => IGNORE,
);

sub new {
	my ($class, %args) = @_;

	$args{interval} = 0.1 if !exists $args{interval};

	my $self = $class->SUPER::_new(%args);

	delete $args{directories};
	delete $args{callback};
	delete $args{filter};
	my $fs_monitor = Mac::FSEvents->new({
		path => $self->directories,
		latency => $args{interval},
		file_events => $has_file_events,
		%args,
	});

	# Create an AnyEvent->io watcher for each fs_monitor
	my $alter_ego = $self;
	$self->{__mac_fh} = $fs_monitor->watch;

	my $watcher = AE::io $self->{__mac_fh}, 0, sub {
		if (my @raw_events = $fs_monitor->read_events) {
			$alter_ego->_processEvents(@raw_events);
		}
	};
	weaken $alter_ego;

	$self->_watcher($watcher);

	return $self;
}

if ($has_file_events) {
	sub _parseEvents {
		my ($self, $filter, @raw_events) = @_;

		my @events;
		foreach my $raw_event (@raw_events) {
			my $cooked = eval { $self->__parseEvent($raw_event) };
			if ($@) {
				if ("rescan\n" eq $@) {
					push @events, $self->rescan;
					return @events;
				}
			}
			push @events, $cooked if $filter->($cooked);
		}

		return @events;
	}
}

sub __parseEvent {
	my ($self, $raw_event) = @_;

	# Count trailing zero bits. Taken from Chess::Plisco::Macro.
	my $ctzb = sub {
		my ($bb) = @_;

		my $B = $bb & -$bb;
		my $A = $B - 1 - ((($B - 1) >> 1) & $FIVES);
		my $C = ($A & $THREES) + (($A >> 2) & $THREES);
		my $n = $C + ($C >> 32);
		$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);
		$n = ($n & 0xffff) + ($n >> 16);
		$n = ($n & 0xff) + ($n >> 8);
	};

	my $flags = $raw_event->flags || return;

	my $path = $self->_makeAbsolute($raw_event->path);
	my ($type, $is_directory);
	my $old_fs = $self->_oldFilesystem;
	while ($flags) {
		my $bit = $ctzb->($flags);
		$flags &= $flags - 1;
		my $flag = $flags[$bit + 1];

		if ('FSEventStreamEventFlagItemIsDir' eq $flag) {
			$is_directory = 1;
		} elsif (CREATED eq $flag_type{$flag}) {
			$type = 'created' if $type ne 'deleted';
		} elsif (MODIFIED eq $flag_type{$flag}) {
			$type = 'modified' if $type ne 'deleted',
		} elsif (DELETED eq $flag_type{$flag}) {
			$type = 'deleted';
		} elsif (IGNORE eq $flag_type{$flag}) {
			next;
		} elsif (RENAMED eq $flag_type{$flag}) {
			if (-e $path) {
				if ($old_fs->{$path}) {
					$type = 'modified';
				} else {
					$type = 'created';
				}
			} else {
				$type = 'deleted';
			}
		} elsif (RESCAN eq $flag_type{$flag}) {
			die "must rescan\n";
		}
	}

	if ('deleted' eq $type) {
		delete $old_fs->{$path};
	} elsif ('modified' eq $type || 'created' eq $type) {
		$old_fs->{path} = $self->_stat($path);
	} else {
		# Issue a warning?
		return;
	}

	return AnyEvent::Filesys::Watcher::Event->new(
		path => $path,
		type => $type,
		is_directory => $is_directory,
		id => $raw_event->id,
	);
}

1;
