use strict;
use warnings;
use Test::More;

use Scalar::Util;

BEGIN {
  eval "use DBD::SQLite";
  plan $@
    ? ( skip_all => 'needs DBD::SQLite for testing' )
      : ( tests => 19 );
}


use lib qw(t/lib);

use_ok('DBIx::Class::Schema::RestrictWithObject');
use_ok('RestrictByUserTest');
my $schema = RestrictByUserTest->init_schema;
ok($schema, "Connected successfully");

my $user1 = $schema->resultset('Users')->create({name => 'user1'});
my $user2 = $schema->resultset('Users')->create({name => 'user2'});
ok(ref $user1 && ref $user2, "Successfully created mock users");

ok($user1->notes->create({name => 'note 1-1'}), "Successfully created 1-1 note");
ok($user1->notes->create({name => 'note 1-2'}), "Successfully created 1-2 note");

ok($user2->notes->create({name => 'note 2-1'}), "Successfully created 2-1 note");
ok($user2->notes->create({name => 'note 2-2'}), "Successfully created 2-2 note");
ok($user2->notes->create({name => 'note 2-3'}), "Successfully created 2-3 note");
ok($user2->notes->create({name => 'note 2-4'}), "Successfully created 2-4 note");

my $u1_schema = $schema->restrict_with_object($user1);
my $u2_schema = $schema->restrict_with_object($user2, "MY");
my $u3_schema = $schema->restrict_with_object($user2, "BUNK");

is($u1_schema->restricting_object->id, $user1->id, "Correct restriction for user 1");
is($u2_schema->restricting_object->id, $user2->id, "Correct restriction for user 2");
is($u2_schema->restricted_prefix, "MY", "Correct prefix for user 2");

ok(Scalar::Util::refaddr($u1_schema) ne Scalar::Util::refaddr($u2_schema),
   "Successful clones");

is($schema->resultset('Notes')->count, 6, 'Correct un resticted count');
is($u1_schema->resultset('Notes')->count, 2, 'Correct resticted count');
is($u2_schema->resultset('Notes')->count, 4, 'Correct resticted count using prefix');
is($u2_schema->resultset('Notes')->count, 4,
   'Correct resticted count using prefix and fallback');

is($u2_schema->resultset('Users')->count, 2, 'Unrestricted resultsets work');


1;
