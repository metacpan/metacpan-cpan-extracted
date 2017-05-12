package Amethyst::Brain::Infobot::Module::Fortune;

use strict;
use vars qw(@ISA);
use Socket qw(AF_INET SOCK_STREAM);
use POE qw(Wheel::SocketFactory Wheel::ReadWrite
				Filter::Line Driver::SysRW);
use Amethyst::Brain::Infobot::Module;

@ISA = qw(Amethyst::Brain::Infobot::Module);

sub new {
	my $class = shift;

	my $self  = $class->SUPER::new(
					Name		=> 'Fortune',
					Regex		=> qr/^(give me a? )?fortune$/i,
					Usage		=> '((?:give me a)? fortune)',
					Description	=> "Get a fortune from the fortune " .
									"server.",
					@_
						);

	return bless $self, $class;
}

sub action {
    my ($self, $message) = @_;

	my $reply = $self->reply_to($message, $self->fortune());
	$reply->send;

	return 1;
}

sub fortune { 
	my $self = shift;

	my $f = qx{/usr/games/fortune -s};

	$f =~ s/\n/ /g;

	return $f;
}

1;
