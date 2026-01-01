use strict;
use warnings;
package Data::Filter::Abstract;

# ABSTRACT: Generate Perl filter subs from data structures

use Data::Filter::Abstract::Util qw/:all/;

use overload
    '""'  => "to_source",
    '&{}' => "to_subref"
    ;

sub new {
    my $class = ref $_[0] ? ref shift : shift;

    my $source = simple_sub(@_);
    my $coderef = eval sprintf 'sub { no warnings qw/uninitialized/; local $_ = shift; %s }', $source;

    die "error in $source : $@" unless ref $coderef eq "CODE";
    bless {
	   source => $source,
	   subref => $coderef,
	  }, $class;
}

sub to_source {
    return shift()->{source}
}

sub to_subref {
    return shift()->{subref}
}

1;

=head1 NAME

Data::Filter::Abstract - generate Perl filter subs from data structures


=head1 SYNOPSIS

    use Data::Filter::Abstract;

    my $filter = Data::Filter::Abstract->new({
        foo => [ 1, "bar", qr/\d+/ ],
        baz => { '>' => 2, '<' => 5 },
    });

    # Use as a CODE reference
    my $match = $filter->({ foo => 1, baz => 3 }); # true

    # Get the generated Perl expression as text
    print "$filter\n"; 

=head1 DESCRIPTION

C<Data::Filter::Abstract> wraps the expression-generation DSL provided by
L<Data::Filter::Abstract::Util> and produces executable Perl predicates.

It compiles a hash- or array-based filter description into:

=over 4

=item *

A string expression suitable for embedding in a C<sub { ... }> block

=item *

A compiled coderef that can be called directly with a hash reference

=back

Objects overload stringification to return the expression and the code
dereference operator to return the coderef.

=head1 CONSTRUCTION

=head2 new

    my $filter = Data::Filter::Abstract->new($dsl);

C<$dsl> is any input accepted by C<simple_sub> in
L<Data::Filter::Abstract::Util> (hash, array, operator hash, scalar, etc.).

The constructor converts the input data structure into a Perl expression string and compiles the expression into a coderef, or dies if the generated coderef cannot be compiled.

=head1 USAGE

=head2 As a CODE reference

The object can be used directly as a predicate:

    my $match = $filter->($row);

=head2 Accessing the coderef

    my $coderef = $filter->to_subref;
    $coderef->($row);

=head2 Accessing the expression string

    my $expr = $filter->to_source;
    print "$expr\n";

=head1 OVERLOADING

=over 4

=item * Stringification

Returns the generated expression.

=item * Code dereference

Returns the compiled coderef.

=back

=head1 CAVEAT

This module uses C<eval> to compile Perl code. Embedded code references are executed verbatim.

=head1 DATA STRUCTURE CONVERSION

=head2 GENERAL SEMANTICS

The data-structure-to-filter-sub attempts to mimic L<SQL::Abstract> as closely as possible.

=over 4

=item *

All generated expressions assume C<$_> is a hash reference.

=item *

Field access is performed as C<$_->{field}>.

=item *

Hashes represent logical AND.

=item *

Arrays represent logical OR, unless explicitly overridden by logical operators.

=item *

Generated expressions are syntactically valid Perl code suitable for C<eval>.

=back

=head2 BASIC FILTER FORMS

=head3 Scalar equality

    simple_sub(foo => "bar")

Generates a string equality comparison:

    ($_->{foo} eq "bar")

If the value looks like a number, numeric comparison is used:

    simple_sub(foo => 1)
    # ($_->{foo} == 1)

=head3 Regular expressions

    simple_sub(foo => qr/12/)
    simple_sub(foo => qr/[a-z]/i)

Generates regex match expressions:

    ($_->{foo} =~ qr/12/)
    ($_->{foo} =~ qr/[a-z]/i)

=head3 Hash form (implicit AND)

    simple_sub({ bar => 1, baz => "wq", boo => qr/12/ })

Equivalent to:

    ($_->{bar} == 1)
    && ($_->{baz} eq "wq")
    && ($_->{boo} =~ qr/12/)

