## -*- perl -*-

################ JustOne ################
package JustOne;
use base 'Class::Singleton';

use Class::Methodist
  (
   scalar => 'just_one_of_me'
  );

################ Alpha ################
package Alpha;
use base 'JustOne';

use Class::Methodist
  (
   ctor => 'new',
   scalar => 'alpha_scalar',
   list => 'alpha_list',
   hash => 'alpha_hash_one',
   hash => 'alpha_hash_two'
  );

################ Beta ################
package Beta;
use base 'Alpha';

use Class::Methodist
  (
   ctor => 'new',
   scalar => 'beta_scalar',
   list => 'beta_list_one',
   list => 'beta_list_two',
   hash => 'beta_hash'
  );

################ main ################
package main;

use strict;
use warnings;

use Test::More qw/no_plan/;

my $beta1 = Beta->new();
isa_ok($beta1, 'Beta');
isa_ok($beta1, 'Alpha');
is($beta1->count_alpha_list(), 0, 'Empty alpha from beta1');

my $beta2 = Beta->new();
isa_ok($beta2, 'Beta');
isa_ok($beta2, 'Alpha');
is($beta2->count_alpha_list(), 0, 'Empty alpha from beta2');

$beta1->push_alpha_list(qw/a b c d/);
is($beta1->count_alpha_list(), 4, 'Beta1 OK');

$beta2->push_alpha_list(qw/x y z/);
is($beta2->count_alpha_list(), 3, 'Beta2 OK');

is($beta1->count_alpha_list(), 4, 'Beta1 still OK');

