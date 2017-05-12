#
# $Id$
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

package AFS::Object::Instance;

use strict;

our @ISA = qw(AFS::Object);
our $VERSION = '1.99';

sub getCommandIndexes {
    my $self = shift;
    return unless ref $self->{_commands};
    return sort keys %{$self->{_commands}};
}

sub getCommands {
    my $self = shift;
    return unless ref $self->{_commands};
    return values %{$self->{_commands}};
}

sub getCommand {
    my $self = shift;
    my $index = shift;
    return unless ref $self->{_commands};
    return $self->{_commands}->{$index};
}

sub _addCommand {
    my $self = shift;
    my $command = shift;
    unless ( ref $command && $command->isa("AFS::Object") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object object");
    }
    return $self->{_commands}->{$command->index()} = $command;
}

1;
