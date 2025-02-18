package AnyEvent::Filesys::Watcher::ReadDirectoryChanges::Queue;

use strict;

# Once this module works it should be inlined with the MS-DOS backend because
# it is only relevant there.  For the time being, ship it separately, so that
# it can be tested independently.

use Locale::TextDomain ('AnyEvent-Filesys-Watcher');
use Thread::Queue 3.13;
use Socket;
use IO::Handle;
use IO::Select;

sub new {
	my ($class, @args) = @_;

	my $q = Thread::Queue->new(@args);

	# You cannot do a select on an anonymous pipe on MS-DOS.  But sockets
	# seem to work.
	socketpair my $rh, my $wh, AF_UNIX, SOCK_STREAM, PF_UNSPEC
		or die __x("cannot create pipe: {error}", error => $!);
	shutdown $rh, 1;
	shutdown $wh, 0;
	$rh = IO::Handle->new_from_fd($rh, 'r');
	$wh = IO::Handle->new_from_fd($wh, 'w');
	$rh->autoflush(1);
	$wh->autoflush(1);

	if ($q->pending) {
		$wh->print('1')
			or die __x("cannot write to pipe: {error}", error => $!);
	}

	bless {
		__q => $q,
		__rh => $rh,
		__wh => $wh,
	}, $class;
}

sub handle {
	shift->{__rh};
}

sub enqueue {
	my ($self, @items) = @_;

	$self->{__q}->enqueue(@items);
	if ($self->{__q}->pending) {
		$self->{__wh}->print('1')
			or die __x("cannot write to pipe: {error}", error => $!);
	}

	return $self;
}

sub dequeue {
	my ($self, @args) = @_;

	my @items = $self->{__q}->dequeue(@args);
	if (!$self->{__q}->pending) {
		# Maybe it is better to set the handle to non-blocking instead of doing
		# a select()? Whatever is more portable.
		while (IO::Select->new($self->{__rh})->can_read(0)) {
			$self->{__rh}->getc;
		}
	}

	return @items;
}

sub pending {
	shift->{__q}->pending;
}

1;
