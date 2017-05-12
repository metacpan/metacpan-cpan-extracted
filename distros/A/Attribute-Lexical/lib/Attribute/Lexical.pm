=head1 NAME

Attribute::Lexical - sane scoping of function/variable attributes

=head1 SYNOPSIS

	use Attribute::Lexical "CODE:Funky" => \&funky_attr_handler;
	sub thingy :Funky { ... }

	$handler = Attribute::Lexical->handler_for_caller(
			[caller(0)], "CODE:Funky");

=head1 DESCRIPTION

This module manages attributes that can be attached to subroutine and
variable declarations.  Although it can be used directly, it is mainly
intended to be infrastructure for modules that supply particular attribute
semantics.

Meanings are assigned to attributes by code which is usually supplied
by modules and which runs at compile time.  The built-in mechanism for
attribute control is awkward to use, difficult in particular to enable
multiple attributes supplied by different modules, and it scopes attribute
meanings according to the package of the object to which attributes are
being applied.  This module is intended to overcome these limitations.

This module supplies a simple pragma to declare an attribute, associating
the attribute's name with a handler function that implements its
semantics.  The declaration is lexically scoped, lasting only until the
end of the enclosing block.  A declaration can be overridden, giving
an attribute name a different meaning or making it meaningless, in an
inner nested block.

=head2 Applying attributes

Attributes can be applied to variables or functions, where they are
declared.  A variable (which must be named) can have attributes added
as part of a declaration with the C<my>, C<our>, or C<state> keywords.
Variables may be of scalar, array, or hash type.  A function can have
attributes added wherever the C<sub> keyword is used: on a declaration
of a named function, whether or not it defines the function body, or on
an anonymous function.

An attribute list is introduced by a "B<:>" character, and attributes
are separated by "B<:>" or whitespace.  Each attribute starts with
an identifier, and may also have a parenthesised string argument.
See L<attributes> for details.

Attributes for functions and C<our> variables are applied at compile time.
For anonymous functions that close over external lexical variables, the
thing that has attributes applied is actually the prototype function,
which stores the code but is not associated with any set of variables and
so cannot be called.  When a closure is created at runtime, it copies
the state of this prototype, and does not get any attribute handling.
Attributes for C<my> and C<state> variables, on the other hand, are
applied at runtime, when execution reaches the variable declaration.

=head2 Attribute names

As noted in the previous section, each type of attribute that can be
applied to an object is identified by a name, in standard identifier
syntax.  The same identifier can also have different meanings depending
on the type of the object.  So for the purposes of this module, an
attribute is identified by the combination of object type and attribute
identifier.  These two parts are combined into one string, consisting
of type keyword ("B<SCALAR>", "B<ARRAY>", "B<HASH>", or "B<CODE>"),
"B<:>", and identifier.  For example, the name "B<CODE:Funky>" refers
to an attribute that can be applied to a function by syntax such as
"C<sub foo :Funky>".

Attribute identifiers that consist entirely of lowercase letters may have
meanings built into Perl.  Some are already defined, and others may be
defined in future versions.  User-defined attributes should therefore
always have identifiers containing some other kind of character.
Most commonly they start with an uppercase letter.

=head2 Handler functions

Each declared attribute is implemented by a handler function, which is
a normal Perl function, and may be either named or anonymous.  A single
function may handle many attributes.  When a declared attribute is to be
applied to an object, the handler function is called with four arguments:

=over

=item *

A reference to the target object.  The handler function is expected to
do something to this object.

=item *

The identifier part of the name under which the attribute was invoked.
Normally not of interest, but possibly useful when reporting errors,
in case the handler was attached to a different name from usual.

=item *

The attribute argument string.  This is what appears between parentheses
immediately following the attribute identifier.  C<undef> if there was
no argument.  A handler that is not expecting an argument should check
that no argument was supplied.

=item *

