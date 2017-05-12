use strict;
use warnings;

package B::Hooks::OP::Check::StashChange;

use parent qw/DynaLoader/;
use B::Hooks::OP::Check;

our $VERSION = '0.06';

sub dl_load_flags { 0x01 }

__PACKAGE__->bootstrap($VERSION);

1;

__END__

=head1 NAME

B::Hooks::OP::Check::StashChange - Invoke callbacks when the stash code is being compiled in changes

=head1 SYNOPSIS

=head2 From Perl

    package Foo;

    use B::Hooks::OP::Check::StashChange;

    our $id = B::Hooks::OP::Check::StashChange::register(sub {
        my ($new, $old) = @_;
        warn "${old} -> ${new}";
    });

    package Bar; # "Foo -> Bar"

    B::Hooks::OP::Check::StashChange::unregister($Foo::id);

    package Moo; # callback not invoked

=head2 From C/XS

    #include "hooks_op_check_stashchange.h"

    STATIC OP *
    my_callback (pTHX_ OP *op, char *new_stash, char *old_stash, void *user_data) {
        /* ... */
        return op;
    }

    UV id;

    /* register callback */
    id = hook_op_check_stashchange (cv, my_callback, NULL);

    /* unregister */
    hook_op_check_stashchange_remove (id);

=head1 DESCRIPTION

=head1 Perl API

=head2 register

    B::Hooks::OP::Check::

    # or
    my $id = B::Hooks::OP::Check::StashChange::register(\&callback);

Register C<callback> when an opcode is being compiled in a different namespace
than the previous one.

An id that can be used for later removal of the handler using C<unregister> is
returned.

=head2 unregister

    B::Hooks::OP::Check::StashChange::unregister($id);

Disable the callback referenced by C<$id>.

=head1 C API

=head2 TYPES

=head3 OP *(*hook_op_check_stashchange_cb) (pTHX_ OP *op, const char *new_stash, const char *old_stash, void *user_data)

The type the callbacks need to implement.

=head2 FUNCTIONS

=head3 UV hook_op_check_stashchange (hook_op_check_stashchange_cb cb, void *user_data)

Register the callback C<cb> to be when an opcode is compiled in a different
namespace than the previous. C<user_data> will be passed to the callback as the
last argument.

Returns an id that can be used to remove the handler using
C<hook_op_check_stashchange_remove>.

=head3 void *hook_op_check_stashchange_remove (UV id)

Remove a previously registered handler referred to by C<id>.

Returns the user data that was associated with the handler.

=head1 SEE ALSO

L<B::Hooks::OP::Check>

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 Florian Ragwitz

This module is free software.

You may distribute this code under the same terms as Perl itself.

=cut
