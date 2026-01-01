package Data::Filter::Abstract::Util;

# ABSTRACT: turns data structures into sub sources

use Exporter 'import';

our @EXPORT_OK   = qw(simple_sub simple_hash simple_array simple_function_hash logical_array sub_source);
our %EXPORT_TAGS = (all => [qw(simple_sub simple_hash simple_array simple_function_hash logical_array sub_source)]);

use Scalar::Util qw(looks_like_number);

use re qw(is_regexp regexp_pattern);

use B;
use B::Deparse;

use strict;
use Carp;

my $deparse = B::Deparse->new;


sub is_equality_op {
    my ($h) = @_;

    # return 0 unless keys($h->%*) == 1;

    my $ops = {
	       '==' => 'numeric', '!=' => 'numeric', '<'  => 'numeric', '>'  => 'numeric', '<=' => 'numeric', '>=' => 'numeric', # numerical comparisons
	       'eq' => 'string', 'ne' => 'string', 'lt' => 'string', 'gt' => 'string', 'le' => 'string', 'ge' => 'string', # string comparison
	       '=~' => 'regexp', '!~' => 'regexp', # unimplemented
    };

    return $ops->{ (keys $h->%*)[0] } // '';
}

sub key_q { local $_ = shift; return /^[a-z0-9_]+$/i ? $_ : B::perlstring($_) }
sub var_q { B::perlstring(shift) }

sub simple_sub {
    my ($k, $v) = @_;
    my $r;

    if (scalar @_ == 1 && ! ref $_[0]) {
	return sprintf '($_->{%s})', key_q($k);
    }
    elsif (scalar @_ == 2 && ! ref $_[1]) {
	return sprintf '(! defined $_->{%s})', key_q($k) unless defined $v;
	return sprintf '($_->{%s} == %s)', key_q($k), $v if looks_like_number($v);
	return sprintf '($_->{%s} eq %s)', key_q($k), var_q($v);
    }
    elsif (0 == (scalar @_ % 2) && scalar @_ > 2) {
	my @args = @_; my @r;
	while (@args) { push @r, simple_sub((shift @args), shift(@args)) }
	return sprintf "%s", join " && ", @r;
    }

    unless ($v) { $v = $k; $k = undef }
    for (ref $v) {
	/^Regexp$/ && do {
	    return sprintf '($_->{%s} =~ qr/%s/%s)', key_q($k), regexp_pattern($v);
	};
	/^HASH$/ && (is_equality_op($v)) && scalar $v->%* == 1 && do {
	    return equality_op($k, $v)
	};
	/^HASH$/ && do {
	    return join " && ", map { is_equality_op({ $_, $v->{$_} }) ? simple_sub($k => { $_, $v->{$_} }) : simple_sub($_ => $v->{$_}) } sort keys $v->%*;
	};
	/^ARRAY$/ && ($r = (logical_array($k, $v))) && do {
	    return $r
	};
	/^ARRAY$/ && do {
	    return simple_array($k, $v)
	};
	/^SCALAR$/ && do {
	    return  sprintf '((looks_like_number($_->{%s})) ? ($_->{%s} == $_->{%s}) : ($_->{%s} eq $_->{%s}))', key_q($k), key_q($k), $$v, key_q($k), $$v;
	};
	/^CODE$/ && do {
	    # carp sprintf "WARNING: defining field \"%s\" with subref is useless\n", $k if defined $k;
	    return sprintf '(sub %s)', $deparse->coderef2text($v) =~ s/\s*\n\s*/ /grs,
	};
	die sprintf "%s ref is unimplemented\n", ref $v
    }
}

sub simple_hash {
    my ($v) = @_;
    return join " && ", map { simple_sub($_, $v->{$_}) } sort keys $v->%*
}

sub simple_array {
    my ($k, $v) = @_;
    return join " || ", map { simple_sub($k, $_) } $v->@*
}

sub simple_function_hash {
    my ($k, $v) = @_;
    return join " && ", map { simple_sub($k, { $_, $v->{$_} }) } sort keys $v->%*;
}

sub logical_array {
    my ($k, $v) = @_;
    my @v = $v->@*;
    my $ops = { '-and' => " && ", '-or' => " || " };
    return unless $ops->{$v[0]};
    my $l = $ops->{(shift @v)};
    die sprintf "Using array as arg with logical op is not permitted\n", $k if ref $v[0] eq "ARRAY";
    return join $l, map { simple_sub($k, $_) } @v;
}

sub equality_op {
    my ($k, $v) = @_;
    my $values = (values $v->%*)[0];
    if (is_equality_op($v) eq 'string') {
	if (ref($values) eq "ARRAY") {
	    return simple_array($k, (values $v->%*))
	}
	elsif (!defined ((values $v->%*)[0]) ) {
	    my ($o, $d) = $v->%*;
	    croak "Use of %s and undef in filter is not allowed", $o unless $o eq 'ne' or $o eq 'eq';
	    return sprintf '(%sdefined $_->{%s})', ($o eq 'ne' ? '' : '!'), key_q($k);
	}
	else {
	    return join " && ", map { sprintf '($_->{%s} %s %s)', key_q($k), $_, var_q($v->{$_}) } keys $v->%*
	}
    }
    elsif (is_equality_op($v) eq 'numeric') {
	if (ref($values) eq "ARRAY") {
	    return simple_array($k, (values $v->%*))
	}
	elsif (!defined ((values $v->%*)[0]) ) {
	    my ($o, $d) = $v->%*;
	    croak "Use of %s and undef in filter is not allowed", $o unless $o eq '!=' or $o eq '==';
	    return sprintf '(%sdefined $_->{%s})', ($o eq '!=' ? '' : '!'), key_q($k);
	}
	else {
	    return join " && ", map { sprintf '($_->{%s} %s %s)', key_q($k), $_, $v->{$_} } keys $v->%*
	}
    }
    elsif (is_equality_op($v) eq 'regexp') {
	if (ref($values) eq "ARRAY") {
	    return simple_array($k, [ map { ref $_ eq "Regexp" ? $_ : qr/$_/ } $values->@* ])
	}
	else {
	    return join " && ", map {
		my $re = ref ($v->{$_}) eq "Regexp" ? $v->{$_} : qr/$v->{$_}/;
		sprintf '($_->{%s} %s qr/%s/%s)', key_q($k), $_, regexp_pattern($re)} keys $v->%*;
	}
    }
    else {
	croak "Unhandled operator %s", keys $v->%*;
    }
}

