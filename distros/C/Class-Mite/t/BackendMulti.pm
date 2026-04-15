package BackendMulti;
use strict;
use warnings;
use Class;

# Multi-parent inheritance using new extends syntax
extends qw/ParentDB ParentFile/;

sub save {
    my $self = shift;
    return $self->to_db . $self->to_file;
}

1;

