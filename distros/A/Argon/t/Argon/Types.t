use Test2::Bundle::Extended;
use AnyEvent;
use Path::Tiny qw(path);
use Moose::Util::TypeConstraints;
use Argon::Types;
use Argon::Constants qw(:commands :priorities);

subtest 'AnyEvent::CondVar' => sub {
  ok my $t = find_type_constraint('AnyEvent::CondVar'), 'exists';
  ok $t->check(AnyEvent->condvar), 'condvar';
  ok !$t->check(1234), 'other';
};

subtest 'Ar::Callback' => sub {
  ok my $t = find_type_constraint('Ar::Callback'), 'exists';
  ok $t->check(AnyEvent->condvar), 'condvar';
  ok $t->check(sub {}), 'code ref';
  ok !$t->check(1234), 'other';
};

subtest 'Ar::Filepath' => sub {
  ok my $t = find_type_constraint('Ar::FilePath'), 'exists';

  my $dir = Path::Tiny->tempdir('temp.XXXXXX', CLEANUP => 1, EXLOCK => 0);
  skip_all 'could not create writable temp directory' unless -w $dir;
  my $path = $dir->child('argon-test-file');

  ok !$t->check("$dir"), 'directory path';
  ok !$t->check("$path"), 'invalid file path';

  $path->touch;
  ok $t->check("$path"), 'valid file path';
};

subtest 'Ar::Command' => sub {
  ok my $t = find_type_constraint('Ar::Command'), 'exists';
  ok $t->check($_), "$_" foreach $ID, $PING, $ACK, $ERROR, $QUEUE, $DENY, $DONE, $HIRE;
  ok !$t->check('fnord'), 'other';
};

subtest 'Ar::Priority' => sub {
  ok my $t = find_type_constraint('Ar::Priority'), 'exists';
  ok $t->check($_), "P$_" foreach $LOW, $NORMAL, $HIGH;
  ok !$t->check('fnord'), 'other';
};

done_testing;
