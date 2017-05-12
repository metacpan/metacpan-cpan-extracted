package TestApp::Schema::Copyright;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("copyright");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    is_auto_increment => 1,
    is_nullable => 0,
    size => undef,
  },
  "rights owner",
  { data_type => "varchar", is_nullable => 0, size => 255, accessor => 'rights_owner' },
  "copyright_year",
  { data_type => "integer", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "tracks",
  "TestApp::Schema::Track",
  { "foreign.copyright_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_05 @ 2008-08-03 20:38:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5JH1GLsrrrWbMI6eviWzug

use overload '""' => sub {
    my $self = shift;
    return $self->get_column('rights owner') || '';
}, fallback => 1;

# You can replace this text with custom content, and it will be preserved on regeneration
1;
