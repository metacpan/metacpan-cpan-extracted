package AnyEvent::ProcessPool::Pipeline;
# ABSTRACT: A simplified, straightforward way to parallelize tasks
$AnyEvent::ProcessPool::Pipeline::VERSION = '0.06';
use strict;
use warnings;
use AnyEvent::ProcessPool;
use Try::Catch;

use parent 'Exporter';

our @EXPORT = qw(pipeline in out);

sub pipeline (%) {
  my %param = @_;
  my $in    = delete $param{in};
  my $out   = delete $param{out};
  my $pool  = delete $param{pool} || AnyEvent::ProcessPool->new(%param);
  my $count = 0;

  my %pending;
  while (my @task = $in->()) {
    my $cv = $pool->async(@task);
    $pending{$cv} = $cv;
    $cv->cb(sub{ ++$count; $out->(shift) });
  }

  $pool->join; # wait for all tasks to complete

  return $count;
}

sub in  (&) { return (in  => $_[0]) }
sub out (&) { return (out => $_[0]) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::ProcessPool::Pipeline - A simplified, straightforward way to parallelize tasks

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use AnyEvent::ProcessPool::Pipeline;

  pipeline workers => 4,
    in {
      my @task = get_next_task(); # list of (CODE ref $task, ARRAY ref $args)
      return @task;
    },
    out {
      process_result(shift->recv);
    };

=head1 EXPORTED SUBROUTINES

=head2 pipeline

Launches an L<AnyEvent::ProcessPool> and immediately starts processing tasks it
receives when executing the code specified by C<in>. As results arrive (and not
necessarily in the order in which they were queued), they are delivered as
L<condition variables|AnyEvent/CONDITION VARIABLES> (ready ones, guaranteed not
to block) via the code supplied by C<out>. The pipeline will continue to run
until C<in> returns an empty list, after which it will continue to run until
all pending results have been delivered. C<pipeline> returns the total number
of tasks processed.

Optionally, an existing pool may be specified using the C<pool> parameter.

  pipeline pool => $pool,
    in  {...},
    out {...};

Aside from C<in> and C<out>, all other arguments are passed unchanged to
L<AnyEvent::ProcessPool>'s constructor.

=over

=item in

Supplies the pipeline with a code ref representing the caller's task queue.
When called, the code ref returns a two item list containing: 1) a code ref to
be executed in a worker sub-process, and, 2) an (optional) array of arguments
to be passed to the code ref when called.

The pipeline will call C<in> until an empty list is returned, after which the
pool will continue to run until all remaining tasks have completed and been
passed to C<out>.

=item out

Specifies the callback to which results are passed. Results may arrive in any
order.

=back

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
