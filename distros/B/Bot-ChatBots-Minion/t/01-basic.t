use strict;
use Test::More tests => 25;
use Test::Exception;
use Mock::Quick;
use Bot::ChatBots::Minion;

my ($add_task, $enqueue, $helper);
my $app = qobj(
   minion => qobj(
      add_task => qmeth { shift; $add_task = [@_] },
      enqueue  => qmeth { shift; $enqueue  = [@_] },
   ),
   helper => qmeth { shift; $helper = [@_] },
);

my $bcm;
($add_task, $enqueue, $helper) = ();
lives_ok {
   $bcm = Bot::ChatBots::Minion->new;
   $bcm->register($app, {});
}
'constructor and register live';

is $bcm->name, ref($bcm), 'default name';
is $bcm->helper_name, 'chatbots.minion', 'helper_name';
isa_ok $helper, 'ARRAY';
ok @$helper == 2, 'elements in helper';
is $helper->[0], 'chatbots.minion', 'helper set with helper_name';
isa_ok $helper->[1], 'CODE';
isa_ok $helper->[1]->(), 'Bot::ChatBots::Minion', 'helper sub result';

$bcm->name('whatever');
is $bcm->name, 'whatever', 'can change name';

($add_task, $enqueue, $helper) = ();
lives_ok {
   $bcm = Bot::ChatBots::Minion->new;
   $bcm->register($app, {helper_name => 'aloha'});
}
'register with different parameters';
isa_ok $helper, 'ARRAY';
ok @$helper == 2, 'elements in helper';
is $helper->[0], 'aloha', 'helper set with helper_name in $conf';
isa_ok $helper->[1], 'CODE';
isa_ok $helper->[1]->(), 'Bot::ChatBots::Minion', 'helper sub result';

my $wrapper;
throws_ok { $wrapper = $bcm->wrapper }
qr{no\ processor/downstream\ provided}mxs,
  'wrapper method picky on processor presence';

($add_task, $enqueue, $helper) = ();
lives_ok {
   $wrapper = $bcm->wrapper(downstream => sub { });
}
'wrapper method lives';
isa_ok $add_task, 'ARRAY';
ok @$add_task == 2, 'two elements in add_task';
is $add_task->[0], ref($bcm), 'task name';
isa_ok $add_task->[1], 'CODE', 'task is a sub reference';
isa_ok $wrapper, 'CODE';

($add_task, $enqueue, $helper) = ();
lives_ok { $wrapper->({what => 'ever'}) } 'wrapper sub lives';
isa_ok $enqueue, 'ARRAY';
is_deeply $enqueue, [ref($bcm), [{what => 'ever'}]],
  'enqueued what expected';

done_testing();