C<simple_hash> behaves identically.

=head2 ARRAY FORMS

=head3 Simple OR array

    simple_sub(foo => [ 1, "wq", qr/12/ ])

Generates a logical OR over the values:

    ($_->{foo} == 1)
    || ($_->{foo} eq "wq")
    || ($_->{foo} =~ qr/12/)

=head3 Arrays of operator expressions

    simple_array(foo => [ { '==', 2 }, { '>', 5 } ])

Generates:

    ($_->{foo} == 2) || ($_->{foo} > 5)

=head2 LOGICAL ARRAYS

Arrays may begin with a logical operator to control how elements are combined.

=head3 AND logic

    simple_sub(foo => [ -and => { '==', 2 }, { '>=', 5 } ])

Generates:

    ($_->{foo} == 2) && ($_->{foo} >= 5)

=head3 OR logic

    simple_sub(foo => [ -or => { '==', 2 }, { '>=', 5 } ])

Generates:

    ($_->{foo} == 2) || ($_->{foo} >= 5)

=head2 OPERATOR HASHES (FUNCTION HASHES)

A field value may be a hash mapping operators to values.

    simple_sub(foo => { '>' => 12, '<' => 23 })

Generates:

    ($_->{foo} < 23) && ($_->{foo} > 12)

The order of operators is not significant.

=head3 Supported operators (as tested)

=over 4

=item * String operators

    eq ne lt le gt ge

=item * Numeric operators

    == != < <= > >=

=item * Regex operators

    =~ !~

=back

=head2 OPERATORS WITH ARRAY VALUES

=head3 Equality with array

    simple_sub(status => { eq => [ 'assigned', 'in-progress', 'pending' ] })

Generates an OR expression:

    ($_->{status} eq "assigned")
    || ($_->{status} eq "in-progress")
    || ($_->{status} eq "pending")

Equivalent logic may also be expressed via a logical array:

    simple_sub(status => [
        -or =>
        { eq => 'assigned' },
        { eq => 'in-progress' },
        { eq => 'pending' },
    ])

=head3 Regex operators with arrays

    simple_sub(foo => { '=~' => [ qr/12/, qr/23/i ] })

Generates:

    ($_->{foo} =~ qr/12/)
    || ($_->{foo} =~ qr/23/i)

Non-regex values are coerced to regexes:

    simple_sub(foo => { '=~' => [ "12", qr/23/i ] })

=head2 UNDEF HANDLING

    simple_sub(user => undef)

Generates:

    (! defined $_->{user})

Operator hashes may also compare against undef, though some combinations are
known to be problematic (see tests marked as failing).

=head2 FIELD-TO-FIELD COMPARISON (SCALAR REF)

If the value is a scalar reference, it is interpreted as another field name.

    simple_sub(foo => \"bar")

Generates a dynamic comparison:

    ( (looks_like_number($_->{foo}))
        ? ($_->{foo} == $_->{bar})
        : ($_->{foo} eq $_->{bar})
    )

This form may also appear inside logical arrays.

=head2 CODE REFERENCES

A code reference may be supplied as a filter.

    simple_sub(sub { $_->{foo}->{bar} > 5 })

or

    simple_sub(foo => sub { $_->{foo}->{bar} > 5 })

The code reference is deparsed and embedded verbatim:

    (sub { use strict; $_->{'foo'}{'bar'} > 5; })

The field name is ignored when a code reference is supplied.

=head2 MIXED COMPLEX EXPRESSIONS

Arrays may contain mixed value types:

    simple_sub(foo => [
        1,
        "wq",
        qr/12/,
        sub { shift()->{foo}->{bar} > 5 }
    ])

Generates a logical OR over all components.

=head1 SEE ALSO

L<Data::Filter::Abstract>, L<SQL::Abstract>

=head1 AUTHOR

Simone Cesano <scesano@cpan.org>

=head1 LICENSE

This software is copyright (c) 2025 by Simone Cesano.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

