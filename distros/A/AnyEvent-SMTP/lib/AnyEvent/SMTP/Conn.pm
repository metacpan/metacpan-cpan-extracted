package AnyEvent::SMTP::Conn;

use AnyEvent;
use common::sense;
m{# trying to cheat with cpants game ;)
use strict;
use warnings;
}x;
use base 'Object::Event';
use AnyEvent::Handle;

our $VERSION = $AnyEvent::SMTP::VERSION;use AnyEvent::SMTP ();

our $NL = "\015\012";
our $QRNL = qr<\015?\012>;

sub new {
	my $pkg = shift;
	my $self = bless { @_ }, $pkg;
	$self->{h} = AnyEvent::Handle->new(
		fh => $self->{fh},
		on_eof => sub {
			local *__ANON__ = 'conn.on_eof';
			warn "eof on handle";
			$self->{h} and $self->{h}->destroy;
			delete $self->{h};
			$self->event('disconnect');
		},
		on_error => sub {
			local *__ANON__ = 'conn.on_error';
			#warn "error on handle: $!";
			$self->{h} and $self->{h}->destroy;
			delete $self->{h};
			$self->event( disconnect => "Error: $!" );
		},
	);
	$self->{h}->timeout($self->{timeout}) if $self->{timeout};
	$self;
}

sub close {
	my $self = shift;
	delete $self->{fh};
	$self->{h} and $self->{h}->destroy;
	delete $self->{h};
	$self->event( disconnect => () );
	return;
}

sub command {
	my $self = shift;
	my $write = shift;
	my %args = @_;
	$args{ok} = '250' unless defined $args{ok};
	$args{cb} or return $self->event( error => "no cb for command at @{[ (caller)[1,2] ]}" );
	$self->{h} or return $args{cb}->(undef,"Not connected");
	#my $i if 0;
	#my $c = ++$i;
	warn ">> $write  " if $self->{debug};
	$self->{h}->push_write("$write$NL");
	#$self->{h}->timeout( $self->{select_timeout} );
	warn "<? read  " if $self->{debug} and $self->{debug} > 1;
	$self->{h}->push_read( regex => $QRNL, sub {
		local *__ANON__ = 'conn.command.read';
		shift;
		for (@_) {
			chomp;
			substr($_,-1,1) = '' if substr($_, -1,1) eq "\015";
		}
		warn "<< @_  " if $self->{debug};
		my $line = join '',@_;
		if ( substr( $line,0,length($args{ok})+1 ) eq $args{ok}.' ' ) {
			$args{cb}($line);
		} else {
			$args{cb}(undef, $line);
		}
	} );
}

sub line {
	my $self = shift;
	my %args = @_;
	$args{ok} = '250' unless defined $args{ok};
	$args{cb} or return $self->event( error => "no cb for command at @{[ (caller)[1,2] ]}" );
	warn "<? read  " if $self->{debug} and $self->{debug} > 1;
	$self->{h}->push_read( regex => $QRNL, sub {
		local *__ANON__ = 'conn.line.read';
		shift;
		for (@_) {
			chomp;
			substr($_,-1,1) = '' if substr($_, -1,1) eq "\015";
		}
		warn "<< @_  " if $self->{debug};
		my $line = join '',@_;
		if ( substr( $line,0,length($args{ok})+1 ) eq $args{ok}.' ' ) {
			$args{cb}(1);
		} else {
			$args{cb}(undef, $line);
		}
	} );
	
}

sub want_command {
	my $self = shift;
	$self->{h} or return warn "Not connected";
	$self->{h}->push_read( regex => $QRNL, sub {
		local *__ANON__ = 'conn.want_command.read';
		shift;
		for (@_) {
			chomp;
			substr($_,-1,1) = '' if substr($_, -1,1) eq "\015";
		}
		warn "<< @_  " if $self->{debug};
		$self->event(command => @_);
		$self->want_command if $self->{h};
	});
}

sub ok {
	my $self = shift;
	$self->{h} or return warn "Not connected";
	@_ = ('Ok.') unless @_;
	$self->{h}->push_write("250 @_$NL");
	warn ">> 250 @_  " if $self->{debug};
}

sub reply {
	my $self = shift;
	$self->{h} or return warn "Not connected";
	$self->{h}->push_write("@_$NL");
	warn ">> @_  " if $self->{debug};
}

sub data {
	my $self = shift;
	my %args = @_;
	$args{cb} or return $self->event( error => "no cb for command at @{[ (caller)[1,2] ]}" );
	$self->{h} or return $args{cb}->(undef,"Not connected");
	warn '<+ read till \r\n.\r\n ' if $self->{debug};
	$self->{h}->unshift_read( regex => qr/((?:\015?\012|^)\.\015?\012)/, sub {
		shift;
		use bytes;
		$args{cb}(substr($_[0],0,length($_[0]) - length ($1)))
	} );

}

sub new_m {
	my $self = shift;
	$self->{m} = { host => $self->{host}, port => $self->{port}, helo => $self->{helo}, @_ };
}
1;
