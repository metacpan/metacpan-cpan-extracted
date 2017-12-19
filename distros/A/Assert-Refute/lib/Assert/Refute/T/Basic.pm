package Assert::Refute::T::Basic;

use 5.006;
use strict;
use warnings;
our $VERSION = 0.0305;

=head1 NAME

Assert::Refute::T::Basic - a set of most common checks for Assert::Refute suite

=head1 DESCRIPTION

This module contains most common test conditions similar to those in
L<Test::More>, like C<is $got, $expected;> or C<like $got, qr/.../;>.

They appear as both exportable functions in this module
and L<Assert::Refute> itself
I<and> as corresponding methods in L<Assert::Refute::Exec>.

=head1 FUNCTIONS

All functions below are prototyped to be used without parentheses and
exported by default. Scalar context is imposed onto arguments, so

    is @foo, @bar;

would actually compare arrays by length.

If a C<contract { ... }> is in action, the results of each assertion
will be recorded there. See L<Assert::Refute::Exec> for more.
If L<Test::More> is in action, a unit testing script is assumed.
If neither is true, an exception is thrown.

In addition, a C<Assert::Refute::Exec-E<gt>function_name> method with
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

build_refute like => sub {
    _like_unlike( $_[0], $_[1], 0 );
}, args => 2, export => 1;

build_refute unlike => sub {
    _like_unlike( $_[0], $_[1], 1 );
}, args => 2, export => 1;

sub _like_unlike {
    my ($str, $reg, $reverse) = @_;

    $reg = qr#^(?:$reg)$# unless ref $reg eq 'Regexp';
        # retain compatibility with Test::More
    return 'unexpected undef' if !defined $str;
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

See L<Assert::Refute::Exec/signature> for exact signature format.

=cut

build_refute contract_is => sub {
    my ($c, $sig) = @_;

    my $got = $c->signature;
    return $got ne $sig && <<"EOF".$c->as_tap;
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
        is_deeply fast_impl( $arg ), $expected, "fast_impl ok for";
    };

Unlike the L<Test::More> counterpart, prints all found discrepancies,
although in a weird format.
Better difference formatting wanted.

=cut

push @EXPORT_OK, qw(deep_diff);

build_refute is_deeply => sub {
    my $diff = deep_diff( shift, shift );
    return unless $diff;
    return "Structures differ (got != expected):\n$diff";
}, export => 1, args => 2;

=head2 deep_diff( $old, $new )

Not exported by default.
Compares 2 scalars recursively, outputs nothing if they are identical,
or a (somewhat strange) in-depth summary if they differ.

=cut

sub deep_diff {
    my ($old, $new, $known, $path) = @_;

    $known ||= {};
    $path ||= '&';

    # TODO combine conditions, too much branching
    # diff refs => isn't right away
    if (ref $old ne ref $new or (defined $old xor defined $new)) {
        return join "!=", to_scalar($old), to_scalar($new);
    };

    # not deep - return right away
    return '' unless defined $old;
    if (!ref $old) {
        return $old ne $new && join "!=", to_scalar($old), to_scalar($new),
    };

    # recursion
    # check topology first to avoid looping
    # new is likely to be simpler (it is the "expected" one)
    # FIXME BUG here - if new is tree, and old is DAG, this code won't catch it
    if (my $new_path = $known->{refaddr $new}) {
        my $old_path = $known->{-refaddr($old)};
        return to_scalar($old)."!=$new_path" unless $old_path;
        return $old_path ne $new_path && "$old_path!=$new_path";
    };
    $known->{-refaddr($old)} = $path;
    $known->{refaddr $new} = $path;

    if (UNIVERSAL::isa( $old , 'ARRAY') ) {
        my @diff;
        for (my $i = 0; $i < @$old || $i < @$new; $i++ ) {
            my $off = deep_diff( $old->[$i], $new->[$i], $known, $path."[$i]" );
            push @diff, "$i:$off" if $off;
        };
        return @diff ? _array2str( \@diff, ref $old ) : '';
    };
    if (UNIVERSAL::isa( $old, 'HASH') ) {
        my ($both_k, $old_k, $new_k) = _both_keys( $old, $new );
        my %diff;
        $diff{$_} = to_scalar( $old->{$_} )."!=(none)" for @$old_k;
        $diff{$_} = "(none)!=".to_scalar( $new->{$_} ) for @$new_k;
        foreach (@$both_k) {
            my $off = deep_diff( $old->{$_}, $new->{$_}, $known, $path."{$_}" );
            $diff{$_} = $off if $off;
        };
        return %diff ? _hash2str( \%diff, ref $old ) : '';
    };

    # finally - don't know what to do, compare refs
    $old = to_scalar($old);
    $new = to_scalar($new);
    return $old ne $new && join "!=", $old, $new;
};

sub _hash2str {
    my ($hash, $type) = @_;
    $type = '' if $type eq 'HASH';
    return $type.'{'
            . join(", ", map { to_scalar($_, 0).":$hash->{$_}" } sort keys %$hash)
        ."}";
};

sub _array2str {
    my ($array, $type) = @_;
    $type = '' if $type eq 'ARRAY';
    return "$type\[".join(", ", @$array)."]";
};

# in: hash + hash
# out: common keys +
sub _both_keys {
    my ($old, $new) = @_;
    # TODO write shorter
    my %uniq;
    $uniq{$_}++ for keys %$new;
    $uniq{$_}-- for keys %$old;
    my (@o_k, @n_k, @b_k);
    foreach (sort keys %uniq) {
        if (!$uniq{$_}) {
            push @b_k, $_;
        }
        elsif ( $uniq{$_} < 0 ) {
            push @o_k, $_;
        }
        else {
            push @n_k, $_;
        };
    };
    return (\@b_k, \@o_k, \@n_k);
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<Assert::Refute> suite.

Copyright 2017 Konstantin S. Uvarin. C<< <khedin at gmail.com> >>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
1;
