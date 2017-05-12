package Bio::Chado::Schema::Result::Genetic::EnvironmentCvterm;
BEGIN {
  $Bio::Chado::Schema::Result::Genetic::EnvironmentCvterm::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Genetic::EnvironmentCvterm::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Genetic::EnvironmentCvterm

=cut

__PACKAGE__->table("environment_cvterm");

=head1 ACCESSORS

=head2 environment_cvterm_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'environment_cvterm_environment_cvterm_id_seq'

=head2 environment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "environment_cvterm_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "environment_cvterm_environment_cvterm_id_seq",
  },
  "environment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("environment_cvterm_id");
__PACKAGE__->add_unique_constraint("environment_cvterm_c1", ["environment_id", "cvterm_id"]);

=head1 RELATIONS

=head2 cvterm

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "cvterm",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "cvterm_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 environment

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Genetic::Environment>

=cut

__PACKAGE__->belongs_to(
  "environment",
  "Bio::Chado::Schema::Result::Genetic::Environment",
  { environment_id => "environment_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/J4m9onF5LNgxWUAtvYkYg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
