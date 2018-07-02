package Assert::Refute::T::Basic;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.1201';

=head1 NAME

Assert::Refute::T::Basic - a set of most common checks for Assert::Refute suite

=head1 DESCRIPTION

This module contains most common test conditions similar to those in
L<Test::More>, like C<is $got, $expected;> or C<like $got, qr/.../;>.

They appear as both exportable functions in this module
and L<Assert::Refute> itself
I<and> as corresponding methods in L<Assert::Refute::Report>.

=head1 FUNCTIONS

All functions below are prototyped to be used without parentheses and
exported by default. Scalar context is imposed onto arguments, so

    is @foo, @bar;

would actually compare arrays by length.

If a C<contract { ... }> is in action, the results of each assertion
will be recorded there. See L<Assert::Refute::Report> for more.
If L<Test::More> is in action, a unit testing script is assumed.
If neither is true, an exception is thrown.

In addition, a C<Assert::Refute::Report-E<gt>function_name> method with
the same signature is generated for each of them
(see L<Assert::Refute::Build>).

=cut

use Carp;
use Scalar::Util qw(blessed looks_like_number refaddr);
use parent qw(Exporter);

use Assert::Refute::Build;
our @EXPORT = qw( diag note );
our @EXPORT_OK;

=head2 is $got, $expected, "explanation"

Check for equality, C<undef> equals C<undef> and nothing else.

=cut

build_refute is => sub {
    my ($got, $exp) = @_;

    if (defined $got xor defined $exp) {
        return "unexpected ". to_scalar($got, 0);
    };

    return '' if !defined $got or $got eq $exp;
    return sprintf "Got:      %s\nExpected: %s"
        , to_scalar($got, 0), to_scalar($exp, 0);
}, args => 2, export => 1;

=head2 isnt $got, $expected, "explanation"

The reverse of is().

=cut

build_refute isnt => sub {
    my ($got, $exp) = @_;
    return if defined $got xor defined $exp;
    return "Unexpected: ".to_scalar($got)
        if !defined $got or $got eq $exp;
}, args => 2, export => 1;

=head2 ok $condition, "explanation"

=cut

build_refute ok => sub {
    my $got = shift;

    return !$got;
}, args => 1, export => 1;

=head2 use_ok

Not really tested well.

=cut

# TODO write it better
build_refute use_ok => sub {
    my ($mod, @arg) = @_;
    my $caller = caller(1);
    eval "package $caller; use $mod \@arg; 1" and return ''; ## no critic
    return "Failed to use $mod: ".($@ || "(unknown error)");
}, list => 1, export => 1;

build_refute require_ok => sub {
    my ($mod, @arg) = @_;
    my $caller = caller(1);
    eval "package $caller; require $mod; 1" and return ''; ## no critic
    return "Failed to require $mod: ".($@ || "(unknown error)");
}, args => 1, export => 1;

=head2 cpm_ok $value1, 'operation', $value2, "explanation"

Currently supported: C<E<lt> E<lt>= == != E<gt>= E<gt>>
C<lt le eq ne ge gt>

Fails if any argument is undefined.

=cut

my %compare;
$compare{$_} = eval "sub { return \$_[0] $_ \$_[1]; }" ## no critic
    for qw( < <= == != >= > lt le eq ne ge gt );
my %numeric;
$numeric{$_}++ for qw( < <= == != >= > );

build_refute cmp_ok => sub {
    my ($x, $op, $y) = @_;

    my $fun = $compare{$op};
    croak "cmp_ok(): Comparison '$op' not implemented"
        unless $fun;

    my @missing;
    if ($numeric{$op}) {
        push @missing, '1 '.to_scalar($x).' is not numeric'
            unless looks_like_number $x or blessed $x;
        push @missing, '2 '.to_scalar($y).' is not numeric'
            unless looks_like_number $y or blessed $y;
    } else {
        push @missing, '1 is undefined' unless defined $x;
        push @missing, '2 is undefined' unless defined $y;
    };

    return "cmp_ok '$op': argument ". join ", ", @missing
        if @missing;

    return '' if $fun->($x, $y);
    return "$x\nis not '$op'\n$y";
}, args => 3, export => 1;

=head2 like $got, qr/.../, "explanation"

=head2 like $got, "regex", "explanation"

B<UNLIKE> L<Test::More>, accepts string argument just fine.

