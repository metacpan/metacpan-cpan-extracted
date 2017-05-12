package Data::PatternCompare;

use strict;
use warnings;

use POSIX;
use Scalar::Util qw(looks_like_number refaddr blessed);
use Scalar::Util::Numeric qw(isfloat);

our $VERSION = '0.04';

sub EMPTY_KEY() { "empty \x{c0}\x{de}" }

our @EXPORT_OK = qw(any empty);
our $any   = Data::PatternCompare::Any->new;
our @empty = (EMPTY_KEY, Data::PatternCompare::Empty->new);

sub _any() {
    $any
}

sub _empty() {
    @empty
}

sub import_to {
    my ($caller, @export) = @_;

    no strict 'refs';
    no warnings 'redefine';

    for my $sub (@export) {
        my $dst = $caller .'::'. $sub;
        my $src = __PACKAGE__ .'::_'. $sub;

        *$dst = *$src;
    }
}

sub import {
    my $class  = shift;
    my $caller = caller;
    my @export;
    my %is_export_ok = map { $_ => 1 } @EXPORT_OK;

    for my $sub ( @_ ) {
        push @export, $sub if $is_export_ok{$sub};
    }

    import_to($caller, @export);
}

sub new {
    my $class  = shift;
    my %params = @_;

    @params{qw(_dup_addr _dup_addra _dup_addrb)} = ({}, {}, {});
    $params{'epsilon'} ||= POSIX::DBL_EPSILON;

    return bless(\%params, $class);
}

sub _is_any {
    my $val   = shift;
    my $class = blessed($val);

    if ($class && $class eq 'Data::PatternCompare::Any') {
        return $class;
    }

    return 0;
}

sub _is_empty {
    my $val = shift;

    if (ref $val eq 'ARRAY') {
        return 0 unless defined $val->[1];

        my $blessed = blessed($val->[1]) || '';
        return (
            defined $val->[0] && $val->[0] eq EMPTY_KEY
            && $blessed eq 'Data::PatternCompare::Empty'
        );
    } else {
        return 0 unless defined $val->{+EMPTY_KEY};

        my $blessed = blessed($val->{+EMPTY_KEY}) || '';
        return $blessed eq 'Data::PatternCompare::Empty';
    }
}

sub _match_ARRAY {
    my ($self, $got, $expected) = @_;

    if (_is_empty($expected)) {
        return scalar(@$got) == 0;
    }

    for (my $i = 0; $i < scalar(@$expected); ++$i) {
        if (_is_any($expected->[$i]) && !exists($got->[$i])) {
            return 0;
        }
        return 0 unless $self->_pattern_match($got->[$i], $expected->[$i]);
    }

    return 1;
}

sub _match_HASH {
    my ($self, $got, $expected) = @_;

    if (_is_empty($expected)) {
        return scalar(keys %$got) == 0;
    }

    for my $key ( keys %$expected ) {
        if (_is_any($expected->{$key}) && !exists($got->{$key})) {
            return 0;
        }
        return 0 unless $self->_pattern_match($got->{$key}, $expected->{$key});
    }

    return 1;
}

sub _pattern_match {
    my ($self, $got, $expected) = @_;

    my $ref = ref($expected);
    unless ($ref) {
        # simple type
        unless (defined $expected && defined $got) {
            unless (defined $expected || defined $got) {
                return 1;
            }
            return 0;
        }

        if (looks_like_number($expected)) {
            return 0 unless looks_like_number($got);

            if (isfloat($expected) || isfloat($got)) {
                return abs($expected - $got) < $self->{'epsilon'};
            }
            return $expected == $got;
        }

        return $expected eq $got;
    }

    my $addr   = refaddr($expected);
    my $is_dup = $self->{'_dup_addr'};
    if (exists $is_dup->{$addr}) {
        die "Cycle in pattern: $expected";
    }
    $is_dup->{$addr} = 1;

    my $class  = blessed($expected);
    if ($class) {
        return 1 if $class eq 'Data::PatternCompare::Any';

        return (
            $class eq blessed($got) &&
            $addr == refaddr($got)
        );
    }

    my $code = $self->can("_match_$ref");
    die "Don't know how to match $ref type" unless $code;

    return 0 unless ref($got) eq $ref;

    return $self->$code($got, $expected);
}

sub pattern_match {
    my $self = shift;

    my $res;
    eval {
        $res = $self->_pattern_match(@_);
    };
    $self->{'_dup_addr'} = {};
    die $@ if $@;

    return $res;
}

