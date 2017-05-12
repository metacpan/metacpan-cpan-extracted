package Cantella::Worker::Role::Beanstalk;

use Moose::Role;
use List::Util 'shuffle';
use MooseX::Types::Common::Numeric qw/PositiveInt/;

our $VERSION = '0.001000';

has beanstalk_clients => (
  is => 'ro',
  isa => 'ArrayRef[Beanstalk::Client]',
  required => 1,
);

has reserve_timeout => (
  is => 'ro',
  isa => PositiveInt,
  predicate => 'has_reserve_timeout',
);

has max_tries => (
  is => 'ro',
  isa => PositiveInt,
  predicate => 'has_max_tries',
);

has delete_on_max_tries => (
  is => 'ro',
  isa => 'Bool',
  required => 1,
  default => sub{ 0 },
);

after _start => sub {
  my $self = shift;
  for my $client ( @{ $self->beanstalk_clients } ){
    $client->disconnect;
    unless( $client->connect ){
      $self->error( $client->error );
    }
  }
};

sub get_work {
  my($self) = @_;
  for my $client ( shuffle @{ $self->beanstalk_clients }){
    if( my $job = $client->reserve($self->has_reserve_timeout ? $self->reserve_timeout : ())){
      if( $self->has_max_tries ){
        my $stats = $job->stats;
        if( $stats->reserves > $self->max_tries ){
          my $job_id = $job->id;
          my $tube = $stats->tube;
          my $args = join( ', ', map { "'$_'" } $job->args);
          if( $self->delete_on_max_tries ){
            $self->logger->notice("Job exceeds max-tries. Deleting job ${job_id} from tube '$tube' with args: $args");
            $job->delete;
          } else {
            $self->logger->notice("Job exceeds max-tries. Burying job ${job_id} from tube '$tube' with args: $args");
            $job->bury;
          }
          redo;
        }
      }
      return $job;
    } else {
      my $error = $client->error;
      if( $error ne 'TIMED_OUT'){
        $self->logger->error( $error );
      }
    }
  }
  return;
}

1;

__END__;

=head1 NAME

Cantella::Worker::Role::Beanstalk - Fetch Cantella::Worker jobs from beanstalkd

=head1 SYNOPSIS

    package TestWorkerPool;

    use Try::Tiny;
    use Moose;
    with(
      'Cantella::Worker::Role::Worker',
      'Cantella::Worker::Role::Beanstalk'
    );

    sub work {
      my ($self, $job) = @_;
      my @args = $job->args;
      try {
        if( do_something(@args) ){
          $job->delete; #work done successfully
        } else {
          $job->release({delay => 10}); #let's try again in 10 seconds
        }
      } catch {
        $job->bury; #job failed, bury it and log to file
        $self->logger->error("Burying job ".$job->id." due to error: '$_'");
      };
    }


=head1 ATTRIBUTES

=head2 beanstalk_clients

=over 4

=item B<beanstalk_clients> - reader

=back

Read-only, required, ArrayRef of L<Beanstalk::Client> instances.

=head2 reserve_timeout

=over 4

=item B<reserve_timeout> - reader

=item B<has_reserve_timeout> - predicate

=back

Read-only integer. The reserve timeout will be passed on to
L<Beanstalk::Client>'s C<reserve> method, and signals how long, in seconds,
the client should wait for a job to become available before timing out and
trying the next client in the pool.

B<WARNING:> If you only have one Beanstalk server, you might be tempted
to set not time out. B<Don't do this.> By setting no timeout, the reserve
command will block all other events, including signal handlers. Instead, it
is suggested that the C<reserve_timeout> is set to something that is resonable
for you workload and the load of your B<beanstalkd> process.

=head2 max_tries

=over 4

=item B<max_tries> - reader

=item B<has_max_tries> - predicate

=back

Read-only, Integer. After a job has been reserved more than C<max_tries>,
it will be deleted and not attempted again.

=head2 delete_on_max_tries

=over 4

=item B<delete_on_max_tries> reader

=back

Reas-only boolean. If C<delet_on_max_tries> is set to true and any job exceeds
C<max_tries>, the job will be deleted from the pool, otherwise the job will be
C<bury>ed. The value defaults to false. This attribue has no effect unless
C<max_tries> is set.

=head1 METHODS

=head2 get_work

=over 4

=item B<arguments:> none

=item B<return value:> C<$beanstalk_job>

=back

Will attempt to reserve a job from all of the clients  and return it.

=head1 _start

=over 4

=item B<arguments:> none

=item B<return value:> none

=back

The C<_start> method is extended to disconnect and reconnect to the beanstalk
servers. This ensures that if a client instance is passed in as an argument
prior to a fork when using L<Cantella::Worker::Manager::Prefork>, the connection
works correctly in the child.

=head1 SEE ALSO

L<Cantella::Worker::Manager::Prefork>, L<Cantella::Worker::Role::Worker>

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009-2010 by Guillermo Roditi.
This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

