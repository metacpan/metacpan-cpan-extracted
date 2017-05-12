#!/usr/bin/perl

package ActualWorker;

sub new {
	my $pkg = shift;
	my $self = bless { @_ },$pkg;
}

sub test {
	my $self = shift;
	sleep 1;
	return "Result from $self->{some}: @_";
}

sub fail {
	my $self = shift;
	die "Fail from $self->{some}: @_";
}

package main;

use lib::abs '../lib';
use common::sense;
use AnyEvent 5;
use AnyEvent::Worker::Pool;

my $pool = AnyEvent::Worker::Pool->new( 5, [ 'ActualWorker' ] );

my $cv = AE::cv;

my $j1;$j1 = sub {
	my $id = shift;
	$cv->begin;
	$pool->do( test => "Test:$id" , sub {
		#my $g = AnyEvent::Util::guard { $j1->(); $cv->end; };
		return warn "Request died: $@\n" if $@;
		warn "Received response: @_\n";
		my $t;$t = AnyEvent->timer(after => 1, cb => sub {
			undef $t;
			#undef $g;
			$cv->end;
			$j1->();
		});
	});
};
$j1->($_) for 1..5;


$cv->begin;
$SIG{INT} = sub { $cv->end };
$cv->recv;
