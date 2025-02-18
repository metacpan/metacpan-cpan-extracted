package AnyEvent::Filesys::Watcher::Fallback;

use strict;

our $VERSION = 'v0.1.1'; # VERSION

use Locale::TextDomain ('AnyEvent-Filesys-Watcher');

use AnyEvent;
use Scalar::Util qw(weaken);

use base qw(AnyEvent::Filesys::Watcher);

sub new {
	my ($class, %args) = @_;

	my $self = $class->SUPER::_new(%args);

	my $alter_ego = $self;
	my $impl = AnyEvent->timer(
		after => $self->interval,
		interval => $self->interval,
		cb => sub {
			$alter_ego->_processEvents();
		}
	);
	weaken $alter_ego;

	if (!$impl) {
		die __x("Error creating timer: {error}\n", error => $@);
	}

	$self->_watcher($impl);

	return $self;
}

1;

