package DBIx::Patcher::Schema::Result::Patcher::Run;
BEGIN {
  $DBIx::Patcher::Schema::Result::Patcher::Run::VERSION = '0.04';
}
BEGIN {
  $DBIx::Patcher::Schema::Result::Patcher::Run::DIST = 'DBIx-Patcher';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

DBIx::Patcher::Schema::Result::Patcher::Run

=head1 VERSION

version 0.04

=cut

__PACKAGE__->table("patcher.run");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'patcher.run_id_seq'

=head2 start

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 finish

  data_type: 'timestamp with time zone'
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
    sequence          => "patcher.run_id_seq",
  },
  "start",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "finish",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 patches

Type: has_many

Related object: L<DBIx::Patcher::Schema::Result::Patcher::Patch>

=cut

__PACKAGE__->has_many(
  "patches",
  "DBIx::Patcher::Schema::Result::Patcher::Patch",
  { "foreign.run_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-02-19 15:51:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Daqwau9crznJbGFbcJhF3Q

sub add_patch {
    my($self,$file,$b64digest) = @_;
    my $args = {
        created => \'default',
        filename => $file,
        b64digest => $b64digest,
    };
   # output 
#    success boolean DEFAULT false,

    return $self->create_related('patches', $args);
}
1;