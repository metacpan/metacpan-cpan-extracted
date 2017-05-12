package AnyEvent::Beanstalk::Job;
$AnyEvent::Beanstalk::Job::VERSION = '1.170590';
use strict;
use warnings;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(id client buried reserved data error));

sub new {
  my $proto = shift;
  bless {@_}, ref($proto) || $proto;
}

sub stats {
  my $self = shift;
  my ($stats, $err) = $self->client->stats_job($self->id)->recv;
  return $self->{_stats} = $stats if $stats;
  $self->error($err || 'unknown');
  return undef;
}

sub delete {
  my $self = shift;
  my ($ok, $err) = $self->client->delete($self->id)->recv;
  if ($ok) {
    $self->reserved(0);
    $self->buried(0);
    return 1;
  }
  $self->error($err || 'unknown');
  return undef;
}

sub touch {
  my $self = shift;
  my ($ok, $err) = $self->client->touch($self->id)->recv;
  return 1 if $ok;
  $self->error($err || 'unknown');
  return undef;
}

sub peek {
  my $self = shift;
  my ($job, $err) = $self->client->peek($self->id)->recv;
  if ($job) {
    $self->data($job->data);
    return 1;
  }
  $self->error($err || 'unknown');
  return undef;
}

sub release {
  my $self = shift;
  my $opt  = shift;
  my ($ok, $err) = $self->client->release($self->id, $opt)->recv;
  $self->reserved(0);
  return 1 if $ok;
  $self->error($err || 'unknown');
  return undef;
}

sub bury {
  my $self = shift;
  my $opt  = shift;
  my ($ok, $err) = $self->client->bury($self->id, $opt)->recv;
  if ($ok) {
    $self->reserved(0);
    $self->buried(1);
    return 1;
  }
  $self->error($err || 'unknown');
  return undef;
}

# DEPRECATED! The proper method name is "args".
sub decode { goto \&args; }

sub args {
  my $self = shift;
  my $data = $self->data;
  return unless defined($data);
  $self->client->decoder->($data);
}

sub tube {
  my $self = shift;

  my $stats = $self->{_stats} || $self->stats
    or return undef;

  $stats->tube;
}

sub ttr {
  my $self = shift;

  my $stats = $self->{_stats} || $self->stats
    or return undef;

  $stats->ttr;
}

sub priority {
  my $self = shift;

  my $stats = $self->{_stats} || $self->stats
    or return undef;

  $stats->pri;
}

1;

__END__

=head1 NAME

AnyEvent::Beanstalk::Job - Class to represent a job from a beanstalkd server

=head1 VERSION

version 1.170590

=head1 SYNOPSIS

  my $client = AnyEvent::Beanstalk->new;

  my $job = $client->stats->recv;

  print $job->data,"\n";

=head1 DESCRIPTION

All communication methods called by this class to the server will call C<recv>
on the condition variable returned by L<AnyEvent::Beanstalk>. If this is undesired
then a call can be made directly to the server via methods on the client.

Note however that beanstalkd processes command in sequence. So if there is currently
a reserve request pending, any calls to these methods will not return until the
reserve command has returned so that beanstalkd can process any subsequent commands.

=head1 METHODS

=over

=item B<id>

Returns job id

=item B<client>

Returns L<AnyEvent::Beanstalk> object for the server the job resides on

=item B<buried>

Returns true if the job is buried

=item B<reserved>

Returns true if the job was created via a reserve command and has not been deleted, buried or released

=item B<data>

Returns the raw data for the beanstalkd server for the job

=item B<error>

Returns the last error

=item B<stats>

Return a Stats object for this job. See L<AnyEvent::Beanstalk> for a list of
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

L<AnyEvent::Beanstalk>, L<AnyEvent::Beanstalk::Stats>

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 COPYRIGHT

Copyright (C) 2010 by Graham Barr.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
