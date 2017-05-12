package Amethyst::Brain::Eliza;

use strict;
use vars qw(@ISA);
use URI;
use Amethyst::Brain;
use Amethyst::Message;
use Chatbot::Eliza;

@ISA = qw(Amethyst::Brain);

sub init {
	my $self = shift;
	# $self->{Eliza} = new Chatbot::Eliza "Amethyst";
	$self->{Eliza} = new Amethyst::Brain::Eliza::Core "Amethyst";
}

sub think {
	my $self = shift;
	my $message = shift;

	my $content = $message->content;

	# return unless random(10) < 2;

	return undef unless
			$content =~ /^Amethyst:/ ||
			$message->channel eq 'tell';

	my $data = $self->{Eliza}->transform($message->content);

	my $reply = $message->reply($data);
	# $reply->channel('spam') unless $message->channel eq 'tell';
	$reply->send;

	return 1;
}

package Amethyst::Brain::Eliza::Core;

use strict;
use vars qw(@ISA);

@ISA = qw(Chatbot::Eliza);

sub DESTROY { }	# Prevent this going to autoload

1;
