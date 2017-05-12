#!/usr/bin/env perl

use Test::More;
use Test::Deep;
use Test::Warnings;
use AnyEvent::Beanstalk;
use t::start_server;

my $c = get_client();

plan tests => 15;

isa_ok($c, 'AnyEvent::Beanstalk');

{
  my @r = $c->use("foobar")->recv;
  is_deeply(\@r, ["foobar", "USING foobar"], 'Received expected response for "use foobar"');
}
{
  my @r = $c->list_tube_used()->recv;
  is_deeply(\@r, ['foobar', 'USING foobar'], 'Am now using tube "foobar"');
}

{
  my @r = $c->watch("foobar")->recv;
  is_deeply(\@r, [2, "WATCHING 2"], 'Received expected response for "watch foobar"');
}

{
  my @r = $c->list_tubes_watched->recv;
  is_deeply([sort @{$r[0] || []}], ["default","foobar"], 'Now watching tubes "default" and "foobar"');
}


$c->put(
  {data => "abc"},
  sub {
    my $job = shift;
    isa_ok($job, 'AnyEvent::Beanstalk::Job');
    is($job && $job->data, "abc", 'Successfully queued job');
  }
);

{
  my $job = $c->reserve->recv;
  isa_ok($job, 'AnyEvent::Beanstalk::Job');
  is($job && $job->data, "abc", 'Successfully fetched job');
  is($job && $job->delete(), 1, 'Deleted job');
}

$c->put(
    { encode => { foo => 'bar' } },
    sub { my $job = shift; isa_ok($job, 'AnyEvent::Beanstalk::Job'); }
);

{
  my $job = $c->reserve->recv;
  cmp_deeply(
    $job,
    all(
      isa('AnyEvent::Beanstalk::Job'),
      methods(
        args => { foo => 'bar' },
        decode => { foo => 'bar' }, # Deprecated, but let's make sure it works
      )
    ),
    'Queued / fetched a job with data encoded by beanstalk'
  );
  ok($job->bury(), 'buried new job');
}

$c->stats(
  sub {
  my $stats = shift;
  cmp_deeply(
    $stats,
    all(
      isa('AnyEvent::Beanstalk::Stats'),
      methods(
        cmd_put => 2,
        cmd_delete => 1,
        cmd_bury => 1,
      )
    ),
    'Beanstalk stats reflect what we\'ve done so far'
  );
  }
);

$c->sync;

done_testing;