A reference to the array returned by the L<caller|perlfunc/caller>
function that describes the site where the attribute was invoked.
This is mainly useful to implement lexical semantics, such as using the
prevailing package in the interpretation of the argument.

=back

Attribute handler functions are mainly called during compile time, but
those for C<my> and C<state> variables are routinely called at runtime.
Any handler can also be called as part of a string L<eval|perlfunc/eval>,
when it is compile time for the code in the string but runtime for the
surrounding code.

When a code attribute handler is called, the target function will not
necessarily have its body defined yet.  Firstly, a function can be
pre-declared, so that it has a name and attributes but no body, and in
that case it might never get a body.  But also, in a normal function
definition with a body, the attributes are processed before the body
has been attached to the function (although after it has been compiled).
If an attribute handler needs to operate on the function's body, it must
take special measures to cause code to run later.

=cut

package Attribute::Lexical;

{ use 5.006001; }
use warnings;
use strict;

use constant _KLUDGE_HINT_LOCALIZE_HH   => "$]" < 5.009004;
use constant _KLUDGE_RUNTIME_HINTS      => "$]" < 5.009004;
use constant _KLUDGE_FAKE_MRO           => "$]" < 5.009005;
use constant _KLUDGE_UNIVERSAL_INVOCANT => 1;   # bug#68654 or bug#81098

use Carp qw(croak);
use Lexical::SealRequireHints 0.005;
use Params::Classify 0.000 qw(is_string is_ref);
use if !_KLUDGE_FAKE_MRO, "mro";

our $VERSION = "0.004";

# Hints stored in %^H only maintain referenceful structure during the
# compilation phase.  Copies of %^H that are accessible via caller(),
# which we need in order to support runtime use of the lexical state,
# flatten all values to plain strings.  So %interned_handler permanently
# holds references to all handler functions seen, keyed by the string
# form of the reference.
my %interned_handler;

{
	package Attribute::Lexical::UNIVERSAL;
	our $VERSION = "0.004";
}

unshift @UNIVERSAL::ISA, "Attribute::Lexical::UNIVERSAL";

