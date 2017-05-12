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
use AnyEvent 5;
use AnyEvent::Worker;
use Guard;

my $worker1 = AnyEvent::Worker->new( [ ActualWorker => some => 'zzz' ] );
my $worker2 = AnyEvent::Worker->new( sub { return "Cb 1 @_"; } );
my $worker3 = AnyEvent::Worker->new( sub { die    "Cb 2 @_"; } );
my $worker4 = AnyEvent::Worker->new( {
	class   => 'ActualWorker',
	new     => 'constructor',
	args    => [qw(arg1 arg2)],
} );

my $cv = AE::cv;

my $j1;$j1 = sub {
	$cv->begin;
	$worker1->do( test => "P:Data" , sub {
		#guard { $j1->(); $cv->end; };
		return warn "Request died: $@\n" if $@;
		warn "Received response: @_\n";
		my $t;$t = AnyEvent->timer(after => 1, cb => sub {
			undef $t;
			$j1->();
			$cv->end;
		});
	});
};
$j1->();

{
	$cv->begin;
	$worker1->do( fail => "P:Data" , sub {
		#guard { $cv->end; };
		$worker1;
		return warn "Request died: $@\n" if $@;
		warn "Received response: @_\n";
		
	});
}

=for rem
$cv->begin;
$worker2->do( "P:Data" , sub {
	guard { $cv->end; };
	return warn "Request died: $@\n" if $@;
	warn "Received response: @_\n";
});

$cv->begin;
$worker3->do( "P:Data" , sub {
	guard { $cv->end; };
	return warn "Request died: $@\n" if $@;
	warn "Received response: @_\n";
});

$cv->begin;
$SIG{INT} = sub { $cv->end };
=cut
$cv->recv;
