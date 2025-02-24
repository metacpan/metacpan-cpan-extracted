package Data::Unixish::date;

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';
use POSIX qw(strftime);
use Scalar::Util qw(looks_like_number blessed);

use Data::Unixish::Util qw(%common_args);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-02-24'; # DATE
our $DIST = 'Data-Unixish'; # DIST
our $VERSION = '1.574'; # VERSION

our %SPEC;

$SPEC{date} = {
    v => 1.1,
    summary => 'Format date',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
        %common_args,
        format => {
            summary => 'Format',
            schema => 'str*',
            cmdline_aliases => { f=>{} },
            pos => 0,
        },
        # tz?
    },
    tags => [qw/datatype:date itemfunc formatting/],
};
sub date {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    _date_begin(\%args);
    while (my ($index, $item) = each @$in) {
        push @$out, _date_item($item, \%args);
    }

    [200, "OK"];
}

sub _date_begin {
    my $args = shift;

    $args->{format} //= '%Y-%m-%d %H:%M:%S';
}

sub _date_item {
    my ($item, $args) = @_;

    my @lt;
    if (looks_like_number($item) &&
            $item >= 0 && $item <= 2**31) { # XXX Y2038-bug
        @lt = localtime($item);
    } elsif (blessed($item) && $item->isa('DateTime')) {
        # XXX timezone!
        @lt = localtime($item->epoch);
    } else {
        goto OUT_ITEM;
    }

    $item = strftime $args->{format}, @lt;

  OUT_ITEM:
    return $item;
}

1;
# ABSTRACT: Format date

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::date - Format date

=head1 VERSION

This document describes version 1.574 of Data::Unixish::date (from Perl distribution Data-Unixish), released on 2025-02-24.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res = lduxl([date => {format=>"%Y-%m-%d"}], DateTime->new(year=>2012, month=>9, day=>6), 1290380232, "foo");
 # => ("2012-09-06","2010-11-22","foo")

In command line:

 % echo -e "1290380232\nfoo" | dux date --format=text-simple
 2010-11-22 05:57:12
 foo

=head1 FUNCTIONS


=head2 date

Usage:

 date(%args) -> [$status_code, $reason, $payload, \%result_meta]

Format date.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<format> => I<str>

Format.

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).


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
