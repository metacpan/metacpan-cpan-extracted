package Child::Link::IPC::Pipe;
use strict;
use warnings;

use Child::Util;

use base 'Child::Link::IPC';

add_abstract qw/cross_pipes/;

sub read_handle  { shift->ipc->[0] }
sub write_handle { shift->ipc->[1] }

sub init {
    my $self = shift;
    my ($pipes) = @_;

    $pipes = [
        $pipes->[1],
        $pipes->[0],
    ] if $self->cross_pipes;

    $self->_ipc([
        $pipes->[0]->[0],
        $pipes->[1]->[1],
    ]);
    $self->autoflush(1);
}

1;

=head1 NAME

Child::Link::IPC::Pipe - Base class for link objects used by the
L<Child::IPC::Pipe> plugin.

=head1 SEE ALSO

This class inherits from:

=over 4

=item L<Child::Link::IPC>

=back

=head1 HISTORY

Most of this was part of L<Parallel::Runner> intended for use in the L<Fennec>
project. Fennec is being broken into multiple parts, this is one such part.

=head1 FENNEC PROJECT

This module is part of the Fennec project. See L<Fennec> for more details.
Fennec is a project to develop an extendable and powerful testing framework.
Together the tools that make up the Fennec framework provide a potent testing
environment.

The tools provided by Fennec are also useful on their own. Sometimes a tool
created for Fennec is useful outside the greater framework. Such tools are
turned into their own projects. This is one such project.

=over 2

=item L<Fennec> - The core framework

The primary Fennec project that ties them all together.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Child is free software; Standard perl licence.

Child is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
