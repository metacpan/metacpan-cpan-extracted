package #hide
	AnyEvent::RPC::Enc;

use common::sense 2;
m{
	use strict;
	use warnings;
}; # Until cpants will know it make strict
use URI;
require AnyEvent::RPC; our $VERSION = $AnyEvent::RPC::VERSION;

sub new {
	my $pkg = shift;
	my $self = bless {}, $pkg;
	$self->init(@_);
	$self;
}

sub init {
	my $self = shift;
	my %args = @_;
	@$self{keys %args} = values %args;
}

sub _postdata {
	shift;
	my $u = URI->new();
	$u->query_form(@_);
	return $u->query || '';
}

sub request {
	my $self = shift;
	my $rpc = shift;
	my %args = @_;
	my %req = (
		method => $args{method} || 'GET'
	);
	my $base =
		'http://'.
			$rpc->{host}.
			( $rpc->{port} ? ':'.$self->{port} : '').
			( $rpc->{base} ? $rpc->{base} : '/' ).
			( $args{path} ? $args{path} : '' )
	;
	warn "Base uri = $base" if $self->{debug};
	$req{body} = delete $args{data} if length $args{data};
	
	if (exists $args{call}) {
		my $call = join '/',@{$args{call}};
		my $u = URI->new_abs($call,$base);
		$u->query_form( %{ $args{query} } ) if $args{query};
		$req{uri} = $u;
	} else {
		$req{uri} = URI->new($base);
	}
	if (exists $args{headers}) {
		@{$req{headers}}{keys %{$args{headers}}} = values %{$args{headers}};
	}
	return %req;
}

sub decode_response {
	my $self = shift;
	my $res  = shift; # don't decode
	return $res->decoded_content( charset => 'none' );
}

sub decode {
	my $self = shift;
	my $rpc = shift;
	my $res = shift;
	if (defined( my $response = eval { $self->decode_response($res) } )) {
		if ($res->is_success) {
			return $response;
		} else {
			return undef, $res->code, $response;
		}
	} else {
		return undef, $res->code, $res->is_success ? "$@" : $res->message;
	}
}

1;
