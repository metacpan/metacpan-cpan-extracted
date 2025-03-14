package Data::Unixish::linum;

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-02-24'; # DATE
our $DIST = 'Data-Unixish'; # DIST
our $VERSION = '1.574'; # VERSION

our %SPEC;

$SPEC{linum} = {
    v => 1.1,
    summary => 'Add line numbers',
    args => {
        %common_args,
        format => {
            summary => 'Sprintf-style format to use',
            description => <<'MARKDOWN',

Example: `%04d|`.

MARKDOWN
            schema  => [str => default=>'%4s|'],
            cmdline_aliases => { f=>{} },
        },
        start => {
            summary => 'Number to start from',
            schema  => [int => default => 1],
            cmdline_aliases => { s=>{} },
        },
        blank_empty_lines => {
            schema => [bool => default=>1],
            description => <<'MARKDOWN',

Example when set to false:

    1|use Foo::Bar;
    2|
    3|sub blah {
    4|    my %args = @_;

Example when set to true:

    1|use Foo::Bar;
     |
    3|sub blah {
    4|    my %args = @_;

MARKDOWN
            cmdline_aliases => {
                b => {},
                B => {
                    summary => 'Equivalent to --noblank-empty-lines',
                    code => sub { $_[0]{blank_empty_lines} = 0 },
                },
            },
        },
    },
    tags => [qw/text itemfunc/],
    "x.dux.strip_newlines" => 0, # for duxapp < 1.41, will be removed later
    "x.app.dux.strip_newlines" => 0,
};
sub linum {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    _linum_begin(\%args);
    while (my ($index, $item) = each @$in) {
        push @$out, _linum_item($item, \%args);
    }

    [200, "OK"];
}

sub _linum_begin {
    my $args = shift;

    $args->{format} //= '%4s|';
    $args->{blank_empty_lines} //= 1;
    $args->{start} //= 1;

    # abuse, use args to store a temp var
    $args->{_lineno} = $args->{start};
}

sub _linum_item {
    my ($item, $args) = @_;

    if (defined($item) && !ref($item)) {
        my @l;
        for (split /^/, $item) {
            my $n;
            $n = ($args->{blank_empty_lines} && !/\S/) ? "" : $args->{_lineno};
            push @l, sprintf($args->{format}, $n), $_;
            $args->{_lineno}++;
        }
        $item = join "", @l;
        chomp($item) if $args->{-dux_cli};
    }
    return $item;
}

1;
# ABSTRACT: Add line numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::linum - Add line numbers

=head1 VERSION

This document describes version 1.574 of Data::Unixish::linum (from Perl distribution Data-Unixish), released on 2025-02-24.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(aduxa);
 my @res = aduxa('linum', "a", "b ", "c\nd ", undef, ["e"]);
 # => ("   1|a", "   2| b", "   3c|\n   4|d ", undef, ["e"])

In command line:

 % echo -e "a\nb\n \nd" | dux linum
    1|a
    2|b
     |
    4|d

=head1 FUNCTIONS


=head2 linum

Usage:

 linum(%args) -> [$status_code, $reason, $payload, \%result_meta]

Add line numbers.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<blank_empty_lines> => I<bool> (default: 1)

Example when set to false:

 1|use Foo::Bar;
 2|
 3|sub blah {
 4|    my %args = @_;

Example when set to true:

 1|use Foo::Bar;
  |
 3|sub blah {
 4|    my %args = @_;

=item * B<format> => I<str> (default: "%4s|")

Sprintf-style format to use.

Example: C<%04d|>.

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<start> => I<int> (default: 1)

Number to start from.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish>.

=head1 SEE ALSO

lins, rins

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
