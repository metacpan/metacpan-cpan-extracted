package Amethyst::Brain;

use strict;
use Data::Dumper;
use POE;

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	return bless $self, $class;
}

sub init {
	my ($self) = @_;
	# Not overriding this is not fatal.
}

sub think {
	my ($self, $messages, @args) = @_;
	die "Think not implemented by brain";
}

sub reply_to {
	my ($self, $message, $text) = @_;
	return $message->reply($text);
}

1;
