package App::Mimosa::Schema::BCS::Result::Mimosa::Job;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);


=head1 NAME

App::Mimosa::Schema::BCS::Result::Mimosa::Job - Mimosa Job

=head1 COLUMNS

=cut

__PACKAGE__->table("mimosa_job");

=head2 mimosa_job_id

Auto-incrementing surrogate primary key.

=head2 sha1

SHA1 hash of the job parameters. This is used to identify duplicate job requests, or
requests for jobs that are already running.

Not null, varchar(40).

=head2 start_time

When the job was submitted.

Not null, datetime.

=head2 end_time

When the job finished. NULL if still running.

=head2 user

User that submitted the job.

Nullable, varchar(64).

=cut

__PACKAGE__->add_columns(

  "mimosa_job_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mimosa_job_mimosa_job_id_seq",
  },

  'sha1',
  { data_type => "varchar", is_nullable => 0, size => 40 },

  # This is text because we will need to interface to many different
  # kinds of authentication systems. We won't necessarily have a user_id
  # in our own schema to look up
  'user',
  { data_type => 'varchar', is_nullable => 1, size => 64 },

  'start_time',
  { data_type => "datetime", is_nullable => 0 },

  'end_time',
  { data_type => "datetime", is_nullable => 1 },

);

__PACKAGE__->set_primary_key("mimosa_job_id");
__PACKAGE__->add_unique_constraint("mimosa_job_c1", ['sha1'] );
