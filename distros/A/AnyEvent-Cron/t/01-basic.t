#!/usr/bin/env perl
use Test::More;
use lib 'lib';
use AnyEvent::Cron;
my $cron = AnyEvent::Cron->new;
ok( $cron );

my $cv = AnyEvent->condvar;
ok( $cv );

my $cnt = 0;
$cv->begin;
$cron->add( '* * * * * *' => sub {
    ok( ++$cnt , 'CRON: * * * * * *' );
    $cv->end;
}, name => 'CRON: * * * * *' );

$cv->begin;
$cron->add( '1 seconds' => sub {
    ok( ++$cnt , 'CRON: 1 seconds' );
    $cv->end;
}, name => 'CRON: 1 seconds' , once => 1 );


$cron->run();

diag "waiting for recv (2 events)";

$cv->recv;

is( 2 , $cnt );

done_testing;

