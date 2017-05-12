package Schema::Result::Printings;
our $VERSION = '0.007';
use parent 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('printings');

__PACKAGE__->source_info({
  skip_shortcut => 1,
});

__PACKAGE__->add_columns(qw(id));
__PACKAGE__->set_primary_key(qw(id));

1;
