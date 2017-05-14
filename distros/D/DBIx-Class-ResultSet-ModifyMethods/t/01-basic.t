use Test::Most;
use Test::DBIx::Class 
  -schema_class => 'Test::DBIx::Class::Example::Schema';
  
ok my $schema = Schema();
isa_ok $schema, 'Test::DBIx::Class::Example::Schema'
  => 'Got Correct Schema';

# Dynamically add the component
ok ref($schema->resultset('Person'))
  ->load_components('ResultSet::ModifyMethods');

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
}, 'Installed fixtures';

my ($around, $before, $after) = (0,0,0);

ok my $rs = $schema
  ->resultset('Person')
  ->around('search_rs', sub {
    my ($orig, $self, @args) = @_;
    ok $before, 'Before was set';
    ok !$after, 'After not yet set';
    $around = 1;
    $self->$orig(@args);
  })
  ->before('search_rs', sub {
    my ($self, @args) = @_;
    $before = 1;
    ok !$after, 'After not yet set';
    ok !$around, 'Around not was set';
  })
  ->after(['search_rs', 'find'], sub {
    my ($self, @args) = @_;
    ok !$after, 'After not yet set';
    $after = 1;
    ok $before, 'Before was set';
    ok $around, 'Around was set';
  })
  ->search_rs({person_id=>[1,2]}),
  'Got a good resultset';

ok $rs->count, 'Got back to original set';
ok $around, 'Around Flag was set';
ok $before, 'Before Flag was set';
ok $after, 'After Flag was set';

done_testing;
