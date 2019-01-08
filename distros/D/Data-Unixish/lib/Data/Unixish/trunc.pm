package Data::Unixish::trunc;

our $DATE = '2019-01-06'; # DATE
our $VERSION = '1.570'; # VERSION

use 5.010;
use locale;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);
use Text::ANSI::Util qw(ta_trunc);
use Text::ANSI::WideUtil qw(ta_mbtrunc);
use Text::WideChar::Util qw(mbtrunc);

our %SPEC;

$SPEC{trunc} = {
    v => 1.1,
    summary => 'Truncate string to a certain column width',
    description => <<'_',

This function can handle text containing wide characters and ANSI escape codes.

Note: to truncate by character instead of column width (note that wide
characters like Chinese can have width of more than 1 column in terminal), you
can turn of `mb` option even when your text contains wide characters.

_
    args => {
        %common_args,
        width => {
            schema => ['int*', min => 0],
            req => 1,
            pos => 0,
            cmdline_aliases => { w => {} },
        },
        ansi => {
            summary => 'Whether to handle ANSI escape codes',
            schema => ['bool', default => 0],
        },
        mb => {
            summary => 'Whether to handle wide characters',
            schema => ['bool', default => 0],
        },
    },
    tags => [qw/itemfunc text/],
};
sub trunc {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    while (my ($index, $item) = each @$in) {
        push @$out, _trunc_item($item, \%args);
    }

    [200, "OK"];
}

sub _trunc_item {
    my ($item, $args) = @_;
    return $item if !defined($item) || ref($item);
    if ($args->{ansi}) {
        if ($args->{mb}) {
            return ta_mbtrunc($item, $args->{width});
        } else {
            return ta_trunc($item, $args->{width});
        }
    } elsif ($args->{mb}) {
        return mbtrunc($item, $args->{width});
    } else {
        return substr($item, 0, $args->{width});
    }
}

1;
# ABSTRACT: Truncate string to a certain column width

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::trunc - Truncate string to a certain column width

=head1 VERSION

This document describes version 1.570 of Data::Unixish::trunc (from Perl distribution Data-Unixish), released on 2019-01-06.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res = lduxl([trunc => {width=>4}], "123", "1234", "12345"); # => ("123", "1234", "1234")

In command line:

 % echo -e "123\n1234\n12345" | dux trunc -w 4 --format=text-simple
 123
 1234
 1234

=head1 FUNCTIONS


=head2 trunc

Usage:

 trunc(%args) -> [status, msg, payload, meta]

Truncate string to a certain column width.

This function can handle text containing wide characters and ANSI escape codes.

Note: to truncate by character instead of column width (note that wide
characters like Chinese can have width of more than 1 column in terminal), you
can turn of C<mb> option even when your text contains wide characters.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ansi> => I<bool> (default: 0)

Whether to handle ANSI escape codes.

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<mb> => I<bool> (default: 0)

Whether to handle wide characters.

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<width>* => I<int>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
