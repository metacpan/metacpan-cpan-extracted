#!/usr/bin/perl

use lib qw(/home/httpd);

use warnings;
use strict;

use POE qw( Filter::Reference Component::Server::TCP);
use Apache::Backend::POE::Message;

$|++;

my %id_to_name;    # $id_to_name{$id} = $name;
my %name_to_ids;    # $name_to_ids{$name}{$id}++;

my $legend = {
	new => '*',
	ping => '+',
	inactive => '-',
	unknown => '?',
	disconnected => 'X',
};
	
print "Legend:\n";
foreach (sort keys %$legend) {
	print "\t$_ = $legend->{$_}\n";
}

# Matrix works, but not quite what I REALLY want
our $x = Matrix->new({
	actions => $legend,
});

POE::Session->create(
	inline_states => {
		_start => sub {
			POE::Component::Server::TCP->new(
			  Port               => 2021,
			  Address            => '127.0.0.1',
			  ClientFilter       => 'POE::Filter::Reference',
			  ClientConnected    => \&handle_client_connect,
			  ClientDisconnected => \&handle_client_disconnect,
			  ClientError        => \&handle_client_error,
			  ClientInput        => \&handle_client_input,
			  InlineStates => {
			    send             => \&do_send_request,
			  },
			);
			$_[KERNEL]->delay_set(show => 2);
		},
		show => sub {
			print sprintf("\r%s                                                              ", $x->matrix());
			$_[KERNEL]->delay_set(show => 2);
		},
	},
);

$poe_kernel->run();

sub send {
  my ($class, $request) = @_;

  # Addressing a particular service.
  my $service = $request->service();
  if (defined $service and length $service) {
    return unless exists $name_to_ids{$service};
	foreach my $id (keys %{$name_to_ids{$service}}) {
		$poe_kernel->post($id => send => $request);
	}
    return;
  }

  # General broadcast.
  foreach my $backend_client_id (keys %id_to_name) {
    $request->{sendtime} = time();
    $poe_kernel->post($backend_client_id => send => $request);
  }
}

# Remainder are POE handlers for backend client sessions.

sub handle_client_connect {
  my $session_id = $_[SESSION]->ID;
  $id_to_name{$session_id} = undef;
  $x->add($session_id);
  $x->add_decay($session_id => 'inactive' => 10);
#  print "session $session_id connected\r\n";
}

sub handle_client_disconnect {
  my $session_id = $_[SESSION]->ID;
  my $name = delete $id_to_name{$session_id};
  if (defined $name) {
  	delete $name_to_ids{$name}{$session_id}
  }
  $x->remove($session_id);
#  print "\r\nsession $session_id disconnected\n";
}

sub handle_client_error {
  my $session_id = $_[SESSION]->ID;
#  warn $session_id;
  my $name = delete $id_to_name{$session_id};
  if (defined $name) {
  	delete $name_to_ids{$name}{$session_id}
  }
  $x->remove($session_id);
#  print "session $session_id errored\r\n";
  $_[KERNEL]->yield("shutdown");
}

sub handle_client_input {
  my ($kernel, $response) = @_[KERNEL, ARG0];
	my $id = $_[SESSION]->ID;

	my $ref = ref($response);
	$ref =~ s/::/\//g;
 unless ($INC{"$ref.pm"}) {
	print "\r\napache sent a ".ref($response)." object instead of a message obj\r\n";
	return;
 }
  
  $response->{srv_recv_time} = time();

  # Handle backend commands.
  if (my $cmd = $response->{cmd}) {

    # Register a service.
    if ($cmd eq "register_service") {
      my $name = lc($response->svc_name());
	  print "[$id] $name registered\r\n";
	  $name_to_ids{$name}{$id}++;
      $id_to_name{$id} = $name;
	  $x->alias($id => $name);
#	$kernel->yield(send => Apache::Backend::POE::Message->new({
#		event => 'register',
#		msg => 'ok',
#	}));
      return;
    }

	if ($cmd eq "ping") {
#		print "ping from ".$id_to_name{$id}."\r\n";
		$x->act($id => 'ping');
		$kernel->yield(send => Apache::Backend::POE::Message->new(
			{
				event => "pong",
				time => time(),
			}
		));
		return;
	}

	$x->act($id => 'unknown');
    #warn "Ignoring unknown command ``$cmd''\r\n";
	$kernel->yield(send => Apache::Backend::POE::Message->new({
		event => 'error',
		error => 'unknown command',
	}));
	return;
  }

  return unless defined $response->client();
  my $res = "res_".$response->client();

	# where the resource could recieve this and respond
  $kernel->post($res => backend_response => $response);
}

