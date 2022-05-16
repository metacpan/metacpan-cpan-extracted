package TestSchema::Result::Doodad;
use Modern::Perl;
use parent qw(DBIx::Class::Core);

__PACKAGE__->table('doodad');
__PACKAGE__->add_columns(qw/id description created_dt created_by/);
__PACKAGE__->add_columns(
  modified_dt => { is_nullable => 1, },
  modified_by => { is_nullable => 1, },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( 'created_by'  => 'TestSchema::Result::Human', 'id' );
__PACKAGE__->belongs_to( 'modified_by' => 'TestSchema::Result::Human', 'id' );

1;
