#!/usr/bin/env perl -w

package t::ActualWorker;

sub new {my $pkg = shift;my $self = bless { @_ },$pkg;}
sub test {my $self = shift;return "Result from $self->{some}: @_";}
sub fail {my $self = shift;die "Fail from $self->{some}: @_";}
sub failref {my $self = shift;die bless ["Fail from $self->{some}: @_"],"CustomException";}

package t::ActualWorker2;

sub create {my $pkg = shift;my $self = bless { @_ },$pkg;}
sub test {my $self = shift;return "Result from $self->{some}: @_";}

package main;

use lib::abs "../lib";
use Test::NoWarnings;
use Test::More tests => 13+1;
use AnyEvent::Impl::Perl;
use AnyEvent 5;
use AnyEvent::Worker;
use AnyEvent::Util(); 

my $worker1 = AnyEvent::Worker->new( [ t::ActualWorker => some => 'object' ] );
my $worker2 = AnyEvent::Worker->new( sub { return "Cb 1 @_"; } );
my $worker3 = AnyEvent::Worker->new( sub { die    "Cb 2 @_"; } );
my $worker4 = AnyEvent::Worker->new( {
        class => "t::ActualWorker2",
        new   => 'create',
        args  => [some => 'object'],
    } );

my $cv = AE::cv;

$SIG{ALRM} = sub { fail("Alarm clock, timeout!"); $cv->send };
alarm 3;

$cv->begin;
$worker1->do( test => "SomeData" , sub {
	shift;
	AnyEvent::Util::guard { $cv->end; };
	is $@, '', 'test: no error';
	is_deeply \@_, ['Result from object: SomeData'], 'test: response';
});

$cv->begin;
$worker1->do( fail => "FailData" , sub {
	shift;
	AnyEvent::Util::guard { $cv->end; };
	like $@, qr/^Fail from object: FailData/, 'fail: error';
	is_deeply \@_, [], 'fail: response';
});

$cv->begin;
$worker1->do( failref => "FailData" , sub {
	shift;
	AnyEvent::Util::guard { $cv->end; };
	is ref $@, 'CustomException', 'failref: reference ok';
	like $@->[0], qr/^Fail from object: FailData/, 'failref: error';
	is_deeply \@_, [], 'failref: response';
});

$cv->begin;
$worker2->do( "W2Data" , sub {
	shift;
	AnyEvent::Util::guard { $cv->end; };
	is $@, '', 'w2: no error';
	is_deeply \@_, ['Cb 1 W2Data'], 'w2: response';
});

$cv->begin;
$worker3->do( "FailData" , sub {
	shift;
	AnyEvent::Util::guard { $cv->end; };
	like $@, qr/^Cb 2 FailData/, 'w3: error';
	is_deeply \@_, [], 'w3: response';
});

$cv->begin;
$worker4->do( test => "SomeData" , sub {
	shift;
	AnyEvent::Util::guard { $cv->end; };
	is $@, '', 'test: no error';
	is_deeply \@_, ['Result from object: SomeData'], 'test: response';
});

$cv->recv;

#Test::NoWarnings::had_no_warnings;
