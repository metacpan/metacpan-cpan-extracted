use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;

# Exercises the DBIO::PopulateMore SYNOPSIS: a single populate_more() call
# across two sources, where the second source cross-references a row
# created by the first via "!Index:Source.key". The Person.gender column
# is a belongs_to Gender -- this is what makes !Index:Gender.male resolve
# down to the *foreign key value* ('male') rather than leaving a raw Row
# object sitting in the column, exactly as a real relationship-backed
# fixture would behave.

{
  package TestDBIO::PopMore::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components(qw/PopulateMore/);
}

{
  package TestDBIO::PopMore::Schema::Result::Gender;
  use base 'DBIO::Core';
  __PACKAGE__->table('gender');
  __PACKAGE__->add_columns(
    label => { data_type => 'varchar', size => 20 },
  );
  __PACKAGE__->set_primary_key('label');
}

{
  package TestDBIO::PopMore::Schema::Result::Person;
  use base 'DBIO::Core';
  __PACKAGE__->table('person');
  __PACKAGE__->add_columns(
    name   => { data_type => 'varchar', size => 20 },
    age    => { data_type => 'integer' },
    gender => { data_type => 'varchar', size => 20 },
  );
  __PACKAGE__->set_primary_key('name');
  __PACKAGE__->belongs_to(gender => 'TestDBIO::PopMore::Schema::Result::Gender', 'gender');
}

TestDBIO::PopMore::Schema->register_class(Gender => 'TestDBIO::PopMore::Schema::Result::Gender');
TestDBIO::PopMore::Schema->register_class(Person => 'TestDBIO::PopMore::Schema::Result::Person');

my $schema  = TestDBIO::PopMore::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
my $storage = $schema->storage;

my %index = $schema->populate_more([
  { Gender => {
      fields => 'label',
      data => {
        male   => 'male',
        female => 'female',
      }}},
  { Person => {
      fields => ['name', 'age', 'gender'],
      data => {
        john => ['john', 38, '!Index:Gender.male'],
        jane => ['jane', 40, '!Index:Gender.female'],
      }}},
]);

subtest 'populate_more expands every source into the returned index' => sub {
  is_deeply(
    [ sort keys %index ],
    [ qw/Gender.female Gender.male Person.jane Person.john/ ],
    'the index has one entry per row across both sources'
  );
  isa_ok $index{'Gender.male'}, 'TestDBIO::PopMore::Schema::Result::Gender';
  isa_ok $index{'Person.john'}, 'TestDBIO::PopMore::Schema::Result::Person';
};

subtest '!Index:Source.key resolves to the referenced row' => sub {
  is $index{'Person.john'}->get_column('gender'), 'male',
    '!Index:Gender.male resolved john\'s gender to the Gender row created earlier in the same call';
  is $index{'Person.jane'}->get_column('gender'), 'female',
    '!Index:Gender.female resolved jane\'s gender to the Gender row created earlier in the same call';
};

subtest 'the resolved rows were actually written through storage' => sub {
  my @inserts = grep { $_->{op} eq 'insert' } $storage->captured_queries;
  ok((grep { $_->{sql} =~ /INSERT INTO "gender"/ } @inserts), 'a Gender row was inserted');
  ok((grep { $_->{sql} =~ /INSERT INTO "person"/ } @inserts), 'a Person row was inserted');
};

subtest 'a bad Index reference throws a clear error' => sub {
  eval {
    $schema->populate_more([
      { Person => {
          fields => ['name', 'age', 'gender'],
          data => { ghost => ['ghost', 1, '!Index:Gender.nonexistent'] },
      }},
    ]);
  };
  like $@, qr/Bad Index in fixture: Gender\.nonexistent/, 'an unresolvable Index reference throws';
};

done_testing;
