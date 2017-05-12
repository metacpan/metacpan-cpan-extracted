package App::RoboBot::Plugin::Types::Set;
$App::RoboBot::Plugin::Types::Set::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

extends 'App::RoboBot::Plugin';

=head1 types.set

Provides functions for creating and manipulating sets of values. Sets differ
from vectors and lists in that duplicate values are automatically removed.

=cut

has '+name' => (
    default => 'Types::Set',
);

has '+description' => (
    default => 'Provides functions for creating and manipulating sets of values.',
);

=head2 set

=head3 Description

Creates a set from the provided arguments. Any duplicate values are removed
automatically from the returned set. If no values are provided, an empty set is
returned.

=head3 Usage

[<list>]

=head3 Examples

    :emphasize-lines: 2

    (set 1 (seq 5 7) 10)
    |1 5 6 7 10|

    (set 1 1 1 2 2 2 3 3 3)
    |1 2 3|

=cut

has '+commands' => (
    default => sub {{
        'set' => { method      => 'set_set',
                   description => 'Converts a list of values into a set, returning the set. If no values are provided, an empty set is returned.' },
    }},
);

sub set_set {
    my ($self, $message, $command, $rpl, @list) = @_;

    return [] unless @list && @list > 0;

    my %seen;
    return [grep { $seen{$_}++ < 1 } @list];
}

__PACKAGE__->meta->make_immutable;

1;
