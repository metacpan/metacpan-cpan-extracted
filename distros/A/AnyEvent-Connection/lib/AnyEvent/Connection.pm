package AnyEvent::Connection;

use common::sense 2;m{
use strict;
use warnings;
};
use Object::Event 1.21;
use base 'Object::Event';

use AnyEvent 5;
use AnyEvent::Socket;

use Carp;

use Scalar::Util qw(weaken);
use AnyEvent::Connection::Raw;
use AnyEvent::Connection::Util;
# @rewrite s/^# //; # Development hacks, see L<Devel::Rewrite>
# use Devel::Leak::Cb;

=head1 NAME

AnyEvent::Connection - Base class for tcp connectful clients

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    package MyTCPClient;
    use base 'AnyEvent::Connection';

    package main;
    my $client = MyTCPClient->new(
        host => 'localhost',
        port => 12345,
    );
    $client->reg_cb(
        connected => sub {
            my ($client,$connection,$host,$port) = @_;
            # ...
            $client->after(
                $interval, sub {
                    # Called after interval, if connection still alive
                }
            );
        }
        connfail = sub {
            my ($client,$reason) = @_;
            # ...
        },
        disconnect => sub {
            my ($client,$reason) = @_;
        },
        error => sub {
            my ($client,$error) = @_;
            # Called in error conditions for callbackless methods
        },
    );
    $client->connect;

=head1 EVENTS

=over 4

=item connected ($connobject, $host, $port)

Called when client get connected.

=item connfail

Called, when client fails to connect

=item disconnect

Called whenever client disconnects

=item error

Called in error conditions for callbackless methods (for ex: when calling push_write on non-connected client)

=back

=head1 OPTIONS

=over 4

=item host

Host to connect to

=item port

Port to connect to

=item timeout [ = 3 ]

Connect/read/write timeout in seconds

=item reconnect [ = 1 ]

If true, automatically reconnect after disconnect/connfail after delay $reconnect seconds

=item rawcon [ = AnyEvent::Connection::Raw ]

Class that implements low-level connection

=back

=head1 OPERATION METHODS

=over 4

=item new

Cleates connection object (see OPTIONS)

=item connect

Begin connection

=item disconnect ($reason)

Close current connection. reason is optional

=item reconnect


Close current connection and establish a new one

=item after($interval, $cb->())

Helper method. AE::timer(after), associated with current connection

Will be destroyed if connection is destroyed, so no timer invocation after connection destruction.

=item periodic($interval, $cb->())

Helper method. AE::timer(periodic), associated with current connection

Will be destroyed if connection is destroyed, so no timer invocation after connection destruction.

=item periodic_stop()

If called within periodic callback, periodic will be stopped.

    my $count;
    $client->periodic(1,sub {
        $client->periodic_stop if ++$count > 10;
    });
    
    # callback will be called only 10 times;

=item destroy

Close connection, destroy all associated objects and timers, clean self

=back

=head1 CONNECT METHODS

When connected, there are some methods, that proxied to raw connection or to AE::Handle


=over 4

=item push_write

See AE::Handle::push_write

=item push_read

See AE::Handle::push_read

=item unshift_read

See AE::Handle::unshift_read

=item say

Same as push_write + newline

=item reply

Same as push_write + newline

=back

For next methods there is a feature.
Callback will be called in any way, either by successful processing or by error or object destruction

=over 4

=item recv($bytes, %args, cb => $cb->())

Similar to

    $fh->push_read(chunk => $bytes, $cb->());

=item command($data, %args, cb => $cb->());

Similar to

    $fh->push_write($data);
    $fh->push_read(line => $cb->());

=back

=cut

sub new {
	my $self = shift->SUPER::new(@_);
	$self->init(@_);
	return $self;
}

sub init {
	my $self = shift;
	$self->{debug}   ||= 0;
	$self->{connected} = 0;
	$self->{connecting} = 0;
	$self->{reconnect} = 1 unless defined $self->{reconnect};
	$self->{timeout} ||= 3;
	$self->{timers}    = {};
	$self->{rawcon}  ||= 'AnyEvent::Connection::Raw';
	#warn "Init $self";
}

#sub connected {
#	warn "Connected";
#	shift->event(connected => ());
#}

