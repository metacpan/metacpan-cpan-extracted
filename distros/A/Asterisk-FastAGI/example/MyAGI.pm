package MyAGI;

use strict;
use base 'Asterisk::FastAGI';

sub agi_handler {
	my $self = shift;
	
	sleep 2;
	$self->agi->say_number(54321);
}

1;
