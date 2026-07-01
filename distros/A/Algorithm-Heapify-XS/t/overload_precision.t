use strict;
use warnings;

use Config;
use Test::More;

use Algorithm::Heapify::XS qw(
    max_heapify
    max_heap_shift
    max_heap_push
    max_heap_adjust_item
    max_heap_adjust_top
    maxstr_heapify
    maxstr_heap_shift
    maxstr_heap_push
    maxstr_heap_adjust_item
    maxstr_heap_adjust_top
    min_heapify
    min_heap_shift
    min_heap_push
    min_heap_adjust_item
    min_heap_adjust_top
    minstr_heapify
    minstr_heap_shift
    minstr_heap_push
    minstr_heap_adjust_item
    minstr_heap_adjust_top
);

{
    package Local::BigNumOnly;

    use overload
        '0+' => sub { ${$_[0]} },
        '""' => sub { ${$_[0]} },
        fallback => 1;

    sub new {
        my ($class, $value) = @_;
        return bless \$value, $class;
    }
}

{
    package Local::BigNumCmp;

    use overload
        '<=>' => sub {
            my ($left, $right, $swap) = @_;
            ($left, $right) = ($right, $left) if $swap;
            return ${$left} <=> ${$right};
        },
        '""' => sub { ${$_[0]} },
        fallback => 1;

    sub new {
        my ($class, $value) = @_;
        return bless \$value, $class;
    }
}

{
    package Local::BigStrCmp;

    use overload
        'cmp' => sub {
            my ($left, $right, $swap) = @_;
            ($left, $right) = ($right, $left) if $swap;
            return ${$left} cmp ${$right};
        },
        '""' => sub { ${$_[0]} },
        fallback => 1;

    sub new {
        my ($class, $value) = @_;
        return bless \$value, $class;
    }
}

my $nv_preserves_64bit_uv =
    ($Config{nvsize} * 8) >= 64
    && (~0 <= 9_007_199_254_740_992);

plan skip_all => 'needs UV values larger than NV can exactly represent'
    if $nv_preserves_64bit_uv;

my $big = ~0;
my @values = ($big - 1, $big, $big - 2, $big - 3, $big - 4);
my @expect_max = ($big, $big - 1, $big - 2, $big - 3, $big - 4);
my @expect_min = reverse @expect_max;

sub drain_max_num {
    my (@heap) = @_;
    my @got;
    push @got, 0 + max_heap_shift(@heap) while @heap;
    return @got;
}

sub drain_min_num {
    my (@heap) = @_;
    my @got;
    push @got, 0 + min_heap_shift(@heap) while @heap;
    return @got;
}

sub drain_max_str {
    my (@heap) = @_;
    my @got;
    push @got, '' . maxstr_heap_shift(@heap) while @heap;
    return @got;
}

sub drain_min_str {
    my (@heap) = @_;
    my @got;
    push @got, '' . minstr_heap_shift(@heap) while @heap;
    return @got;
}

sub find_idx {
    my ($heap, $want) = @_;
    for my $idx (0 .. $#$heap) {
        return $idx if "$heap->[$idx]" eq "$want";
    }
    die "value $want not found in heap";
}

{
    my @heap = map Local::BigNumOnly->new($_), @values;

    max_heapify(@heap);

    is_deeply(
        [ drain_max_num(@heap) ],
        \@expect_max,
        'max heap keeps overloaded large UVs in numeric order',
    );
}

{
    my @heap = map Local::BigNumOnly->new($_), @values;

    min_heapify(@heap);

    is_deeply(
        [ drain_min_num(@heap) ],
        \@expect_min,
        'min heap keeps overloaded large UVs in numeric order',
    );
}

{
    my @heap = map Local::BigNumOnly->new($_), @values[2 .. 4];

    max_heapify(@heap);
    is(0 + max_heap_push(@heap, Local::BigNumOnly->new($big)), $big,
        'max_heap_push returns new large overloaded top');
    is_deeply(
        [ drain_max_num(@heap) ],
        [ $big, $big - 2, $big - 3, $big - 4 ],
        'max_heap_push preserves full numeric heap order after insert',
    );
}

{
    my @heap = map Local::BigNumOnly->new($_), @values[0 .. 2];

    min_heapify(@heap);
    is(0 + min_heap_push(@heap, Local::BigNumOnly->new($big - 4)), $big - 4,
        'min_heap_push returns new small overloaded top');
    is_deeply(
        [ drain_min_num(@heap) ],
        [ $big - 4, $big - 2, $big - 1, $big ],
        'min_heap_push preserves full numeric heap order after insert',
    );
}

{
    my @heap = map Local::BigNumOnly->new($_), @values;
    my $idx;

    max_heapify(@heap);
    $idx = find_idx(\@heap, $big - 3);
    ${$heap[$idx]} = $big;
    is(0 + max_heap_adjust_item(@heap, $idx), $big,
        'max_heap_adjust_item promotes mutated overloaded item');

    ${$heap[0]} = $big - 4;
    is(0 + max_heap_adjust_top(@heap), $big,
        'max_heap_adjust_top restores max heap after top mutation');
    is_deeply(
        [ drain_max_num(@heap) ],
        [ $big, $big - 1, $big - 2, $big - 4, $big - 4 ],
        'max heap remains ordered after numeric adjust_item and adjust_top',
    );
}

