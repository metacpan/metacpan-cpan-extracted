package Amethyst::Brain::Infobot::Module::Cool;

use strict;
use vars qw(@ISA);
use Amethyst::Message;
use Amethyst::Brain::Infobot;
use Amethyst::Brain::Infobot::Module;

@ISA = qw(Amethyst::Brain::Infobot::Module);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(
					Name		=> 'Cool',
					Regex		=> qr/^(?:neat|cool)(?:[!.])?$/i,
					Usage		=> 'cool',
					Description	=> "Be Cool",
					@_
						);

	return bless $self, $class;
}

sub action {
    my ($self, $message) = @_;

	my $reply = $self->reply_to($message, 'cool ' x (2 + rand(5)));
	$reply->send;

	return 1;
}

1;
