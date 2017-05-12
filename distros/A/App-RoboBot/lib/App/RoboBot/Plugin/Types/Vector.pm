package App::RoboBot::Plugin::Types::Vector;
$App::RoboBot::Plugin::Types::Vector::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

extends 'App::RoboBot::Plugin';

=head1 types.vector

Provides functions for creating and manipulating vectors of values.

=cut

has '+name' => (
    default => 'Types::Vector',
);

has '+description' => (
    default => 'Provides functions for creating and manipulating vectors of values.',
);

=head2 vec

=head3 Description

Converts a list of values into a vector, returning the vector. If no values are
provided, an empty vector is returned.

=head3 Usage

[<list>]

=head3 Examples

    :emphasize-lines: 2

    (vec 1 (seq 5 7) 10)
    [1 5 6 7 10]

=cut

has '+commands' => (
    default => sub {{
        'vec' => { method      => 'vec_vec',
                   description => 'Converts a list of values into a vector, returning the vector. If no values are provided, an empty vector is returned.',
                   usage       => '[<list>]',
                   example     => '1 (seq 5 7) 10',
                   result      => '[1 5 6 7 10]', },
    }},
);

sub vec_vec {
    my ($self, $message, $command, $rpl, @list) = @_;

    return [] unless @list && @list > 0;
    return [@list];
}

__PACKAGE__->meta->make_immutable;

1;
