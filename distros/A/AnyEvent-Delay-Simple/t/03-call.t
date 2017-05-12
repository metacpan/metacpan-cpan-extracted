#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

use AnyEvent;
use AnyEvent::Delay::Simple qw(delay easy_delay);


local $ENV{PERL_ANYEVENT_LOG} = 'log=nolog';

my $cv = AE::cv;
my @res;

$cv->begin();
delay(
	(map { my $v = $_; sub { push(@res, $v); die() if $v == 5; } } 0 .. 9),
	sub { push(@res, -1); $cv->end(); },
	sub { $cv->end(); }
);
$cv->begin();
delay(
	[map { my $v = $_; sub { push(@res, $v); } } 10 .. 19],
	sub { $cv->end(); }
);
$cv->wait();
cmp_bag \@res, [-1, 0 .. 5, 10 .. 19];

$cv = AE::cv;
@res = ();
$cv->begin();
easy_delay(
	(map { my $v = $_; sub { push(@res, $v); die() if $v == 5; } } 0 .. 9),
	sub { push(@res, -1); $cv->end(); },
	sub { $cv->end(); }
);
$cv->begin();
easy_delay(
	[map { my $v = $_; sub { push(@res, $v); } } 10 .. 19],
	sub { $cv->end(); }
);
$cv->wait();
cmp_bag \@res, [-1, 0 .. 5, 10 .. 19];

$cv = AE::cv;
$cv->begin();
delay([
	sub { pop()->send(1); },
	sub { my $c = pop(); is scalar(@_), 1; is $_[0], 1; $c->send(1, 2, 3); },
	sub { my $c = pop(); is scalar(@_), 3; cmp_deeply \@_, [1, 2, 3]; $c->send(2); }],
	sub { $cv->end(); },
	sub { pop(); is scalar(@_), 1; is $_[0], 2; $cv->end(); }
);
$cv->wait();

$cv = AE::cv;
$cv->begin();
easy_delay([
	sub { 1; },
	sub { is scalar(@_), 1; is $_[0], 1; return (1, 2, 3); },
	sub { is scalar(@_), 3; cmp_deeply \@_, [1, 2, 3]; 2; }],
	sub { $cv->end(); },
	sub { is scalar(@_), 1; is $_[0], 2; $cv->end(); }
);
$cv->wait();

$cv = AE::cv;
delay([
	sub { pop()->send(1); },
	sub { my $c = pop(); is scalar(@_), 1; is $_[0], 1; $c->send(1, 2, 3); },
	sub { die('foo'); }],
	sub { is scalar(@_), 2; like $_[0], qr/^foo/; $cv->send(1); },
	sub { $cv->send(2); }
);
is $cv->recv(), 1;

$cv = AE::cv;
easy_delay([
	sub { 1; },
	sub { is scalar(@_), 1; is $_[0], 1; return (1, 2, 3); },
	sub { die('foo'); }],
	sub { is scalar(@_), 1; like $_[0], qr/^foo/; $cv->send(1); },
	sub { $cv->send(2); }
);
is $cv->recv(), 1;


done_testing;
