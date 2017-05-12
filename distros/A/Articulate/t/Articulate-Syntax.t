use Test::More;
use Articulate::Syntax qw(
  instantiate instantiate_array instantiate_selection instantiate_array_selection
  new_location         new_location_specification
  dpath_get   dpath_set
  throw_error
  select_from
  is_single_key_hash
);
use strict;
use warnings;

use lib 't/lib';

subtest instantiate => sub {
  isa_ok( instantiate('MadeUp::Class'),
    'MadeUp::Class', 'instantiate works on class names' );

  foreach my $foobar (
    instantiate( { class => 'MadeUp::Class', args => [ { foo => 'bar' } ] } ),
    instantiate( { class => 'MadeUp::Class', args => { foo => 'bar' } } ),
    instantiate( { 'MadeUp::Class' => { foo => 'bar' } } ),
    )
  {
    isa_ok( $foobar, 'MadeUp::Class', 'can use hashref and set class' );
    is( $foobar->foo, 'bar', 'can use hashref and pass bar' );
  }

  is(
    instantiate(
      {
        class       => 'MadeUp::Class::WeirdConstructor',
        constructor => 'makeme',
        args        => { foo => 'bar' },
      }
      )->foo,
    'bar',
    'can use hashref and set constructor'
  );

  instantiate(
    { class => 'MadeUp::Class::Singleton', args => [ { foo => 'bar' } ] } );

  is instantiate('MadeUp::Class::Singleton')->foo, 'bar';

  is instantiate( { class => 'MadeUp::Class::Singleton' } )->foo, 'bar';

  my $altered = MadeUp::Class->new;
  $altered->foo('bor');
  isa_ok( instantiate($altered), 'MadeUp::Class',
    'instantiate works on existing objects' );
  is( instantiate($altered)->foo,
    'bor', 'instantiate does not try to recreate existing objects' );
};

subtest instantiate_array => sub {
  my $_make_array = sub {
    [
      'MadeUp::Class',
      { class => 'MadeUp::Class::Singleton', args => [ { foo => 'bar' } ] }
    ];
  };

  is( ref( $_make_array->() ),                   ref [] );
  is( ref( instantiate_array $_make_array->() ), ref [] );
  is( ref( instantiate_array [] ), ref [] );
  is( ref( instantiate_array 'MadeUp::Class' ), ref [] );

  is( ref( instantiate_array('MadeUp::Class')->[0] ),    'MadeUp::Class' );
  is( ref( instantiate_array( $_make_array->() )->[0] ), 'MadeUp::Class' );
  is( ref( instantiate_array( $_make_array->() )->[1] ),
    'MadeUp::Class::Singleton' );
};

subtest instantiate_selection => sub {
  my $selection = {
    default => 'MadeUp::Class',
    foo     => { alias => 'default' },
    bar     => { alias => 'foo' },
  };
  instantiate_selection($selection);
  is( ref( $selection->{default} ), 'MadeUp::Class' );
  is( ref( $selection->{foo} ),     'MadeUp::Class' );
  is( ref( $selection->{bar} ),     'MadeUp::Class' );

  $selection = instantiate_selection('MadeUp::Class');
  is( ref( $selection->{default} ), 'MadeUp::Class' );
};

subtest instantiate_array_selection => sub {
  my $selection = {
    default => 'MadeUp::Class',
    foo     => { alias => 'default' },
    bar     => { alias => 'foo' },
  };
  instantiate_array_selection($selection);
  is( ref( $selection->{default} ), ref [] );
  is( ref( $selection->{default}->[0] ), 'MadeUp::Class' );
  is( ref( $selection->{foo}->[0] ),     'MadeUp::Class' );
  is( ref( $selection->{bar}->[0] ),     'MadeUp::Class' );

  $selection = instantiate_array_selection('MadeUp::Class');
  is( ref( $selection->{default} ), ref [] );
  is( ref( $selection->{default}->[0] ), 'MadeUp::Class' );
};

subtest dpath => sub {
  my $structure = { foo => { bar => 2 }, baz => [ 3, 4 ] };

  is( dpath_get( $structure, '/foo/bar' ),  2 );
  is( dpath_get( $structure, '/baz/*[0]' ), 3 );

  is( dpath_set( $structure, '/baz/*', 5 ), 5 );
  is( $structure->{baz}->[0], 5 );
};

subtest is_single_key_hash => sub {
  is( is_single_key_hash(undef), 0 );
  is( is_single_key_hash( [ foo => 123 ] ), 0 );
  is( is_single_key_hash( { foo => 123 } ), 1 );
  is( is_single_key_hash( { foo => 123, bar => 123 } ), 0 );
  is( is_single_key_hash( { foo => 123 }, 'foo' ), 1 );
  is( is_single_key_hash( { bar => 123 }, 'foo' ), 0 );
  is( is_single_key_hash( { foo => 123, bar => 123 }, 'foo', ), 0 );
};

done_testing;
