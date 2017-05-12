package Bot::BasicBot::Pluggable::Module::Notes::Store::DBIC::Schema::Result::Note;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Bot::BasicBot::Pluggable::Module::Notes::Store::DBIC::Schema::Result::Note

=cut

__PACKAGE__->table("notes");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 1

=head2 timestamp

  data_type: 'text'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 channel

  data_type: 'text'
  is_nullable: 1

=head2 notes

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1 },
  "timestamp",
  { data_type => "text" },
  "name",
  { data_type => "text" },
  "channel",
  { data_type => "text" },
  "notes",
  { data_type => "text" },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many('tags', 'Bot::BasicBot::Pluggable::Module::Notes::Store::DBIC::Schema::Result::Tag', 'note_id');

1;
