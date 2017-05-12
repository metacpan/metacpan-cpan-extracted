package AMQP::Subscriber;
our $VERSION = '0.01';

use Mojo::Base 'AMQP';
use AnyEvent::RabbitMQ;
use Sys::Hostname;

has 'debug' => 1;
has 'host' => 'localhost';
has 'port' => 5672;
has 'username' => 'guest';
has 'password' => 'guest';
has 'vhost' => '/';
has 'timeout' => 1;
has 'heartbeat' => 30;
has 'exchange' => 'test';
has 'type' => 'topic';
has 'key' => '#';
has 'queue' => 'test';
has 'rabbit';
has 'connection';
has 'channel';
has 'status';
has 'tag' => $ENV{LOGNAME} . "@" . hostname;
has 'on_message';

sub attach {
	my $self = shift;
	$self->useragent(Mojo::UserAgent->new);
	$self->status(AnyEvent->condvar);
	$self->rabbit(AnyEvent::RabbitMQ->new);
	$self->rabbit->load_xml_spec();
	$self->rabbit->connect(
		host => $self->host,
		port => $self->port,
		username => $self->username,
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
					$self->channel->declare_exchange(
						exchange => $self->exchange,
						type => $self->type,
						auto_delete => 1,
						on_failure => $self->status,
						on_success => sub {
							say "Declared exchange " . $self->exchange if $self->debug;
							$self->channel->declare_queue(
								queue => $self->queue,
								auto_delete => 1,
								on_failure => $self->status,
								on_success => sub {
									say "Declared queue " . $self->queue if $self->debug;
									$self->channel->bind_queue(
										queue => $self->queue,
										exchange => $self->exchange,
										routing_key => $self->key,
										on_failure => $self->status,
										on_success => sub {
											say "Bound " . $self->queue . " to " . $self->exchange . " " . $self->key if $self->debug;
											$self->channel->consume(
												consumer_tag => $self->tag,
												on_success => sub {
													say 'Consuming from ' . $self->queue if $self->debug;
												},
												on_consume => sub {
													my $msg = shift;
													$self->on_message->($self,$msg);
												},
												on_cancel => sub {
													say "Consumption canceled" if $self->debug;
													$self->status->send;
												},
												on_failure => $self->status,
											);
										}
									);
								}
							);
						}
					);
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
		

1;

__END__

=pod

=head1 NAME

AMQP::Subscriber -- Listens for messages on a queue and does stuff with them.

=head1 SYNOPSIS
  
 use AMQP::Subscriber;
 my $subscriber = AMQP::Subscriber->new;
 $subscriber->server('amqp://foo:bar@localhost:5672/testing');
 $subscriber->exchange('test');
 $subscriber->type('topic');
 $subscriber->queue('testing');
 $subscriber->callback( sub {
 	my ($self,$message) = @_;
	say $message;
 });
 $subscriber->attach;

=head1 DESCRIPTION

The AMQP::Subscriber wraps 

=head1 METHODS


B<new( \%params )> (constructor)

Create a new instance of this class. Initialize the object with
whatever is in C<\%params>, which are not predefined.</p>

Returns: new instance of this class.

B<server($url)>

Configures all of the connection settings based on an AMQP url.  The format of which is:
  
 amqp://username:password@host:port/vhost

All of the elements of the url are required if you are not using the defaults.  The default settings are:

 amqp://guest:guest@localhost:5672/

B<attach()>
 

=head1 TODO


=head1 BUGS

If you find them out

=head1 COPYRIGHT

Same as Perl.

=head1 AUTHORS

Dave Goehrig <dave@dloh.org>

=cut
