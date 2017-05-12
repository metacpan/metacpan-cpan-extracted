package Bot::BasicBot::Pluggable::Module::Notes::Store::DBIC::Schema::Result::Tag;

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 NAME

Bot::BasicBot::Pluggable::Module::Notes::Store::DBIC::Schema::Result::Tag

=cut

__PACKAGE__->table("tags");

__PACKAGE__->add_columns(
  "note_id",
  { data_type => "integer" },
  "tag",
  { data_type => "text" },
);

__PACKAGE__->set_primary_key('note_id', 'tag');
__PACKAGE__->belongs_to('note', 'Bot::BasicBot::Pluggable::Module::Notes::Store::DBIC::Schema::Result::Note', 'note_id');

1;