{
    my @heap = map Local::BigNumOnly->new($_), @values;
    my $idx;

    min_heapify(@heap);
    $idx = find_idx(\@heap, $big - 1);
    ${$heap[$idx]} = $big - 4;
    is(0 + min_heap_adjust_item(@heap, $idx), $big - 4,
        'min_heap_adjust_item promotes mutated overloaded item');

    ${$heap[0]} = $big;
    is(0 + min_heap_adjust_top(@heap), $big - 4,
        'min_heap_adjust_top restores min heap after top mutation');
    is_deeply(
        [ drain_min_num(@heap) ],
        [ $big - 4, $big - 3, $big - 2, $big, $big ],
        'min heap remains ordered after numeric adjust_item and adjust_top',
    );
}

{
    my @heap = map Local::BigNumCmp->new($_), @values;

    max_heapify(@heap);

    is_deeply(
        [ drain_max_num(@heap) ],
        \@expect_max,
        'explicit <=> overload keeps numeric heap order',
    );
}

{
    my @heap = map Local::BigNumCmp->new($_), @values;

    min_heapify(@heap);

    is_deeply(
        [ drain_min_num(@heap) ],
        \@expect_min,
        'explicit <=> overload keeps min numeric heap order',
    );
}

{
    my @strings = (
        '18446744073709551611',
        '18446744073709551612',
        '18446744073709551613',
        '18446744073709551614',
        '18446744073709551615',
    );
    my @expect_str_max = reverse @strings;
    my @expect_str_min = @strings;
    my @heap = map Local::BigStrCmp->new($_), @strings;

    maxstr_heapify(@heap);

    is_deeply(
        [ drain_max_str(@heap) ],
        \@expect_str_max,
        'explicit cmp overload keeps max string heap order',
    );

    @heap = map Local::BigStrCmp->new($_), @strings;
    minstr_heapify(@heap);

    is_deeply(
        [ drain_min_str(@heap) ],
        \@expect_str_min,
        'explicit cmp overload keeps min string heap order',
    );
}

{
    my @strings = (
        '18446744073709551613',
        '18446744073709551614',
        '18446744073709551615',
    );
    my @heap = map Local::BigStrCmp->new($_), @strings;

    maxstr_heapify(@heap);
    is('' . maxstr_heap_push(@heap, Local::BigStrCmp->new('18446744073709551612')),
        '18446744073709551615',
        'maxstr_heap_push keeps existing lexicographic top');
    is_deeply(
        [ drain_max_str(@heap) ],
        [
            '18446744073709551615',
            '18446744073709551614',
            '18446744073709551613',
            '18446744073709551612',
        ],
        'maxstr_heap_push preserves full string heap order after insert',
    );

    @heap = map Local::BigStrCmp->new($_), @strings;
    minstr_heapify(@heap);
    is('' . minstr_heap_push(@heap, Local::BigStrCmp->new('18446744073709551612')),
        '18446744073709551612',
        'minstr_heap_push returns new lexicographic top');
    is_deeply(
        [ drain_min_str(@heap) ],
        [
            '18446744073709551612',
            '18446744073709551613',
            '18446744073709551614',
            '18446744073709551615',
        ],
        'minstr_heap_push preserves full string heap order after insert',
    );
}

{
    my @heap = map Local::BigStrCmp->new($_),
        qw(18446744073709551611 18446744073709551612 18446744073709551613
           18446744073709551614 18446744073709551615);
    my $idx;

    maxstr_heapify(@heap);
    $idx = find_idx(\@heap, '18446744073709551612');
    ${$heap[$idx]} = '18446744073709551616';
    is('' . maxstr_heap_adjust_item(@heap, $idx), '18446744073709551616',
        'maxstr_heap_adjust_item promotes mutated overloaded item');
    ${$heap[0]} = '18446744073709551610';
    is('' . maxstr_heap_adjust_top(@heap), '18446744073709551615',
        'maxstr_heap_adjust_top restores max string heap after top mutation');
    is_deeply(
        [ drain_max_str(@heap) ],
        [
            '18446744073709551615',
            '18446744073709551614',
            '18446744073709551613',
            '18446744073709551611',
            '18446744073709551610',
        ],
        'max string heap remains ordered after adjust_item and adjust_top',
    );

    @heap = map Local::BigStrCmp->new($_),
        qw(18446744073709551611 18446744073709551612 18446744073709551613
           18446744073709551614 18446744073709551615);
    minstr_heapify(@heap);
    $idx = find_idx(\@heap, '18446744073709551614');
    ${$heap[$idx]} = '18446744073709551610';
    is('' . minstr_heap_adjust_item(@heap, $idx), '18446744073709551610',
        'minstr_heap_adjust_item promotes mutated overloaded item');
    ${$heap[0]} = '18446744073709551616';
    is('' . minstr_heap_adjust_top(@heap), '18446744073709551611',
        'minstr_heap_adjust_top restores min string heap after top mutation');
    is_deeply(
        [ drain_min_str(@heap) ],
        [
            '18446744073709551611',
            '18446744073709551612',
            '18446744073709551613',
            '18446744073709551615',
            '18446744073709551616',
        ],
        'min string heap remains ordered after adjust_item and adjust_top',
    );
}

done_testing;
