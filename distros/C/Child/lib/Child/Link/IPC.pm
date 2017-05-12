package Child::Link::IPC;
use strict;
use warnings;

use Child::Util;

use base 'Child::Link';

add_accessors qw/ipc/;
add_abstract qw/
    read_handle
    write_handle
/;

sub init {}

sub new {
    my $class = shift;
    my ( $pid, @shared ) = @_;
    my $self = $class->SUPER::new($pid);
    $self->init( @shared );
    return $self;
}

sub autoflush {
    my $self = shift;
    my ( $value ) = @_;
    my $write = $self->write_handle;

    my $selected = select( $write );
    $| = $value if @_;
    my $out = $|;

    select( $selected );

    return $out;
}

sub flush {
    my $self = shift;
    my $orig = $self->autoflush();
    $self->autoflush(1);
    my $write = $self->write_handle;
    $self->autoflush($orig);
}

sub read {
    my $self = shift;
    my $handle = $self->read_handle;
    return <$handle>;
}

sub say {
    my $self = shift;
    $self->write( map {$_ . $/} @_ );
}

sub write {
    my $self = shift;
    my $handle = $self->write_handle;
    print $handle @_;
}

1;

=head1 NAME

Child::Link::IPC - Base class for process links that provide IPC.

=head1 SEE ALSO

This class inherits from:

=over 4

=item L<Child::Link>

=back

=head1 METHODS

=over 4

=item $proc->new( $pid. @shared )

Constructor

=item $proc->read()

Read a message from the child.

=item $proc->write( @MESSAGES )

Send the messages to the child. works like print, you must add "\n".

=item $proc->say( @MESSAGES )

Send the messages to the child. works like say, adds the separator for you
(usually "\n").

=item $proc->autoflush( $BOOL )

Turn autoflush on/off for the current processes write handle. This is on by
default.

=item $proc->flush()

Flush the current processes write handle.

=item $proc->ipc()

=item $proc->_ipc( $new )

Accessors for you to use or ignore.

=back

=head1 ABSTRACT METHODS

=over 4

=item $proc->read_handle()

Should return a read handle for reading from the child.

=item $proc->write_handle()

Should return a write handle for writing to the child.

=item $proc->init( @shared )

Called by new during construction

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
