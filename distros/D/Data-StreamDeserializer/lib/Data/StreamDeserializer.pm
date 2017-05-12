package Data::StreamDeserializer;

use 5.010001;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);
our $VERSION = '0.06';

use XSLoader;
XSLoader::load('Data::StreamDeserializer', $VERSION);

sub new
{
    my ($class, %opts) = @_;
    my $class_name = ref($class) || $class;

    my $self = $class_name->_low_level_new;
    $self->block_size($opts{block_size}) if exists $opts{block_size};
    if (exists $opts{data}) {
        $self->part($opts{data});
        $self->part;
    }
    return $self;
}


sub block_size
{
    my ($self, $value) = @_;
    return $self->{block_size} unless @_ > 1;
    croak "You can't set zero block_size" unless $value;
    return $self->{block_size} = $value;
}


sub part
{
    my ($self, @data) = @_;
    goto SET_EOF unless @data;
    goto SET_EOF unless defined $data[0];
    $self->{data} .= join '', @data;
    return;

    SET_EOF:
        $self->{data} .= ' ' unless $self->{eof}; # hack for tail digists
        $self->{eof} = 1;
        return;
}


sub next
{
    my ($self, @data) = @_;

    $self->part(@data) if @data;


    return 1 if $self->{done};
    if ($self->{seen} < -1 + length $self->{data}) {
        return 0 unless $self->_ds_look_tail;
        goto CHECK_ERROR;
    }
    goto CHECK_ERROR if $self->{eof};
    return 0;

    CHECK_ERROR:
        my $mode = $self->{mode};
        if ($mode < 0) {
            $self->_push_error($self->_error_string);
            delete $self->{data};
            return $self->{done} = 1;
        }
        if ($self->{eof}) {
            return 0 if $self->{seen} < -1 + length $self->{data};
            if (@{$self->{markers}}) {
                $self->_push_error(
                    sprintf "Unclosed brackets: '%s'",
                        join "', '", map $_->[0], @{ $self->{markers} }
                );
            }
            delete $self->{data};
            return $self->{done} = 1;
        }

        return 0;
}

sub is_done
{
    my ($self) = @_;
    return $self->{done};
}

sub next_object
{
    my ($self, @data) = @_;
    my $cnt = $self->{object_counter};

    $self->{one_object_mode} = 1;
    my $res = $self->next(@data);
    $self->{one_object_mode} = 0;
    return 1 if $res;
    return $cnt < $self->{object_counter};
}

sub skip_divider
{
    my ($self) = @_;
    $self->_skip_divider;
}

sub is_error
{
    my ($self) = @_;
    return scalar @{ $self->{error} };
}

sub error
{
    my ($self) = @_;
    return '' unless @{ $self->{error} };
    return join "\n", @{ $self->{error} };
}


sub tail
{
    my ($self) = @_;
    if ($self->{eof}) {
        return '' unless length $self->{tail};
        return substr $self->{tail}, 0, -1 + length $self->{tail};
    }
    return $self->{tail};
}


sub result
{
    my ($self, $behaviour) = @_;
    $behaviour ||= 'first';
    return $self->{queue}[0] if $behaviour eq 'first';
    return $self->{queue} if $behaviour eq 'all';
    croak "Unknown behaviour '$behaviour'";
}

sub _push_error
{
    my ($self, $error) = @_;
    return if @{$self->{error}} and $self->{error}[-1] eq $error;
    push @{ $self->{error} }, $error;
    return;
}

1;

__END__

=head1 NAME

Data::StreamDeserializer - non-blocking deserializer.

=head1 SYNOPSIS


    my $sr = new Data::StreamDeserializer
            data => $very_big_dump;

    ... somewhere

    unless($sr->next) {
        # deserialization hasn't been done yet
    }

    ...

    if ($sr->next) {
        # deserialization has been done

        ...
        if ($sr->is_error) {
            printf "%s\n",  $sr->error;
            printf "Unparsed string tail: %s\n", $sr->tail;
        }

        my $result = $sr->result;           # first deserialized object
        my $result = $sr->result(first);    # the same

        my $results = $sr->result('all');   # all deserialized objects
                                            # (ARRAYREF)
    }


    # stream deserializer
    $sr = new Data::StreamDeserializer;

    while(defined (my $block = read_next_data_block)) {
        $sr->next($block);
        ...
    }
    $sr->next(undef); # eof signal
    until ($sr->next) {
        ... do something
    }
    # all data were parsed

=head1 DESCRIPTION

Sometimes You need to deserialize a lot of data. If You use 'eval'
(or Safe->reval, etc) it can take You too much time. If Your code
is executed in event machine it can be inadmissible. So using the
module You can deserialize Your stream progressively and do
something else between deserialization itearions.

=head2 Recognized statements

=head3 HASHES

 { something }

=head3 ARRAYS

 [ something ]

=head3 REFS

 \ something
 \[ ARRAY ]
 \{ HASH }

=head3 Regexps

 qr{something}

=head3 SCALARS

 "something"
 'something'
 q{something}
 qq{something}

=head1 METHODS

=head2 new

Creates new deserializer. It can receive a few named arguments:

=head3 block_size

The size of block which will be serialized in each 'next' cycle.
Default value is 512 bytes.

=head3 data

If You know (have) all data to deserialize before constructing the object,
You can use this argument.

B<NOTE>: You must not use the function L<part> or L<next> with arguments
if You used this argument.

=head2 block_size

Set/get the same field.

=head2 part

Append a part of input data to serialize. If there is no argument
(or B<undef>), deserializer will know that there will be no data
in the future.


=head2 next

Processes to parse next L<block_size> bytes. Returns B<TRUE> if an error
was detected or all input datas were parsed.

=head2 next_object

