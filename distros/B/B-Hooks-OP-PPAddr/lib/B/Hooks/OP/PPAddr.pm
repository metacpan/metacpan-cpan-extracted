use strict;
use warnings;
package B::Hooks::OP::PPAddr; # git description: v0.05-5-gf0d3ed7
# ABSTRACT: Hook into opcode execution

use parent qw/DynaLoader/;

our $VERSION = '0.06';

sub dl_load_flags { 0x01 }

__PACKAGE__->bootstrap($VERSION);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B::Hooks::OP::PPAddr - Hook into opcode execution

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    #include "hook_op_check.h"
    #include "hook_op_ppaddr.h"

    STATIC OP *
    execute_entereval (pTHX_ OP *op, void *user_data) {
        ...
    }

    STATIC OP *
    check_entereval (pTHX_ OP *op, void *user_data) {
        hook_op_ppaddr (op, execute_entereval, NULL);
    }

    hook_op_check (OP_ENTEREVAL, check_entereval, NULL);

=head1 DESCRIPTION

This module provides a C API for XS modules to hook into the execution of perl
opcodes.

L<ExtUtils::Depends> is used to export all functions for other XS modules to
use. Include the following in your F<Makefile.PL>:

    my $pkg = ExtUtils::Depends->new('Your::XSModule', 'B::Hooks::OP::PPAddr');
    WriteMakefile(
        ... # your normal makefile flags
        $pkg->get_makefile_vars,
    );

Your XS module can now include C<hook_op_ppaddr.h>.

=head1 TYPES

=head2 OP

    typedef OP *(*hook_op_ppaddr_cb_t) (pTHX_ OP *, void *user_data)

Type that callbacks need to implement.

=head1 FUNCTIONS

=head2 hook_op_ppaddr

    void hook_op_ppaddr (OP *op, hook_op_ppaddr_cb_t cb, void *user_data)

Replace the function to execute C<op> with the callback C<cb>. C<user_data>
will be passed to the callback as the last argument.

=head2 hook_op_ppaddr_around

    void hook_op_ppaddr_around (OP *op, hook_op_ppaddr_cb_t before, hook_op_ppaddr_cb_t after, void *user_data)

Register the callbacks C<before> and C<after> to be called before and after the
execution of C<op>. C<user_data> will be passed to the callback as the last
argument.

=head1 SEE ALSO

=over 4

=item *

L<B::Hooks::OP::Check>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=B-Hooks-OP-PPAddr>
(or L<bug-B-Hooks-OP-PPAddr@rt.cpan.org|mailto:bug-B-Hooks-OP-PPAddr@rt.cpan.org>).

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Alexandr Ciornii Stephan Loyd

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

Stephan Loyd <stephanloyd9@gmail.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
