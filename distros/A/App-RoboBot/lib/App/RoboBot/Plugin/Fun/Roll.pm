package App::RoboBot::Plugin::Fun::Roll;
$App::RoboBot::Plugin::Fun::Roll::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use Number::Format;

extends 'App::RoboBot::Plugin';

=head1 fun.roll

Random number generator, including functionality for obtaining numbers in the
style of arbitrary-sided dice-rolling.

=cut

has '+name' => (
    default => 'Fun::Roll',
);

has '+description' => (
    default => 'Random number generator in the style of arbitrary-sided dice-rolling.',
);

=head2 roll

=head3 Description

Given a die-size and a number of rolls, returns the summed result of all those
rolls. Each roll is effectively a call to ``(random n)`` where ``n`` is your
die size.

Assumes a single roll if you don't specify otherwise.

=head3 Usage

<die size> [<roll count>]

=head3 Examples

    (roll 20)
    (roll 4 3)

=head2 random

=head3 Description

Returns a random integer between ``0`` and ``max`` (defaults to 1).

=head3 Usage

[<max>]

=head3 Examples

    (random 10)

=cut

has '+commands' => (
    default => sub {{
        'roll' => { method          => 'roll',
                    preprocess_args => 1,
                    usage           => '<die size> [<die count>]',
                    example         => '2 10',
                    result          => '17' },

        'random' => { method      => 'random_int',
                      description => 'Returns a random integer between 0 and <max> (defaults to 1).',
                      usage       => '[<max>]', },
    }},
);

sub random_int {
    my ($self, $message, $command, $rpl, $max) = @_;

    $max //= 1;
    return unless $max =~ m{^\d+$};

    return int(rand($max+1));
}

sub roll {
    my ($self, $message, $command, $rpl, @args) = @_;

    my $nf = Number::Format->new();

    unless (@args && @args > 0) {
        return $message->response->raise('Invalid die size and roll count arguments.');
    }

    unless ($args[0] =~ m{^\d+$}o) {
        return $message->response->raise('Die size must always be expressed as an integer.');
    }

    my $size = $args[0];
    my $rolls = 1;

    if (defined $args[1]) {
        unless ($args[1] =~ m{^\d+$}o) {
            return $message->response->raise('Number of rolls must be expressed as an integer. Omitting the roll count will default to 1.');
        }

        $rolls = $args[1];
    }

    if ($size > 2**16 || $rolls > 2**16) {
        return $message->response->raise('My arms cannot handle that much dice rolling. Please try smaller numbers');
    }

    my $result = 0;
    for (1..$rolls) {
        $result += int(rand($size)) + 1;
    }
    $message->response->push(sprintf('You rolled a %s-sided die %s time%s for a total of %s.',
        $nf->format_number($size),
        $nf->format_number($rolls),
        $rolls != 1 ? 's' : '',
        $nf->format_number($result)));
    return $result;
}

__PACKAGE__->meta->make_immutable;

1;
