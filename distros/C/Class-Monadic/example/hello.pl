#!perl -w

use strict;

use IO::Handle;
use Class::Monadic;

Class::Monadic->initialize(\*STDOUT)->add_method(
	say       => sub{
		my $io = shift;
		$io->print(@_, "\n");
	},
	say_hello => sub{
		my($io) = @_;

		$io->say("Hello, world!");
	},
);

STDOUT->say_hello();