If argument is plain scalar, it is anchored to match the WHOLE string,
so that C<"foobar"> does NOT match C<"ob">,
but DOES match C<".*ob.*"> OR C<qr/ob/>.

=head2 unlike $got, "regex", "explanation"

The exact reverse of the above.

B<UNLIKE> L<Test::More>, accepts string argument just fine.

If argument is plain scalar, it is anchored to match the WHOLE string,
so that C<"foobar"> does NOT match C<"ob">,
but DOES match C<".*ob.*"> OR C<qr/ob/>.

=cut

build_refute like => \&_like_unlike,
    args => 2, export => 1;

build_refute unlike => sub {
    _like_unlike( $_[0], $_[1], 1 );
}, args => 2, export => 1;

sub _like_unlike {
    my ($str, $reg, $reverse) = @_;

    $reg = qr#^(?:$reg)$# unless ref $reg eq 'Regexp';
        # retain compatibility with Test::More
    return "got (undef), expecting ".($reverse ? "anything except" : "")."\n$reg"
        if !defined $str;
    return '' if $str =~ $reg xor $reverse;
    return "$str\n".($reverse ? "unexpectedly matches" : "doesn't match")."\n$reg";
};

=head2 can_ok

=cut

build_refute can_ok => sub {
    my $class = shift;

    croak ("can_ok(): no methods to check!")
        unless @_;

    return 'undefined' unless defined $class;
    return 'Not an object: '.to_scalar($class)
        unless UNIVERSAL::can( $class, "can" );

    my @missing = grep { !$class->can($_) } @_;
    return @missing && (to_scalar($class, 0)." has no methods ".join ", ", @missing);
}, list => 1, export => 1;

=head2 isa_ok

=cut

build_refute isa_ok => \&_isa_ok, args => 2, export => 1;

build_refute new_ok => sub {
    my ($class, $args, $target) = @_;

    croak ("new_ok(): at least one argument must be present")
        unless defined $class;
    croak ("new_ok(): too many arguments")
        if @_ > 3;

    $args   ||= [];
    $class  = ref $class || $class;
    $target ||= $class;

    return "Not a class: ".to_scalar($class, 0)
        unless UNIVERSAL::can( $class, "can" );
    return "Class has no 'new' method: ".to_scalar( $class, 0 )
        unless $class->can( "new" );

    return _isa_ok( $class->new( @$args ), $target );
}, list => 1, export => 1;

sub _isa_ok {
    my ($obj, $class) = @_;

    croak 'isa_ok(): No class supplied to check against'
        unless defined $class;
    return "undef is not a $class" unless defined $obj;
    $class = ref $class || $class;

    if (
        (UNIVERSAL::can( $obj, "isa" ) && !$obj->isa( $class ))
        || !UNIVERSAL::isa( $obj, $class )
    ) {
        return to_scalar( $obj, 0 ) ." is not a $class"
    };
    return '';
};

=head2 contract_is $contract, "signature", ["message"]

Check that a contract has been fullfilled to exactly the specified extent.

See L<Assert::Refute::Report/get_sign> for exact signature format.

=cut

build_refute contract_is => sub {
    my ($c, $sig) = @_;

    my $got = $c->get_sign;
    return $got ne $sig && <<"EOF".$c->get_tap;
Unexpected subcontract signature.
Got:      $got
Expected: $sig
Execution log:
EOF
}, args => 2, export => 1;

=head2 diag @message

Human-readable diagnostic message.

References are automatically serialized to depth 1.

=head2 note @message

Human-readable comment message.

References are automatically serialized to depth 1.

=cut

sub diag (@) { ## no critic
    current_contract->diag(@_);
};

sub note (@) { ## no critic
    current_contract->note(@_);
};

=head2 is_deeply( $got, $expected )

    my $check = contract {
        my $arg = shift;
        my $expected = naive_impl( $arg );
        is_deeply fast_impl( $arg ), $expected, "fast_impl generates same data";
    };

Unlike the L<Test::More> counterpart, it will not first after first mismatch
and print details about 10 mismatching entries.

=head2 is_deeply_diff( $got, $expected, $max_diff )

Same as above, but the third parameter specifies the number
of mismatches in data to be reported.

B<[EXPERIMENTAL]> name and meaning may change in the future.
a C<$max_diff> of 0 would lead to unpredictable results.

=cut

push @EXPORT_OK, qw(deep_diff);