sub connect {
	my $self = shift;
	$self->{connecting} and return;
	$self->{connecting} = 1;
	weaken $self;
	croak "Only client can connect but have $self->{type}" if $self->{type} and $self->{type} ne 'client';
	$self->{type} = 'client';
	
	warn "Connecting to $self->{host}:$self->{port}..." if $self->{debug};
	# @rewrite s/sub {/cb connect {/;
	$self->{_}{con}{cb} = sub {
		pop;
		delete $self->{_}{con};
			if (my $fh = shift) {
				warn "Connected @_" if $self->{debug};
				$self->{con} = $self->{rawcon}->new(
					fh      => $fh,
					timeout => $self->{timeout},
					debug   => $self->{debug},
				);
				$self->{con}->reg_cb(
					disconnect => sub {
						warn "Disconnected $self->{host}:$self->{port} @_" if $self->{debug};
						$self->disconnect(@_);
						$self->_reconnect_after();
					},
				);
				$self->{connected} = 1;
				#warn "Send connected event";
				$self->event(connected => $self->{con}, @_);
			} else {
				warn "Not connected $self->{host}:$self->{port}: $!" if $self->{debug};
				$self->event(connfail => "$!");
				$self->_reconnect_after();
			}
	};
	$self->{_}{con}{pre} = sub { $self->{timeout} };
	$self->{_}{con}{grd} =
		AnyEvent::Socket::tcp_connect
			$self->{host}, $self->{port},
			$self->{_}{con}{cb}, $self->{_}{con}{pre}
	;
}

sub accept {
	croak "Not implemented yet";
}


sub _reconnect_after {
	weaken( my $self = shift );
	$self->{reconnect} or return $self->{connecting} = 0;
	$self->{timers}{reconnect} = AnyEvent->timer(
		after => $self->{reconnect},
		cb => sub {
			$self or return;
			delete $self->{timers}{reconnect};
			$self->{connecting} = 0;
			$self->connect;
		}
	);
}

sub periodic_stop;
sub periodic {
	weaken( my $self = shift );
	my $interval = shift;
	my $cb = shift;
	#warn "Create periodic $interval";
	$self->{timers}{int $cb} = AnyEvent->timer(
		after => $interval,
		interval => $interval,
		cb => sub {
			local *periodic_stop = sub {
				warn "Stopping periodic ".int $cb;
				delete $self->{timers}{int $cb}; undef $cb
			};
			$self or return;
			$cb->();
		},
	);
	defined wantarray and return AnyEvent::Util::guard(sub {
		delete $self->{timers}{int $cb};
		undef $cb;
	});
	return;
}

sub after {
	weaken( my $self = shift );
	my $interval = shift;
	my $cb = shift;
	#warn "Create after $interval";
	$self->{timers}{int $cb} = AnyEvent->timer(
		after => $interval,
		cb => sub {
			$self or return;
			delete $self->{timers}{int $cb};
			$cb->();
			undef $cb;
		},
	);
	defined wantarray and return AnyEvent::Util::guard(sub {
		delete $self->{timers}{int $cb};
		undef $cb;
	});
	return;
}

sub reconnect {
	my $self = shift;
	$self->disconnect;
	$self->connect;
}

sub disconnect {
	my $self = shift;
	#$self->{con} or return;
	#warn "Disconnecting $self->{connected} || $self->{connecting} || $self->{reconnect} by @{[ (caller)[1,2] ]}";
	ref $self->{con} eq 'HASH' and warn dumper($self->{con});
	$self->{con} and eval{ $self->{con}->close; };
	warn if $@;
	delete $self->{con};
	my $wascon = $self->{connected} || $self->{connecting};
	$self->{connected}  = 0;
	$self->{connecting} = 0;
	#$self->{reconnect}  = 0;
	delete $self->{timers}{reconnect};
	$self->event('disconnect',@_) if $wascon;
	return;
}

sub AnyEvent::Connection::destroyed::AUTOLOAD {}

sub destroy {
	my ($self) = @_;
	$self->DESTROY;
	bless $self, "AnyEvent::Connection::destroyed";
}

sub DESTROY {
	my $self = shift;
	warn "(".int($self).") Destroying AE::CNN" if $self->{debug};
	$self->disconnect;
	%$self = ();
}

BEGIN {
	no strict 'refs';
	for my $m (qw(push_write push_read unshift_read say reply recv command want_command)) {
		*$m = sub {
			my $self = shift;
			$self->{connected} or return $self->event( error => "Not connected for $m" );
			$self->{con}->$m(@_);
		};
	}
}

=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-anyevent-connection at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-Connection>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::Connection


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-Connection>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AnyEvent-Connection>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AnyEvent-Connection>

=item * Search CPAN

L<http://search.cpan.org/dist/AnyEvent-Connection/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of AnyEvent::Connection
