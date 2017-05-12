#!/usr/bin/env perl -w

package main;

use lib::abs "../lib";
use Test::NoWarnings;
use Test::More tests => 8+1;
use AnyEvent::Impl::Perl;
use AnyEvent 5;
use AnyEvent::Worker;
use AnyEvent::Util(); 

my $worker1 = AnyEvent::Worker->new( sub { exit 0; }, on_error => sub {
	my ($x,$error,$fatal,$file,$line) = @_;
	like $error, qr/^unexpected eof/, 'on_err: got error';
	ok $fatal, 'error is fatal';
	ok $file, 'have caller file';
	ok $line, 'have caller line';
} );
my $cv = AE::cv;

$SIG{ALRM} = sub { fail("Alarm clock, timeout!"); $cv->send };
alarm 3;

$cv->begin;
$worker1->do( test => "SomeData" , sub {
	shift;
	AnyEvent::Util::guard { $cv->end; };
	like $@, qr/^(unexpected eof|read error)/, 'test1: got error';
	diag "$@" unless $@ =~ /^unexpected eof/;
	is_deeply \@_, [], 'test1: no response';
});

$cv->begin;
$worker1->do( fail => "FailData" , sub {
	shift;
	AnyEvent::Util::guard { $cv->end; };
	like $@, qr/^(unexpected eof|read error)/, 'test2: got error';
	diag "$@" unless $@ =~ /^unexpected eof/;
	is_deeply \@_, [], 'test2: no response';
});

$cv->recv;

#Test::NoWarnings::had_no_warnings;
#done_testing( 9 );
