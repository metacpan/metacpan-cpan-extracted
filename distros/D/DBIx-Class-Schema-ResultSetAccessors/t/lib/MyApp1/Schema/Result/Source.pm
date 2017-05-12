package MyApp1::Schema::Result::Source;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('source');
__PACKAGE__->add_columns(qw/ sourceid sourcename /);
__PACKAGE__->set_primary_key('sourceid');

1;