sub do_send_request {
  my ($heap, $request) = @_[HEAP, ARG0];
  return unless $heap->{client};
  $request->{svrsend} = time();
  $heap->{client}->put($request);
}

1;

package Matrix;
use POE;

our %decay = (
	10 => 'O',
	9 => 'O',
	8 => 'U',
	7 => 'U',
	6 => ')',
	5 => ')',
	4 => '|',
	3 => ':',
	2 => ':',
	1 => '.',
	0 => '.',
);

sub new {
	my $c = shift;
	my $self = bless(shift || {},$c);
	$self->{decay} = {};
	$self->{map} = {};
	POE::Session->create(
		object_states => [
			$self => [qw(
				_start
				decay
				delay
			)],
		],
	);
	return $self;
}

sub _start {
#	print "matrix started\n";
	$_[KERNEL]->alias_set('matrix');
}

sub delay {
#	print "delay called\n";
	return $_[KERNEL]->delay_set(splice(@_,ARG0));
}

sub del {
#	print "del called\n";
	if (defined $_[ARG0]) {
		delete $_[OBJECT]->{map}->{$_[ARG0]};
		delete $_[OBJECT]->{decay}->{$_[ARG0]};
	}
}

sub decay {
	my $self = $_[OBJECT];
	my $id = $_[ARG0];
#	print "decay called for $id\n";
	if (defined($id) && defined $self->{decay}->{$id}) {
		$self->{decay}->{$id}->{delay}-- if ($self->{decay}->{$id}->{delay} > 0);
#		print "decay is now ".$self->{decay}->{$id}->{delay}."\n";
		if ($self->{decay}->{$id}->{delay} > 0) {
			$_[KERNEL]->delay_set(decay => 1 => $id);
		}
	}
}


# -obj methods
#
sub alias {

}

sub add {
	my $self = shift;
	my $id = shift;
	$self->{map}->{$id} = 'new';
}

sub remove {
	my $self = shift;
	my $id = shift;
	$self->{map}->{$id} = 'decay';

	$self->{decay}->{$id} = {
		cmd => 'remove',
		delay => 10,
		alarm => $poe_kernel->call(matrix => delay => del => 11 => $id),
	};
	
	$poe_kernel->call(matrix => delay => decay => 1 => $id);
}

sub add_decay {
	my ($self,$id,$cmd,$delay) = @_;

	$self->{decay}->{$id} = {
		cmd => $cmd,
		delay => $delay,
	};
	
	$poe_kernel->call(matrix => delay => decay => 1 => $id);
}

sub act {
	my $self = shift;
	my $id = shift;
	
	$self->{map}->{$id} = shift;
	$self->add_decay($id => inactive => 10);
}

sub matrix {
	my $self = shift;

	my %out;
	foreach my $id (sort { $a <=> $b } keys %{$self->{map}}) {
		$out{$id} = "-";
		my $act;
		AGAIN:
		$act = $self->{map}->{$id};
#		print "\naction: $act for $id\n";
		if (defined($self->{decay}->{$id})) {
			my $d = $self->{decay}->{$id};
#			require Data::Dumper;
#			print "\n".Data::Dumper->Dump([$d]);
			if ($d->{delay} > 0) {
				if ($act eq 'delay') {
					if (exists($decay{$d->{delay}})) {
						$out{$id} = $decay{$d->{delay}};
					} else {
						$out{$id} = "[$d->{delay}]";
					}
				}
			} else {
				if ($d->{cmd} eq 'remove') {
					delete $self->{decay}->{$id};
					delete $self->{map}->{$id};
				} elsif ($self->{map}->{$id} ne $d->{cmd}) {
					$self->{map}->{$id} = $d->{cmd};
#					print "$id is now $d->{cmd}\n";
					goto AGAIN;
				}
			}
		}
		if ($self->{actions} && ref($self->{actions}) eq 'HASH') {
			#$out{$id} = (exists($self->{actions}->{$act})) ? $self->{actions}->{$act} : $self->{actions}->{unknown};
			$out{$id} = (exists($self->{actions}->{$act})) ? $self->{actions}->{$act} : $self->{actions}->{disconnected};
			#foreach my $a (keys %{$self->{actions}}) {
			#	next unless ($act eq $a);
			#	$out{$id} = $self->{actions}->{$a};
			#}
		}
		if ($act eq 'new') {
			$out{$id} = $self->{actions}->{$act};
		}
	}
	return join('',(map { defined $out{$_} ? $out{$_} : "" } (sort { $a <=> $b } keys %{$self->{map}}) ))."|";
}

