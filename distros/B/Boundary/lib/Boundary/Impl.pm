package Boundary::Impl;
use strict;
use warnings;

use B::Hooks::EndOfScope;
use Boundary ();

sub import {
    my ($class, @interfaces) = @_;
    my ($target, $filename, $line) = caller;

    on_scope_end {
        local $Boundary::CROAK_MESSAGE_SUFFIX = ". at $filename line $line\n";
        Boundary->apply_interfaces_to_package($target, @interfaces)
    };

    return;
}

1;
