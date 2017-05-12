package Data::Alias;

use 5.008001;

use strict;
use warnings;

our $VERSION = '1.20';

use base 'Exporter';
use base 'DynaLoader';

our @EXPORT = qw(alias);
our @EXPORT_OK = qw(alias copy deref);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

bootstrap Data::Alias $VERSION;
pop our @ISA;

=head1 NAME

Data::Alias - Comprehensive set of aliasing operations

=head1 SYNOPSIS

    use Data::Alias;

    alias {
	    # aliasing instead of copying whenever possible
    };

    alias $x = $y;		# alias $x to $y
    alias @x = @y;		# alias @x to @y
    alias $x[0] = $y;		# similar for array and hash elements
    alias push @x, $y;		# push alias to $y onto @x
    $x = alias [ $y, $z ];	# construct array of aliases
    alias my ($x, $y) = @_;	# named aliases to arguments
    alias { ($x, $y) = ($y, $x) };		# swap $x and $y
    alias { my @t = @x; @x = @y; @y = @t };	# swap @x and @y

    use Data::Alias qw/ alias copy /;

    alias { copy $x = $y };	# force copying inside alias-BLOCK

    use Data::Alias qw/ deref /;

    my @refs = (\$x, \@y, \%z);
    foo(deref @refs)		# same as foo($x, @y, %z)

=head1 DESCRIPTION

Aliasing is the phenomenon where two different expressions actually refer to 
the same thing.  Modifying one will modify the other, and if you take a 
reference to both, the two values are the same.

Aliasing occurs in Perl for example in for-loops and sub-calls:

    for $var ($x) {
            # here $var is an alias to $x
    }

    foo($y);
    sub foo {
            # here $_[0] is an alias to $y
    }

Data::Alias is a module that allows you to apply "aliasing semantics" to a 
section of code, causing aliases to be made wherever Perl would normally make 
copies instead.  You can use this to improve efficiency and readability, when 
compared to using references.

The exact details of aliasing semantics are below under L</DETAILS>.

Perl 5.22 added some support for aliasing to the Perl core.  It has a
different syntax, and a different set of operations, from that supplied by
this module; see L<perlref/Assigning to References>.  The core's aliasing
facilities are implemented more robustly than this module and are better
supported.  If you can rely on having a sufficiently recent Perl version,
you should prefer to use the core facility rather than use this module.
If you are already using this module and are now using a sufficiently
recent Perl, you should attempt to migrate to the core facility.

=head1 SYNTAX

=head2 alias I<EXPR> | alias I<BLOCK>

Exported by default.

Enables aliasing semantics within the expression or block.  Returns an alias 
to the expression, or the block's return value.

C<alias> is context-transparent, meaning that whichever context it is placed in 
(list, scalar, void), the expression/block is evaluated in the same context.

=head2 copy I<EXPR> | copy I<BLOCK>

Restores normal (copying) semantics within the expression or block, and 
makes a copy of the result value (unless in void context).

Like C<alias>, C<copy> is context-transparent.

=head2 deref I<LIST>

Accepts a list of references to scalars, arrays, or hashes.  Applies the 
applicable dereferencing operator to each.  This means that:

    deref $scalarref, $arrayref, $hashref

behaves like:

    $$scalarref, @$arrayref, %$hashref

Where an array or hash reference is given, the returned list does not
include the array or hash as an lvalue; the array/hash is expanded and
the list includes its elements.  Scalars, including the elements of an
array/hash, I<are> treated as lvalues, and can be enreferenced using
the C<\> operator or aliased to using the C<alias> operator.  This is
slightly different from what you'd get using the built-in dereference
operators: C<@$arrayref> references the array as an lvalue, so C<\>
or C<alias> can operate on the array itself rather than just its elements.

=head1 EXAMPLES

A common usage of aliasing is to make an abbreviation for an expression, to 
avoid having to repeat that (possibly verbose or ugly) expression over and 
over:
    
    alias my $fi = $self->{FrobnitzIndex};
    $fi = $fi > 0 ? $fi - $adj : $fi + $adj;

    sub rc4 {
            alias my ($i, $j, $S) = @_;
            my $a = $S->[($i += 1) &= 255];
            my $b = $S->[($j += $S->[$i]) &= 255];
            $S->[(($S->[$j] = $a) + ($S->[$i] = $b)) & 255]
    }

In the second example, the rc4 function updates its first two arguments (two 
state values) in addition to returning a value.

Aliasing can also be used to avoid copying big strings.  This example would 
work fine without C<alias> but would be much slower when passed a big string:

    sub middlesection ($) {
            alias my $s = shift;
            substr $s, length($s)/4, length($s)/2
    }

You can also apply aliasing semantics to an entire block.  Here this is used to 
swap two arrays in O(1) time:

    alias {
            my @temp = @x;
            @x = @y;
            @y = @temp;
    };

