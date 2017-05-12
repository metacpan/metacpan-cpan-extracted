#!perl

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::MockObject;
use DBICx::Hooks::Registry;


subtest 'good usage' => sub {
  my $cb1 = sub { };
  my $cb2 = sub { };

  is(scalar(dbic_hooks_for('Source', 'create')),
    0, 'No callbacks for Source/create');

  is(exception { dbic_hooks_register('Source', 'create', $cb1) },
    undef, 'Added Source/create cb ok');
  is(scalar(dbic_hooks_for('Source', 'create')),
    1, 'We have one callback for Source/create');

  is(exception { dbic_hooks_register('Source', 'create', $cb2) },
    undef, 'Added Source/create cb ok');
  is(scalar(dbic_hooks_for('Source', 'create')),
    2, 'We have two callbacks for Source/create');

  cmp_deeply(
    [dbic_hooks_for('Source', 'create')],
    [$cb1, $cb2],
    'Expected callbacks for Source/create',
  );
};


subtest 'obj for sources' => sub {
  my $row =
    Test::MockObject->new->set_always('result_source' =>
      Test::MockObject->new->set_always('result_class' => 'Row'));
  my $set =
    Test::MockObject->new->set_always('result_source' =>
      Test::MockObject->new->set_always('result_class' => 'Set'));

  dbic_hooks_register($row, 'create', sub { });
  dbic_hooks_register($set, 'update', sub { });

  cmp_deeply(
    [dbic_hooks_for('Row', 'create')],
    [dbic_hooks_for($row,  'create')],
    'Proper callbacks for Row',
  );
  cmp_deeply(
    [dbic_hooks_for('Set', 'update')],
    [dbic_hooks_for($set,  'update')],
    'Proper callbacks for Set',
  );
};


subtest 'bad usage' => sub {
  like(
    exception { dbic_hooks_register() },
    qr/Missing required first parameter 'source',/,
    'Bad boy forgot the source',
  );

  like(
    exception { dbic_hooks_register('MySource') },
    qr/Missing required second parameter 'action',/,
    'Bad boy forgot the action',
  );

  like(
    exception { dbic_hooks_register('MySource', 'doit') },
    qr/Action 'doit' not supported, only 'create', 'update' or 'delete',/,
    'Bad boy used a bad action',
  );

  like(
    exception { dbic_hooks_register('MySource', 'create') },
    qr/Missing required third parameter 'callback', /,
    'Bad boy forgot the callback',
  );

  like(
    exception { dbic_hooks_register('MySource', 'update', undef) },
    qr/Missing required third parameter 'callback', /,
    'Bad boy used undef for the callback',
  );

  like(
    exception {
      dbic_hooks_register('MySource', 'delete', 'my_pretty_callback');
    },
    qr/Parameter 'callback' must be a coderef, /,
    'Bad boy used something else besides coderef for the callback',
  );
};


done_testing();
