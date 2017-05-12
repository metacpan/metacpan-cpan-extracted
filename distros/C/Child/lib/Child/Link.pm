package Child::Link;
use strict;
use warnings;

use Child::Util;
use Carp qw/croak/;

add_accessors qw/pid/;

sub ipc { undef }

sub _no_ipc { croak "Child was created without IPC support" }

sub new {
    my $class = shift;
    my ( $pid ) = @_;
    return bless( { _pid => $pid }, $class );
}

{
    no strict 'refs';
    *{__PACKAGE__ . '::' . $_} = \&_no_ipc
        for qw/autoflush flush read say write/;
}

1;

=head1 NAME

Child::Link - Base class for objects that link child and parent processes.

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
