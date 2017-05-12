
use Test::Most;
use lib 't/lib';
use Sample::Schema;
use My::Fixtures;

my $schema = Sample::Schema->test_schema;

{
    # introduce a scope to test DEMOLISH
    ok my $fixtures = My::Fixtures->new( schema => $schema ),
      'Creating a fixtures object should succeed';
    isa_ok $fixtures, 'My::Fixtures';
    isa_ok $fixtures, 'DBIx::Class::EasyFixture';

    ok $fixtures->load('producer'),
      'We should be able to load a basic fixture';

    ok my $person
      = $schema->resultset('Person')
      ->find( { name => 'Rick Rubin' } ),
      'We should be able to find our fixture object';
    is $person->birthday->ymd, '1983-02-12', '... and his birthday should be correct';
    is $person->favorite_album->name, 'La Futura', '... and his favorite album is La Futura';

    ok my $album
      = $schema->resultset('Album')
      ->find( { name => 'La Futura' } ),
      'We should be able to find the related fixture object';
    is $album->producer->name, 'Rick Rubin', '... and this album was produced by Rick Rubin';
}

done_testing;
