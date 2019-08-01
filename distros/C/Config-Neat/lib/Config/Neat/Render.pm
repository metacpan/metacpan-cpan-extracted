=head1 NAME

Config::Neat::Render - Render configs in Config::Neat format

=head1 SYNOPSIS

    use Config::Neat::Render;

    my $r = Config::Neat::Render->new();

    my $data = {
        'foo' => 'Hello, World!',
        'bar' => [1, 2, 3],
        'baz' => {
            'etc' => ['foo bar', 'baz', '', 1]
        }
    };

    print $r->render($data);

The output will be:

    bar         1 2 3

    baz
    {
        etc    `foo bar` baz `` 1
    }

    foo         Hello, World!

=head1 DESCRIPTION

This module allows you to render Config::Neat-compatible structures from your data
(but read below for limitations). See
L<https://github.com/iafan/Config-Neat/blob/master/sample/readme.nconf>
for the detailed file syntax specification. For parsing, use L<Config::Neat>.

=head2 METHODS

=over 4

=item B<< Config::Neat::Render->new([$options]) >>

Constructs a new renderer object. $options is a reference to a hash containing
rendering options' overrides (see the RENDERING OPTIONS section below).

=item B<< Config::Neat::Render->render($data[, $options]) >>

Renders $data into a string and returns it. $options is a reference to a hash
containing rendering options' overrides (see the RENDERING OPTIONS section below).

=back

=head2 RENDERING OPTIONS

=over 4

=item B<< indentation >>

A number of spaces to indent each nested block contents with.

Default value: C<4>

=item B<< key_spacing >>

A number of spaces between a key and and a value.

Default value: C<4>

=item B<< wrap_width >>

A suggested maximum width of each line in a multiline string or array.

Default value: C<60>

=item B<< brace_under >>

If true, put the opening brace under the key name, not on the same line

Default value: C<1> (true)

=item B<< separate_blocks >>

If true, surrond blocks with empty lines for better readability.

Default value: C<1> (true)

=item B<< align_all >>

If true, align all values in the configuration file
(otherwise the values are aligned only within current block).

Default value: C<1> (true)

=item B<< sort >>

Note that hashes in Perl do not guarantee the correct order, so blocks may have
individual parameters shuffled randomly. Set this option to a true value
if you want to sort keys alphabetically, or to a reference to an array holding
an ordered list of key names

Default value: C<undef> (false)

Example:

    my $data = {
        'bar' => [1, 2, 3],
        'baz' => {
            'etc' => ['foo bar', 'baz', '', 1]
        }
        'foo' => 'Hello, World!',
    };

    my @order = qw(foo bar baz);

    print $r->render($data, {sort => \@order});

The output will be:

    foo        Hello, World!
    bar        1 2 3

    baz
    {
        etc    `foo bar` baz `` 1
    }

=item B<< undefined_value >>

A string representation of the value to emit for undefined values

Default value: C<'NO'>

=back

=head1 LIMITATIONS

Do not use L<Config::Neat::Render> in conjunction with L<Config::Neat> for
arbitrary data serialization/desrialization. JSON and YAML will work better
for this kind of task.

Why? Because Config::Neat was primarily designed to allow easier configuration
file authoring and reading, and uses relaxed syntax where strings are treated like
space-separated arrays (and vice versa), and where there's no strict definition
for boolean types, no null values, etc.

It's the developer's responsibility to treat any given parameter as a boolean,
or string, or an array. This means that once you serialize your string into
Config::Neat format and parse it back, it will be converted to an array,
and you will need to use `->as_string` method to get the value as string.

In other words, when doing this:

    my $c = Config::Neat->new();
    my $r = Config::Neat::Render->new();
    my $parsed_data = $c->parse($r->render($arbitrary_data));

$parsed_data will almost always be different from $arbitrary_data.

However, doing this immediately after:

    my $parsed_data_2 = $c->parse($r->render($parsed_data));

Should produce the same data structure again.

=head1 COPYRIGHT

Copyright (C) 2012-2015 Igor Afanasyev <igor.afanasyev@gmail.com>

=head1 SEE ALSO

L<https://github.com/iafan/Config-Neat>

=cut

package Config::Neat::Render;

our $VERSION = '1.401';

use strict;

no warnings qw(uninitialized);

use Config::Neat::Util qw(new_ixhash is_number is_code is_hash is_array is_scalar
                          is_neat_array is_homogenous_simple_array hash_has_only_sequential_keys
                          hash_has_sequential_keys);
use Tie::IxHash;

my $PARAM = 1;
my $BLOCK = 2;

