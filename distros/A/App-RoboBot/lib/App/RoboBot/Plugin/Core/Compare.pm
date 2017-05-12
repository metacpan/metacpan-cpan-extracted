package App::RoboBot::Plugin::Core::Compare;
$App::RoboBot::Plugin::Core::Compare::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

extends 'App::RoboBot::Plugin';

=head1 core.compare

Exports functions for performing various types of vaue comparisons.

=cut

has '+name' => (
    default => 'Core::Compare',
);

has '+description' => (
    default => 'Provides functions for performing comparisons between values.',
);

=head2 eq

=head3 Description

String equality test. Returns 1 if both operands are the same in a string
context, 0 if they are not.

=head3 Usage

<operand> <operand>

=head2 lt

=head3 Description

String ordinality test. Returns 1 if ``a`` sorts before ``b`` according to the
collation rules of the locale in which the bot is running. Returns 0 otherwise.

=head3 Usage

<operand a> <operand b>

=head3 Examples

    (lt "abc" "def")

=head2 gt

=head3 Description

String ordinality test. Returns 1 if ``a`` sorts after ``b`` according to the
collation rules of the locale in which the bot is running. Returns 0 otherwise.

=head3 Usage

<operand a> <operand b>

=head3 Examples

    (gt "zyx" "abc")

=head2 ne

=head3 Description

String inequaity test. Returns 1 if both operands are different in a string
context, 0 otherwise.

=head3 Usage

<operand a> <operand b>

=head2 cmp

=head3 Description

String comparison. Returns -1 if ``a`` collates before ``b``, 1 if ``b``
collates first, and 0 if they are equal. Collation uses the locale under which
the bot is running.

=head3 Usage

<operand a> <operand b>

=head2 ==

=head3 Description

Numeric equality test. Returns 1 if both operands the same numerically, 0
otherwise.

=head3 Usage

<operand a> <operand b>

=head3 Examples

    (== 1 1.0000000)

=head2 <

=head3 Description

Numeric less-than test. Returns 1 if ``a`` is less than ``b``, 0 otherwise.

=head3 Usage

<operand a> <operand b>

=head3 Examples

    (< 1 2)

=head2 >

=head3 Description

Numeric greater-than test. Returns 1 if ``a`` is greater than ``b``, 0
otherwise.

=head3 Usage

<operand a> <operand b>

=head3 Examples

    (> 50 10)

=head2 !=

=head3 Description

Numeric inequality test. Returns 1 if both operands are different numbers, 0
otherwise.

=head3 Usage

<operand a> <operand b>

=head3 Examples

    (!= 0.1 1.0)

=cut

has '+commands' => (
    default => sub {{
        'eq' => { method      => 'comparison_str',
                  description => 'Compares whether two values in string context are the same.',
                  usage       => '<value a> <value b>',
                  example     => '"string" "a phrase"',
                  result      => '0' },

        'ne' => { method      => 'comparison_str',
                  description => 'Compares whether two values in string context are not the same.',
                  usage       => '<value a> <value b>',
                  example     => '"string" "a phrase"',
                  result      => '1' },

        'lt' => { method      => 'comparison_str',
                  description => 'Determines whether value A would be sorted before value B in a string context.',
                  usage       => '<value a> <value b>',
                  example     => '"bar" "baz"',
                  result      => '1' },

        'gt' => { method      => 'comparison_str',
                  description => 'Determines whether value A would be sorted after value B in a string context.',
                  usage       => '<value a> <value b>',
                  example     => '"foo" "bar"',
                  result      => '1' },

        'cmp' => { method      => 'comparison_str',
                   description => 'Compares two vaues in string context. Returns 0 if the same, -1 is first value sorts first, and 1 if second value sorts first.',
                   usage       => '<value a> <value b>',
                   example     => '"the same phrase" "the same phrase"',
                   result      => '0' },

        '==' => { method      => 'comparison',
                  description => 'Compares whether two values in numeric context are the same.',
                  usage       => '<value a> <value b>',
                  example     => '5 6',
                  result      => '0' },

        '<' => { method      => 'comparison',
                 description => 'Determines whether the first value is less than the second value in a numeric context.',
                 usage       => '<value a> <value b>',
                 example     => '15 20',
                 result      => '1' },

        '>' => { method      => 'comparison',
                 description => 'Determines whether the first value is greater than the second value in a numeric context.',
                 usage       => '<value a> <value b>',
                 example     => '17 23',
                 result      => '0' },

        '!=' => { method      => 'comparison',
                  description => 'Compares whether two values in a numeric context are not the same.',
                  usage       => '<value a> <value b>',
                  example     => '5 23',
                  result      => '1' },
    }},
);

sub comparison {
    my ($self, $message, $op, $rpl, @args) = @_;

    return undef unless $self->has_two_values($message, @args);

    my $r;
    eval '$r = $args[0] ' . $op . ' $args[1];';

    $message->response->raise('Comparison failed: %s', $@) if $@;
    return $r ? 1 : 0;
}

sub comparison_str {
    my ($self, $message, $op, $rpl, @args) = @_;

    return undef unless $self->has_two_values($message, @args);

    my $r;
    eval '$r = "$args[0]" ' . $op . ' "$args[1]";';

    $message->response->raise('Comparison failed: %s', $@) if $@;
    return $r > 0 ? 1 : $r < 0 ? -1 : 0;
}

sub has_two_values {
    my ($self, $message, @args) = @_;

    unless (@args && @args == 2) {
        $message->response->raise('Must supply exactly two values for comparison.');
        return 0;
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
