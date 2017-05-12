#/usr/local/bin/perl -w

{
  package TestIntrospectableM2M::FooBar;
  
  use strict;
  use warnings;
  use base 'DBIx::Class::Core';

  __PACKAGE__->table('foobar');
  __PACKAGE__->add_columns(
    fooid => {data_type => 'integer'},
    barid => {data_type => 'integer'},
  );
  __PACKAGE__->set_primary_key(qw/fooid barid/);
  __PACKAGE__->belongs_to(foo => 'TestIntrospectableM2M::Foo', { 'foreign.id' => 'self.fooid' },);
  __PACKAGE__->belongs_to(bar => 'TestIntrospectableM2M::Bar', { 'foreign.id' => 'self.barid' },);

  package TestIntrospectableM2M::Foo;
  
  use strict;
  use warnings;
  use base 'DBIx::Class';

  __PACKAGE__->load_components(qw/IntrospectableM2M Core/);
  __PACKAGE__->table('foo');
  __PACKAGE__->add_columns( id => {data_type => 'integer'} );
  __PACKAGE__->has_many(foobars => 'TestIntrospectableM2M::FooBar', { 'foreign.fooid' => 'self.id' },);
  __PACKAGE__->many_to_many(bars => foobars => 'bar');

  package TestIntrospectableM2M::Bar;
  
  use strict;
  use warnings;
  use base 'DBIx::Class';

  __PACKAGE__->load_components(qw/IntrospectableM2M Core/);
  __PACKAGE__->table('bar');
  __PACKAGE__->add_columns( id => {data_type => 'integer'} );
  __PACKAGE__->has_many(foobars => 'TestIntrospectableM2M::FooBar', { 'foreign.barid' => 'self.id' },);
  __PACKAGE__->many_to_many(foos => foobars => 'foo');
}

package main;

use strict;
use warnings;
use Test::More tests => 3;

my $metadata = TestIntrospectableM2M::Bar->_m2m_metadata;

is(scalar(keys(%$metadata)), 1, 'number of keys');

is_deeply( [keys(%$metadata)], ['foos'], 'correct keys');

is_deeply(
  $metadata->{foos},
  {
    accessor => 'foos',
    relation => 'foobars',
    foreign_relation => 'foo',
    rs_method => "foos_rs",
    add_method => "add_to_foos",
    set_method => "set_foos",
    remove_method => "remove_from_foos",
  },
  'metadata hash correct',
);