1;


=head1 NAME

Data::Filter::Abstract::Util - DSL for generating Perl filter expressions from data structures

=head1 SYNOPSIS

    use Data::Filter::Abstract::Util qw(:all);

    my $expr = simple_sub(foo => "bar");
    # => '($_->{foo} eq "bar")'

    my $code = eval "sub { $expr }";
    $code->({ foo => "bar" }); # true

=head1 DESCRIPTION

This module implements a small domain-specific language (DSL) for describing
boolean filters as Perl data structures. The DSL is compiled into Perl
expressions (as strings) which operate on C<$_>, assumed to be a hash reference.

The resulting expressions are intended to be embedded into C<sub { ... }>
blocks and evaluated.

The test suite defines the DSL behavior and serves as its authoritative
specification.

=head1 GENERAL SEMANTICS

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

=head1 BASIC FILTER FORMS

=head2 Scalar equality

    simple_sub(foo => "bar")

Generates a string equality comparison:

    ($_->{foo} eq "bar")

If the value looks like a number, numeric comparison is used:

    simple_sub(foo => 1)
    # ($_->{foo} == 1)

=head2 Regular expressions

    simple_sub(foo => qr/12/)
    simple_sub(foo => qr/[a-z]/i)

Generates regex match expressions:

    ($_->{foo} =~ qr/12/)
    ($_->{foo} =~ qr/[a-z]/i)

=head2 Hash form (implicit AND)

    simple_sub({ bar => 1, baz => "wq", boo => qr/12/ })

Equivalent to:

    ($_->{bar} == 1)
    && ($_->{baz} eq "wq")
    && ($_->{boo} =~ qr/12/)

C<simple_hash> behaves identically.

=head1 ARRAY FORMS

=head2 Simple OR array

    simple_sub(foo => [ 1, "wq", qr/12/ ])

Generates a logical OR over the values:

    ($_->{foo} == 1)
    || ($_->{foo} eq "wq")
    || ($_->{foo} =~ qr/12/)

=head2 Arrays of operator expressions

    simple_array(foo => [ { '==', 2 }, { '>', 5 } ])

Generates:

    ($_->{foo} == 2) || ($_->{foo} > 5)

=head1 LOGICAL ARRAYS

Arrays may begin with a logical operator to control how elements are combined.

=head2 AND logic

    simple_sub(foo => [ -and => { '==', 2 }, { '>=', 5 } ])

Generates:

    ($_->{foo} == 2) && ($_->{foo} >= 5)

=head2 OR logic

    simple_sub(foo => [ -or => { '==', 2 }, { '>=', 5 } ])

Generates:

    ($_->{foo} == 2) || ($_->{foo} >= 5)

=head1 OPERATOR HASHES (FUNCTION HASHES)

A field value may be a hash mapping operators to values.

    simple_sub(foo => { '>' => 12, '<' => 23 })

Generates:

    ($_->{foo} < 23) && ($_->{foo} > 12)

The order of operators is not significant.

=head2 Supported operators (as tested)

=over 4

=item * String operators

    eq ne lt le gt ge

=item * Numeric operators

    == != < <= > >=

=item * Regex operators

    =~ !~

=back

=head1 OPERATORS WITH ARRAY VALUES

=head2 Equality with array

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

=head2 Regex operators with arrays

    simple_sub(foo => { '=~' => [ qr/12/, qr/23/i ] })

Generates:

    ($_->{foo} =~ qr/12/)
    || ($_->{foo} =~ qr/23/i)

Non-regex values are coerced to regexes:

    simple_sub(foo => { '=~' => [ "12", qr/23/i ] })

=head1 UNDEF HANDLING

    simple_sub(user => undef)

Generates:

    (! defined $_->{user})

Operator hashes may also compare against undef, though some combinations are
known to be problematic (see tests marked as failing).

=head1 FIELD-TO-FIELD COMPARISON (SCALAR REF)

If the value is a scalar reference, it is interpreted as another field name.

    simple_sub(foo => \"bar")

Generates a dynamic comparison:

    ( (looks_like_number($_->{foo}))
        ? ($_->{foo} == $_->{bar})
        : ($_->{foo} eq $_->{bar})
    )

This form may also appear inside logical arrays.

=head1 CODE REFERENCES

A code reference may be supplied as a filter.

    simple_sub(sub { $_->{foo}->{bar} > 5 })

or

    simple_sub(foo => sub { $_->{foo}->{bar} > 5 })

The code reference is deparsed and embedded verbatim:

    (sub { use strict; $_->{'foo'}{'bar'} > 5; })

The field name is ignored when a code reference is supplied.

=head1 MIXED COMPLEX EXPRESSIONS

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

=cut
