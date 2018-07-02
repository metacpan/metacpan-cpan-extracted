=head1 NAME

Devel::CallParser - custom parsing attached to subroutines

=head1 SYNOPSIS

	# to generate header prior to XS compilation

	perl -MDevel::CallParser=callparser0_h \
		-e 'print callparser0_h' > callparser0.h
	perl -MDevel::CallParser=callparser1_h \
		-e 'print callparser1_h' > callparser1.h

	# in Perl part of module

	use Devel::CallParser;

	/* in XS */

	#include "callparser0.h"

	cv_get_call_parser(cv, &psfun, &psobj);
	static OP *my_psfun(pTHX_ GV *namegv, SV *psobj, U32 *flagsp);
	cv_set_call_parser(cv, my_psfun, psobj);

	#include "callparser1.h"

	cv_get_call_parser(cv, &psfun, &psobj);
	static OP *my_psfun(pTHX_ GV *namegv, SV *psobj, U32 *flagsp);
	cv_set_call_parser(cv, my_psfun, psobj);

	args = parse_args_parenthesised(&flags);
	args = parse_args_nullary(&flags);
	args = parse_args_unary(&flags);
	args = parse_args_list(&flags);
	args = parse_args_block_list(&flags);
	args = parse_args_proto(namegv, protosv, &flags);
	args = parse_args_proto_or_list(namegv, protosv, &flags);

=head1 DESCRIPTION

