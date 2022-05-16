package TestSchema::Result::Contraption;
use Modern::Perl;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('teddy_bear');
__PACKAGE__->add_columns(qw(id purchased_by purchase_dt color height where_purchased));
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to( 'purchased_by' => 'TestSchema::Result::Human', 'id' );

1;
