package B::OPCheck; # git description: v0.31-4-gd081d88
# ABSTRACT: PL_check hacks using Perl callbacks

use 5.008;

use strict;
use warnings;

use Carp;
use XSLoader;
use Scalar::Util;
use Scope::Guard;
use B::Utils 0.08 ();

our $VERSION = '0.32';

XSLoader::load 'B::OPCheck', $VERSION;

sub import {
    my ($class, $opname, $mode, $sub) = @_;

    $^H |= 0x120000; # set HINT_LOCALIZE_HH + an unused bit to work around a %^H bug

    my $by_opname = $^H{OPCHECK_leavescope} ||= {};
    my $guards = $by_opname->{$opname} ||= [];
    push @$guards, Scope::Guard->new(sub {
        leavescope($opname, $mode, $sub);
    });

    enterscope($opname, $mode, $sub);
}

sub unimport {
    my ($class, $opname) = @_;

    if ( defined $opname ) {
        my $by_opname = $^H{OPCHECK_leavescope};
        delete $by_opname->{$opname};
        return if scalar keys %$by_opname; # don't delete other things
    }

    delete $^H{OPCHECK_leavescope};
    $^H &= ~0x120000;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B::OPCheck - PL_check hacks using Perl callbacks

=head1 VERSION

version 0.32

=head1 SYNOPSIS

    use B::Generate; # to change things

    use B::OPCheck entersub => check => sub {
        my $op = shift; # op has been checked by normal PL_check
        sodomize($op);
    };

    foo(); # this entersub will have the callback triggered

=head1 DESCRIPTION

PL_check is an array indexed by opcode number (op_type) that contains function
pointers invoked as the last stage of optree compilation, per op.

This hook is called in bottom up order, as the code is parsed and the optree is
prepared.

This is how modules like L<autobox> do their magic

This module provides an api for registering PL_check hooks lexically, allowing
you to alter the behavior of certain ops using L<B::Generate> from perl space.

=head1 CHECK TYPES

=over 4

=item check

Called after normal PL_checking. The return value is ignored.

=item after

Not yet implemented.

Allows you to return a processed B::OP. The op has been processed by PL_check
already.

=item before

Not yet implemented.

Allows you to return a processed B::OP to be passed to normal PL_check.

=item replace

Not yet implemented.

Allows you to return a processed B::OP yourself, skipping normal PL_check
handling completely.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=B-OPCheck>
(or L<bug-B-OPCheck@rt.cpan.org|mailto:bug-B-OPCheck@rt.cpan.org>).

=head1 AUTHORS

=over 4

=item *

Chia-liang Kao <clkao@clkao.org>

=item *

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=back

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Florian Ragwitz Alexandr Ciornii

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by Chia-liang Kao, יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
