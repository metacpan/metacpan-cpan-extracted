package App::RoboBot::Plugin::Types::List;
$App::RoboBot::Plugin::Types::List::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use List::Util qw( shuffle );
use Scalar::Util qw( blessed );

extends 'App::RoboBot::Plugin';

=head1 types.list

Provides functions which generate and operate on lists.

=cut

has '+name' => (
    default => 'Types::List',
);

has '+description' => (
    default => 'Provides functions which generate and operate on lists.',
);

=head2 nth

=head3 Description

Returns the ``n``th entry from the given list. Lists are considered
``1``-indexed and negative numbers count backwards from the end of the list.
If ``n`` is larger than the size of the list, no value is returned.

=head3 Usage

<n> <list>

=head3 Examples

    :emphasize-lines: 2

    (nth 3 "James" "Alice" "Frank" "Janet")
    "Frank"

=head2 first

=head3 Description

Returns the first element of the given list, discarding all remaining elements.

=head3 Usage

<list>

=head3 Examples

    :emphasize-lines: 2

    (first "James" "Alice" "Frank")
    "James"

=head2 shuffle

=head3 Description

Returns the full list of elements in a randomized order.

=head3 Usage

<list>

=head2 sort

=head3 Description

Returns the full list of elements, sorted.

=head3 Usage

<list>

=head2 seq

=head3 Description

Generates and returns a list of numeric elements, beginning with the number
``first`` and ending with ``last``. By default, numbers increment by ``1``, but
a custom increment may be supplied via ``step``.

=head3 Usage

<first> <last> <step>

=head3 Examples

    :emphasize-lines: 2,5

    (seq 1 10)
    (1 2 3 4 5 6 7 8 9 10)

    (seq 2 20 2)
    (2 4 6 8 10 12 14 16 18 20)

=head2 any

=head3 Description

Returns ``1`` if ``string`` matches any element of ``list``, ``0`` otherwise.

=head3 Usage

<string> <list>

=head2 count

=head3 Description

Returns the number of elements in the provided list.

=head3 Usage

<list>

=head2 filter

=head3 Description

Returns a list of elements from the input list which, when aliased to ``%`` and
applied to ``function``, result in a true evaluation.

=head3 Usage

<function> <list>

=head3 Examples

    :emphasize-lines: 2

    (filter (match "a" %) "Jon" "Jane" "Frank" "Zoe")
    ("Jane" "Frank")

=head2 reduce

=head3 Description

Returns the result of repeatedly applying ``function`` to the ``accumulator``,
aliased as ``$``, and each element of the input list, aliased as ``%``.

Reductions may be performed on any type, but you should ensure that you provide
an initial value for the accumulator that is appropriate to the function you
will be applying. In the example provided, a simple factorial was performed by
initializing the accumulator to ``1`` and then applying a continuous sequence
of integers beginning at 1 to the product function. It would have made no sense
to initialize the accumulator in that example with a string value.

=head3 Usage

<function> <accumulator> <list>

=head3 Examples

    :emphasize-lines: 2

    (reduce (* $ %) 1 (seq 1 10))
    3628800

=head2 map

=head3 Description

Applies ``function`` to every element of the input list and returns a list of
the results, preserving order. Each element of the input list is aliased to
``%`` within the function being applied.

=head3 Usage

<function> <list>

=head3 Examples

    :emphasize-lines: 2

    (map (* 2 %) (seq 1 5))
    (2 4 6 8 10)

=cut

has '+commands' => (
    default => sub {{
        'nth' => { method      => 'list_nth',
                   description => 'Returns the nth entry of a list, discarding all others. One-indexed. Negative numbers count backwards from the end of the list.',
                   usage       => '<n> <... list ...>',
                   example     => '3 "James" "Alice" "Frank" "Janet"',
                   result      => 'Frank' },

        'first' => { method      => 'list_first',
                     description => 'Returns the first entry of a list, discarding all others.',
                     usage       => '<... list ...>',
                     example     => '"James" "Alice" "Frank" "Janet"',
                     result      => 'James' },

        'shuffle' => { method      => 'list_shuffle',
                       description => 'Returns the list elements in a randomized order.',
                       usage       => '<... list ...>',
                       example     => '"James" "Alice" "Frank" "Janet"',
                       result      => '"Alice" "Janet" "James" "Frank"' },

        'sort' => { method      => 'list_sort',
                    description => 'Returns the list elements in sorted order.',
                    usage       => '<... list ...>',
                    example     => '"James" "Alice" "Frank" "Janet"',
                    result      => '"Alice" "Frank" "James" "Janet"' },

        'seq' => { method      => 'list_seq',
                   description => 'Returns a sequence of numbers.',
                   usage       => '<first> <last> [<step>]',
                   example     => '1 10 3',
                   result      => '1 4 7 10' },

        'any' => { method      => 'list_any',
                   description => 'Returns true if any list element is matched by the first function parameter.',
                   usage       => '<string> < ... list to search ... >',
                   example     => 'foo bar baz foo xyzzy',
                   result      => '1', },

        'count' => { method      => 'list_count',
                     description => 'Returns the number of items in the provided list. If no arguments are provided, the return value will be 0, same as for an empty list.',
                     usage       => '[<list>]' },

        'filter' => { method      => 'list_filter',
                      preprocess_args => 0,
                      description => 'Returns a list of elements from the input list which, when aliased to % and applied to <function>, result in a true evaluation.',
                      usage       => '<function> <list>',
                      example     => '(match "a" %) "Jon" "Jane" "Frank" "Zoe"',
                      result      => '"Jane" "Frank"' },

        'reduce' => { method      => 'list_reduce',
                      preprocess_args => 0,
                      description => 'Returns the result of repeatedly applying <function> to the <accumulator>, aliased as $, and each element of the input list, aliased as %.',
                      usage       => '<function> <accumulator> <list>',
                      example     => '(* $ %) 1 (seq 1 10)',
                      result      => '3628800' },

        'map' => { method      => 'list_map',
                   preprocess_args => 0,
                   description => 'Applies <function> to every element of the input list and returns a list of the results, preserving order. Each element of the input list is aliased to % within the function being applied.',
                   usage       => '<function> <list>',
                   example     => '(upper %) "Jon" "Jane" "frank"',
                   result      => '"JON" "JANE" "FRANK"' },
    }},
);

