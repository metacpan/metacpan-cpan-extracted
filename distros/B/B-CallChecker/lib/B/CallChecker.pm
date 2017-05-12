=head1 NAME

B::CallChecker - custom B-based op checking for subroutines

=head1 SYNOPSIS

	use B::CallChecker
		qw(cv_get_call_checker cv_set_call_checker);

	($ckfun, $ckobj) = cv_get_call_checker(\&foo);
	cv_set_call_checker(\&foo, \&ckfun_bar, $ckobj);

	use B::CallChecker qw(
		ck_entersub_args_list ck_entersub_args_proto
		ck_entersub_args_proto_or_list
	);

	$entersubop = ck_entersub_args_list($entersubop);
	$entersubop = ck_entersub_args_proto(
			$entersubop, $namegv, $ckobj);
	$entersubop = ck_entersub_args_proto_or_list(
			$entersubop, $namegv, $ckobj);

=head1 DESCRIPTION

This module allows pure Perl code to attach a magical annotation to
a Perl subroutine, resulting in resolvable calls to that subroutine
being mutated at compile time by arbitrary Perl code.  The ops of the
subroutine call are manipulated via the L<B> system.  Despite coding in
Perl, the programmer must be aware of implementation details normally
only encountered in XS.

During compilation, when an C<entersub> op tree is constructed for a
subroutine call, the call is not marked with C<&>, and the callee can be
identified at compile time as a particular subroutine I<SUB>, part of
the op check phase for the C<entersub> op is implemented by a function
attached to the subroutine.  Two items are attached to the subroutine
for this purpose: I<CKFUN> is a subroutine reference and I<CKOBJ> is a
reference to anything.  The C<entersub> op gets modified by a process
amounting to

	$entersubop = $ckfun->($entersubop, $namegv, $ckobj);

In this call, I<ENTERSUBOP> is a reference to the C<entersub> op (in
C<B::OP> form, see L<B>), which may be replaced by the check function,
and I<NAMEGV> is a reference to a glob supplying the name that should
be used by the check function to refer to I<SUB> if it needs to emit
any diagnostics.  If possible, errors should be queued up in the parser
state, and the fixup function should return a well-formed op tree (albeit
possibly a silly or null one).  Aborting by C<die> is also permissible,
but it aborts compilation immediately, and the fixup function should
make sure to free the op tree first.

The I<CKFUN> and I<CKOBJ> for a particular I<SUB> can be determined
using L</cv_get_call_checker> and replaced using L</cv_set_call_checker>.
By default, a I<SUB>'s I<CKFUN> is L</ck_entersub_args_proto_or_list>, and
I<CKOBJ> is I<SUB> itself, which implements standard prototype processing.
It is permitted to apply the check function in non-standard situations,
such as to a call to a different subroutine or to a method call.

=cut

package B::CallChecker;

{ use 5.008; }
use warnings;
use strict;

use B ();
use Devel::CallChecker 0.003 ();
use XSLoader;

our $VERSION = "0.001";

use parent "Exporter";
our @EXPORT_OK = qw(
	cv_get_call_checker cv_set_call_checker
	ck_entersub_args_list ck_entersub_args_proto
	ck_entersub_args_proto_or_list
);

XSLoader::load(__PACKAGE__, $VERSION);

=head1 FUNCTIONS

=over

=item cv_get_call_checker(SUB)

I<SUB> must be a reference to a subroutine.  This function retrieves
the function that will be used to fix up calls to I<SUB>.  It returns a
two-element list, in which the first element (I<CKFUN>) is a reference to
a subroutine and the second element (I<CKOBJ>) is a reference to anything.

=item cv_set_call_checker(SUB, CKFUN, CKOBJ)

I<SUB> must be a reference to a subroutine.  This function sets the
function that will be used to fix up calls to I<SUB>.

=item ck_entersub_args_list(ENTERSUBOP)

Performs the default fixup of the arguments part of an C<entersub> op
tree, consisting of applying list context to each of the argument ops.
Note that this cannot be used directly as the fixup function to attach
to a subroutine.

=item ck_entersub_args_proto(ENTERSUBOP, NAMEGV, PROTOOBJ)

Performs the fixup of the arguments part of an C<entersub> op tree based
on a subroutine prototype.

I<PROTOOBJ> supplies the subroutine prototype to be applied to the call.
It must be a reference.  The referent may be a normal defined scalar,
of which the string value will be used.  Alternatively, for convenience,
the referent may be a subroutine which has a prototype.  The prototype
supplied, in whichever form, does not need to match the actual callee
referenced by the op tree.

=item ck_entersub_args_proto_or_list(ENTERSUBOP, NAMEGV, PROTOOBJ)

Performs the fixup of the arguments part of an C<entersub> op tree either
based on a subroutine prototype or using default list-context processing.
This is the standard treatment used on a subroutine call, not marked
with C<&>, where the callee can be identified at compile time.

I<PROTOOBJ> supplies the subroutine prototype to be applied to the
call, or indicates that there is no prototype.  It must be a reference.
The referent may be a normal scalar, in which case if it is defined then
the string value will be used as a prototype, and if it is undefined
then there is no prototype.  Alternatively, for convenience, the referent
may be a subroutine, of which the prototype will be used if it has one.
The prototype (or lack thereof) supplied, in whichever form, does not
need to match the actual callee referenced by the op tree.

=back

=head1 SEE ALSO

L<Devel::CallChecker>,
L<Sub::Mutate>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2011, 2012 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
