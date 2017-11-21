package AnyEvent::ProcessPool::Worker;
# ABSTRACT: The task executor code run in the worker process
$AnyEvent::ProcessPool::Worker::VERSION = '0.06';
use strict;
use warnings;
use v5.10;
require AnyEvent::ProcessPool::Task;

sub run {
  local $| = 1;
  while (defined(my $line = <STDIN>)) {
    my $task = AnyEvent::ProcessPool::Task->decode($line);
    $task->execute;
    say $task->encode;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::ProcessPool::Worker - The task executor code run in the worker process

=head1 VERSION

version 0.06

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
