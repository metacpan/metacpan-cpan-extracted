use strict;
use warnings;

use lib './local/lib/perl5';
use lib qw{ ./t/lib };

use Test::More tests => 6;
use Test::Deep;
use Test::Exception;
use Test::Warnings qw/:no_end_test :all/;
use Test::DBIx::Class {
  schema_class => 'test::Schema',
}, 'User';
my $first_user;
my $create_warns = warning {
  $first_user = User->create({
    id => '',
    email => 'test@example.com',
    first_name => 'Alice',
    last_name => 'Wonderland',
    suffix => 'MD',
  });
};
# SQLite doesnt like integers being given as a blank string. So
# DBIC::Validation::Structure should sugar coat that for the user when
# they give a blank string to an auto incremented field. Notice above
# the 'id' field is given as a blank string.
unlike(
  $create_warns,
  qr/Non\-integer/,
  'didnt get warning about non-integer values with sqlite',
);

my $errors;
my $create_warns_dup = warning {
  $errors = User->create({
    id => '',
    email => 'test@example.com',
    first_name => 'Bob',
    last_name => 'Builder',
  });
};

is_deeply $errors, {
  errors => [
    { 'email' => 'must be unique', }
  ],
}, 'Email Dupe returns proper error message';

cmp_bag User->create({
  id => '',
  email => 'alice@example.com',
  first_name => 'Alice',
  last_name => 'Wonderland',
})->{errors}, [
  { 'middle_name' => 'must be unique when combined with first_name, last_name', },
  { 'last_name'   => 'must be unique when combined with first_name, middle_name', },
  { 'first_name'  => 'must be unique when combined with middle_name, last_name', },
], 'Dupe of names returns plural error message';

cmp_bag User->create({
  id => '',
  email => 'alice@example.com',
  first_name => 'Alice',
  last_name => 'Wonderland',
  suffix => 'MD',
})->{errors}, [
  { 'suffix'      => 'must be unique when combined with last_name', },
  { 'middle_name' => 'must be unique when combined with first_name, last_name', },
  { 'first_name'  => 'must be unique when combined with middle_name, last_name', },
  { 'last_name'   => 'must be unique when combined with first_name, middle_name and must be unique when combined with suffix', },
], 'Dupe with two unique constraints returns combined error message';

isa_ok $first_user->update({
    email => 'alice@example.com',
  }), 'DBIx::Class::Core';

is_deeply User->create({
    id => $first_user->id,
    email => 'bob@example.com',
    first_name => 'Bob',
    last_name => 'Builder',
    suffix => 'A.C.E.',
  }), {
    errors => [
      { 'id'      => 'must be unique', },
    ],
  }, 'Cannot dupe primary keys';
