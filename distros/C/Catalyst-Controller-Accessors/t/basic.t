use strict;
use warnings;

use lib 't/lib';
use Test::More;
use Test::Fatal;
use A::App;

my $app = A::App->new;
my $a = A::Controller::A->new;
my $b = A::Controller::B->new;
my $c = A::Controller::C->new;

ok(!$a->a_list($app), 'value starts empty');
$a->a_list($app, '1,2,3');
is $a->a_list($app), '1,2,3', 'basic rw accessor works';
is $b->a_list($app), '1,2,3', 'initial namespaced rw accessor works';
$b->a_list($app, '3,2,1');
is $b->a_list($app), '3,2,1', 'namespaced rw accessor works';

ok(!$a->a_thing($app), 'value starts empty');
ok(!$b->a_thing($app), 'namespaced value starts empty');
$a->a_thing($app, '1,2,3');
ok(!$a->a_thing($app), 'ro value remains empty');
$b->a_thing($app, '1,2,3');
ok(!$b->a_thing($app), 'namespaced ro value remains empty');
$app->stash->{'A::Controller::A'}{'a_thing'} = 'brap';
is $a->a_thing($app), 'brap', 'accessor can still read correctly';
is $b->a_thing($app), 'brap', 'namespaced accessor can still read correctly';

ok(!$a->my_friend($app), 'slot value starts empty');
ok(!$b->his_friend($app), 'namespaced/slotted value starts empty');
$a->my_friend($app, 'frew');
is($a->my_friend($app), 'frew', 'slotted value set');
is($b->his_friend($app), 'frew', 'slotted/namespaced value set');

like(exception { A::Controller::A::cat_has( 'foo' ) }, qr/cat_has requires "is" to be "ro" or "rw/, 'get exception when we leave out "is"');

subtest isa => sub {
   ok(!$c->thing($app), 'slot value starts empty');
   like(exception { $c->thing($app, 'frew') }, qr/thing is not an int!/, 'isa fails correctly');
   ok(!exception { $c->thing($app, 10) }, 'isa passes correctly');
   is($c->thing($app), 10, 'slotted/namespaced value set');
};

subtest 'error checking' => sub {
   like(exception { $c->thing }, qr/You must pass \$c to thing/, '2 arg check - rw');
   like(exception { $c->thing(10, 11) }, qr/The \$c you passed must have a stash method/, '3 arg check - rw');
   like(exception { $b->a_thing }, qr/You must pass \$c to a_thing/, '2 arg check - ro');
   like(exception { $b->a_thing(10) }, qr/The \$c you passed must have a stash method/, '3 arg check - ro');

};

done_testing;

BEGIN {
   package A::Controller::A;

   use Moose;
   use Catalyst::Controller::Accessors;

   cat_has a_list => (
      is => 'rw',
   );

   cat_has a_thing => (
      is => 'ro',
   );

   cat_has my_friend => (
      is => 'rw',
   );

   1;
}

BEGIN {
   package A::Controller::B;

   use Moose;
   use Catalyst::Controller::Accessors;

   cat_has a_list => (
      is => 'rw',
      namespace => 'A::Controller::A',
   );

   cat_has a_thing => (
      is => 'ro',
      namespace => 'A::Controller::A',
   );

   cat_has his_friend => (
      is => 'ro',
      namespace => 'A::Controller::A',
      slot => 'my_friend',
   );

   1;
}

BEGIN {
   package A::Controller::C;

   use Moose;
   use Catalyst::Controller::Accessors;

   cat_has thing => (
      is => 'rw',
      isa => sub { die 'thing is not an int!' if $_[0] !~ /^\d+$/ },
   );

   1;
}
