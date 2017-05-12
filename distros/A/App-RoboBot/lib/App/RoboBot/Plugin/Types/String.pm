package App::RoboBot::Plugin::Types::String;
$App::RoboBot::Plugin::Types::String::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

extends 'App::RoboBot::Plugin';

=head1 types.string

Provides functions for creating and manipulating string-like values.

=cut

has '+name' => (
    default => 'Types::String',
);

has '+description' => (
    default => 'Provides functions for creating and manipulating string-like values.',
);

=head2 substring

=head3 Description

Returns ``n`` characters from ``str`` beginning at ``position`` (first
character in a string is ``0``).

Without ``n`` will return from ``position`` to the end of the original string.

A negative value for ``n`` will return from ``position`` until ``|n| - 1``
characters prior to the end of the string (``n = -1`` would have the same
effect as omitting ``n``).

=head3 Usage

<str> <position> [<n>]

=head3 Examples

    :emphasize-lines: 2

    (substring "The quick brown fox ..." 4 5)
    "quick"

=head2 index

=head3 Description

Returns the starting position(s) in a list of all occurrences of the substring
``match`` in ``str``. If ``match`` does not exist anywhere in ``str`` then an
empty list is returned.

=head3 Usage

<str> <match>

=head3 Examples

    :emphasize-lines: 2,5

    (index "The quick brown fox ..." "fox")
    (16)

    (index "The quick brown fox ..." "o")
    (12 17)

=head2 index-n

=head3 Description

Returns the nth (from 1) starting position of the substring ``match`` in
``str``.

If there are no occurrences of ``match`` in ``str``, or there are less than
``n``, nothing is returned.

=head3 Usage

=head3 Examples

    :emphasize-lines: 2

    (index-n "This string has three occurrences of the substring \"str\" in it." "str" 2)
    44

=cut

has '+commands' => (
    default => sub {{
        'substring' => { method      => 'str_substring',
                         description => 'Returns <n> characters from <str> beginning at position <pos> (first character in a string is 0). Without <n> will return from <pos> to the end of the original string. A negative value for <n> will return from <pos> until |<n>|-1 characters prior to the end of the string (<n> = -1 would have the same effect as omitting <n>)..',
                         usage       => '<str> <pos> [<n>]',
                         example     => '"The quick brown fox ..." 4 5',
                         result      => 'quick', },

        'index' => { method      => 'str_index',
                     description => 'Returns the starting position(s) in a list of all occurrences of the substring <match> in <str>. If <match> does not exist anywhere in <str> then an empty list is returned.',
                     usage       => '<str> <match>',
                     example     => '"The quick brown fox ..." "fox"',
                     result      => '[16]',
                     see_also    => ['index-n'], },

        'index-n' => { method      => 'str_index_n',
                       description => 'Returns the <n>th (from 1) starting position of the substring <match> in <str>. If there are no occurrences of <match> in <str>, or there are less than <n>, nothing is returned.',
                       usage       => '<str> <match> <n>',
                       example     => '"This string has three occurrences of the substring \"str\" in it." "str" 2',
                       result      => '44',
                       see_also    => ['index'], },
    }},
);

sub str_index {
    my ($self, $message, $command, $rpl, $str, $match) = @_;

    unless (defined $str && defined $match) {
        $message->response->raise('Must provide a string and substring.');
        return;
    }

    # Short circuit if a match is going to be impossible. This is not an error.
    return [] if length($match) > length($str);

    my @positions;

    for (my $i = 0; $i <= length($str) - length($match); $i++) {
        push(@positions, $i) if substr($str, $i, length($match)) eq $match;
    }

    return \@positions;
}

sub str_index_n {
    my ($self, $message, $command, $rpl, $str, $match, $n) = @_;

    unless (defined $n && $n =~ m{^\d+$}) {
        $message->response->raise('Must supply <n> as a positive integer.');
        return;
    }

    my $matches = $self->str_index($message, $command, $rpl, $str, $match);

    return unless defined $matches && ref($matches) eq 'ARRAY' && scalar(@{$matches}) >= $n;
    return $matches->[$n - 1];
}

sub str_substring {
    my ($self, $message, $command, $rpl, $str, $pos, $n) = @_;

    unless (defined $str && defined $pos) {
        $message->response->raise('Must provide a string and starting position.');
        return;
    }

    unless ($pos =~ m{^-?\d+$}) {
        $message->response->raise('Starting position must be an integer.');
        return;
    }

    return "" if $pos >= length($str);

    if (defined $n) {
        if ($n =~ m{^-?\d+$}) {
            return substr($str, $pos, $n);
        } else {
            $message->response->raise('Character count <n> must be an integer.');
            return;
        }
    } else {
        return substr($str, $pos);
    }
}

__PACKAGE__->meta->make_immutable;

1;
