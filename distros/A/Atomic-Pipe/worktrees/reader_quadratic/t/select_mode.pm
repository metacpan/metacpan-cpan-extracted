use strict;
use warnings;
use Atomic::Pipe;

sub io_select_modes {
    my @modes = (0);  # always test without IO::Select
    # MSWin32 and cygwin have pipe/select semantics that don't match the
    # IO::Select fill/drain assumptions these tests make.
    unshift @modes, 1
        if Atomic::Pipe->HAVE_IO_SELECT && $^O ne 'MSWin32' && $^O ne 'cygwin';
    return @modes;
}

1;
