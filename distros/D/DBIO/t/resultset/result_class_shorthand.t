use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::ResultClass::HashRefInflator;

# DBIx::Class::Helper::ResultSet::ResultClassDWIM resolved a leading
# '::' in result_class against the ResultClass namespace ('::HRI' ->
# DBIx::Class::ResultClass::HashRefInflator). DBIO deliberately does NOT adopt
# that idiom -- it was an opt-in upstream component, not core, and the case it
# mattered for is covered by the folded-in ->hri shortcut.
#
# What DBIO owes the user who types it anyway is a message about DBIO, not
# "Can't locate /HRI.pm" from inside Class::C3::Componentised. This file pins
# that message, and pins that the supported spellings keep working.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

my @artist_rows = (
  [ 1, 'Caterwauler McCrae', 13, undef ],
  [ 2, 'Random Boy Band',     5, undef ],
);

# --- 1. the '::' shorthand is refused, with a message that explains itself ---

# the attribute path: search_rs(undef, { result_class => ... }) reaches
# ResultSet::result_class through ResultSet::new
throws_ok {
  $schema->resultset('Artist')->search_rs(undef, { result_class => '::HRI' })->next;
} qr/\Q'::HRI'\E/,
  q{search_rs({ result_class => '::HRI' }) throws naming the value it was given};

my $err = $@;

unlike "$err", qr{Can't locate /HRI\.pm},
  'the bare Class::C3::Componentised path error no longer leaks out';

like "$err", qr/DBIO::ResultClass::HashRefInflator|->hri/,
  'the message points at the supported spelling for the HRI case';

isa_ok $err, 'DBIO::Exception', 'it is a typed DBIO::Exception';

# the setter path
throws_ok {
  $schema->resultset('Artist')->result_class('::HRI');
} qr/\Q'::HRI'\E/,
  q{$rs->result_class('::HRI') throws the same way};

# a generic '::Foo' has no DBIO equivalent to suggest, but must still say what
# is wrong rather than hunt for /Foo.pm
throws_ok {
  $schema->resultset('Artist')->search_rs(undef, { result_class => '::Foo' })->next;
} qr/\Q'::Foo'\E/,
  q{a generic '::Foo' is refused too};

unlike "$@", qr{Can't locate /Foo\.pm},
  '... and not by way of a file-not-found from Class::C3::Componentised';

like "$@", qr/full(?:y qualified)? class name|fully-qualified/i,
  '... and the message asks for the full class name';

# the construction path, in case a caller builds a resultset directly
throws_ok {
  DBIO::ResultSet->new($schema->source('Artist'), { result_class => '::HRI' });
} qr/\Q'::HRI'\E/,
  'ResultSet->new with the shorthand in its attrs throws as well';

# --- 2. everything DBIO does support is untouched -------------------------

subtest 'the full class name still works as a search attribute' => sub {
  $storage->mock(qr/SELECT.*FROM "artist"/i, [ @artist_rows ]);

  my $row = $schema->resultset('Artist')
    ->search_rs(undef, { result_class => 'DBIO::ResultClass::HashRefInflator' })
    ->next;

  is ref($row), 'HASH', 'a fully qualified result_class inflates as before';
  is $row->{name}, 'Caterwauler McCrae', 'and carries the expected data';
};

subtest 'the full class name still works through the setter' => sub {
  $storage->mock(qr/SELECT.*FROM "artist"/i, [ @artist_rows ]);

  my $rs = $schema->resultset('Artist');
  $rs->result_class('DBIO::ResultClass::HashRefInflator');
  is $rs->result_class, 'DBIO::ResultClass::HashRefInflator',
    'the setter stores and returns the class';

  is ref($rs->next), 'HASH', 'and iteration inflates through it';
};

subtest '->hri, the supported shortcut, still works' => sub {
  $storage->mock(qr/SELECT.*FROM "artist"/i, [ @artist_rows ]);

  my $rs = $schema->resultset('Artist')->hri;
  is $rs->result_class, 'DBIO::ResultClass::HashRefInflator',
    '->hri sets the full class name';
  is ref($rs->next), 'HASH', 'and yields plain hashrefs';
};

# a class name that merely *contains* '::' (i.e. every normal one) must not be
# caught by the guard -- only a leading '::' is the shorthand
is $schema->resultset('Artist')->result_class, 'DBIO::Test::Schema::Artist',
  'an ordinary namespaced result class is unaffected by the guard';

done_testing;