foreach my $type (qw(SCALAR ARRAY HASH CODE)) { eval "
	package Attribute::Lexical::UNIVERSAL;
	my \$type = \"$type\";
	sub MODIFY_${type}_ATTRIBUTES
{".q{
	my $invocant = shift(@_);
	my $target = shift(@_);
	my @unhandled;
	my @caller;
	for(my $i = 0; ; $i++) {
		@caller = caller($i);
		if(!@caller || $caller[3] =~ /::BEGIN\z/) {
			# Strangely not called via attributes::import.
			# No idea of the relevant lexical environment,
			# so don't handle any attributes.
			ALL_UNHANDLED:
			@unhandled = @_;
			goto HANDLE_UNHANDLED;
		}
		if($caller[3] eq "attributes::import") {
			if(Attribute::Lexical::_KLUDGE_RUNTIME_HINTS) {
				# On earlier perls we can only get lexical
				# hints during compilation, because %^H
				# isn't shown by caller().  In that case,
				# we check here that the attributes are
				# being applied as part of compilation,
				# indicated by attributes::import being
				# called directly from a BEGIN block.
				# If it's called elsewhere, including
				# indirectly from within a BEGIN
				# block, then it's a runtime attribute
				# application, which we can't handle.
				my @nextcall = caller($i+1);
				unless(@nextcall &&
						$nextcall[3] =~ /::BEGIN\z/) {
					goto ALL_UNHANDLED;
				}
			}
			last;
		}
	}
	foreach my $attr (@_) {
		my($ident, $arg) = ($attr =~ /\A
			([A-Za-z_][0-9A-Za-z_]*)
			(?:\((.*)\))?
		\z/sx);
		if(defined($ident) && defined(my $handler = (
			Attribute::Lexical::_KLUDGE_RUNTIME_HINTS ? 
				# %^H is not available through caller() on
				# earlier perls.  In that case, if called
				# during compilation, we can kludge by
				# looking at the current compilation %^H.
				Attribute::Lexical->handler_for_compilation(
					"$type:$ident")
			:
				Attribute::Lexical->handler_for_caller(
					\@caller, "$type:$ident")
		))) {
			$handler->($target, $ident, $arg, \@caller);
		} else {
			push @unhandled, $attr;
		}
	}
	HANDLE_UNHANDLED:
	return () unless @unhandled;
	my $next;
	if(Attribute::Lexical::_KLUDGE_FAKE_MRO) {
		# next::can is not available in earlier perls, or at least
		# not in the core, so do it manually.
		my $found_self;
		foreach my $class (@UNIVERSAL::ISA) {
			if(!$found_self) {
				$found_self = $class eq __PACKAGE__;
				next;
			}
			$next = $class->can("MODIFY_${type}_ATTRIBUTES")
				and last;
		}
	} else {
		# On earlier perls next::can doesn't look at methods
		# defined in UNIVERSAL and its superclases, where they
		# are implicit ancestors.  The first attempt at fixing
		# that was just as broken, jumping backward in the class
		# precedence list when dealing with universal superclasses
		# and a real invocant.	In either case, starting the
		# search at the UNIVERSAL class produces sane results.
		$next = (Attribute::Lexical::_KLUDGE_UNIVERSAL_INVOCANT ?
				"UNIVERSAL" : $invocant)->next::can;
	}
	if($next) {
		return $invocant->$next($target, @unhandled);
	} else {
		return @unhandled;
	}
}."}
	1;
" or die $@; }

sub _check_attribute_name($) {
	croak "attribute name must be a string" unless is_string($_[0]);
	croak "malformed attribute name" unless $_[0] =~ qr/\A
		(?:SCALAR|ARRAY|HASH|CODE):
		[A-Za-z_][0-9A-Za-z_]*
	\z/x;
}

=head1 PACKAGE METHODS

All these methods are meant to be invoked on the C<Attribute::Lexical>
package.

=over

=item Attribute::Lexical->handler_for_caller(CALLER, NAME)

Looks up the attribute named I<NAME> (e.g., "B<CODE:Funky>")
according to the lexical declarations prevailing in a specified place.
I<CALLER> must be a reference to an array of the form returned by
the L<caller|perlfunc/caller> function, describing the lexical site
of interest.  If the requested attribute is declared in scope then
a reference to the handler function is returned, otherwise C<undef>
is returned.

This method is not available prior to Perl 5.9.4, because earlier Perls
don't make lexical state available at runtime.

=cut

BEGIN { unless(_KLUDGE_RUNTIME_HINTS) { eval q{ sub handler_for_caller {
	my($class, $caller, $name) = @_;
	_check_attribute_name($name);
	my $h = ($caller->[10] || {})->{"Attribute::Lexical/$name"};
	return defined($h) ? $interned_handler{$h} : undef;
} 1; } or die $@; } }

=item Attribute::Lexical->handler(NAME)

Looks up the attribute named I<NAME> (e.g., "B<CODE:Funky>") according
to the lexical declarations prevailing at the site of the call to this
method.  If the requested attribute is declared in scope then a reference
to the handler function is returned, otherwise C<undef> is returned.

This method is not available prior to Perl 5.9.4, because earlier Perls
don't make lexical state available at runtime.

=cut

BEGIN { unless(_KLUDGE_RUNTIME_HINTS) { eval q{
	sub handler { shift->handler_for_caller([caller(0)], @_) }
1; } or die $@; } }

=item Attribute::Lexical->handler_for_compilation(NAME)

Looks up the attribute named I<NAME> (e.g., "B<CODE:Funky>") according to
the lexical declarations prevailing in the code currently being compiled.
If the requested attribute is declared in scope then a reference to the
handler function is returned, otherwise C<undef> is returned.

=cut

sub handler_for_compilation {
	my($class, $name) = @_;
	_check_attribute_name($name);
	my $h = $^H{"Attribute::Lexical/$name"};
	return defined($h) ? $interned_handler{$h} : undef;
}

=item Attribute::Lexical->import(NAME => HANDLER, ...)

Sets up lexical attribute declarations, in the lexical environment that
is currently compiling.  Each I<NAME> must be an attribute name (e.g.,
"B<CODE:Funky>"), and each I<HANDLER> must be a reference to a function.
The name is lexically associated with the handler function I<HANDLER>.
Within the resulting scope, use of the attribute name will result in
the handler function being called to apply the attribute.

=cut

sub import {
	my $class = shift(@_);
	croak "$class does no default importation" if @_ == 0;
	croak "import list for $class must alternate name and handler"
		unless @_ % 2 == 0;
	$^H |= 0x20000 if _KLUDGE_HINT_LOCALIZE_HH;   # implicit in later perls
	for(my $i = 0; $i != @_; $i += 2) {
		my($name, $handler) = @_[$i, $i+1];
		_check_attribute_name($name);
		croak "attribute handler must be a subroutine"
			unless is_ref($handler, "CODE");
		$interned_handler{"$handler"} = $handler;
		$^H{"Attribute::Lexical/$name"} = "$handler";
	}
}

=item Attribute::Lexical->unimport(NAME [=> HANDLER], ...)

Sets up negative lexical attribute declarations, in the lexical
environment that is currently compiling.  Each I<NAME> must be
an attribute name (e.g., "B<CODE:Funky>").  If the name is given
on its own, it is lexically dissociated from any handler function.
Within the resulting scope, the attribute name will not be recognised.
If a I<HANDLER> (which must be a function reference) is specified with
a name, the name will be dissociated if and only if it is currently
handled by that function.

=cut

sub unimport {
	my $class = shift(@_);
	croak "$class does no default unimportation" if @_ == 0;
	$^H |= 0x20000 if _KLUDGE_HINT_LOCALIZE_HH;   # implicit in later perls
	for(my $i = 0; $i != @_; ) {
		my $name = $_[$i++];
		_check_attribute_name($name);
		my $handler = is_ref($_[$i], "CODE") ? $_[$i++] : undef;
		my $key = "Attribute::Lexical/$name";
		next unless exists $^H{$key};
		if($handler) {
			next unless $interned_handler{$^H{$key}} == $handler;
		}
		delete $^H{$key};
	}
}

=back

=head1 BUGS

This module uses relatively new and experimental features of Perl, and
is liable to expose problems in the interpreter.  On older versions of
Perl some of the necessary infrastructure is missing, so the module uses
workarounds, with varying degrees of success.  Specifically:

Prior to Perl 5.9.4, the lexical state of attribute declarations is not
available at runtime.  Most attributes are handled at compile time,
when the lexical state is available, so the module largely works.
But C<my>/C<state> variables have attributes applied at runtime,
which won't work.  Usually the attributes will be simply unavailable
at runtime, as if they were never declared, but some rare situations
involving declaring attributes inside a C<BEGIN> block can confuse the
module into applying the wrong attribute handler.

Prior to Perl 5.9.3, the lexical state of attribute declarations does
not propagate into string eval.

Prior to Perl 5.8, attributes don't work at all on C<our> variables.
Only function attributes can be used effectively on such old versions.

This module tries quite hard to play nicely with other modules that manage
attributes, in particular L<Attribute::Handlers>.  However, the underlying
protocol for attribute management is tricky, and convoluted arrangements
of attribute managers are liable to tread on each other's toes.

The management of handler functions is likely to run into trouble where
threads are used.  Code compiled before any threads are created should
be OK, as should anything contained entirely within a single thread,
but code shared between threads will probably have trouble due to Perl
not properly sharing data structures.

=head1 SEE ALSO

L<Attribute::Handlers>,
L<attributes>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2010, 2011 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