build_refute is_deeply => \&deep_diff, export => 1, args => 2;
build_refute is_deeply_diff => \&deep_diff, export_ok => 1, args => 3;

=head2 deep_diff( $old, $new )

Not exported by default.
Compares 2 scalars recursively, outputs nothing if they are identical,
or a I<complete> difference if they differ.

The exact difference format shall not be relied upon.

=cut

sub deep_diff {
    my ($old, $new, $maxdiff, $known, $path) = @_;

    $path ||= '$deep';
    $maxdiff = 10 unless defined $maxdiff;

    # First compare types. Report if different.
    if (ref $old ne ref $new or (defined $old xor defined $new)) {
        return _deep_not($path, $old, $new);
    };

    # Check scalar values. compare with eq.
    if (!ref $old) {
        return unless defined $old;
        return $old eq $new
            ? ()
            : _deep_not($path, $old, $new),
    };

    # Topology check (and also avoid infinite loop)
    # If we've seen these structures before,
    #    just compare the place where it happened
    # if not, remember for later
    # From now on, $path eq $seen_* really means "never seen before"
    # NOTE refaddr(...) to get rid of warning under older perls
    my $seen_old = $known->{-refaddr($old)} ||= $path;
    my $seen_new = $known->{ refaddr($new)} ||= $path;

    # Seen previously in different places - report
    if ($seen_old ne $seen_new) {
        # same as _deep_not, but with addresses
        return [
            "At $path: ",
            "     Got: ".($seen_old ne $path ? "Same as $seen_old" : to_scalar($old,2)),
            "Expected: ".($seen_new ne $path ? "Same as $seen_new" : to_scalar($new,2)),
        ];
    };
    # these structures have already been compared elsewhere - skip
    return if $seen_old ne $path;

    # this is the same structure - skip
    return if refaddr($old) eq refaddr($new);

    # descend into deep structures
    $known ||= {};

    if (UNIVERSAL::isa( $old , 'ARRAY') ) {
        my @diff;
        my $min = @$old < @$new ? scalar @$old : scalar @$new;
        my $max = @$old > @$new ? scalar @$old : scalar @$new;
        foreach my $i( 0 .. $min - 1 ) {
            my $off = deep_diff( $old->[$i], $new->[$i], $maxdiff, $known, $path."[$i]" );
            if ($off) {
                push @diff, @$off;
                $maxdiff -= @$off / 3;
            };
            last if $maxdiff <= 0;
        };
        foreach my $i ($min .. $max - 1) {
            push @diff, _deep_noexist( $path."[$i]", $old->[$i], $new->[$i], @$new - @$old );
            $maxdiff--;
            last if $maxdiff <= 0;
        };
        return @diff ? \@diff : ();
    };

    if (UNIVERSAL::isa( $old, 'HASH') ) {
        my %both;
        $both{$_}-- for keys %$old;
        $both{$_}++ for keys %$new;
        my @diff;
        foreach (sort keys %both) {
            if ($both{$_}) {
                # nonzero = only one side exists
                push @diff, _deep_noexist( $path."{$_}", $old->{$_}, $new->{$_}, $both{$_} );
                $maxdiff--;
                last if $maxdiff <= 0;
            } else {
                my $off = deep_diff( $old->{$_}, $new->{$_}, $maxdiff, $known, $path."{$_}" );
                if ($off) {
                    push @diff, @$off;
                    $maxdiff -= @$off/3;
                };
                last if $maxdiff <= 0;
            };
        };
        return @diff ? \@diff : ();
    };

    # finally - totally different - just output them
    return _deep_not($path, $old, $new);
};

sub _deep_not {
    my ($path, $old, $new) = @_;
    return [
        "At $path: ",
        "     Got: ".to_scalar( $old, 2 ),
        "Expected: ".to_scalar( $new, 2 ),
    ];
};

# $sign < 0 = $old exists, $sign > 0 $new exists
# $sign == 0 and see above
sub _deep_noexist {
    my ($path, $old, $new, $sign) = @_;
    # return array, not arrayref, as this is getting pushed
    return (
        "At $path: ",
        "     Got: ".($sign < 0 ? to_scalar( $old, 2 ) : "Does not exist"),
        "Expected: ".($sign > 0 ? to_scalar( $new, 2 ) : "Does not exist"),
    );
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<Assert::Refute> suite.

Copyright 2017-2018 Konstantin S. Uvarin. C<< <khedin at cpan.org> >>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
