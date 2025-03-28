package Data::Unixish::wc;

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

$SPEC{wc} = {
    v => 1.1,
    summary => 'Print newline, word, and byte counts',
    description => <<'MARKDOWN',

Behavior mimics that of the Unix <prog:wc> utility. The order of the counts
which is returned is always: newline, word, character, byte, maximum line
length.

MARKDOWN
    args => {
        %common_args,
        bytes => {
            summary => "Return the bytes counts",
            schema => [bool => default => 0],
            cmdline_aliases => { c => {} },
        },
        chars => {
            summary => "Return the character counts",
            schema => [bool => default => 0],
            cmdline_aliases => { m => {} },
        },
        words => {
            summary => "Return the word counts",
            schema => [bool => default => 0],
            cmdline_aliases => { w => {} },
        },
        lines => {
            summary => "Return the newline counts",
            schema => [bool => default => 0],
            cmdline_aliases => { l => {} },
        },
        max_line_length => {
            summary => "Return the length of the longest line",
            schema => [bool => default => 0],
            cmdline_aliases => { L => {} },
        },
    },
    tags => [qw/text group/],
    "x.dux.strip_newlines" => 0, # for duxapp < 1.41, will be removed later
    "x.app.dux.strip_newlines" => 0,
};
sub wc {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    my ($bytes, $chars, $words, $lines);
    my $maxllen = 0;
    while (my ($index, $item) = each @$in) {
        next if !defined($item) || ref($item);
        for my $line (split /^/, $item) {
            $lines++;
            $chars += length($line);
            { use bytes; $bytes += length($line) }
            my @w = split /[ \t]+/o, $line; $words += @w;

            chomp($line);
            my $llen;
            { use bytes; $llen = length($line) }
            $maxllen = $llen if $llen > $maxllen;
        }
    }

    my $pbytes   = $args{bytes};
    my $pchars   = $args{chars};
    my $pwords   = $args{words};
    my $plines   = $args{lines};
    my $pmaxllen = $args{max_line_length};
    if (!$pbytes && !$pchars && !$pwords && !$plines && !$pmaxllen) {
        $pbytes++; $pwords++; $plines++;
    }
    my @res;
    push @res, $lines   if $plines;
    push @res, $words   if $pwords;
    push @res, $chars   if $pchars;
    push @res, $bytes   if $pbytes;
    push @res, $maxllen if $pmaxllen;

    push @$out, join("\t", @res);
    [200, "OK"];
}

1;
# ABSTRACT: Print newline, word, and byte counts

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::wc - Print newline, word, and byte counts

=head1 VERSION

This document describes version 1.574 of Data::Unixish::wc (from Perl distribution Data-Unixish), released on 2025-02-24.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @text = split /^/, "What do you want?\nWhat do you want me to want?\n";
 my $res = lduxl([wc => {words=>1, lines=>1}], @text); # => "2\t11"

In command line:

 % seq 1 100 | dux wc
 100    100    292

=head1 FUNCTIONS


=head2 wc

Usage:

 wc(%args) -> [$status_code, $reason, $payload, \%result_meta]

Print newline, word, and byte counts.

Behavior mimics that of the Unix L<wc> utility. The order of the counts
which is returned is always: newline, word, character, byte, maximum line
length.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<bytes> => I<bool> (default: 0)

Return the bytes counts.

=item * B<chars> => I<bool> (default: 0)

Return the character counts.

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<lines> => I<bool> (default: 0)

Return the newline counts.

=item * B<max_line_length> => I<bool> (default: 0)

Return the length of the longest line.

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<words> => I<bool> (default: 0)

Return the word counts.


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

wc(1)

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