sub list_filter {
    my ($self, $message, $command, $rpl, $filter_func, @list) = @_;

    my @ret_list = ();
    my $p_masked = exists $rpl->{'%'} ? $rpl->{'%'} : undef;

    foreach my $el (@list) {
        my @vals = $el->evaluate($message, $rpl);

        foreach my $val (@vals) {
            $rpl->{'%'} = $val;

            push(@ret_list, $val) if $filter_func->evaluate($message, $rpl);
        }
    }

    if (defined $p_masked) {
        $rpl->{'%'} = $p_masked;
    } else {
        delete $rpl->{'%'};
    }

    return @ret_list;
}

sub list_reduce {
    my ($self, $message, $command, $rpl, $reduce_func, $accumulator, @list) = @_;

    my $p_masked = exists $rpl->{'%'} ? $rpl->{'%'} : undef;
    my $d_masked = exists $rpl->{'$'} ? $rpl->{'$'} : undef;

    $accumulator = $accumulator->evaluate($message, $rpl);

    foreach my $el (@list) {
        my @vals = $el->evaluate($message, $rpl);

        foreach my $val (@vals) {
            $rpl->{'$'} = $accumulator;
            $rpl->{'%'} = $val;

            $accumulator = $reduce_func->evaluate($message, $rpl);
        }
    }

    if (defined $p_masked) {
        $rpl->{'%'} = $p_masked;
    } else {
        delete $rpl->{'%'};
    }

    if (defined $d_masked) {
        $rpl->{'$'} = $d_masked;
    } else {
        delete $rpl->{'$'};
    }

    return $accumulator;
}

sub list_map {
    my ($self, $message, $command, $rpl, $map_func, @list) = @_;

    my @ret_list = ();
    my $p_masked = exists $rpl->{'%'} ? $rpl->{'%'} : undef;

    foreach my $el (@list) {
        my @vals = $el->evaluate($message, $rpl);

        foreach my $val (@vals) {
            $rpl->{'%'} = $val;

            push(@ret_list, $map_func->evaluate($message, $rpl));
        }
    }

    if (defined $p_masked) {
        $rpl->{'%'} = $p_masked;
    } else {
        delete $rpl->{'%'};
    }

    return @ret_list;
}

sub list_count {
    my ($self, $message, $command, $rpl, @list) = @_;

    return 0 unless @list;
    return scalar(@list) || 0;
}

sub list_any {
    my ($self, $message, $command, $rpl, $str, @list) = @_;

    return unless defined $str && @list && scalar(@list) > 0;

    foreach my $el (@list) {
        return 1 if $str eq $el;
    }
    return;
}

sub list_nth {
    my ($self, $message, $command, $rpl, $nth, @args) = @_;

    if (defined $nth && $nth =~ m{^-?\d+$}o) {
        if ($nth < 0) {
            if (($nth * -1) > scalar(@args)) {
                $message->response->raise(sprintf('List out-of-bounds error. Attempted to access entry %d of %d member list.', $nth, scalar(@args)));
            } else {
                return $args[$nth];
            }
        } elsif ($nth > 0) {
            if ($nth > scalar(@args)) {
                $message->response->raise(sprintf('List out-of-bounds error. Attempted to access entry %d of %d member list.', $nth, scalar(@args)));
            } else {
                return $args[$nth - 1];
            }
        }
    } else {
        $message->response->raise('Position nth must be provided as an integer.');
    }

    return;
}

sub list_first {
    my ($self, $message, $command, $rpl, @args) = @_;

    return $self->list_nth($message, $command, $rpl, 1, @args);
}

sub list_shuffle {
    my ($self, $message, $command, $rpl, @args) = @_;

    return shuffle @args;
}

sub list_sort {
    my ($self, $message, $command, $rpl, @args) = @_;

    return sort @args;
}

sub list_seq {
    my ($self, $message, $command, $rpl, $first, $last, $step) = @_;

    $step //= 1;

    unless (defined $first && defined $last && $first =~ m{^\d+$} && $last =~ m{^\d+$}) {
        $message->response->raise('You must supply a starting number and ending number for the sequence.');
        return;
    }

    unless ($first <= $last) {
        $message->response->raise('Sequence starting number cannot be greater than the ending number.');
        return;
    }

    my @seq;

    do {
        push(@seq, $first);
        $first += $step;
    } while ($first <= $last);

    return @seq;
}

__PACKAGE__->meta->make_immutable;

1;
