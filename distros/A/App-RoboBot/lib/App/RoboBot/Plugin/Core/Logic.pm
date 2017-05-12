package App::RoboBot::Plugin::Core::Logic;
$App::RoboBot::Plugin::Core::Logic::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use Scalar::Util qw( blessed );

extends 'App::RoboBot::Plugin';

=head1 core.logic

Exports logic, bitwise, and boolean functions.

=cut

has '+name' => (
    default => 'Core::Logic',
);

has '+description' => (
    default => 'Provides logic, bitwise, and boolean functions.',
);

=head2 and

=head3 Description

Returns a true value only if all expressions are also true. This function will
short-circuit as soon as a falsey expression is encountered, and will not
evaluate any of the subsequent expressions. This includes any potential side
effects of those expressions.

=head3 Usage

<expression 1> [... <expression N>]

=head3 Examples

    (and (> 20 1) (> 40 20))

=head2 or

=head3 Description

Returns a true value if at least one expression is true. This function will
short-circuit as soon as a truthy expression is encountered, and will not
evaluate any of the subsequent expressions. This includes any potential side
effects of those expressions.

=head3 Usage

<expression 1> [... <expression N>]

=head3 Examples

    (or (> 20 1) (> 1 20))

=head2 not

=head3 Description

Returns the logical negation of the value provided.

=head3 Usage

<expression>

=head3 Examples

    (not (> 1 20))

=cut

has '+commands' => (
    default => sub {{
        'and' => { method          => 'bool_and',
                   preprocess_args => 0,
                   description     => 'Returns a true value only if both expressions are also true. Short-circuits as soon as an expression evaluates falsey, eliminating the evaluation of all subsequent expressions (including any of their potential side-effects).',
                   usage           => '(<expression>) (<expression>)',
                   example         => '(> 20 1) (> 1 20)',
                   result          => '0' },

        'or' => { method          => 'bool_or',
                  preprocess_args => 0,
                  description     => 'Returns a true value if either expression is true. Short-circuits as soon as an expression evauates truthy, eliminating the evaluation of all subsequent expressions (including any of their potential side-effects).',
                  usage           => '(<expression>) (<expression>)',
                  example         => '(> 20 1) (> 1 20)',
                  result          => '1' },

        'not' => { method      => 'bool_unary',
                   description => 'Returns the logical negation of the value provided.',
                   usage       => '(<expression>)',
                   example     => '1',
                   result      => '0' },

    }},
);

sub bool_and {
    my ($self, $message, $cmd, $rpl, @args) = @_;

    return 0 unless @args && @args > 0;

    foreach my $arg (@args) {
        if (blessed($arg) && $arg->can('evaluate')) {
            return 0 unless $arg->evaluate($message, $rpl);
        } else {
            return 0 unless $arg;
        }
    }

    return 1;
}

sub bool_or {
    my ($self, $message, $cmd, $rpl, @args) = @_;

    return 0 unless @args && @args > 0;

    foreach my $arg (@args) {
        if (blessed($arg) && $arg->can('evaluate')) {
            return 1 if $arg->evaluate($message, $rpl);
        } else {
            return 1 if $arg;
        }
    }

    return 0;
}

sub bool_unary {
    my ($self, $message, $op, $rpl, @args) = @_;

    return unless $self->has_one_value($message, @args);

    $op = '!' if lc($op) eq 'not';

    my $r;
    eval '$r = ' . $op . ' $args[0];';
    return $r ? 1 : 0;
}

sub has_one_value {
    my ($self, $message, @args) = @_;

    return 0 unless @args && @args == 1;
    return 1;
}

sub has_two_values {
    my ($self, $message, @args) = @_;

    return 0 unless @args && @args == 2;
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
