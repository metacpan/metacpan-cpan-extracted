package Cantella::Worker;

use strict;
use warnings;
use Carp qw/cluck/;

our $VERSION = '0.002003';
$VERSION = eval $VERSION;

sub import {
  my $package = shift;
  return unless @_;
  my $error = "Tried to import the symbols " . join(', ', @_)
    . " from Cantella::Worker.\nDid you mean Cantella::Worker::Role::Worker"
      . " or Cantella::Worker::Manager::Prefork?";
  cluck($error);
}

1;

__END__;

=head1 NAME

Cantella::Worker - Worker/Manager worker pool system

=head1 SYNOPSIS

    package TestPreforkWorkerClass;
    use Moose;
    with 'Cantella::Worker::Role::Worker';
    has work_pile => (
      is => 'ro',
      isa => 'ArrayRef',
      default => sub{ [1..5] },
      required => 1
    );

    sub get_work {
      my $self = shift;
      return unless @{ $self->work_pile };
    }

    sub work {
      my ($self,$work) = @_;
      print STDOUT "===DOING ${work}===\n";
    }

    ############################

    my $manager = Cantella::Worker::Manager::Prefork->new(
      logger => [
        [ File => (
            filename => 'myapp-error.log',
            newline => 1,
            mode => '>>',
            min_level => 'warning'
          )
        ],
      ],
      workers => 3,
      worker_class => 'TestPreforkWorkerClass',
      max_worker_age => 300,
      close_on_call => 0,
      worker_args => {
        interval => 1,
        logger => [
          [ Screen => (newline => 1, min_level => 'debug') ],
        ],
      },
      worker_stderr_log_level => 'notice',
      worker_stdout_log_level => 'info',
    );

    $manager->start;

=head1 SEE ALSO

L<Cantella::Worker::Manager::Prefork>, L<Cantella::Worker::Role::Worker>,

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009-2010 by Guillermo Roditi.
This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
