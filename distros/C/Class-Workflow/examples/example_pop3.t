#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "Class::Workflow";
use ok "Class::Workflow::Context";

{
	package POP3::Connection;
	use Moose;

	# stateless protocol code
	# the view in MVC

	has 'socket' => (
		isa => "Object",
		is  => "ro",
		handles => [qw/is_open write readline close/],
	);

	sub ok {
		my ( $self, $response ) = @_;
		$self->respond("+OK" => $response);
	}

	sub err {
		my ( $self, $response ) = @_;
		$self->respond("-ERR" => $response);
	}

	sub respond { # MMD-esque
		my ( $self, $prefix, $response ) = @_;

		if ( ref($response) ) {
			$self->send_multiline( $prefix, $response );
		} else {
			$self->send_simple( $prefix, $response );
		}
	}

	sub send_simple {
		my ( $self, $prefix, $response ) = @_;
		$self->write( "$prefix $response" );
	}

	sub send_multiline {
		die "stub";
	}

	sub receive {
		my ( $self, $c ) = @_;

		my $line = $self->readline;
		my ( $cmd, @args ) = split /\s+/, $line;

		return ( $cmd, @args );
	}

	package POP3::Server;
	use Moose;

	# stateless backend code
	# the model in MVC

	has users => (
		isa => "HashRef",
		is  => "rw",
		required => 1,
	);

	#has mail_store => (
	#	...
	#);

	sub verify_user_password {
		my ( $self, $user, $password ) = @_;
		$self->users->{$user} eq $password;
	}

	sub uidl {
		my ( $self, %params ) = @_;
	}

	sub list {
		my ( $self, %params ) = @_;
	}

	sub top {
		my ( $self, %params ) = @_;
	}

	sub retr {
		my ( $self, %params ) = @_;
	}

	package POP3::Session;
	use Moose;

	# stateful
	# the controller in MVC
	# the session doubles as a context

	our $Workflow;

	has server => (
		isa => "POP3::Server",
		is  => "ro",
		required => 1,
	);

	has workflow_instance => (
		isa => "POP3::Workflow::Instance",
		is  => "rw",
		default => sub { $Workflow->new_instance() },
		clearer => "clear_workflow_instance",
	);

	has connection => (
		isa => "POP3::Connection",
		is  => "ro",
		required => 1,
	);

	sub run {
		my $self = shift;

		my $i = $self->workflow_instance or return;

		if ( $i->state->name eq "disconnecting" ) {
			$self->connection->close;
			$self->clear_workflow_instance;
			return;
		}

		$self->connection->is_open or return;

		my ( $command, @args ) = $self->connection->receive;
		$self->do_command( $command, @args );
		return 1;
	}

	sub do_command {
		my ( $self, $command, @args ) = @_;

		my $i = $self->workflow_instance;

		# clear any error before proceeding
		$i = $i->derive( error => undef ) if $i->error;

		my $connection = $self->connection;

		if ( my $transition = $i->state->get_transition(lc($command)) ) {
			eval {
				my ( $new_instance, $response ) = $transition->apply( $i, $self, @args );

				$self->workflow_instance( $new_instance );

				my $error = $new_instance->error;
				my $status = $error ? "err" : "ok";
				$response ||= $error;
				$connection->$status( $response );
			};

			$connection->err( "Internal error: $@" ) if $@;
		} else {
			$connection->err( "Invalid command" );
		}
	}

	package POP3::Workflow::Instance;
	use Moose;

	extends "Class::Workflow::Instance::Simple";

	#has server => (
	#	...
	#);

	has user => (
		isa => "Str",
		is  => "ro",
	);

	package MockSocket;
	use Moose;

	# emits a sequence of lines
	# logs all read/writes

	has lines => (
		isa => "ArrayRef",
		is  => "rw",
		default => sub { [] },
	);

	has 'log' => (
		isa => "ArrayRef",
		is  => "rw",
		default => sub { [] },
	);

	sub reset {
		my $self = shift;
		$self->$_([]) for qw/lines log/;
	}

	sub is_open {
		my $self = shift;
		return (scalar @{ $self->lines } > 0);
	}

	sub write {
		my ( $self, $line ) = @_;
		push @{ $self->log }, [ "write", $line ];
	}

	sub readline {
		my $self = shift;
		my $line = shift @{ $self->lines };
		push @{ $self->log }, [ "read", $line ];
		return $line;
	}

	sub close {
		my $self = shift;
		push @{ $self->log }, ["close"];
	}
}

