#-*- mode: cperl -*-#
use strict;
use warnings;
use feature 'say';
use Test::More;
use AnyEvent;
use AnyEvent::Beanstalk::Worker;
BEGIN { eval { require EV } }  ## this is only here to silence a warning I don't understand

do './t/shared.pl';

plan tests => 2;

my $cv = AnyEvent->condvar;
$cv->begin(sub { $_[0]->send("reserved job") }); # cv++; will run when cv == 0

my $w = new AnyEvent::Beanstalk::Worker
  ( max_jobs => 2,
    concurrency => 1,
    initial_state => 'reserved',
    beanstalk_watch => "test-$$" );

$w->on(reserved => sub {
    my $self = shift;
    my ($qjob, $qresp) = @_;

    $cv->end;  ## cv--
    $self->finish(delete => $qjob->id);
});

## add a job
add_job($cv => "job 1");  ## cv++

$w->start;

$cv->end;  ## cv--

is( $cv->recv, "reserved job", "reserved a job");  ## block until send()

undef $w;
undef $cv;

$cv = AnyEvent->condvar;
$cv->begin(sub { $_[0]->send("reserved 2 jobs") });

$w = new AnyEvent::Beanstalk::Worker
  ( max_jobs => 2,
    initial_state => 'reserved',
    beanstalk_watch => "test-$$" );

$w->on(reserved => sub {
    my $self = shift;
    my ($qjob, $qresp) = @_;

    $cv->end;
    $self->finish(delete => $qjob->id);
});

## add 2 jobs
add_job($cv => "job 2");
add_job($cv => "job 3");

$w->start;

$cv->end;

is($cv->recv, "reserved 2 jobs", "reserved 2 jobs");

exit;