The same as L<next> but returns B<true> after new object is found.
Drop previous results.

For example You have the string:

    $str = "1, 2, [ 0, 1 ], { 'a' => 'b' }";

You can extract objects:

    my $dsr = new Data::StreamDeserializer data => $str;

    1 until $dsr->next_object;
    my $first = $dsr->result;       # scalar: 1

    1 until $dsr->next_object;
    my $second = $dsr->result;      # scalar: 2

    1 until $dsr->next_object;
    my $third = $dsr->result;       # arrayref: [ 0, 1 ]

    1 until $dsr->next_object;
    my $third = $dsr->result;       # hashref: { 'a' => 'b' }

=head2 skip_divider

If You have a string:

    Object Object Object

(there are no dividers between objects), You can call L<skip_divider> after
fetching the next object.

Example:

    $str = "1 2 [ 0, 1 ]{ 'a' => 'b' }";

    my $dsr = new Data::StreamDeserializer data => $str;

    1 until $dsr->next_object;
    my $first = $dsr->result;       # scalar: 1

    $dsr->skip_divider;

    1 until $dsr->next_object;
    my $second = $dsr->result;      # scalar: 2

    $dsr->skip_divider;
    1 until $dsr->next_object;
    my $third = $dsr->result;       # arrayref: [ 0, 1 ]

B<Important>: You can't skip dividers inside nested object. The function
will croak if You call it in the point that isn't between objects.


=head2 is_error

Returns B<TRUE> if an error was detected.

=head2 error

Returns error string.

=head2 tail

Returns unparsed data.

=head2 result

Returns result of parsing. By default the function returns only
the first parsed object.

You can call the function with argument B<'all'>
to get all parsed objects. In this case the function will receive
B<ARRAYREF>.

=head2 is_done

Returns B<TRUE> if all input data were processed or an error was found.
If You didn't call L<part> without arguments, and didn't call L<next>
or L<next_object> with B<undef> the function could return B<TRUE> only
if an error occured.

=head1 PRIVATE METHODS

=head2 _push_error

Pushes error into deserializer's error stack.


=head1 SEE ALSO

L<DATA::StreamSerializer>

=head1 BENCHMARKS

This module is almost fully written using XS/C language. So it works
a bit faster or slowly than L<CORE::eval>.

You can try a few scripts in B<benchmark/> directory. There are a few
test arrays in this directory.

Here are a few test results of my system.


=head2 Array which contains 100 hashes:

It works faster than B<eval>:

    $ perl benchmark/ds_vs_eval.pl -n 1000 -b 512 benchmark/tests/01_100x10
    38296 bytes were read
    First deserializing by eval... done
    First deserializing by Data::DeSerializer... done
    Check if deserialized objects are same... done

    Starting 1000 iterations for eval... done (3.755 seconds)
    Starting 1000 iterations for Data::StreamDeserializer... done (3.059 seconds)

    Eval statistic:
            1000 iterations were done
            maximum deserialization time: 0.0041 seconds
            minimum deserialization time: 0.0035 seconds
            average deserialization time: 0.0036 seconds

    StreamDeserializer statistic:
            1000 iterations were done
            75000 SUBiterations were done
            512 bytes in one block in one iteration
            maximum deserialization time: 0.0045 seconds
            minimum deserialization time: 0.0028 seconds
            average deserialization time: 0.0029 seconds
            average subiteration time:    0.00004 seconds

=head2 Array which contains 1000 hashes:

It works slowly than B<eval>:

    $ perl benchmark/ds_vs_eval.pl -n 1000 -b 512 benchmark/tests/02_1000x10
    355623 bytes were read
    First deserializing by eval... done
    First deserializing by Data::DeSerializer... done
    Check if deserialized objects are same... done

    Starting 1000 iterations for eval... done (43.920 seconds)
    Starting 1000 iterations for Data::StreamDeserializer... done (71.668 seconds)

    Eval statistic:
            1000 iterations were done
            maximum deserialization time: 0.0490 seconds
            minimum deserialization time: 0.0416 seconds
            average deserialization time: 0.0426 seconds

    StreamDeserializer statistic:
            1000 iterations were done
            689000 SUBiterations were done
            512 bytes in one block in one iteration
            maximum deserialization time: 0.0773 seconds
            minimum deserialization time: 0.0656 seconds
            average deserialization time: 0.0690 seconds
            average subiteration time:    0.00010 seconds

You can see, that one block is parsed in a very short time period. So You
can increase L<block_size> value to reduce total parsing time.

If B<block_size> is equal string size the module works two times
faster than eval:

    $ perl benchmark/ds_vs_eval.pl -n 1000 -b 355623 benchmark/tests/02_1000x10
    355623 bytes were read
    First deserializing by eval... done
    First deserializing by Data::DeSerializer... done
    Check if deserialized objects are same... done

    Starting 1000 iterations for eval... done (44.456 seconds)
    Starting 1000 iterations for Data::StreamDeserializer... done (19.702 seconds)

    Eval statistic:
            1000 iterations were done
            maximum deserialization time: 0.0474 seconds
            minimum deserialization time: 0.0423 seconds
            average deserialization time: 0.0431 seconds

    StreamDeserializer statistic:
            1000 iterations were done
            1000 SUBiterations were done
            355623 bytes in one block in one iteration
            maximum deserialization time: 0.0179 seconds
            minimum deserialization time: 0.0168 seconds
            average deserialization time: 0.0171 seconds
            average subiteration time:    0.01705 seconds

=head1 AUTHOR

Dmitry E. Oboukhov, E<lt>unera@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dmitry E. Oboukhov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 VCS

The project is placed in my git repo. See here:
L<http://git.uvw.ru/?p=data-stream-deserializer;a=summary>

=cut


