use strict;
use warnings;

use Test::More;
use Test::Exception;

use AnyEvent::Filesys::Watcher;

use Test::Without::Module qw(
	Linux::Inotify2
	Mac::FSEvents
	Filesys::Notify::Win32::ReadDirectoryChanges
	IO::KQueue);

my $w = AnyEvent::Filesys::Watcher->new(
	directories => ['t'],
	callback => sub { },
	backend => 'Fallback',
);
isa_ok $w, 'AnyEvent::Filesys::Watcher';
isa_ok $w, 'AnyEvent::Filesys::Watcher::Fallback',  '... Fallback';

SKIP: {
	my $backend;
	if ('linux' eq $^O) {
		$backend = 'Inotify2';
	} elsif ('darwin' eq $^O) {
		$backend = 'FSEvents';
	} elsif ('MSWin32' eq $^O || 'cygwin' eq $^O) {
		$backend = 'ReadDirectoryChanges';
	} elsif ($^O =~ /bsd/i) {
		$backend = 'KQueue';
	} else {
		skip 'Test for Mac/Linux/MS-DOS/BSD only', 1;
	}
	throws_ok {
		AnyEvent::Filesys::Watcher->new(
			directories => ['t'],
			callback => sub { },
			backend => $backend,
		);
	}
	qr/you may need to install the [_0-9a-zA-Z:]+ module/, 'fails ok';
}

done_testing;
