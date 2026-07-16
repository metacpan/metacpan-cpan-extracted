use Test::Most;
use Test::Lib;
use Test::DBIx::Class
  -schema_class => 'Schema::Nested';

# A nested relationship value that is not a hashref or arrayref used to hit a
# stray 'next' outside any loop in the multi and m2m param setters: it exited
# the setter via the caller's dispatch loop (warning 'Exiting subroutine via
# next') and silently ignored even garbage input.  Now undef means 'nothing to
# do' and any other non reference is a caller error.

Schema->resultset("State")->populate([
  [ qw( name abbreviation ) ],
  [ 'Texas', 'TX' ],
]);

Schema->resultset("Role")->populate([
  [ qw( label ) ],
  [ 'admin' ],
  [ 'user' ],
]);

ok my $person = Schema
  ->resultset('Person')
  ->create({
    username => 'jjn9',
    last_name => 'napiorkowski',
    first_name => 'john',
    state => { abbreviation => 'TX' },
    roles => [
      { label => 'user' },
    ],
  });

ok $person->valid, 'setup person is valid';
ok $person->in_storage, 'setup person is stored';
is $person->roles->count, 1, 'setup person has one role';

$person = Schema
  ->resultset('Person')
  ->find(
    {'me.id'=>$person->id},
    {prefetch=>{person_roles=>'role'}}
  );

UNDEF_MEANS_NOTHING_TO_DO: {
  warnings_are {
    $person->update({ person_roles => undef });
  } [], 'undef for a multi rel is ignored without warnings';
  ok $person->valid;

  warnings_are {
    $person->update({ roles => undef });
  } [], 'undef for a m2m rel is ignored without warnings';
  ok $person->valid;

  $person->discard_changes;
  is $person->roles->count, 1, 'related rows untouched';
}

OTHER_NON_REFS_ARE_CALLER_ERRORS: {
  throws_ok {
    $person->update({ person_roles => 'garbage' });
  } qr/We expect 'garbage' to be some sort of reference/,
    'a non-ref for a multi rel dies';

  throws_ok {
    $person->update({ roles => 'garbage' });
  } qr/We expect 'garbage' to be some sort of reference/,
    'a non-ref for a m2m rel dies';
}

done_testing;
