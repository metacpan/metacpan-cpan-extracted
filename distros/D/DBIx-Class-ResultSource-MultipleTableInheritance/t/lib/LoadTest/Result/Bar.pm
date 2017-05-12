package    # hide from PAUSE
    LoadTest::Result::Bar;

use strict;
use warnings;
use parent 'LoadTest::Result::Foo';

require LoadTest::Result::Mixin;

__PACKAGE__->table('bar');
__PACKAGE__->result_source_instance->deploy_depends_on(["LoadTest::Result::Foo"]);
__PACKAGE__->result_source_instance->add_additional_parents(
    "LoadTest::Result::Mixin" );

__PACKAGE__->add_columns( b => { data_type => 'integer' } );

__PACKAGE__->belongs_to(
    'b_thang',
    'LoadTest::Result::JustATable',
    { 'foreign.id' => 'self.b' },
);

__PACKAGE__->has_many( 'foos', 'LoadTest::Result::Foo',
    { 'foreign.a' => 'self.id' } );

1;
