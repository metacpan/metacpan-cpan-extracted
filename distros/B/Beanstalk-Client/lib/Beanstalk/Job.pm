package Beanstalk::Job;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

our $VERSION = "1.07";

__PACKAGE__->mk_accessors(
  qw(id client buried reserved data error)
);

sub stats {
  my $self = shift;
  $self->{_stats} = $self->client->stats_job($self->id)
    or $self->error($self->client->error);
  $self->{_stats};
}

sub delete {
  my $self = shift;

  my $ret = $self->client->delete($self->id)
    or $self->error($self->client->error);

  $self->reserved(0);
  $self->buried(0);

  $ret;
}

sub touch {
  my $self = shift;

  my $ret = $self->client->touch($self->id)
    or $self->error($self->client->error);

  $ret;
}

sub peek {
  my $self = shift;

  my $ret = $self->client->peek($self->id)
    or $self->error($self->client->error);

  $ret;
}

sub release {
  my $self = shift;
  my $opt  = shift;

  my $ret = $self->client->release($self->id, $opt)
    or $self->error($self->client->error);

  $self->reserved(0);

  $ret;
}

sub bury {
  my $self = shift;
  my $opt  = shift;

  unless ($self->client->bury($self->id, $opt)) {
    $self->error($self->client->error);
    return undef;
  }

  $self->reserved(0);
  $self->buried(1);

  return 1;
}

sub args {
  my $self = shift;
  my $data = $self->data;

  return unless defined($data);
  $self->client->decoder->($data);
}

sub tube {
  my $self  = shift;

  my $stats = $self->{_stats} || $self->stats
    or return undef;

  $stats->tube;
}

sub ttr {
  my $self  = shift;

  my $stats = $self->{_stats} || $self->stats
    or return undef;

  $stats->ttr;
}

sub priority {
  my $self  = shift;

  my $stats = $self->{_stats} || $self->stats
    or return undef;

  $stats->pri;
}

1;

__END__

=head1 NAME

Beanstalk::Job - Class to represent a job from a beanstalkd server

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=item B<id>

Returns job id

=item B<client>

Returns L<Beanstalk::Client> object for the server the job resides on

=item B<buried>

Returns true if the job is buried

=item B<reserved>

Returns true if the job was created via a reserve command and has not been deleted, buried or released

=item B<data>

Returns the raw data for the beanstalkd server for the job

=item B<error>

Returns the last error

=item B<stats>

Return a Stats object for this job. See L<Beanstalk::Client> for a list of
methods available.

=item B<delete>

Tell the server to delete this job

=item B<touch>

Calling C<touch> on a reserved job will reset the time left for the job to complete
back to the original ttr value.

=item B<peek>

Peek this job on the server.

=item B<release>

Release the job.

=item B<bury>

Tell the server to bury the job

=item B<args>

Decode and return the raw data from the beanstalkd server

=item B<tube>

Return the name of the tube the job is in

=item B<ttr>

Returns the jobs time to run, in seconds.

=item B<priority>

Return the jobs priority

=back

=head1 SEE ALSO

L<Beanstalk::Pool>, L<Beanstalk::Client>, L<Beanstalk::Stats>

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 COPYRIGHT

Copyright (C) 2008 by Graham Barr.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