This module provides a C API, for XS modules, concerned with custom
parsing.  It is centred around the function C<cv_set_call_parser>, which
allows XS code to attach a magical annotation to a Perl subroutine,
resulting in resolvable calls to that subroutine having their arguments
parsed by arbitrary C code.  (This is a more conveniently structured
facility than the core's C<PL_keyword_plugin> API.)  This module makes
C<cv_set_call_parser> and several supporting functions available.

This module provides the implementation of the functions at runtime.
It also, at compile time, supplies the C header file and link
library which provide access to the functions.  In normal use,
L</callparser0_h>/L</callparser1_h> and L</callparser_linkable> should
be called at build time (not authoring time) for the module that wishes
to use the C functions.

=cut

package Devel::CallParser;

{ use 5.011002; }
use warnings;
use strict;

use Devel::CallChecker 0.001 ();

our $VERSION = "0.002";

use parent "Exporter";
our @EXPORT_OK = qw(callparser0_h callparser1_h callparser_linkable);

{
	require DynaLoader;
	local our @ISA = qw(DynaLoader);
	local *dl_load_flags = sub { 1 };
	__PACKAGE__->bootstrap($VERSION);
}

=head1 CONSTANTS

=over

=item callparser0_h

Content of a C header file, intended to be named "C<callparser0.h>".
It is to be included in XS code, and C<perl.h> must be included first.
When the XS module is loaded at runtime, the C<Devel::CallParser>
module must be loaded first.  This will result in a limited form of
the C functions C<cv_get_call_parser> and C<cv_set_call_parser> being
available to the XS code.

The C<cv_get_call_parser> and C<cv_set_call_parser> functions supplied
by this header are mostly as described below.  However, for subroutines
that have default argument parsing behaviour, C<cv_get_call_parser>
will return null pointers for the parsing function and its SV argument,
rather than pointing to a real function that implements default parsing.
Correspondingly, C<cv_set_call_parser> will accept such a pair of
null pointers to restore default argument parsing for a subroutine.
The advantage of these modified semantics is that this much of the
functionality is available on Perl versions where it is not possible
to implement standard argument parsing as a distinct function.  This is
the case on all Perl versions prior to 5.13.8.

This header is only available on Perl versions 5.11.2 and higher.

=item callparser1_h

Content of a C header file, intended to be named "C<callparser1.h>".
It is to be included in XS code, and C<perl.h> must be
included first.  When the XS module is loaded at runtime, the
C<Devel::CallParser> module must be loaded first.  This will result
in the C functions C<cv_get_call_parser>, C<cv_set_call_parser>,
C<parse_args_parenthesised>, C<parse_args_nullary>, C<parse_args_unary>,
C<parse_args_list>, C<parse_args_block_list>, C<parse_args_proto>, and
C<parse_args_proto_or_list>, as defined below, being available to the
XS code.

This header is only available on Perl versions 5.13.8 and higher.

=item callparser_linkable

List of names of files that must be used as additional objects when
linking an XS module that uses the C functions supplied by this module.
This list will be empty on many platforms.

=cut

sub callparser_linkable() {
	require DynaLoader::Functions;
	DynaLoader::Functions->VERSION(0.001);
	return DynaLoader::Functions::linkable_for_module(__PACKAGE__);
}

=back

=head1 C FUNCTIONS

=over

=item cv_get_call_parser

Retrieves the function that will be used to parse the arguments for a
call to I<cv>.  Specifically, the function is used for a subroutine call,
not marked with C<&>, where the callee can be identified at compile time
as I<cv>.

The C-level function pointer is returned in I<*psfun_p>, and an SV
argument for it is returned in I<*psobj_p>.  The function is intended
to be called in this manner:

    argsop = (*psfun_p)(aTHX_ namegv, (*psobj_p), &flags);

This call is to be made when the parser has just scanned and accepted
a bareword and determined that it begins the syntax of a call to I<cv>.
I<namegv> is a GV supplying the name that should be used by the parsing
function to refer to the callee if it needs to emit any diagnostics,
and I<flags> is a C<U32> that the parsing function can write to as an
additional output.  It is permitted to apply the parsing function in
non-standard situations, such as to a call to a different subroutine.

The parsing function's main output is an op tree describing a list of
argument expressions.  This may be null for an empty list.  The argument
expressions will be combined with the expression that identified I<cv> and
used to build an C<entersub> op describing a complete subroutine call.
The parsing function may also set flag bits in I<flags> for special
effects.  The bit C<CALLPARSER_PARENS> indicates that the argument
list was fully parenthesised, which makes a difference only in obscure
situations.  The bit C<CALLPARSER_STATEMENT> indicates that what was
parsed was syntactically not an expression but a statement.

By default, the parsing function is
L<Perl_parse_args_proto_or_list|/parse_args_proto_or_list>, and the
SV parameter is I<cv> itself.  This implements standard subroutine
argument parsing.  It can be changed, for a particular subroutine,
by L</cv_set_call_parser>.

	void cv_get_call_parser(CV *cv, Perl_call_parser *psfun_p,
		SV **psobj_p)

=item cv_set_call_parser

Sets the function that will be used to parse the arguments for a call
to I<cv>.  Specifically, the function is used for a subroutine call,
not marked with C<&>, where the callee can be identified at compile time
as I<cv>.

The C-level function pointer is supplied in I<psfun>, and an SV argument
for it is supplied in I<psobj>.  The function is intended to be called
in this manner:

    argsop = (*psfun_p)(aTHX_ namegv, (*psobj_p), &flags);

This call is to be made when the parser has just scanned and accepted
a bareword and determined that it begins the syntax of a call to I<cv>.
I<namegv> is a GV supplying the name that should be used by the parsing
function to refer to the callee if it needs to emit any diagnostics,
and I<flags> is a C<U32> that the parsing function can write to as an
additional output.  It is permitted to apply the parsing function in
non-standard situations, such as to a call to a different subroutine.

The parsing function's main output is an op tree describing a list of
argument expressions.  This may be null for an empty list.  The argument
expressions will be combined with the expression that identified I<cv> and
used to build an C<entersub> op describing a complete subroutine call.
The parsing function may also set flag bits in I<flags> for special
effects.  The bit C<CALLPARSER_PARENS> indicates that the argument
list was fully parenthesised, which makes a difference only in obscure
situations.  The bit C<CALLPARSER_STATEMENT> indicates that what was
parsed was syntactically not an expression but a statement.

The current setting for a particular CV can be retrieved by
L</cv_get_call_parser>.

	void cv_set_call_parser(CV *cv, Perl_call_parser psfun,
		SV *psobj)

=item parse_args_parenthesised

Parse a parenthesised argument list for a subroutine call.  The argument
list consists of an optional expression enclosed in parentheses.
This is the syntax that is used for any subroutine call where the first
thing following the subroutine name is an open parenthesis.  It is used
regardless of the subroutine's prototype.

The op tree representing the argument list is returned.  The bit
C<CALLPARSER_PARENS> is set in I<*flags_p>, to indicate that the argument
list was fully parenthesised.

	OP *parse_args_parenthesised(U32 *flags_p)

=item parse_args_nullary

Parse an argument list for a call to a subroutine that is syntactically
a nullary function.  The argument list is either parenthesised or
completely absent.  This is the syntax that is used for a call to a
subroutine with a C<()> prototype.

The op tree representing the argument list is returned.  The bit
C<CALLPARSER_PARENS> is set in I<*flags_p> if the argument list was
parenthesised.

	OP *parse_args_nullary(U32 *flags_p)

=item parse_args_unary

Parse an argument list for a call to a subroutine that is syntactically
a unary function.  The argument list is either parenthesised, absent,
or consists of an unparenthesised arithmetic expression.  This is the
syntax that is used for a call to a subroutine with prototype C<($)>,
C<(;$)>, or certain similar prototypes.

The op tree representing the argument list is returned.  The bit
C<CALLPARSER_PARENS> is set in I<*flags_p> if the argument list was
parenthesised.

	OP *parse_args_unary(U32 *flags_p)

=item parse_args_list

Parse an argument list for a call to a subroutine that is syntactically
a list function.  The argument list is either parenthesised, absent, or
consists of an unparenthesised list expression.  This is the syntax that
is used for a call to a subroutine with any prototype that does not have
special handling (such as C<(@)> or C<($$)>) or with no prototype at all.

The op tree representing the argument list is returned.  The bit
C<CALLPARSER_PARENS> is set in I<*flags_p> if the argument list was
parenthesised.

	OP *parse_args_list(U32 *flags_p)

=item parse_args_block_list

Parse an argument list for a call to a subroutine that is syntactically
a block-and-list function.  The argument list is either parenthesised,
absent, an unparenthesised list expression, or consists of a code block
followed by an optionl list expression.  Where the first thing seen
is an open brace, it is always interpreted as a code block.  This is
the syntax that is used for a call to a subroutine with any prototype
beginning with C<&>, such as C<(&@)> or C<(&$)>.

The op tree representing the argument list is returned.  The bit
C<CALLPARSER_PARENS> is set in I<*flags_p> if the argument list was
parenthesised.

	OP *parse_args_block_list(U32 *flags_p)

=item parse_args_proto

Parse a subroutine argument list based on a subroutine prototype.
The syntax used for the argument list will be that implemented by
L</parse_args_nullary>, L</parse_args_unary>, L</parse_args_list>, or
L</parse_args_block_list>, depending on the prototype.  This is the
standard treatment used on a subroutine call, not marked with C<&>,
where the callee can be identified at compile time and has a prototype.

I<protosv> supplies the subroutine prototype to be applied to the call.
It may be a normal defined scalar, of which the string value will be used.
Alternatively, for convenience, it may be a subroutine object (a C<CV*>
that has been cast to C<SV*>) which has a prototype.

The I<namegv> parameter would be used to refer to the callee if required
in any error message, but currently no message does so.

The op tree representing the argument list is returned.  The bit
C<CALLPARSER_PARENS> is set in I<*flags_p> if the argument list was
parenthesised.

	OP *parse_args_proto(GV *namegv, SV *protosv, U32 *flags_p)

=item parse_args_proto_or_list

Parse a subroutine argument list either based on a subroutine prototype or
using default list-function syntax.  The syntax used for the argument list
will be that implemented by L</parse_args_nullary>, L</parse_args_unary>,
L</parse_args_list>, or L</parse_args_block_list>, depending on the
prototype.  This is the standard treatment used on a subroutine call,
not marked with C<&>, where the callee can be identified at compile time.

I<protosv> supplies the subroutine prototype to be applied to the call, or
indicates that there is no prototype.  It may be a normal scalar, in which
case if it is defined then the string value will be used as a prototype,
and if it is undefined then there is no prototype.  Alternatively, for
convenience, it may be a subroutine object (a C<CV*> that has been cast
to C<SV*>), of which the prototype will be used if it has one.

The I<namegv> parameter would be used to refer to the callee if required
in any error message, but currently no message does so.

The op tree representing the argument list is returned.  The bit
C<CALLPARSER_PARENS> is set in I<*flags_p> if the argument list was
parenthesised.

	OP *parse_args_proto_or_list(GV *namegv, SV *protosv,
		U32 *flags_p)

=back

=head1 BUGS

Due to reliance on Perl core features to do anything interesting, only
a very limited form of custom parsing is possible prior to Perl 5.13.8,
and none at all prior to Perl 5.11.2.

The way this module determines which parsing code to use for a subroutine
conflicts with the expectations of some particularly tricky modules that
use nasty hacks to perform custom parsing without proper support from the
Perl core.  In particular, this module is incompatible with versions of
L<Devel::Declare> prior to 0.006004 and versions of L<Data::Alias> prior
to 1.13.  An arrangement has been reached that allows later versions of
those modules to coexist with this module.

Custom parsing code is only invoked if the subroutine to which it is
attached is invoked using an unqualified name.  For example, the name
C<foo> works, but the name C<main::foo> will not, despite referring
to the same subroutine.  This is an unavoidable limitation imposed by
the core's interim facility for custom parser plugins.  This should
be resolved if the API provided by this module, or something similar,
migrates into the core in a future version of Perl.

=head1 SEE ALSO

L<Devel::CallChecker>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2011, 2013 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
