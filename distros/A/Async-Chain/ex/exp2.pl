#!/usr/bin/perl
use strict;
use warnings;
use Async::Chain;
use AnyEvent;
use AnyEvent::Loop;
use AnyEvent::HTTP;
use JSON;

use Data::Dumper;

my %state;
chain
	sub {
		my $next = shift;
		http_get(
			'http://api.metacpan.org/v0/release/_search?q=status:latest&fields=name,author,date&sort=date:desc&size=1',
			$next
		);
	},
	sub {
		my $next = shift;
		my ($body, $headers) = @_;
		%state = %{ from_json($body)->{hits}->{hits}->[0]->{fields} };
		http_get "http://api.metacpan.org/v0/author/$state{author}?fields=name", $next;
	},
	sub {
		my $next = shift;
		my ($body, $headers) = @_;
		$state{realname} = from_json($body)->{name};
		printf "%s (aka %s) release %s at %s\n", $state{realname}, $state{author}, $state{name}, $state{date};
		exit;
	};

AnyEvent::Loop::run();
