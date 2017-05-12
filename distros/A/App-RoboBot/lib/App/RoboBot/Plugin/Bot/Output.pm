package App::RoboBot::Plugin::Bot::Output;
$App::RoboBot::Plugin::Bot::Output::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;
use MooseX::SetOnce;

use Data::Dumper;
use Number::Format;
use Scalar::Util qw( looks_like_number );

extends 'App::RoboBot::Plugin';

=head1 bot.output

Provides string formatting and output/display functions.

=cut

has '+name' => (
    default => 'Bot::Output',
);

has '+description' => (
    default => 'Provides string formatting and output/display functions.',
);

=head2 clear

=head3 Description

Clears current contents of the output buffer without displaying them.

This applies only to normal output - error messages will still be dispayed to
the user should occur.

=head2 join

=head3 Description

Joins together arguments into a single string, using the first argument as the
delimiter.

=head3 Usage

<delimiter string> <list>

=head3 Examples

    :emphasize-lines: 2

    (join ", " (seq 1 10))
    "1, 2, 3, 4, 5, 6, 7, 8, 9, 10"

=head2 split

=head3 Description

Splits a string into a list based on the delimiter provided. Delimiters may be
a regular expression or fixed string.

=head3 Usage

<delimiter> <string>

=head3 Examples

    :emphasize-lines: 2

    "[,\s]+" "1, 2, 3,4,    5"
    (1 2 3 4 5)

=head2 lower

=head3 Description

Converts the given string to lower-case.

=head3 Usage

<string>

=head3 Examples

    :emphasize-lines: 2

    (lower "Foo Bar Baz")
    "foo bar baz"

=head2 upper

=head3 Description

Converts the given string to upper-case.

=head3 Usage

<string>

=head3 Examples

    :emphasize-lines: 2

    (lower "Foo Bar Baz")
    "FOO BAR BAZ"

=head2 print

=head3 Description

Prints input arguments. If one argument is given, it is echoed unaltered. If
multiple arguments are given they are printed in array notation.

=head3 Usage

<value> [<value> ...]

=head3 Examples

    :emphasize-lines: 2,5

    (print "foo")
    "foo"

    (print foo 123 "bar" 456)
    ("foo" 123 "bar" 456)

=head2 format

=head3 Description

Provides a printf-like string formatter. Placeholders follow the same rules as
printf(1).

=head3 Usage

<format string> [<list>]

=head3 Examples

    :emphasize-lines: 2

    (format "Random number: %d" (random 100))
    "Random number: 42"

=head2 format-number

=head3 Description

Provides numeric formatting for thousands separators, fixed precisions, and
trailing zeroes.

By default, numbers are formatted only with thousands separators added. Any
decimal places in the original number are preserved without any change in
precision.

By specifying a precision only, any decimal places will be truncated to that
as a maximum precision. The decimal places will not, however, be padded out
with zeroes unless a positive integer (anything > 0) is passed as the third
operand.

=head3 Usage

<number> [<precision> [<trailing zeroes>]]

=head3 Examples

    :emphasize-lines: 2,5,8

    (format-number 12398123)
    "12,398,123"

    (format-number 3.1459 2)
    "3.14"

    (format-number 5 4 1)
    "5.0000"

=head2 str

=head3 Description

Returns a single string, either a simple concatenation of all arguments, or an
empty string when no argument are given.

=head3 Usage

[<list>]

=head3 Examples

    :emphasize-lines: 2,5,8

    (str)
    ""

    (str "foo")
    "foo"

    (str foo 123 "bar" 456)
    "foo123bar456"

=cut

has '+commands' => (
    default => sub {{
        'clear' => { method      => 'clear_output',
                     description => 'Clears current contents of the output buffer without displaying them.',
                     usage       => '',
                     example     => '',
                     result      => '' },

        'join' => { method      => 'join_str',
                    description => 'Joins together arguments into a single string, using the first argument as the delimiter.',
                    usage       => '<delimiter> <value> [<value 2> ... <value N>]',
                    example     => '", " 1 2 3 4 5',
                    result      => '1, 2, 3, 4, 5' },

        'split' => { method      => 'split_str',
                     description => 'Splits a string into a list based on the delimiter provided. Delimiters may be a regular expression or fixed string.',
                     usage       => '<delimiter> <string>',
                     example     => '"[,\s]+" "1, 2, 3,4,    5"',
                     result      => '(1 2 3 4 5)' },

        'lower' => { method      => 'str_lower',
                     description => 'Converts the given string to lower-case.', },

        'upper' => { method      => 'str_upper',
                     description => 'Converts the given string to upper-case.', },

        'print' => { method      => 'print_str',
                     description => 'Prints input arguments. If one argument is given, it is simply echoed unaltered. If multiple arguments are given they are printed in array notation.',
                     usage       => '<value> [<value 2> ... <value N>]',
                     example     => 'foo 123 bar 456',
                     result      => '[foo, 123, bar, 456]' },

        'format' => { method      => 'format_str',
                      description => 'Provides a printf-like string formatter. Placeholders follow the same rules as printf(1).',
                      usage       => '"<format>" [<value 1> ... <value N>]',
                      example     => '"%d / %d = %.2f" 5 3 (/ 5 3)',
                      result      => '5 / 3 = 1.67' },

        'format-number' => { method      => 'format_num',
                             description => 'Provides numeric formatting for thousands separators, fixed precisions, and trailing zeroes.',
                             usage       => '<number> [<precision> [<trailing zeroes>]]',
                             example     => '1830472.2 4 1',
                             result      => '1,830,472.2000' },

        'str' => { method      => 'str_str',
                   description => 'Returns a single string, either a simple concatenation of all arguments, or an empty string when no argument are given.',
                   usage       => '[<list>]', },
    }},
);

