package Business::Cart::Generic::Schema::Result::Log;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::Log

=cut

__PACKAGE__->table("log");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'log_id_seq'

=head2 level

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 message

  data_type: 'text'
  is_nullable: 0

=head2 timestamp

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "log_id_seq",
  },
  "level",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "message",
  { data_type => "text", is_nullable => 0 },
  "timestamp",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PsL+0sGPrW2bMqmQgI3GKw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