The C<copy> function is typically used to temporarily reinstate normal 
semantics, but can also be used to explicitly copy a value when perl would 
normally not do so:

    my $ref = \copy $x;

=head1 DETAILS

This section describes exactly what the aliasing semantics are of operations.  
Anything not listed below has unaltered behaviour.

=over 4

=item scalar assignment to variable or element.

Makes the left-side of the assignment an alias to the right-side expression, 
which can be anything.

    alias my $lexvar = $foo;
    alias $pkgvar = $foo;
    alias $array[$i] = $foo;
    alias $hash{$k} = $foo;

An attempt to do alias-assignment to an element of a tied (or "magical") array 
or hash will result in a "Can't put alias into tied array/hash" error.

=item scalar assignment to dereference

If $ref is a reference or undef, this simply does C<$ref = \$foo>.  Otherwise, 
the indicated package variable (via glob or symbolic reference) is made an 
alias to the right-side expression.

    alias $$ref = $foo;

=item scalar assignment to glob

Works mostly the same as normal glob-assignment, however it does not set the 
import-flag.  (If you don't know what this means, you probably don't care)

    alias *glob = $reference;

=item scalar assignment to anything else

Not supported.

    alias substr(...) = $foo;	# ERROR!
    alias lvalsub() = $foo;	# ERROR!

=item conditional scalar assignment

Here C<$var> (and C<$var2>) are aliased to C<$foo> if the applicable condition 
is satisfied.  C<$bool> and C<$foo> can be any expression.  C<$var> and 
C<$var2> can be anything that is valid on the left-side of an alias-assignment.

    alias $bool ? $var : $var2 = $foo;
    alias $var &&= $foo;
    alias $var ||= $foo;
    alias $var //= $foo; # (perl 5.9.x or later)

=item whole aggregate assignment from whole aggregate

This occurs where the expressions on both sides of the assignment operator
are purely complete arrays or hashes.
The entire aggregate is aliased, not merely the contents.  
This means for example that C<\@lexarray == \@foo>.

    alias my @lexarray = @foo;
    alias my %lexhash = %foo;
    alias @pkgarray = @foo;
    alias %pkghash = %foo;

Making the left-side a dereference is also supported:

    alias @$ref = @foo;
    alias %$ref = %foo;

and analogously to assignment to scalar dereference, these will change C<$ref> 
to reference the aggregate, if C<$ref> was undef or already a reference.  If 
C<$ref> is a string or glob, the corresponding package variable is aliased.

Anything more complex than a whole-aggregate expression on either side,
even just enclosing the aggregate expression in parentheses, will prevent
the assignment qualifying for this category.  It will instead go into
one of the following two categories.  Parenthesisation is the recommended
way to avoid whole-aggregate aliasing where it is unwanted.  If you want
to merely replace the contents of the left-side aggregate with aliases
to the contents of the right-side aggregate, parenthesise the left side.

=item whole aggregate assignment from list

If the left-side expression is purely a complete array or hash,
and the right-side expression is not purely a matching aggregate, then a new 
aggregate is implicitly constructed.  This means:

    alias my @lexfoo = (@foo);
    alias my @array = ($x, $y, $z);
    alias my %hash = (x => $x, y => $y);

is translated to:

    alias my @lexfoo = @{ [@foo] };
    alias my @array = @{ [$x, $y, $z] };
    alias my %hash = %{ {x => $x, y => $y} };

If you want to merely replace the contents of the aggregate with aliases to the 
contents of another aggregate, rather than create a new aggregate, you can 
force list-assignment by parenthesizing the left side, see below.

=item list assignment

List assignment is any assignment where the left-side is an array-slice, 
hash-slice, or list in parentheses.  This behaves essentially like many scalar 
assignments in parallel.

    alias my (@array) = ($x, $y, $z);
    alias my (%hash) = (x => $x, y => $y);
    alias my ($x, $y, @rest) = @_;
    alias @x[0, 1] = @x[1, 0];

Any scalars that appear on the left side must be valid targets for scalar 
assignment.  When an array or hash appears on the left side, normally as the 
last item, its contents are replaced by the list of all remaining right-side 
elements.  C<undef> can also appear on the left side to skip one corresponding 
item in the right-side list.

Beware when putting a parenthesised list on the left side.  Just like Perl 
parses C<print (1+2)*10> as C<(print(1+2))*10>, it would parse C<alias ($x, $y) 
= ($y, $x)> as C<(alias($x, $y)) = ($y, $x)> which does not do any aliasing, 
and results in the "Useless use of alias" warning, if warnings are enabled.

To circumvent this issue, you can either one of the following:

    alias +($x, $y) = ($y, $x);
    alias { ($x, $y) = ($y, $x) };

=item Anonymous aggregate constructors

