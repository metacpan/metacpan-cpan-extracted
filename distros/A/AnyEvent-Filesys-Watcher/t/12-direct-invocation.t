use strict;
use warnings;

use Test::More;

use AnyEvent::Filesys::Watcher;

my $AEFW = 'AnyEvent::Filesys::Watcher';

subtest 'Try to load the correct backend for this O/S' => sub {
	if ($^O eq 'linux' and eval { require Linux::Inotify2; 1 }) {
		require AnyEvent::Filesys::Watcher::Inotify2;
		my $w = AnyEvent::Filesys::Watcher::Inotify2->new (
			directories => ['t'],
			callback => sub { }
		);
		isa_ok $w, "${AEFW}::Inotify2", 'Inotify2';
		isa_ok $w, "${AEFW}", 'parent class';
	} elsif (
		$^O eq 'darwin' and eval {
			require Mac::FSEvents;
			1;
		}) {
		require AnyEvent::Filesys::Watcher::FSEvents;
		my $w = AnyEvent::Filesys::Watcher::FSEvents->new (
			directories => ['t'],
			callback => sub { }
		);
		isa_ok $w, "${AEFW}::FSEvents", 'FSEvents';
		isa_ok $w, "${AEFW}", 'parent class';
	} elsif (
		$^O eq 'MSWin32' and eval {
			require Filesys::Notify::Win32::ReadDirectoryChanges;
			1;
		}) {
		require AnyEvent::Filesys::Watcher::ReadDirectoryChanges;
		my $w = AnyEvent::Filesys::Watcher::ReadDirectoryChanges->new (
			directories => ['t'],
			callback => sub { }
		);
		isa_ok $w, "${AEFW}::ReadDirectoryChanges", 'ReadDirectoryChanges';
		isa_ok $w, "${AEFW}", 'parent class';
	} elsif (
		$^O =~ /bsd/ and eval {
			require IO::KQueue;
			1;
		}) {
		require AnyEvent::Filesys::Watcher::KQueue;
		my $w = AnyEvent::Filesys::Watcher::KQueue->new (
			directories => ['t'],
			callback => sub { }
		);
		isa_ok $w, "${AEFW}::KQueue", 'KQueue';
		isa_ok $w, "${AEFW}", 'parent class';
	} else {
		my $w = AnyEvent::Filesys::Watcher->new (
			directories => ['t'],
			callback => sub { }
		);
		require AnyEvent::Filesys::Watcher::Fallback;
		isa_ok $w, "${AEFW}::Fallback", 'Fallback';
		isa_ok $w, "${AEFW}", 'parent class';
	}
};

if ($^O eq 'darwin' and eval { require IO::KQueue; 1; }) {
	subtest 'Try to force KQueue on Mac with IO::KQueue installed' => sub {
		my $w = eval {
			require AnyEvent::Filesys::Watcher::KQueue;
			AnyEvent::Filesys::Watcher::KQueue->new(
				directories => ['t'],
				callback => sub { },
			);
		};
		my $x = $@ || 'no exception';
		ok !$@, "$x";
		isa_ok $w, "${AEFW}::KQueue", 'KQueue';
		isa_ok $w, $AEFW;
	}
}

done_testing;
