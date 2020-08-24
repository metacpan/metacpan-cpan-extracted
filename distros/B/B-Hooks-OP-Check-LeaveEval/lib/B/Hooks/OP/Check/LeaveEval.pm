package B::Hooks::OP::Check::LeaveEval;
use strict;
use warnings;
use version 0.77; our $VERSION = version->declare('v0.0.4');

use B::Hooks::OP::Check;
use XSLoader;

XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__
=pod

=encoding utf8

=head1 NAME

B::Hooks::OP::Check::LeaveEval - call a subroutine when new code finishes compiling

=head1 SYNOPSIS

    use B::Hooks::OP::Check::LeaveEval;

    my $id = B::Hooks::OP::Check::LeaveEval::register(sub { print "New code!\n" });

    require Foo;                 # will print "New code!"
    eval 'sub Foo::bar { ... }'; # will print "New code!"

    B::Hooks::OP::Check::LeaveEval::unregister($id);

    require Bar;                 # won't print

=head1 DESCRIPTION

This module allows to hook into every execution of the C<leaveeval> opcode,
this happens when a new module is finished loading (either via C<use> or C<require>)
or an C<eval> is done.  Essentially, this means it will be called whenever new
code is finished compling.

=head1 FUNCTIONS

=head2 register

    my $id = B::Hooks::OP::Check::LeaveEval::register(sub { ... });

Register a callback for C<leaveeval> executions.
The callback will receive no arguments and its return value will be ignored.

The returned C<$id> can be used to remove the callback later (see L<unregister>).

=head2 unregister

    B::Hooks::OP::Check::LeaveEval::unregister($id);

Remove the callback referenced by C<$id>.

=head1 AUTHOR

Szymon Nieznański <s.nez@member.fsf.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Szymon Nieznański.

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
