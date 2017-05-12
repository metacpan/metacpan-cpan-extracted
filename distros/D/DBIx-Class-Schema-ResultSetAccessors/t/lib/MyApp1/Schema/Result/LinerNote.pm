package MyApp1::Schema::Result::LinerNote;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('liner_note');
__PACKAGE__->add_columns(qw/ noteid note /);
__PACKAGE__->set_primary_key('noteid');

1;