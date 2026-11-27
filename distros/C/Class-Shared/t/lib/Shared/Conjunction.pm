package Shared::Conjunction;

# A target for the test suite that wraps a real module rather than the suite's
# own Shared::Counter.  Lingua::Conjunction is a function library with
# package-level settings and no new(), so it cannot be the target itself: this
# gives the backend something to construct, and every object remembers the
# language it wants while the real work is still done by Lingua::Conjunction.

use strict;
use warnings;

use Lingua::Conjunction ();

our $VERSION = '0.01';

sub new {
	my ($class, %opt) = @_;

	return bless {
		lang => defined $opt{lang} ? $opt{lang} : 'en',
	}, $class;
}

sub lang { $_[0]->{lang} }

sub module_version { $Lingua::Conjunction::VERSION }

sub conjunction {
	my ($self, @items) = @_;

	# The language is package state, not object state, so set it on every
	# call: the backend answers one call at a time, so this is deterministic.
	Lingua::Conjunction->lang($self->{lang});

	return Lingua::Conjunction::conjunction(@items);
}

1;
