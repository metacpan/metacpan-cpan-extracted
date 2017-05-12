package App::RoboBot::Plugin::Core::Control;
$App::RoboBot::Plugin::Core::Control::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use Scalar::Util qw( blessed );

extends 'App::RoboBot::Plugin';

=head1 core.control

Exports a selection of control structure functions and special forms.

Most of these functions and forms operate on the principle of "truthiness"
which may not be self-evident to users of languages that have strict concepts
of ``True`` and ``False`` (and sometimes nil/null/etc.). App::RoboBot follows the
somewhat more expansive concept of truthiness that the Perl language uses, in
which anything that isn't a negative number, the literal number ``0``,
undefined, an empty string, or a string of nothing but a single zero character
is considered to be true. Thus, an empty Map would be true; a String containing
two or more zeroes but nothing else would be true; even the String ``"false"``
would be true.  But a comparison operator that returns the numeric ``0``, or a
string with a single zero character, or a ``nil`` would be false.

=cut

has '+name' => (
    default => 'Core::Control',
);

has '+description' => (
    default => 'Provides a selection of control structure functions.',
);

=head2 if

=head3 Description

Evaluates the given condition, which if truthy leads to the evaluation of the
``<true expression>``. If the condition did not yield a truthy value and a
third operand is present, that is evaluated instead.

Neither of the true or false expressions need to be quoted to prevent their
initial evaluation, as this is a special form. Only one of the expressions will
ever be evaluated on any invocation of the ``if`` form.

=head3 Usage

<condition> <true expression> [<false expression>]

=head3 Examples

    :emphasize-lines: 2

    (if (< 1 2) "One is less than two." "This will never evaluate.")
    "One is less than two."

=head2 while

=head3 Description

Evaluates the given condition repeatedly, evaluating the expression each time
that the condition is true. Completes only when the condition eventualy returns
a false value (or the internal loop limit is reached).

Note that is the condition has side-effects, they will occur on every single
iteration until the ``while`` itself terminates.

=head3 Usage

<condition> <expression>

=head3 Examples

    (while (< 5 (random 10)) (print "Rolled over 5."))

=head2 cond

=head3 Description

Similar to ``if``, this form evaluates a condition and if it yields a truthy
value, evluates the expression immediately following the condition. Unlike
``if``, this form accepts an arbitrary number of condition-expression pairs.
The first pair whose condition is true will have its expression evaluated and
the ``cond`` form will terminate without any further evaluations.

If none of the conditions from the pairs yields a truthy value, and there are
an odd number of operands provided, the last one will be used as a default
expression to evaluate and its value will be returned by ``cond`` instead.

The return value of the ``cond`` is that of the single expression which was
evaluated.

=head3 Usage

<condition> <expression> [<condition> <expression> ...] [<fallback>]

=head3 Examples

    :emphasize-lines: 4,9,14

    (cond
      (== 1 2) "No way this gets evaluated."
      (> 10 5) "Ten is a bigger number than five.")
    "Ten is a bigger number than five."

    (cond
      (eq "foo" "bar") "Inequal strings. This won't happen."
      (print "Fallback expression being evaluated."))
    "Fallback expression being evaluated."

    (cond
      (!= 1 2) "These are indeed different numbers!"
      (!= 3 4) "We never get this far, because the first condition was true.")
    "These are indeed different numbers!"

=head2 apply

=head3 Description

Repeatedly applies the function to each element of the list, in the order
provided by the list, returning a new list of the results.

=head3 Usage

<function> <list>

=head3 Examples

    :emphasize-lines: 2

    (apply + (seq 1 5))
    (2 3 4 5 6)

=head2 repeat

=head3 Description

Repeats the evaluation of the given list/expression ``count`` times, returning
a list of all the results.

=head3 Usage

<count> <list|expression>

=head3 Examples

    (repeat 3 (upper "foo"))

=cut

