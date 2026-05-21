use strict;
use warnings;
use Atomic::Pipe;

sub io_select_modes {
    my @modes = (0);  # always test without IO::Select
    unshift @modes, 1 if Atomic::Pipe->HAVE_IO_SELECT && $^O ne 'MSWin32';
    return @modes;
}

1;