Return a reference to a new anonymous array or hash, populated with aliases.  
This means that for example C<\$hashref-E<gt>{x} == \$x>.

    my $arrayref = alias [$x, $y, $z];
    my $hashref = alias {x => $x, y => $y};

Note that this also works:

    alias my $arrayref = [$x, $y, $z];
    alias my $hashref = {x => $x, y => $y};

but this makes the lhs an alias to the temporary, and therefore read-only, 
reference made by C<[]> or C<{}>.  Therefore later attempts to assign to 
C<$arrayref> or C<$hashref> results in an error.  The anonymous aggregate that 
is referenced behaves the same in both cases obviously.

=item Array insertions

These work as usual, except the inserted elements are aliases.

    alias push @array, $foo;
    alias unshift @array, $foo;
    alias splice @array, 1, 2, $foo;

An attempt to do any of these on tied (or "magical") array will result in a 
"Can't push/unshift/splice alias onto tied array" error.

=item Returning an alias

Returns aliases from the current C<sub> or C<eval>.  Normally this only
happens for lvalue subs, but C<alias return> can be used in any sub.
Lvalue subs only work for scalar return values, but C<alias return>
can handle a list of return values.

A sub call will very often copy the return value(s) immediately after
they have been returned.  C<alias return> can't prevent that.  To pass
an alias through a sub return and into something else, the call site
must process the return value using an aliasing operation, or at least a
non-copying one.  For example, ordinary assignment with the sub call on
the right hand side will copy, but if the call site is in the scope of an
C<alias> pragma then the assignment will instead alias the return value.

When alias-returning a list of values from a subroutine, each individual
value in the list is aliased.  The list as a whole is not aliasable;
it is not an array.  At the call site, a list of aliases can be captured
into separate variables or into an array, by an aliasing list assignment.

=item Subroutines and evaluations

Placing a subroutine or C<eval STRING> inside C<alias> causes it to be compiled 
with aliasing semantics entirely.  Additionally, the return from such a sub or 
eval, whether explicit using C<return> or implicitly the last statement, will 
be an alias rather than a copy.

    alias { sub foo { $x } };

    my $subref = alias sub { $x };
    
    my $xref1 = \foo;
    my $xref2 = \alias eval '$x';
    my $xref3 = \$subref->();

Explicitly returning an alias can also be done using C<alias return> inside any 
subroutine or evaluation.

    sub foo { alias return $x; }
    my $xref = \foo;

=item Localization

Use of local inside C<alias> usually behaves the same as local does in general, 
however there is a difference if the variable is tied:  in this case, Perl 
doesn't localise the variable at all but instead preserves the tie by saving a 
copy of the current value, and restoring this value at end of scope.

    alias local $_ = $string;

The aliasing semantics of C<local> avoids copying by always localizing the 
variable itself, regardless of whether it is tied.

=back

=head1 IMPLEMENTATION

This module does B<not> use a source filter, and is therefore safe to use 
within eval STRING.  Instead, Data::Alias hooks into the Perl parser, and 
replaces operations within the scope of C<alias> by aliasing variants.

For those familiar with perl's internals:  it triggers on a ck_rv2cv which 
resolves to the imported C<alias> sub, and does a parser hack to allow the 
C<alias BLOCK> syntax.  When the ck_entersub is triggered that corresponds to 
it, the op is marked to be found later.  The actual work is done in a peep-hook,
which processes the marked entersub 
and its children, replacing the pp_addrs with aliasing replacements.  The peep 
hook will also take care of any subs defined within the lexical (but not 
dynamical) scope between the ck_rv2cv and the ck_entersub.

=head1 KNOWN ISSUES

=over 4

=item Lexical variables

When aliasing existing lexical variables, the effect is limited in scope to the 
current subroutine and any closures create after the aliasing is done, even if 
the variable itself has wider scope.  While partial fixes are possible, it 
cannot be fixed in any reliable or consistent way, and therefore I'm keeping 
the current behaviour.

When aliasing a lexical that was declared outside the current subroutine, a 
compile-time warning is generated "Aliasing of outer lexical variable has 
limited scope" (warnings category "closure").

=back

=head1 ACKNOWLEDGEMENTS

Specials thanks go to Elizabeth Mattijsen, Juerd Waalboer, and other members of 
the Amsterdam Perl Mongers, for their valuable feedback.

=head1 AUTHOR

Matthijs van Duin <xmath@cpan.org> developed the module originally,
and maintained it until 2007.  Andrew Main (Zefram) <zefram@fysh.org>
updated it to work with Perl versions 5.11.0 and later.

=head1 LICENSE

Copyright (C) 2003-2007  Matthijs van Duin.
Copyright (C) 2010, 2011, 2013, 2015 Andrew Main (Zefram) <zefram@fysh.org>.
All rights reserved.
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut

__PACKAGE__