has 'nf' => (
    is      => 'ro',
    isa     => 'Number::Format',
    default => sub { Number::Format->new() },
);

sub str_str {
    my ($self, $message, $command, $rpl, @list) = @_;

    return "" unless @list;
    return join('', @list);
}

sub clear_output {
    my ($self, $message) = @_;

    $message->response->clear_content;
}

sub join_str {
    my ($self, $message, $command, $rpl, @args) = @_;

    return unless @args && scalar(@args) >= 2;
    return join($args[0], @args[1..$#args]);
}

sub split_str {
    my ($self, $message, $command, $rpl, $pattern, $string) = @_;

    return unless defined $pattern && defined $string;

    my @list;

    eval {
        @list = split(($pattern =~ m{^m?[/\{|\[](.*)[/\}|\]]$}s ? m{$1} : $pattern), $string);
    };

    if ($@) {
        $message->response->raise('Invalid pattern provided for splitting.');
        return;
    }

    return @list;
}

sub str_lower {
    my ($self, $message, $command, $rpl, $str) = @_;

    return unless defined $str;
    return lc($str);
}

sub str_upper {
    my ($self, $message, $command, $rpl, $str) = @_;

    return uc($str);
}

sub print_str {
    my ($self, $message, $command, $rpl, @args) = @_;

    # Do nothing if we received nothing.
    return unless @args && @args > 0;

    # If we received only a single scalar value, send that unaltered as the message,
    # and return it to any outer expression.
    if (@args == 1 && !ref($args[0])) {
        $message->response->push($args[0]);
        return @args;
    }

    # For everything else, traverse the input and pretty-print it on a single
    # line with appropriate expression/type markup.
    my $output = '';
    _print_el($self->bot, \$output, $_) for @args;

    $output =~ s{(^\s+|\s+$)}{}ogs;

    $output = "($output)" if @args > 1;

    $message->response->push($output);
    return @args;
}

sub _print_el {
    my ($bot, $output, $el) = @_;

    if (!defined $el) {
        $$output .= " undef";
    } elsif (ref($el) eq 'HASH') {
        _print_map($bot, $output, $el);
    } elsif (ref($el) eq 'ARRAY') {
        _print_list($bot, $output, $el);
    } elsif (looks_like_number($el)) {
        $$output .= " $el";
    } else {
        $el =~ s{"}{\\"}g;
        $el =~ s{\n}{\\n}gs;
        $el =~ s{\r}{\\r}gs;
        $el =~ s{\t}{\\t}gs;
        $$output .= sprintf(' "%s"', $el);
    }

    return;
}

sub _print_list {
    my ($bot, $output, $list) = @_;

    $$output .= ' (';

    if (!ref($list->[0]) && (exists $bot->commands->{lc($list->[0])} || exists $bot->macros->{lc($list->[0])})) {
        $$output .= shift @{$list};
    }

    _print_el($bot, $output, $_) for @{$list};

    $$output .= ')';
}

sub _print_map {
    my ($bot, $output, $map) = @_;

    $$output .= ' {';

    foreach my $k (keys %{$map}) {
        $$output .= " $k";
        _print_el($bot, $output, $map->{$k});
    }

    $$output .= ' }';
}

sub format_str {
    my ($self, $message, $command, $rpl, $format, @args) = @_;

    my $str;

    eval { $str = sprintf($format, @args) };

    if ($@) {
        $message->response->raise(sprintf('Error: %s', $@));
        return;
    }

    return $str;
}

sub format_num {
    my ($self, $message, $command, $rpl, @args) = @_;

    return $self->nf->format_number(@args);
}

__PACKAGE__->meta->make_immutable;

1;