has '+commands' => (
    default => sub {{
        'if' => { method          => 'control_if',
                  preprocess_args => 0,
                  description     => 'Conditionally evaluates an expression when the given condition is true. If the condition is not true, and a third argument is provided, then it is evaluated and its result is returned instead.',
                  usage           => '(<boolean condition>) (<expression>) [(<else>)]',
                  example         => '(> 1 5) ("One is somehow larger than five on this system.")',
                  result          => '' },

        'while' => { method          => 'control_while',
                     preprocess_args => 0,
                     description     => 'Repeatedly evaluates the expression for as long as the condition remains true.',
                     usage           => '(<boolean condition>) (<expression>)',
                     example         => '(== (roll 6 2) 2) ("Snake-eyes!")',
                     result          => 'Snake-eyes!' },

        'cond' => { method          => 'control_cond',
                    preprocess_args => 0,
                    description     => 'Accepts pairs of expressions, where the first of each pair is a condition that if true in its evaluation leads to the second expression being evaluated and its value returned. The first condition-expression pair to evaluate will terminate the (cond) function\'s evaluation. If the argument list ends with a single, un-paired fallback expression, that will be evaluated in the event none of the preceding conditions were true.',
                    usage           => '(<condition>) (<expression>) [(<condition>) (<expression>) [...]] [(<fallback>)]',
                    example         => '(> 1 5) (format "%d is somehow greater than %d" 1 5) (eq "foo" "bar") (format "%s somehow matches %s" "foo" "bar") "Nothing is true."',
                    result          => '"Nothing is true."' },

        'apply' => { method          => 'control_apply',
                     preprocess_args => 0,
                     description     => 'Accepts a function name as its first argument and passes all remaining list elements one-by-one as arguments to the supplied expression.',
                     usage           => '<function to apply> <list(s) of elements>',
                     example         => '+ (seq 1 5)',
                     result          => '2 3 4 5 6' },

        'repeat' => { method          => 'control_repeat',
                      preprocess_args => 0,
                      description     => 'Repeats <n> times the evaluation of <list>. Returns a list containing the return values of every evaluation.',
                      usage           => '<n> <list>',
                      example         => '3 (upper "foo")',
                      result          => 'FOO FOO FOO', },
    }},
);

sub control_repeat {
    my ($self, $message, $command, $rpl, $num, $list) = @_;

    if (defined $num && blessed($num) && $num->can('evaluate')) {
        $num = $num->evaluate($message, $rpl);
    }

    unless (defined $num && $num =~ m{^\d+$}) {
        $message->response->raise('First argument must be the number of times to repeat list evaluation.');
        return;
    }

    unless (defined $list && blessed($list) && $list->can('evaluate')) {
        $message->response->raise('Must provide a list or expression to repeatedly evaluate.');
        return;
    }

    # Even this is probably ripe for abuse, but at least it's not unlimited.
    $num = 100 if $num > 100;

    my @ret;

    while ($num--) {
        push(@ret, $list->evaluate($message, $rpl));
    }

    return @ret;
}

sub control_if {
    my ($self, $message, $command, $rpl, $condition, $expr_if, $expr_else) = @_;

    if (defined $condition && blessed($condition) && $condition->can('evaluate')) {
        $condition = $condition->evaluate($message, $rpl);
    }

    unless (defined $expr_if && blessed($expr_if) && $expr_if->can('evaluate')) {
        $message->response->raise('Second argument must be a list or expression to evaluate when condition is truthy.');
        return;
    }

    if ($condition) {
        return $expr_if->evaluate($message, $rpl);
    } elsif (defined $expr_else && blessed($expr_else) && $expr_else->can('evaluate')) {
        return $expr_else->evaluate($message, $rpl);
    }

    return;
}

sub control_while {
    my ($self, $message, $command, $rpl, $condition, $expr_loop) = @_;

    my @res;

    # TODO make the loop-limit configurable
    my $i = 0;

    unless (defined $condition && blessed($condition) && $condition->can('evaluate')) {
        $message->response->raise('First argument must be a list or expression which will evaluate to a truthy/falsey value.');
        return;
    }

    my $ret = $condition->evaluate($message, $rpl);

    while ($i < 100 && $ret) {
        @res = $expr_loop->evaluate($message, $rpl);
        $ret = $condition->evaluate($message, $rpl);
        $i++;
    }

    return @res;
}

sub control_cond {
    my ($self, $message, $command, $rpl, @pairs) = @_;

    unless (@pairs && @pairs >= 2) {
        $message->response->raise('You must supply at least one condition and action.');
        return;
    }

    my $fallback = pop @pairs if scalar(@pairs) % 2 == 1;

    while (my $cond = shift @pairs) {
        my $action = shift @pairs;
        if ($cond->evaluate($message, $rpl)) {
            return $action->evaluate($message, $rpl)
        }
    }

    if (defined $fallback) {
        return $fallback->evaluate($message, $rpl);
    }

    return;
}

sub control_apply {
    my ($self, $message, $command, $rpl, $func, @args) = @_;

    unless (defined $func && blessed($func) =~ m{^App::RoboBot::Type::(Function|Macro)}) {
        $message->response->raise('You must provide a function or macro to apply to your arguments.');
        return;
    }

    unless (@args) {
        $message->response->raise('You cannot apply a function or macro to a non-existent list of arguments.');
        return;
    }

    # it's not an error to have no arguments, but we can at least short-circuit.
    return unless @args > 0;

    my @collect;

    foreach my $arg (@args) {
        my @res = $arg->evaluate($message, $rpl);
        push(@collect, $func->evaluate($message, $rpl, $_)) foreach @res;
    }

    return @collect;
}

__PACKAGE__->meta->make_immutable;

1;
