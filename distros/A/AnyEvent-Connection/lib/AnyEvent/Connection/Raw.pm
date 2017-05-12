package #hide
	AnyEvent::Connection::Raw;

use common::sense 2;m{
use strict;
use warnings;
};
use Object::Event 1.21;
use base 'Object::Event';
use AnyEvent::Handle;
use AnyEvent::Connection::Util;
use Scalar::Util qw(weaken);
use Carp;
# @rewrite s/^# //;
# use Devel::Leak::Cb;

sub _call_waiting {
	my $me = shift;
	for my $k (keys %{ $me->{waitingcb} }) {
		warn "call waiting $k with @_" if $me->{debug};
		if ($me->{waitingcb}{$k}) {
			$me->{waitingcb}{$k}->(undef, @_);
		}
		delete $me->{waitingcb}{$k};
	}
}

sub new {
	my $pkg = shift;
	my $self = $pkg->SUPER::new(@_);
	$self->{nl} = "\015\012" unless defined $self->{nl};
	$self->{debug} = 0 unless defined $self->{debug};
	weaken(my $me = $self);
	# @rewrite s/sub /cb 'conn.cb.eof' /;
	$self->{cb}{eof} = sub {
		$me or return;
		#local *__ANON__ = 'conn.cb.eof';
		warn "[\U$me->{side}\E] Eof on handle";
		delete $me->{h};
		$me->event('disconnect');
		$me->_call_waiting("EOF from handle");
	} ;
	# @rewrite s/sub /cb 'conn.cb.err' /;
	$self->{cb}{err} = sub {
		$me or return;
		#local *__ANON__ = 'conn.cb.err';
		#use Carp;Carp::cluck((0+$!).": $!");
		my $e = "$!";
		if ( $me->{destroying} ) {
			warn "err on destroy";
			$e = "Connection closed";
		} else {
			#warn "[\U$me->{side}\E] Error on handle: $e"; # uncomment
		}
		delete $me->{h};
		$self->event( disconnect => "Error: $e" );
		$me->_call_waiting($e);
	};
	$self->{timeout} ||= 30;
	$self->{h} = AnyEvent::Handle->new(
		fh        => $self->{fh},
		autocork  => 1,
		keepalive => 1,
		on_eof    => $self->{cb}{eof},
		on_error  => $self->{cb}{err},
	);
	$self;
}

sub destroy {
	my ($self) = @_;
	$self->DESTROY;
	bless $self, "AnyEvent::Connection::Raw::destroyed";
}
*close = \&destroy;
sub AnyEvent::Connection::Raw::destroyed::AUTOLOAD {}
sub DESTROY {
	my $self = shift;
	warn "(".int($self).") Destroying AE::CNN::Raw" if $self->{debug};
	delete $self->{fh};
	$self->_call_waiting("destroying connection");
	$self->{h} and $self->{h}->destroy;
	delete $self->{h};
	%$self = ();
	return;
}

sub push_write {
	my $self = shift;
	$self->{h} or return;
	for (@_) {
		if (!ref and utf8::is_utf8($_)) {
			$_ = $_;
			utf8::encode $_;
		}
	}
	$self->{h}->push_write(@_);
	warn ">> @_  " if $self->{debug};
}

sub push_read {
	my $self = shift;
	my $cb = pop;
	$self->{h} or return;
	$self->{h}->timeout($self->{timeout}) if $self->{timeout};
	$self->{h}->push_read(@_,sub {
		shift->timeout(undef); # disable timeout and remove handle from @_
		$cb->($self,@_);
		undef $cb;
	});
}

sub unshift_read {
	my $self = shift;
	$self->{h} or return;
	$self->{h}->unshift_read(@_);
}

sub say {
	my $self = shift;
	$self->{h} or return;
	for (@_) {
		if (!ref and utf8::is_utf8($_)) {
			$_ = $_;
			utf8::encode $_;
		}
	}
	$self->{h}->push_write("@_$self->{nl}");
	warn ">> @_  " if $self->{debug};
	return;
}
*reply = \&say;

sub recv {
	my ($self,$bytes,%args) = @_;
	$args{cb}  or croak "no cb for recv at @{[ (caller)[1,2] ]}";
	$self->{h} or return $args{cb}(undef,"Not connected");
	warn "<+ read $bytes " if $self->{debug};
	weaken( $self->{waitingcb}{int $args{cb}} = $args{cb} );
	$self->{h}->unshift_read( chunk => $bytes, sub {
		#local *__ANON__ = 'conn.recv.read';
		# Also eat CRLF or LF from read buffer
		substr( $self->{h}{rbuf}, 0, 1 ) = '' if substr( $self->{h}{rbuf}, 0, 1 ) eq "\015";
		substr( $self->{h}{rbuf}, 0, 1 ) = '' if substr( $self->{h}{rbuf}, 0, 1 ) eq "\012";
		delete $self->{waitingcb}{int $args{cb}};
		shift; (delete $args{cb})->(@_);
		%args = ();
	} );
}

sub command {
	my $self = shift;
	my $write = shift;
	if (utf8::is_utf8($write)) {
		utf8::encode $write;
	}
	my %args = @_;
	$args{cb}  or croak "no cb for command at @{[ (caller)[1,2] ]}";
	$self->{h} or return $args{cb}(undef,"Not connected"),%args = ();
	weaken( $self->{waitingcb}{int $args{cb}} = $args{cb} );
	
	#my $i if 0;
	#my $c = ++$i;
	warn ">> $write  " if $self->{debug};
	$self->{h}->push_write("$write$self->{nl}");
	#$self->{h}->timeout( $self->{select_timeout} );
	warn "<? read  " if $self->{debug};
	# @rewrite s/sub {/cb 'conn.command.read' {/;
	$self->{h}->push_read( regex => qr<\015?\012>, sub {
		#local *__ANON__ = 'conn.command.read';
		shift;
		for (@_) {
			chomp;
			substr($_,-1,1) = '' if substr($_, -1,1) eq "\015";
		}
		warn "<< @_  " if $self->{debug};
		delete $self->{waitingcb}{int $args{cb}};
		delete($args{cb})->(@_);
		%args = ();
		undef $self;
	} );
	#sub {
		#$self->{state}{handle}->timeout( 0 ) if $self->_qsize < 1;
		#diag "<< $c. $write: $_[1] (".$self->_qsize."), timeout ".($self->{state}{handle}->timeout ? 'enabled' : 'disabled');
		#$cb->(@_);
	#});
}

# Serverside feature
sub want_command {
	my $self = shift;
	$self->{h} or return;
	# @rewrite s/sub {/cb 'conn.wand_command.read' {/;
	$self->{h}->push_read( regex => qr<\015?\012>, sub {
		#local *__ANON__ = 'conn.want_command.read';
		shift;
		for (@_) {
			chomp;
			substr($_,-1,1) = '' if substr($_, -1,1) eq "\015";
		}
		$self->event( command => @_ );
		$self->want_command;
	});
}

1;
