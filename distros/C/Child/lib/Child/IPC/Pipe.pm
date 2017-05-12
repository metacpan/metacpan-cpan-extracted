package Child::IPC::Pipe;
use strict;
use warnings;

use Child::Link::IPC::Pipe::Proc;
use Child::Link::IPC::Pipe::Parent;

use base 'Child';

sub child_class  { 'Child::Link::IPC::Pipe::Proc'   }
sub parent_class { 'Child::Link::IPC::Pipe::Parent' }

sub shared_data {
    pipe( my ( $ain, $aout ));
    pipe( my ( $bin, $bout ));
    return [
        [ $ain, $aout ],
        [ $bin, $bout ],
    ];
}

sub new {
    my ( $class, $code ) = @_;
    return bless( { _code => $code }, $class );
}

1;

=head1 NAME

Child::IPC::Pipe - Pipe based IPC plugin for L<Child>

=head1 DESCRIPTION

Creates 2 pipes just before forking.

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
