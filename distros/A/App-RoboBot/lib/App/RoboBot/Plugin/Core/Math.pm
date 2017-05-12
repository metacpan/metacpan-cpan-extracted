package App::RoboBot::Plugin::Core::Math;
$App::RoboBot::Plugin::Core::Math::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

extends 'App::RoboBot::Plugin';

=head1 core.math

Exports functions for performing a variety of mathematical operations.

=cut

has '+name' => (
    default => 'Core::Math',
);

has '+description' => (
    default => 'Provides a set of functions for mathematical operations.',
);

=head2 +

=head3 Description

Adds operands together.

=head3 Usage

<addend> <addend>

=head2 -

=head3 Description

Subtracts the subtrahend from the minuend..

=head3 Usage

<minuend> <subtrahend>

=head2 *

=head3 Description

Returns the product of the operands.

=head3 Usage

<factor> <factor>

=head2 /

=head3 Description

Divides the operands.

=head3 Usage

<dividend> <divisor>

=head2 modulo

=head3 Description

Returns the remainder from the division.

=head3 Usage

<dividend> <divisor>

=head2 pow

=head3 Description

Returns the result of raising base to the power.

=head3 Usage

<base> <power>

=head2 sqrt

=head3 Description

Returns the square root of numeral.

=head3 Usage

<numeral>

=head2 abs

=head3 Description

Returns the absolute value of numeral.

=head3 Usage

<numeral>

=cut

has '+commands' => (
    default => sub {{
        '+' => { method  => 'add',
                 usage   => '<addend> <addend>',
                 example => '3 5',
                 result  => '8' },

        '-' => { method  => 'subtract',
                 usage   => '<minuend> <subtrahend>',
                 example => '9 2',
                 result  => '7' },

        '*' => { method  => 'multiply',
                 usage   => '<factor> <factor>',
                 example => '4 5',
                 result  => '20' },

        '/' => { method  => 'divide',
                 usage   => '<dividend> <divisor>',
                 example => '9 3',
                 result  => '3' },

        'modulo' => { method  => 'modulo',
                      usage   => '<dividend> <divisor>',
                      example => '6 4',
                      result  => '2' },

        'pow' => { method  => 'power',
                   usage   => '<base> <exponent>',
                   example => '3 2',
                   result  => '8' },

        'sqrt' => { method  => 'sqrt',
                    usage   => '<numeral>',
                    example => '4',
                    result  => '2' },

        'abs' => { method  => 'abs',
                   usage   => '<numeral>',
                   example => '-4',
                   result  => '4' },
    }},
);

sub abs {
    my ($self, $message, $command, $rpl, @args) = @_;

    return unless $self->has_n_number($message, 1, @args);
    return $args[0] >= 0 ? $args[0] : $args[0] * -1;
}

sub add {
    my ($self, $message, $command, $rpl, @args) = @_;

    push(@args, 1) unless @args && @args > 1;
    return unless $self->has_n_numbers($message, 2, @args);
    return $args[0] + $args[1];
}

sub subtract {
    my ($self, $message, $command, $rpl, @args) = @_;

    return unless $self->has_n_numbers($message, 2, @args);
    return $args[0] - $args[1];
}

sub multiply {
    my ($self, $message, $command, $rpl, @args) = @_;

    return unless $self->has_n_numbers($message, 2, @args);
    return $args[0] * $args[1];
}

sub divide {
    my ($self, $message, $command, $rpl, @args) = @_;

    return unless $self->has_n_numbers($message, 2, @args);
    return unless $self->denominator_not_zero($message, @args);
    return $args[0] / $args[1];
}

sub modulo {
    my ($self, $message, $command, $rpl, @args) = @_;

    return unless $self->has_n_numbers($message, 2, @args);
    return unless $self->denominator_not_zero($message, @args);
    return $args[0] % $args[1];
}

sub power {
    my ($self, $message, $command, $rpl, @args) = @_;

    return unless $self->has_n_numbers($message, 2, @args);
    return $args[0] ** $args[1];
}

sub sqrt {
    my ($self, $message, $command, $rpl, @args) = @_;

    return unless $self->has_n_numbers($message, 1, @args);
    return unless $self->has_all_positive_numbers($message, @args);
    return sqrt($args[0]);
}

sub has_n_numbers {
    my ($self, $message, $n, @args) = @_;

    unless (@args && @args == $n) {
        $message->response->raise(sprintf('Must supply exactly %d %s for the given mathematical function.', $n, ($n == 1 ? 'number' : 'numbers')));
        return 0;
    }

    return $self->has_only_numbers($message, @args);
}

sub has_only_numbers {
    my ($self, $message, @args) = @_;

    my $non_number = 0;

    foreach my $arg (@args) {
        unless ($arg =~ m{^\-?(\d+(\.\d+)?|\d*\.\d+)$}o) {
            $non_number++;
            last;
        }
    }

    if ($non_number) {
        $message->response->raise('All values must be numeric.');
        return 0;
    }

    return 1;
}

sub has_all_positive_numbers {
    my ($self, $message, @args) = @_;

    my $neg_number = 0;

    foreach my $arg (@args) {
        unless ($arg >= 0) {
            $neg_number++;
            last;
        }
    }

    if ($neg_number) {
        $message->response->raise('All values must be positive.');
        return 0;
    }

    return 1;
}

sub denominator_not_zero {
    my ($self, $message, @args) = @_;

    if ($args[1] == 0) {
        $message->response->raise('Cannot divide by zero.');
        return 0;
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