my $w = $POP3::Session::Workflow = Class::Workflow->new;

$w->instance_class("POP3::Workflow::Instance");

# the stupid state names are from RFC 1939

$w->initial_state("authorization");

# define all the states

$w->state(
	name => "authorization",
	transitions => [qw/user apop/],
);

$w->state(
	name => "authorization_accepting_password",
	transitions => [qw/pass/],
);

$w->state(
	name => "transaction",
	transitions => [qw/list stat retr dele noop rset quit top uidl/],
);

$w->state(
	name => "update",
	auto_transition => "close_connection",
);

$w->state("disconnecting");


# transitions for the authorization state

$w->transition(
	name             => "user",
	to_state         => "authorization_accepting_password",
	body_sets_fields => 1,
	body             => sub {
		my ( $self, $instance, $c, $username ) = @_;
		return { user => $username }, "user ok, enter password",
	},
);

$w->transition(
	name        => "pass",
	to_state    => "transaction",
	error_state => "invalid_password",
	validators  => [
		sub {
			my ( $self, $instance, $c, $password ) = @_;
			die "Incorrect login"
				unless $c->server->verify_user_password( $instance->user, $password );
		}
	],
	body        => sub { "Login successful" },
);

$w->state(
	name            => "invalid_password",
	auto_transition => "reset_user",
);

$w->transition(
	name       => "reset_user",
	to_state   => "authorization",
	set_fields => {
		user  => undef,
	},
);



# transitions in the transaction state

foreach my $command (qw/list retr top uidl/) {
	$w->transition(
		name     => $command,
		to_state => "transaction",
		body     => sub {
			my ( $self, $instance, $c, $message ) = @_;
			return $c->server->$command(
				message => $message,
				user    => $instance->user,
			);
		},
	);
}

$w->transition(
	name     => "noop",
	to_state => "transaction",
);

$w->transition(
	name     => "quit",
	to_state => "update",
	body     => sub { "Will I see you again?" },
);


# close the connection in the update state

$w->transition(
	name     => "close_connection",
	to_state => "disconnecting",
);


## ACTUAL TESTS


my $serv = POP3::Server->new(
	users => {
		foo => "secret",
	},
);


{
	my $sock = MockSocket->new(
		lines => [
			"USER foo",
			"PASS secret",
			"QUIT",
		],
	);
	my $conn = POP3::Connection->new( 'socket' => $sock );
	my $sess = POP3::Session->new( connection => $conn, server => $serv );


	isa_ok( $sess->workflow_instance, "POP3::Workflow::Instance" );

	is( $sess->workflow_instance->state->name, "authorization", "initial state is correct" );

	ok( $sess->run, "session still open" );

	is( $sess->workflow_instance->state->name, "authorization_accepting_password", "waiting for password" );

	ok( $sess->run, "session still open" );

	is( $sess->workflow_instance->state->name, "transaction", "transaction state");

	ok( $sess->run, "session still open" );

	is( $sess->workflow_instance->state->name, "disconnecting", "state is disconnecting" );

	ok( !$sess->run, "session over" );

	is( $sock->log->[-1][0], "close", "last op is close");

	foreach my $response ( map { $_->[1] } grep { $_->[0] eq "write" } @{ $sock->log } ) {
		like( $response, qr/^\+OK .*/, "response is not an error" );
	}
}

{
	my $sock = MockSocket->new(
		lines => [
			"USER foo",
			"PASS bar",
			"USER foo",
			"PASS secret",
		],
	);
	my $conn = POP3::Connection->new( 'socket' => $sock );
	my $sess = POP3::Session->new( connection => $conn, server => $serv );

	isa_ok( $sess->workflow_instance, "POP3::Workflow::Instance" );

	is( $sess->workflow_instance->state->name, "authorization", "initial state is correct" );

	ok( $sess->run, "session still open" );

	is( $sess->workflow_instance->state->name, "authorization_accepting_password", "waiting for password" );

	ok( $sess->run, "session still open" );

	is( $sess->workflow_instance->state->name, "authorization", "bumped back to authz state" );

	ok( $sess->workflow_instance->error, "there's an error in the last state" );
	is ( $sock->log->[-1][1], "-ERR Incorrect login",  "incorrect login" );

	ok( $sess->run, "session still open" );

	is( $sess->workflow_instance->state->name, "authorization_accepting_password", "waiting for password" );
	ok( !$sess->workflow_instance->error, "the error was cleared" );

	ok( $sess->run, "session still open" );

	is( $sess->workflow_instance->state->name, "transaction", "transaction state");
}
