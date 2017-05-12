package AnyEvent::Processor::WatchableTask;
#ABSTRACT: Role for tasks which are watchable
$AnyEvent::Processor::WatchableTask::VERSION = '0.006';
use Moose::Role;

requires 'process_message';
requires 'start_message';
requires 'end_message';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Processor::WatchableTask - Role for tasks which are watchable

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Defines methods that a watchable task must implement.

=head1 METHODS

=head2 process_message

=head2 start_message

=head2 end_message

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
