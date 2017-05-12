package #hide
	AnyEvent::RPC::UA;

use common::sense 2;
m{
	use strict;
	use warnings;
}; # Until cpants will know it make strict

use Carp;
use HTTP::Response;
use HTTP::Headers;

use AnyEvent::HTTP 'http_request';

require AnyEvent::RPC; our $VERSION = $AnyEvent::RPC::VERSION;

sub async { 1 }

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
	$self->{ua} ||= 'AnyEvent::RPC/'.$VERSION;
}

sub call {
	my $self = shift;
	my ($method, $url) = splice @_,0,2;
	my %args = @_;
	$args{cb} or croak "cb required for useragent @{[%args]}";
	warn
		"Call $method $url".
		#($self->{debug} > 3 ? "\n".dumper($args{headers})."BODY=$args{body}" : '' ).
		"\n"
		if $self->{debug};
	http_request
		$method => $url,
		headers => {
			#'Content-Type'   => 'text/xml',
			'User-Agent'     => $self->{ua},
			do { use bytes; ( 'Content-Length' => length($args{body}) ) },
			%{$args{headers} || {}},
		},
		body    => $args{body},
		timeout => exists $args{timeout} ? $args{timeout} : $self->{timeout},
		cb => sub {
			warn "Response for $url: $_[1]{Status} $_[1]{Reason}\n" if $self->{debug};
			$args{cb}( HTTP::Response->new(
				$_[1]{Status},
				$_[1]{Reason},
				HTTP::Headers->new(%{$_[1]}),
				$_[0],
			) );
		},
	;
	return;
}

1;
