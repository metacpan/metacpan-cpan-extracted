package AMQP::Publisher;
our $VERSION = '0.01';

use Mojo::Base 'AMQP';
use AnyEvent::RabbitMQ;
use Sys::Hostname;

has 'debug' => 1;
has 'host' => 'localhost';
has 'port' => 5672;
has 'user' => 'guest';
has 'password' => 'guest';
has 'vhost' => '/';
has 'timeout' => 1;
has 'heartbeat' => 30;
has 'exchange' => 'log';
has 'type' => 'topic';
has 'key' => '#';
has 'rabbit';
has 'connection';
has 'channel';
has 'status';
has 'on_connect';

sub attach {
	my $self = shift;
	$self->status(AnyEvent->condvar);
	$self->rabbit(AnyEvent::RabbitMQ->new);
	$self->rabbit->load_xml_spec();
	$self->rabbit->connect(
		host => $self->host,
		port => $self->port,
		user => $self->user,
		pass => $self->password,
		vhost => $self->vhost,
		timeout => $self->timeout,
		tune => { heartbeat => $self->heartbeat },
		on_success => sub {
			say "Connected to amqp://" . $self->host . ":" . $self->port . $self->vhost if $self->debug;
			$self->connection(shift);
			$self->connection->open_channel(
				on_failure => $self->status,
				on_close => sub {
					say "Channel closed" if $self->debug;
					$self->status->send;
				},
				on_success => sub {
					say "Opened channel" if $self->debug;
					$self->channel(shift);
					$self->on_connect->($self);
				},
			);
		},
		on_failure => $self->status,
		on_read_failure =>  sub {
			say "Failed to read" if $self->debug;
			$self->status->send;
		},
		on_return => sub {
			say "Failed to send" if $self->debug;
			$self->status->send;
		},
		on_close => sub {
			say "Connection closed" if $self->debug;
			$self->status->send;
		}
	);
	$self->status->recv;
}

sub send {
	my ($self,$message) = @_;
	$self->channel->send($message);
}

1;

__END__

=pod

=head1 NAME

AMQP::Publisher -- Publishes messages to an exchange.

=head1 SYNOPSIS
  
 use AMQP::Publisher;
 my $publisher = AMQP::Publisher->new;
 $publisher->server('amqp://foo:bar@localhost:5672/testing');
 $publisher->exchange('test');
 $publisher->type('topic');
 $publisher->queue('testing');
 $publisher->on_connect( sub {
 	my ($self) = @_;
	$self->channel->send('hello world');
 });
 $publisher->attach;

=head1 DESCRIPTION

The AMQP::Publisher publishes messages to an AMQP exchange

=head1 METHODS

B<new()> (constructor)

Creates a new AMQP::Producer which can 

Returns: new instance of this class.

B<server($url)>

Configures all of the connection settings based on an AMQP url.  The format of which is:
  
 amqp://username:password@host:port/vhost

All of the elements of the url are required if you are not using the defaults.  The default settings are:

 amqp://guest:guest@localhost:5672/

B<attach()>

Connects to the AMQP server specified by the C<server()> method.  When the server connects it will invoke the publisher's C<on_connect()>
callback.  This can enable you to setup additional event loops to drive the publisher.


B<send()>

After the Publisher object has attached to the AMQP server, it is capable of sending messages to the configured exchange and key.


B<exchange( $exchange )>

An accessor to the configured exchange.  

B<key( $key )>
 
And accessor to the configured routing key.

=head1 TODO


=head1 BUGS

If you find them out

=head1 COPYRIGHT

Same as Perl.

=head1 AUTHORS

Dave Goehrig <dave@dloh.org>

=cut
