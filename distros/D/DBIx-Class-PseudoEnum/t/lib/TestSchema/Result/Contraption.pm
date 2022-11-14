package TestSchema::Result::Contraption;
use Modern::Perl;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('contraption');
__PACKAGE__->add_columns(qw(id color));
__PACKAGE__->add_columns( status => { is_nullable => 1, }, );
__PACKAGE__->set_primary_key('id');
__PACKAGE__->load_components('PseudoEnum');
__PACKAGE__->source_info(
   {
      enumerations => { 'status' => [qw/Sold Packaged Shipped/] }
   }
);

1;
