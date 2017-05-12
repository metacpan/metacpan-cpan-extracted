package Amethyst::Brain::Infobot::Module::Insult;

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
					Name		=> 'Insult',
					Regex		=> qr/^insult (.*)$/i,
					Usage		=> 'insult (.*)',
					Description	=> "Insult someone.",
					@_
						);

	return bless $self, $class;
}

sub action {
	my ($self, $message) = @_;

	my %states = map { $_ => "handler_$_" } qw(
					_start connect failure read
						);

	print STDERR "Creating child session for insult\n";

	POE::Session->create(
		package_states	=> [ ref($self) => \%states ],
		args			=> [ $self, $message, $1 ],
			);

    return 1;
}

sub handler_read {
	my ($kernel, $heap, $session, $data) =
					@_[KERNEL, HEAP, SESSION, ARG0];

	my $name = $heap->{Name};
	$data =~ s/You are/$name is/;
    chomp($data);

	my $reply = $heap->{Module}->reply_to($heap->{Message}, $data);
	$reply->send;

	delete $heap->{ReadWrite};
}

sub handler_connect {
	my ($kernel, $heap, $session, $socket) =
					@_[KERNEL, HEAP, SESSION, ARG0];

	delete $heap->{SocketFactory};

	my $wheel = POE::Wheel::ReadWrite->new(
					Handle		=> $socket,
					Driver		=> POE::Driver::SysRW->new(),
					Filter		=> POE::Filter::Line->new(),
					InputEvent	=> 'read',
						);

	$heap->{ReadWrite} = $wheel;
}

sub handler_failure {
	my ($kernel, $heap, $session, $reason) =
					@_[KERNEL, HEAP, SESSION, ARG0, ARG2];

	my $reply = $heap->{Module}->reply_to($heap->{Message},
					"Insult failure: $reason");
	$reply->send;
}

sub handler__start {
	my ($kernel, $heap, $session, $module, $message, $name) =
					@_[KERNEL, HEAP, SESSION, ARG0, ARG1, ARG2];

	$heap->{Module} = $module;
	$heap->{Message} = $message;
	$heap->{Name} = $name;

	my $wheel = new POE::Wheel::SocketFactory(
					SocketDomain	=> AF_INET,
					SocketType		=> SOCK_STREAM,
					SocketProtocol	=> 'tcp',
					RemoteAddress	=> 'insulthost.colorado.edu',
					RemotePort		=> 1695,
					SuccessEvent	=> 'connect',
					FailureEvent	=> 'failure',
						);

	$heap->{SocketFactory} = $wheel;
}

1;
