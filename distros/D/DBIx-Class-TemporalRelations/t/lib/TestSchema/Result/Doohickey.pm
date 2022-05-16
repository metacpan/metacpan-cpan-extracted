package TestSchema::Result::Doohickey;
use Modern::Perl;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('doohickey');
__PACKAGE__->add_columns(qw/id model make purchased_by purchase_dt/);
__PACKAGE__->add_columns(
  modified_dt => { is_nullable => 1, },
  modified_by => { is_nullable => 1, },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( 'purchased_by' => 'TestSchema::Result::Human', 'id' );
__PACKAGE__->belongs_to( 'modified_by'  => 'TestSchema::Result::Human', 'id' );

1;