sub _compare_ARRAY {
    my ($self, $pa, $pb) = @_;

    my @tmp = map { _is_empty($_) } ($pa, $pb);
    if ($tmp[0] + $tmp[1]) {
        return $tmp[1] - $tmp[0];
    }

    my $sizea = scalar(@$pa);
    my $sizeb = scalar(@$pb);

    unless ($sizea eq $sizeb) {
        return $sizea > $sizeb ? -1 : 1;
    }

    for (my $i = 0; $i < $sizea; ++$i) {
        my $res = $self->_compare_pattern($pa->[$i], $pb->[$i]);

        return $res if $res;
    }

    return 0;
}

sub _compare_HASH {
    my ($self, $pa, $pb) = @_;

    my @tmp = map { _is_empty($_) } ($pa, $pb);
    if ($tmp[0] + $tmp[1]) {
        return $tmp[1] - $tmp[0];
    }

    my $sizea = scalar keys(%$pa);
    my $sizeb = scalar keys(%$pb);

    unless ($sizea eq $sizeb) {
        return $sizea > $sizeb ? -1 : 1;
    }

    for my $key ( keys %$pa ) {
        next unless exists $pb->{$key};

        my $res = $self->_compare_pattern($pa->{$key}, $pb->{$key});

        return $res if $res;
    }

    return 0;
}

sub _compare_pattern {
    my ($self, $pa, $pb) = @_;

    my $refa = ref($pa);
    my $refb = ref($pb);
    my @tmp  = grep { $_ } ($refa, $refb);
    my $cnt  = scalar(@tmp);

    # simple type - equal
    return 0 unless $cnt;

    # 1 ref
    if ($cnt == 1) {
        # any ref (including any) is wider than simple type
        return $refb ? -1 : 1;
    }

    my $addra  = refaddr($pa);
    my $addrb  = refaddr($pb);
    my $classa = blessed($pa);
    my $classb = blessed($pb);

    my $is_dupa = $self->{'_dup_addra'};
    my $is_dupb = $self->{'_dup_addrb'};
    if (exists $is_dupa->{$addra} || exists $is_dupb->{$addrb}) {
        die "Cycle in pattern";
    }
    $is_dupa->{$addra} = 1;
    $is_dupb->{$addrb} = 1;

    @tmp = grep { $_ && $_ eq 'Data::PatternCompare::Any' } ($classa, $classb);
    $cnt = scalar @tmp;

    # 1 "any"
    if ($cnt == 1) {
        return $classb eq 'Data::PatternCompare::Any' ? -1 : 1;
    }

    # both are "any"
    return 0 if $cnt == 2;

    # different types, no reason to go deeper
    return 0 unless $refa eq $refb;

    my $code = __PACKAGE__->can("_compare_$refa");
    die "Don't know how to compare $refa type" unless $code;

    return $self->$code($pa, $pb);
}

sub compare_pattern {
    my $self = shift;

    my $res;
    eval {
        $res = $self->_compare_pattern(@_);
    };
    $self->{'_dup_addra'} = {};
    $self->{'_dup_addrb'} = {};

    die $@ if $@;

    return $res;
}

sub _eq_ARRAY {
    my ($self, $got, $expected) = @_;

    return 0 unless scalar(@$got) == scalar(@$expected);

    for (my $i = 0; $i < scalar(@$expected); ++$i) {
        return 0 unless $self->_eq_pattern($got->[$i], $expected->[$i]);
    }

    return 1;
}

sub _eq_HASH {
    my ($self, $got, $expected) = @_;

    return 0 unless scalar(keys %$got) == scalar(keys %$expected);

    for my $key ( keys %$expected ) {
        return 0 unless $self->_eq_pattern($got->{$key}, $expected->{$key});
    }

    return 1;
}

sub _eq_pattern {
    my ($self, $got, $expected) = @_;

    my $ref = ref($expected);
    unless ($ref) {
        # simple type
        unless (defined $expected && defined $got) {
            unless (defined $expected || defined $got) {
                return 1;
            }
            return 0;
        }

        if (looks_like_number($expected)) {
            return 0 unless looks_like_number($got);

            if (isfloat($expected) || isfloat($got)) {
                return abs($expected - $got) < $self->{'epsilon'};
            }
            return $expected == $got;
        }

        return $expected eq $got;
    }

    my $addr   = refaddr($expected);
    my $is_dup = $self->{'_dup_addr'};
    if (exists $is_dup->{$addr}) {
        die "Cycle in pattern: $expected";
    }
    $is_dup->{$addr} = 1;

    my $class  = blessed($expected);
    if ($class) {
        my $got_blessed = blessed($got) || '';
        my $got_addr = refaddr($got) || 0;
        return (
            $class eq $got_blessed &&
            $addr == $got_addr
        );
    }

    my $code = $self->can("_eq_$ref");
    die "Don't know how to eq $ref type" unless $code;

    return 0 unless ref($got) eq $ref;

    return $self->$code($got, $expected);
}

