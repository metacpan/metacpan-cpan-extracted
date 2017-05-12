use Test::Most;
use Test::DBIx::Class 
  -schema_class => 'Test::DBIx::Class::Example::Schema';

# Dynamically add the component
ok ref(Schema->resultset('Person'))
  ->load_components('ResultSet::CallbackInflator');

fixtures_ok sub {
  my $schema = shift @_;
  my $person_rs = $schema->resultset('Person');
  my ($john, $vincent, $vanessa) = $person_rs->populate([
      ['person_id','name', 'age', 'email'],
      [1,'John', 40, 'john@nowehere.com'],
      [2, 'Vincent', 15, 'vincent@home.com'],
      [3, 'Vanessa', 35, 'vanessa@school.com'],
      [4, 'Joe', 25, 'joe@school.com'],
      [5, 'James', 55, 'james@school.com'],

  ]);
  $john->add_to_phone_rs({number=>'2123879509'});
}, 'Installed fixtures';

ok my $rs = Schema->resultset('Person')
  ->search({},{prefetch=>'phone_rs', order_by=>{-asc => 'person_id'}})
  ->inflator(sub {
    my ($cb, $source, $data, $optional_prefetch, $id) = @_;
    is $data->{name}, $_{name};
    ok $optional_prefetch;
    is $id, 11;
    return $data;
  }, 11);

cmp_deeply(
  [$rs->all],
  [
    {
      age => 40,
      created => ignore(),
      email => "john\@nowehere.com",
      name => "John",
      person_id => 1
    },
    {
      age => 15,
      created => ignore(),
      email => "vincent\@home.com",
      name => "Vincent",
      person_id => 2
    },
    {
      age => 35,
      created => ignore(),
      email => "vanessa\@school.com",
      name => "Vanessa",
      person_id => 3
    },
    {
      age => 25,
      created => ignore(),
      email => "joe\@school.com",
      name => "Joe",
      person_id => 4
    },
    {
      age => 55,
      created => ignore(),
      email => "james\@school.com",
      name => "James",
      person_id => 5
    }
  ]
);

done_testing;