#
# Initialize object
#
sub new {
    my ($class, $options) = @_;

    my $default_options = {
        indentation     =>  4, # number of spaces to indent each nested block contents with
        key_spacing     =>  4, # number of spaces between a key and and a value

        wrap_width      => 60, # a suggested maximum width of each line in a multiline string or array

        brace_under     =>  1, # if true, put the opening brace under the key name, not on the same line
        separate_blocks =>  1, # if true, surrond blocks with empty lines for better readability
        align_all       =>  1, # if true, align all values in the configuration file
                               # (otherwise the values are aligned only within current block)

        sort            => undef, # can be a true value if you want to sort keys alphabetically
                                  # or a reference to an array with an ordered list of key names
        undefined_value => 'NO'   # default value to emit for undefined values
    };

    $options = {} unless $options;
    %$options = (%$default_options, %$options);

    my $self = {
        _options => $options
    };

    bless $self, $class;
    return $self;
}

# Renders a nested tree structure into a Config::Neat-compatible text representaion.
# @@@@@@@@
# CAUTION: Config::Neat::Render->render() and Config::Neat->parse()
# are NOT SYMMETRICAL and should not be used for arbitrary data
# serialization/deserialization.
#
# In other words, when doing this:
#
#     my $c = Config::Neat->new();
#     my $r = Config::Neat::Render->new();
#     my $parsed_data = $c->parse($r->render($arbitrary_data));
#
# $parsed_data will almost always be different from $arbitrary_data.
# However, doing this immediately after:
#
#     my $parsed_data_2 = $c->parse($r->render($parsed_data));
#
# Should produce the same data structure again.
#
# See README for more information.
# @@@@@@@@
sub render {
    my ($self, $data, $options) = @_;

    $options = {} unless $options;
    %$options = (%{$self->{_options}}, %$options);

    $options->{global_key_length} = 0;

    # convert an array into a hash with 0..n values
    my $sort = $options->{sort};
    if (ref($sort) eq 'ARRAY') {
        my %h;
        @h{@$sort} = (0 .. scalar(@$sort) - 1);
        $options->{sort} = \%h;
    }

    sub max_key_length {
        my ($node, $options, $indent, $recursive) = @_;

        my $len = 0;
        if (is_hash($node)) {
            foreach my $key (keys %$node) {
                my $subnode = $node->{$key};

                if (is_array($subnode) && !is_homogenous_simple_array($subnode)) {
                    $subnode = convert_array_to_hash($subnode);
                }

                my $key_len;
                if (is_hash($subnode) && !exists $subnode->{''}) {
                    # do not take into account the length of a hash key
                    # if it doesn't contain default values (which we want to align as well)
                } else {
                    $key_len = $indent + length($key);
                    # if the key contains spaces and will be wrapped
                    # with `...`, add two extra symbols
                    if ($key =~ m/\s/) {
                        $key_len += 2;
                    }
                    $len = $key_len if $key_len > $len;
                }

                if ($recursive && (is_hash($subnode) || is_neat_array($subnode) || is_array($subnode))) {
                    my $sub_indent = is_hash($subnode) ? $options->{indentation} : 0;
                    my $child_len = max_key_length($subnode, $options, $indent + $sub_indent, $recursive);
                    my $key_len = $child_len;
                    $len = $key_len if $key_len > $len;
                }
            }
        } elsif ((is_neat_array($node) || is_array($node)) && !is_homogenous_simple_array($node)) {
            map {
                my $child_len = max_key_length($_, $options, $indent + $options->{indentation}, $recursive);
                my $key_len = $child_len;
                $len = $key_len if $key_len > $len;
            } @$node;
        }
        return $len;
    }

    sub convert_array_to_hash {
        my $node = shift;

        my $i = 0;

        my $h = new_ixhash;

        foreach my $value (@$node) {
            $h->{$i++} = $value;
        }
        return $h;
    }

    sub render_wrapped_array {
        my ($array, $options, $indent) = @_;

        my $wrap_width = $options->{wrap_width};

        my @a;
        my $line = '';
        foreach my $item (@$array) {
            my $l = $line ? length($line) + 1 : 0;

            if ($l + length($item) > $wrap_width) {
                push(@a, $line) if $line ne '';
                $line = '';
            }

            if (length($item) >= $wrap_width) {
                push(@a, $item);
            } else {
                $line .= ' ' if $line ne '';
                $line .= $item;
            }
        }
        push(@a, $line) if $line ne '';

        return join("\n".(' ' x $indent), @a);
    }

    sub render_scalar {
        my ($scalar, $options, $indent, $should_escape) = @_;

        # dereference scalar
        $scalar = $$scalar if ref($scalar) eq 'SCALAR';

        $scalar =~ s/`/\\`/g;

        if ($scalar =~ m/(\n|\s{2,})/) {
            $should_escape = 1;
        }

        if (!defined $scalar) {
            $scalar = $options->{undefined_value};
        }

        if ($scalar eq '') {
            $scalar = '``';
        }

        if ($should_escape and $scalar =~ m/\s/) {
            $scalar = '`'.$scalar.'`';
        }

        if (!$should_escape and $scalar ne '') {
            my @a = split(/\s+/, $scalar);
            return render_wrapped_array(\@a, $options, $indent);
        }

        return $scalar;
    }

    sub pad {
        my ($s, $width) = @_;
        my $spaces = $width - length($s);
        return ($spaces <= 0) ? $s : $s . ' ' x $spaces;
    }

    sub render_key_val {
        my ($options, $key_length, $indent, $wasref, $array_mode, $sequential_keys, $key, $val) = @_;

        my $text = '';
        my $space_indent = (' ' x $indent);

        # if the key name contains whitespace, wrap it in backticks
        if ($key =~ m/\s/) {
            $key = "`$key`";
        }

        if (is_scalar($val)) {
            $text .= "\n" if ($$wasref == $BLOCK) and $options->{separate_blocks};

            $text .= $space_indent .
                     pad($key, $key_length - $indent) .
                     (' ' x $options->{key_spacing}) .
                     render_scalar($val, $options, $key_length + $options->{key_spacing}) .
                     "\n";

            $$wasref = $PARAM;

        } elsif (is_homogenous_simple_array($val)) {
            # escape individual array items
            my @a = map { render_scalar($_, $options, undef, 1) } @$val;

            $text .= "\n" if ($$wasref == $BLOCK) and $options->{separate_blocks};

            $text .= $space_indent .
                     pad($key, $key_length - $indent) .
                     (' ' x $options->{key_spacing}) .
                     render_wrapped_array(\@a, $options, $key_length + $options->{key_spacing}) .
                     "\n";

            $$wasref = $PARAM;

        } elsif (is_neat_array($val)) {
            map {
                $text .= render_key_val($options, $key_length, $indent, $wasref, $array_mode, $sequential_keys, $key, $_);
            } @$val;

        } else {
            $text .= "\n" if $$wasref and $options->{separate_blocks};

            if (is_hash($val) && exists $val->{''}) {
                my $default_value = $val->{''};
                if (!is_scalar($default_value) && !is_homogenous_simple_array($default_value)) {
                    die "Only scalar or simple array can be rendered as a default node value";
                }
                $$wasref = $PARAM;
                $text .= render_key_val($options, $key_length, $indent, $wasref, undef, $sequential_keys, $key, $default_value);
                $text .= $space_indent;
            } else {
                $text .= $space_indent;

                if (!$array_mode && !($sequential_keys && is_number($key))) {
                    $text .= $options->{brace_under} ? "$key\n$space_indent" : "$key ";
                }
            }

            $text .= "{\n" .
                     render_node_recursively($val, $options, $indent + $options->{indentation}) .
                     $space_indent .
                     "}\n";

            $$wasref = $BLOCK;
        }

        return $text;
    }

    sub render_node_recursively {
        my ($node, $options, $indent) = @_;
        my $text = '';
        my $key_length = 0;
        my $array_mode;
        my $sequential_keys;

        if (is_array($node) || is_neat_array($node)) {
            if (is_homogenous_simple_array($node)) {
                die "Can't render simple arrays as a main block content";
            } else {
                $array_mode = 1;
                $node = convert_array_to_hash($node);
            }
        }

        if (is_hash($node)) {
            $array_mode = hash_has_only_sequential_keys($node);
            $sequential_keys = hash_has_sequential_keys($node);
            $key_length = $options->{align_all} ? $options->{global_key_length} : max_key_length($node, $options, $indent);

        } else {
            die "Unsupported data type: '".ref($node)."'";
        }

        my $was = undef;

        my $sort = $options->{sort};
        my @keys = keys %$node;
        if (!$array_mode and scalar(@keys) > 1) {
            if (is_hash($sort)) {
                @keys = sort { $sort->{$a} <=> $sort->{$b} } @keys;
            } elsif ($sort) {
                @keys = sort @keys;
            }
        }

        foreach my $key (@keys) {
            # default node values are rendered separately
            if ($key ne '') {
                $text .= render_key_val($options, $key_length, $indent, \$was, $array_mode, $sequential_keys, $key, $node->{$key});
            }
        }
        return $text;
    }

    if ($options->{align_all}) {
        # calculate indent recursively
        $options->{global_key_length} = max_key_length($data, $options, 0, 1);
    }

    return render_node_recursively($data, $options, 0);
}

1;