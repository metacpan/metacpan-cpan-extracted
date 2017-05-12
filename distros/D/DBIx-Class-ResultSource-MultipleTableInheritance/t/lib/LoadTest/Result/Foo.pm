package    # hide from PAUSE
    LoadTest::Result::Foo;

use strict;
use warnings;
use parent 'DBIx::Class::Core';
use aliased 'DBIx::Class::ResultSource::MultipleTableInheritance' => 'MTI';

__PACKAGE__->table_class(MTI);
__PACKAGE__->table('foo');

__PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    a  => { data_type => 'integer', is_nullable       => 1 }
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to( 'bar', 'LoadTest::Result::Bar',
    { 'foreign.id' => 'self.a' } );

1;
