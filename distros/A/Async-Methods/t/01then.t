use strict;
use warnings;
use Async::Methods;
use Test::More
  eval { require Future; 1 }
    ? qw(no_plan)
    : (skip_all => "Test skipped: requires Future.pm: $@");

my $start_f;

sub MyTest::thing { $start_f = Future->new }

sub MyTest::continue { Future->done(3+($_[1]||0)) }

sub MyTest::rescue { Future->done('ARGH: '.$_[1]) }

sub MyTest::oops { Future->fail("OOPS\n") }

my $f;

$f = MyTest->thing;

$start_f->done(12);

is($f->get, 12);

$f = MyTest->start::thing;

$start_f->done(12);

is($f->get, 12);

$f = MyTest->thing->then::continue;

$start_f->done('MyTest');

is($f->get, 3);

$f = MyTest->start::thing->then::continue;

$start_f->done(MyTest => 5);

is($f->get, 8);

$f = MyTest->start::thing->then::continue->else::rescue;

$start_f->fail('doh');

is($f->get, 'ARGH: doh');

$f = MyTest->start::thing->catch::rescue;

$start_f->fail('doh');

is($f->get, 'ARGH: doh');

is(MyTest->await::continue, 3);

is(MyTest->start::continue->await::this, 3);

is(eval { MyTest->start::oops->await::this }, undef);

like($@, qr/^OOPS/);

$f = MyTest->start::_(sub { Future->done("yay") });

is($f->await::this, 'yay');