sub eq_pattern {
    my $self = shift;

    my $res;
    eval {
        $res = $self->_eq_pattern(@_);
    };
    $self->{'_dup_addr'} = {};

    die $@ if $@;

    return $res;
}

package Data::PatternCompare::Any;

sub new { bless({}); }

package Data::PatternCompare::Empty;

sub new { bless({}); }

42;

__END__

=head1 NAME

Data::PatternCompare - Module to match data to pattern.

=head1 SYNOPSIS

Create a comparator object.

    use Data::PatternCompare;

    my $cmp = Data::PatternCompare->new;

You can match Perl data structure to pattern like so:

    my $data = [1, 2, { name => "cono" }];
    my $pattern = [1, 2, { name => $Data::PatternCompare::any }];

    if ($cmp->pattern_match($data, $pattern)) {
        print "Matched";
    }

If you have array of patterns, you can sort them from stricter to wider like
so:

    my @array_of_patterns = ( ... );

    my @sorted = sort { $cmp->compare_pattern($a, $b) } @array_of_patterns;

=head1 DESCRIPTION

This module provides to you functionality of matching Perl data structures to
patterns. Could be used for some kind of multi method dispatching.

This module is far from high performance.

=head1 FUNCTIONS

=head2 import_to($pkg, @export_list)

This function imports functions C<@export_list> in defined package C<$pkg>.
Available functions: C<any> and C<empty>.

=head1 METHODS

=head2 import()

By default module does not export anything. You can export 2 functions: C<any>
and C<empty>.

e.g.
    use Data::PatternCompare qw(any empty);

=head2 new( epsilon => 0.01 )

It is a constructor. Currently takes only one parameter: C<epsilon> for float
comparison. Floats are equal if true the following statement: abs(float1 -
float2) E<lt> epsilon. Returns instance of the Data::PatternCompare class.

=head2 pattern_match($data, $pattern) : Boolean

This method takes 2 arguments, Perl data structure and pattern. Returns true if
data matches to pattern.

Pattern can contain special objects of class C<Data::PatternCompare::Any>, you
can refer to instance of this class simply using C<$Data::PatternCompare::any>
variable.

C<$Data::PatterCompare::any> can be used to match any value.

So call C<pattern_match( DATA, $Data::PatternCompare::any)> will match any
data: Integers, Strings, Objects, ...

Because of nature of matching method you can't match empty arrays (zero sized
array patterns can match any amount of data). C<@Data::PatternCompare::empty>
array was defined. It's also exported via function C<empty>. It matches only
zero sized arrays.

=head2 compare_pattern($pattern_a, $pattern_b) : Integer

This method takes 2 pattern as an arguments and return Integer value like any
other comparator does.

    return_value < 0 - means that $pattern_a more strict than $pattern_b
                   0 - pattern are equal to each others
    0 < return_value - $pattern_a wider than $pattern_b

=head3 Simple type

What stricter/wider means?

If we take 2 following patterns:

=over 4

=item 1. 42

=item 2. C<$Data::PatternCompare::any>

=back

The second one is more wide. If we represent patterns as a set of values, that
means that second pattern contain first one. In another words: 42 is a member
of Set C<any>.

=head3 Array

Before matching values inside of the array, length of array is taking into
consideration. Arrays with bigger length are more strict.

This rule applies because we consider: C<pattern_match([42, 1], [42])> as true
value. Because of this C<@Data::PatternCompare::empty> array was created.

You can define empty array pattern like so: C<[ @Data::PatternCompare::empty] >.

Empty (not zero sized) arrays will take precedense over any other arrays.

=head3 Hash

The same rules as for the Array. The bigger size of the hash treats as
stricter.

e.g.:

    $cmp->compare_pattern({ qw|a b c d| }, { qw|a b| }) # -1

To define empty hash pattern you can use following code:

    $pattern = { @Data::PatternCompare::empty };

Be careful with the following example:

    $cmp->compare_pattern(
        { a => $Data::PatternCompare::any, b => 42 },
        { a => 42, b => $Data::PatternCompare::any }
    );

Result of the code above is unpredicted. It depends on in what order keys will
be returned by the C<keys()> function.

=head2 eq_pattern($pattern_a, $pattern_b) : Boolean

This method takes 2 arguments. Returns true if 2 patterns are strictly equal to
each others.

The main differece to C<compare_pattern() == 0> is that 42 != 43.
C<$Data::PatterCompare::any> and C<@Data::PatternCompare::empty> matched only
to the same object.

=head1 AUTHOR

cono E<lt>cono@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014 - cono

=head1 LICENSE

Artistic v2.0

=head1 SEE ALSO

=cut
