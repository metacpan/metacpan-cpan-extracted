package #hide
	AnyEvent::Memcached::Peer;

use common::sense 2;m{
use strict;
use warnings;
}x;
use base 'AnyEvent::Connection';
use Carp;
use AnyEvent::Connection::Util;
use Scalar::Util qw(weaken);
#use Devel::Leak::Cb;
sub DEBUG () { 0 }

use AnyEvent::Memcached::Conn;

sub new {
	my $self = shift->SUPER::new(
		rawcon    => 'AnyEvent::Memcached::Conn',
		reconnect => 1,
		@_,
	);
	$self->{waitingcb} = {};
	$self;
}

sub connect {
	my $self = shift;
	$self->{connecting} and return;
	$self->{grd}{con} = $self->reg_cb( connected  => sub { $self->{failed} = 0; } );
	$self->{grd}{cfl} = $self->reg_cb( connfail   => sub { $self->{failed} = 1; } );
	$self->{grd}{dis} = $self->reg_cb( disconnect => sub {
		shift;shift;
		%$self or return;
		warn "Peer $self->{host}:$self->{port} disconnected".(@_ ? ": @_" : '')."\n" if $self->{debug};
		my $e = @_ ? "@_" : "disconnected";
		for ( keys %{$self->{waitingcb}} ) {
			if ($self->{waitingcb}{$_}) {
				#warn "Cleanup: ",::sub_fullname( $self->{waitingcb}{$_} );
				$self->{waitingcb}{$_}(undef,$e);
			}
			delete $self->{waitingcb}{$_};
		}
	} );
	$self->SUPER::connect(@_);
	return;
}

sub conntrack {
	my $self = shift;
	my ($method,$args,$cb) = @_;
	if($self->{connecting} and $self->{failed}) {
		warn "Is connecting, have fails => not connected" if DEBUG;
		$cb and $cb->(undef, "Not connected");
		return;
	}
	elsif (!$self->{connected}) {
		my @args = @$args; # copy to avoid rewriting
		warn time()." Not connected, do connect for ".\@args.", ".dumper($args[0]) if DEBUG;
		my ($c,$t);
		weaken( $self->{waitingcb}{int $cb} = $cb ) if $cb;
		weaken( $self );
		# This rely on correct event invocation order of Object::Event.
		# If this could change, I'll add own queue
		$c = $self->reg_cb(
			connected => sub {
				shift->unreg_me;
				#$c or return;
				warn "connected cb for ".\@args.", ".dumper($args[0]) if DEBUG;
				undef $c;undef $t;
				$self or return;
				delete $self->{waitingcb}{int $cb} if $cb;
				return $self->{con}->$method(@args);
			},
		);
		$t = AnyEvent->timer(
			after => $self->{timeout},# + 0.05, # Since there are timers inside connect, we need to delay a bit longer
			cb => sub {
				#$t or return;
				warn time()." timeout $self->{timeout} cb for $args->[0]" if DEBUG;
				undef $c;undef $t;
				$self or return;
				if ($cb){
					$self->{waitingcb}{int $cb};
					$cb->(undef, "Connect timeout");
				}
			},
		);
		$self->connect();
	}
	else {
		Carp::cluck "How do I get here?";
		return $self->{con}->$method(@$args);
	}
}

sub command {
	my $self = shift;
	if ($self->{connected}) {
		return $self->{con}->command( @_ );
	}
	else {
		my ($cmd,%args) = @_;
		$self->conntrack( command => \@_, $args{cb} );
	}
}

sub request {
	my $self = shift;
	if ($self->{connected}) {
		return $self->{con}->say(@_);
	}
	else {
		# no cb
		$self->conntrack( say => \@_ );
	}
}

sub reader {
	my $self = shift;
	if ($self->{connected}) {
		return $self->{con}->reader(@_);
	}
	else {
		my %args = @_;
		$self->conntrack( reader => \@_, $args{cb} );
	}
	
}

sub want_command {
	my $self = shift;
	warn "wanting command";
	if ($self->{connected}) {
		return $self->{con}->want_command(@_);
	}
	else {
		my %args = @_;
		$self->conntrack( want_command => \@_ );
	}
}

1;
