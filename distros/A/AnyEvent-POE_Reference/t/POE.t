# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 2;

my $TCP_PORT = 4567;
my @WELCOME = ('Welcome', 1, 2, 3);

my %ok;
foreach my $path (@INC)
{
    foreach my $req_module (qw(AnyEvent POE))
    {
	if (-f "$path/$req_module.pm")
	{
	    $ok{$req_module}++;
	}
    }

    last if keys(%ok) == 2;
}

SKIP: {
    skip 'POE or AnyEvent not installed', 2 if keys(%ok) != 2;

    my $pid = fork;
    die "Can not fork: $!\n" unless defined $pid;

    if ($pid == 0)
    {
	run_poe();
    }
    else
    {
	run_any($pid);
    }
};


sub run_poe
{
    require POE;
    require POE::Wheel::SocketFactory;
    require POE::Filter::Reference;
    require POE::Wheel::ReadWrite;

    POE->import;

    POE::Session->create(
    inline_states => {
	_start => sub
	{
	    $_[HEAP()]{listener} = POE::Wheel::SocketFactory->new(
		BindAddress  => '127.1',
		BindPort     => $TCP_PORT,
		SuccessEvent => 'server_accept',
		FailureEvent => 'server_error',
		Reuse        => 'on',
		);
	},
	# Someone want to talk to us
	server_accept => sub
	{
	    my($socket, $ip, $port) = @_[ARG0() .. ARG2()];

	    my $client = POE::Wheel::ReadWrite->new(
		Handle	   => $socket,
		InputEvent => "client_input",
		ErrorEvent => "client_error",
		Filter	   => POE::Filter::Reference->new('Storable', 1),
		);

	    $_[HEAP()]{clients}{$client->ID} = $client;

	    # Send a welcome message
	    $client->put(\@WELCOME);
	},
	# Problem when accepting... Too bad...
	server_error => sub
	{
	    my($syscall, $errstr) = @_[ARG0(), ARG2()];

	    #warn "$syscall failed: $errstr\n" if $errstr;

	    delete $_[HEAP()]{listener};
	    delete $_[HEAP()]{clients};
	},
	# A message from one client
	client_input => sub
	{
	    my($ref_data, $wheel_id) = @_[ARG0(), ARG1()];

	    $ref_data->[1]++;
	    $ref_data->[2]++;
	    $ref_data->[3]++;

	    $_[HEAP()]{clients}{$wheel_id}->put($ref_data);

	    # Quit after first response...
	    $_[HEAP()]{clients}{$wheel_id}->event(
		FlushedEvent => 'server_error');
	},
	# A client error!
	client_error => sub
	{
	    my($syscall, $error, $errstr, $wheel_id) = @_[ARG0() .. ARG3()];
	    #if ($error)
	    #{ warn "Client $wheel_id, $syscall() failed: $errstr\n" }
	    #else
	    #{ warn "Client $wheel_id disconnected...\n" }
	    delete $_[HEAP()]{clients}{$wheel_id};
	},
    }
    );

    POE::Kernel->run;
}


sub run_any
{
    my $pid = shift;

    require AnyEvent;
    require AnyEvent::Socket;
    AnyEvent::Socket->import;
    require AnyEvent::Handle;
    require AnyEvent::POE_Reference;

    my $condvar = AnyEvent->condvar;

    # Let some time to POE to start...
    sleep 3;

    tcp_connect(
	'127.1', $TCP_PORT, sub
	{
	    my $fh = shift or die "Can't connect: $!\n";

	    my $handle = AnyEvent::Handle->new(
		fh => $fh,
		timeout => 5,
		on_error => sub
		{
		    my($hdl, $fatal, $msg) = @_;

		    $hdl->destroy;
		    $condvar->send;

		    fail("got error $msg");
		});

	    my $xxx = AnyEvent::POE_Reference->new('Storable', 1);

	    $handle->push_read(
		poe_reference => $xxx, sub
		{
		    my($handle, $ref_data) = @_;

		    ok("@$ref_data" eq "@WELCOME", "Welcome message");

		    my @response = ("Bye", 3, 2, 1);

		    $handle->push_write(
			poe_reference => $xxx, \@response);

		    $handle->push_read(
			poe_reference => $xxx, sub
			{
			    my($handle, $ref_data) = @_;

			    $response[1]++;
			    $response[2]++;
			    $response[3]++;
			    ok("@response" eq "@$ref_data", "Response message");

			    $handle->on_drain(sub
					      {
						  my $handle = shift;
						  shutdown($handle->fh, 1);
						  $handle->destroy;
						  $condvar->send;
					      });
			});
		});
	});

    $condvar->recv;
}
