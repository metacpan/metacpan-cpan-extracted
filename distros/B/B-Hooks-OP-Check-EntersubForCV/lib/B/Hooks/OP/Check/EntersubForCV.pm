use strict;
use warnings;

package B::Hooks::OP::Check::EntersubForCV;

use parent qw/DynaLoader/;
use B::Hooks::OP::Check 0.19;
use Scalar::Util qw/refaddr/;
use B::Utils 0.19 ();

our $VERSION = '0.10';

sub dl_load_flags { 0x01 }

__PACKAGE__->bootstrap($VERSION);

my %CALLBACKS;

sub import {
    my $class = shift;

    die 'odd number of arguments'
        unless @_ % 2 == 0;

    while (@_) {
        my ($cv, $cb) = (shift, shift);
        $CALLBACKS{ refaddr $cv } = register($cv, $cb);
    }

    return;
}

sub unimport {
    my $class = shift;

    unregister($_) for delete @CALLBACKS{ map { refaddr $_ } @_ };
    return;
}

1;

__END__

=head1 NAME

B::Hooks::OP::Check::EntersubForCV - Invoke callbacks on construction of entersub OPs for certain CVs

=head1 SYNOPSIS

=head2 From Perl

    sub foo {}

    use B::Hooks::OP::Check::EntersubForCV
        \&foo => sub { warn "entersub for foo() being compiled" };

    foo(); # callback is invoked when this like is compiled

    no B::Hooks::OP::Check::EntersubForCV \&foo;

    foo(); # callback isn't invoked

=head2 From C/XS

    #include "hook_op_check_entersubforcv.h"

    STATIC OP *
    my_callback (pTHX_ OP *op, CV *cv, void *user_data) {
        /* ... */
        return op;
    }

    hook_op_check_id id;

    /* register callback */
    id = hook_op_check_entersubforcv (cv, my_callback, NULL);

    /* unregister */
    hook_op_check_entersubforcv_remove (id);

=head1 DESCRIPTION

=head1 Perl API

=head2 import / register

    use B::Hooks::OP::Check::EntersubForCV
        \&code => \&handler;

    # or
    my $id = B::Hooks::OP::Check::EntersubForCV::register(\&code => \&handler);

Register C<handler> to be executed when an entersub opcode for the CV C<code>
points to is compiled.

When using C<register> an id that can be used for later removal of the handler
using C<unregister> is returned.

=head2 unimport / unregister

    no B::Hooks::OP::Check::EntersubForCV \&code;

    # or
    B::Hooks::OP::Check::EntersubForCV::unregister($id);

Stop calling the registered handler for C<code> for all entersubs after this.

=head1 C API

=head2 TYPES

=head3 OP *(*hook_op_check_entersubforcv_cb) (pTHX_ OP *, CV *, void *)

The type the handlers need to implement.

=head2 FUNCTIONS

=head3 hook_op_check_id hook_op_check_entersubforcv (CV *cv, hook_op_check_entersubforcv_cb cb, void *user_data)

Register the callback C<cb> to be called when an entersub opcode for C<cv> is
compiled. C<user_data> will be passed to the callback as the last argument.

Returns an id that can be used to remove the handler using
C<hook_op_check_entersubforcv_remove>.

=head3 void *hook_op_check_entersubforcv_remove (hook_op_check_id id)

Remove a previously registered handler referred to by C<id>.

Returns the user data that was associated with the handler.

=head1 SEE ALSO

L<B::Hooks::OP::Check>

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008, 2009 Florian Ragwitz

Copyright (c) 2011, 2012, 2017 Andrew Main (Zefram)

This module is free software.

You may distribute this code under the same terms as Perl itself.

=cut
