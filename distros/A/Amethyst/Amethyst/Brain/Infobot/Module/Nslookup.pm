package Amethyst::Brain::Infobot::Module::Nslookup;

use strict;
use vars qw(@ISA);
use POE;
use POE::Component::Client::DNS;
use Amethyst::Message;
use Amethyst::Brain::Infobot;
use Amethyst::Brain::Infobot::Module;

@ISA = qw(Amethyst::Brain::Infobot::Module);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(
					Name		=> 'Nslookup',
					Regex		=> qr/^(?:resolve|nslookup)\s+(.*)$/i,
					Usage		=> 'resolve|nslookup .*',
					Description	=> "Resolve names/IPs",
					@_
						);

	return bless $self, $class;
}

sub init {
	my $self = shift;

	spawn POE::Component::Client::DNS;
}

sub action {
    my ($self, $message, $addr) = @_;

	my %states = map { $_ => "handler_$_" } qw(
					_start _stop answer
						);

	POE::Session->create(
		package_states	=> [ ref($self) => \%states ],
		args			=> [ $self, $message, $addr ],
			);

	return 1;
}

sub handler_answer {
	my ($kernel, $heap, $session, $request, $response) =
					@_[KERNEL, HEAP, SESSION, ARG0, ARG1];

	my $addr = $request->[0];
	my $packet = $response->[0];

	my $module = $heap->{Module};
	my $message = $heap->{Message};

	unless (defined $packet) {
		my $error = $response->[1];
		my $reply = $module->reply_to($message, "$addr: Error: $error");
		$reply->send;
		return;
	}

	my @answers = $packet->answer;

	unless (@answers) {
		if ($request->[1] eq 'A') {
			my $reply = $module->reply_to($message, "$addr: " .
							"No records in packet");
			$reply->send;
		}
		return;
	}

	foreach my $answer (@answers) {
		my $reply = $module->reply_to($message, "$addr: " .
						$answer->type . " " . $answer->rdatastr);
		$reply->send;
	}
}

sub handler__stop {
	my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
	print STDERR "Ending child session for nslookup\n";
}

sub handler__start {
	my ($kernel, $heap, $session, $module, $message, $addr) =
					@_[KERNEL, HEAP, SESSION, ARG0, ARG1, ARG2];

	print STDERR "Creating child session for nslookup\n";

	$heap->{Module} = $module;
	$heap->{Message} = $message;

	$kernel->post('resolver', 'resolve', 'answer', $addr, 'A', 'IN');
	# $kernel->post('resolver', 'resolve', 'answer', $addr, 'MX', 'IN');
	# $kernel->post('resolver', 'resolve', 'answer', $addr, 'NS', 'IN');
}

1;
