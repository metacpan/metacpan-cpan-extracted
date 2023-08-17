package TestSchema::Result::Contraption;
use Modern::Perl;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('contraption');
__PACKAGE__->add_columns(qw(id color));
__PACKAGE__->add_columns( status => { is_nullable => 1, }, );
__PACKAGE__->add_columns( note => { is_nullable => 1, }, );
__PACKAGE__->add_columns( active => { data_type => 'boolean', default_value => 'true' });
__PACKAGE__->add_columns( blocked => { data_type => 'boolean', default_value => 'false' });
__PACKAGE__->add_columns( size => { data_type => 'numeric', is_nullable => 1 });
__PACKAGE__->add_columns( quantity => { data_type => 'numeric', default_value => 0 });
__PACKAGE__->set_primary_key('id');

1;
