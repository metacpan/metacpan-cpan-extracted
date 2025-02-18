use strict;

use Test::More;
use Test::Memory::Cycle;

use AnyEvent::Filesys::Watcher;

# Devel::Cycle has a bug/limitation - first reported in 2010 - in that it
# issues a warning "Unhandled type: GLOB at .../Devel/Cycle.pm line NNN",
# see https://rt.cpan.org/Public/Bug/Display.html?id=56681.  Since Devel::Cycle
# is unfortunately not maintained at the moment, we have to help ourselves
# and try to shut up the by gratuituous warning by hooking into the pseudo
# signal handler for __WARN__.
#
# The other options would be to use a wrapper around Devel::Cycle::_get_type()
# or UNIVERSAL::isa() but that would rely on the current implementation of
# Devel::Cycle.
$SIG{__WARN__} = sub {
	my ($msg) = @_;

	if ($msg !~ m{^Unhandled type: (?:GLOB|REGEXP|OBJECT) at /.*/Devel/Cycle.pm line [0-9]+}) {
		print STDERR $msg;
	}
};

my $instance;

$instance = AnyEvent::Filesys::Watcher->new(
	directories => 't',
	callback => sub {},
	backend => 'Fallback',
);
memory_cycle_ok $instance, 'Fallback';

if ('linux' eq $^O && eval { require Linux::Inotify2 }) {
	$instance = AnyEvent::Filesys::Watcher->new(
		directories => 't',
		callback => sub {},
		backend => 'Inotify2',
	);
	memory_cycle_ok $instance, 'Inotify2';
}

if ('darwin' eq $^O && eval { require Mac::FSEvents }) {
	$instance = AnyEvent::Filesys::Watcher->new(
		directories => 't',
		callback => sub {},
		backend => 'FSEvents',
	);
	memory_cycle_ok $instance, 'FSEvents';
}

if (('MSWin32' eq $^O || 'cygwin' eq $^O) && eval { require Mac::FSEvents }) {
	$instance = AnyEvent::Filesys::Watcher->new(
		directories => 't',
		callback => sub {},
		backend => 'ReadDirectoryChanges',
	);
	memory_cycle_ok $instance, 'ReadDirectoryChanges';
}

if (($^O =~ /bsd/i || 'darwin' eq $^O) && eval { require IO::KQueue }) {
	$instance = AnyEvent::Filesys::Watcher->new(
		directories => 't',
		callback => sub {},
		backend => 'KQueue',
	);
	memory_cycle_ok $instance, 'KQueue';
}

done_testing;
