package CSS::Moonfall;
use strict;
use warnings;
use base 'Exporter';
use Text::Balanced 'extract_bracketed';

our @EXPORT = qw/filter fill/;
our $VERSION = '0.04';

sub filter {
    my $package = shift;
    my $in = shift;
    my $out = '';

    while (length $in) {
        ((my $extracted), $in, my $prefix)
            = extract_bracketed($in, '[q]', '[^\[]+');
        return $out . $in if !defined($extracted);
        $out .= $prefix;

        # get rid of the []
        substr($extracted, -1, 1, '');
        substr($extracted, 0, 1, '');

        # get the rest of the line around the extracted text so we can check
        # how much we should indent, and whether to compress the output into
        # one line
        my ($preline)  = $prefix =~ /(.*)$/;
        my ($postline) = $in     =~ /^(.*)/;

        $out .= _process($package, $extracted, 1, $preline, $postline);
    }

    return $out;
}

sub fill {
    my $values = shift;
    my $total = delete $values->{total} or do {
        require Carp;
        Carp::croak "You must define a total size in a call to fill.";
    };

    my $unfilled = 0;

    for my $k (keys %$values) {
        if (defined(my $w = $values->{$k})) {
            $total -= $w;
        }
        else {
            ++$unfilled;
        }
    }

    $total = int($total / $unfilled);

    for (values %$values) {
        defined or $_ = $total;
    }

    return $values;
}

# this is where all the logic of expanding [foo] into some arbitrary string is
sub _process {
    my $package = shift;
    my $in      = shift;
    my $top     = shift;
    my $pre     = shift;
    my $post    = shift;

    $in =~ s/^\s+//;
    $in =~ s/\s+$//;

    if ($in =~ /^[a-zA-Z_]\w*/) {
        return $in if !$top;
        $in = '$' . $in;
    }

    my $out = $top ? eval "package $package; no strict 'vars'; $in" : $in;

    my @kv = _expand($out);

    if (@kv > 1) {
        my $joiner = ' ';
        my $indent = '';
        if ($pre =~ /^\s*$/ && $post =~ /^\s*$/) {
            $joiner = "\n";
            $indent = $pre;
        }

        my $first = 0;
        $out = join $joiner, map {
            my ($k, $v) = @$_;
            $k =~ s/_/-/g;
            $v = _process($package, $v, 0, $pre, $post);
            ($first++ ? $indent : '') . "$k: $v;";
        }
        sort {$a->[0] cmp $b->[0]} @kv;
    }
    elsif ($kv[0] =~ /^\d+$/) {
        $out .= 'px';
    }

    return $out;
}

# try to expand an array/hash ref, recursively, into a list of pairs
# if a value is a reference, then the key is dropped and the value is expanded
# in place
sub _expand {
    my $in = shift;
    return $in if !ref($in);

    my @kv;

    if (ref($in) eq 'HASH') {
        while (my ($k, $v) = each %$in) {
            if (ref($v)) {
                push @kv, _expand($v);
            }
            else {
                push @kv, [$k => $v];
            }
        }
    }
    elsif (ref($in) eq 'ARRAY') {
        if (ref($in->[0]) eq 'ARRAY') {
            for (@$in) {
                my ($k, $v) = @$_;
                if (ref($v)) {
                    push @kv, _expand($v);
                }
                else {
                    push @kv, [$k => $v];
                }
            }
        }
        else {
            my $i;
            for ($i = 0; $i < @$in; $i += 2) {
                my ($k, $v) = ($in->[$i], $in->[$i+1]);
                if (ref($v)) {
                    push @kv, _expand($v);
                }
                else {
                    push @kv, [$k => $v];
                }
            }
        }
    }

    return @kv;
}

1;

__END__

=head1 NAME

CSS::Moonfall - port of Lua's Moonfall for dynamic CSS generation

=head1 SYNOPSIS

    package MySite::CSS;
    use CSS::Moonfall;
    our $page_width = 1000;
    our $colors = { background => '#000000', color => '#FFFFFF' };

    package main;
    print MySite::CSS->filter(<<'CSS');
    body { width: [page_width]; }
    #header { width: [$page_width-20]; [colors] }
    CSS

=head1 DESCRIPTION

C<Moonfall> is an application for the dynamic generation of CSS. The problem it
solves is making CSS more programmable. The most basic usage is to define
variables within CSS (e.g., so similar elements can have their common color
defined in one and only one place). C<CSS::Moonfall> aims to be a faithful port
from Lua to Perl.

See L<http://moonfall.org/> for more details.

=head1 DEVIATIONS FROM MOONFALL

Obviously C<CSS::Moonfall> uses Perl (not Lua) as its programming language. :)

C<Moonfall> is actually a standalone C program that filters CSS with its
embedded Lua interpreter. C<CSS::Moonfall> is a module that lets you easily
builds the tools to do the same task.

Lua has only one data structure: the table. Perl has two: arrays and hashes.
Lua's tables fulfill the purpose of both: it's an ordered table indexable by
arbitrary strings. I've tried to make C<CSS::Moonfall> let you use both arrays
and hashes. You should really only use hashes (it feels nicer that way). Later
versions may have extra semantics (such as guaranteed ordering) tied to arrays.

=head1 FUNCTIONS

The C<CSS::Moonfall> module has two exports: C<fill> and C<filter>. C<fill> is
to be used by the Moonfall script itself, to aid in the creation of auto-sized
fields. C<filter> is used by modules calling your library to filter input.

=head2 fill HASHREF => HASHREF

Takes a hashref and uses the known values to fill in the unknown values. This
is mostly useful for dynamically calculating the width of multiple elements.

You must pass in a nonzero C<total> field which defines the total size. Pass
in known values in the usual fashion (such as: C<< center => 300 >>). Unknown
values should be explicitly set to C<undef> (such as: C<< left => undef >>).

Here's an example:

    fill { total => 1000, middle => 600, bottom => undef, top => undef }
        => { middle => 600, top => 200, bottom => 200 }

=head2 filter STRING => STRING

This takes the pseudo-CSS passed in and applies what it can to return real CSS.
Text within brackets C<[...]> is filtered through C<eval>.

As a convenience, barewords (such as C<[foo]>) will be replaced with the value
of the global scalar with that name. If that scalar is a hash reference, then
each (key, value) pair will be turned into CSS-style C<key: value;>
declarations. You may use underscores in key names instead of C<-> to avoid
having to quote the key. This means that if you want to call functions, you
must include a pair of parentheses or something else to distinguish it from
a bareword (much like in Perl itself for C<$hash{keys}>.

Hashes (and arrays) are recursively expanded. If the input looks like this:

    our $default = {
        foo => {
            color => '#FF0000',
            baz => {
                background_color => '#000000',
            },
        },
    };

then you'll get output that looks like:

    color: #FF0000;
    background-color: #000000;

If any value looks like a plain integer, it will have C<px> appended to it.

=head1 SEE ALSO

The original Lua Moonfall: L<http://moonfall.org/>

=head1 PORTER

Shawn M Moore, C<sartak@gmail.com>

=head1 ORIGINAL AUTHOR

Kevin Swope, C<kevin@moonfall.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

