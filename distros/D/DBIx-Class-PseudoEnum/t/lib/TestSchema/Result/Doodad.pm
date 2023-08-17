package TestSchema::Result::Doodad;
use Modern::Perl;
use parent qw(DBIx::Class::Core);

__PACKAGE__->table('doodad');
__PACKAGE__->add_columns(qw/id status color/);
__PACKAGE__->add_columns( note => { is_nullable => 1, }, );
__PACKAGE__->set_primary_key('id');

__PACKAGE__->load_components('PseudoEnum');
__PACKAGE__->enumerate( 'status', [qw/Ordered In-Stock Out-Of-Stock/] );
__PACKAGE__->enumerate( 'color',  [qw/Black Blue Green Red/] );

1;
