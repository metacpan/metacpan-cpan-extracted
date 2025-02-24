package Data::Unixish::split;

use 5.010001;
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

sub _pattern_to_re {
    my $args = shift;

    my $re;
    my $pattern = $args->{pattern}; defined $pattern or die "Please specify pattern";
    if ($args->{fixed_string}) {
        $re = $args->{ignore_case} ? qr/\Q$pattern/i : qr/\Q$pattern/;
    } else {
        eval { $re = $args->{ignore_case} ? qr/$pattern/i : qr/$pattern/ };
        die "Invalid pattern: $@" if $@;
    }

    $re;
}

$SPEC{split} = {
    v => 1.1,
    summary => 'Split string into array',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
        %common_args,
        pattern => {
            summary => 'Pattern or string',
            schema  => 'str*',
            req     => 1,
            pos     => 0,
        },
        fixed_string => {
            summary => 'Interpret pattern as fixed string instead of regular expression',
            schema  => 'true*',
            cmdline_aliases => {F=>{}},
        },
        ignore_case => {
            summary => 'Whether to ignore case',
            schema  => 'bool*',
            cmdline_aliases => {i=>{}},
        },
        limit => {
            schema  => 'uint*',
            default => 0,
            pos     => 1,
        },
    },
    tags => [qw/text itemfunc/],
};
sub split {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    # we don't call _split_item() to optimize
    my $re = _pattern_to_re(\%args);
    while (my ($index, $item) = each @$in) {
        push @$out, [CORE::split($re, $item, $args{limit}//0)];
    }

    [200, "OK"];
}

sub _split_item {
    my ($item, $args) = @_;

    my $re = _pattern_to_re($args);
    [CORE::split($re, $item, $args->{limit}//0)];
}

1;
# ABSTRACT: Split string into array

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::split - Split string into array

=head1 VERSION

This document describes version 1.574 of Data::Unixish::split (from Perl distribution Data-Unixish), released on 2025-02-24.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 @res = lduxl([split => {pattern=>','}], "a,b,c", "d,e");
 # => (["a","b","c"], ["d","e"])

=head1 FUNCTIONS


=head2 split

Usage:

 split(%args) -> [$status_code, $reason, $payload, \%result_meta]

Split string into array.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<fixed_string> => I<true>

Interpret pattern as fixed string instead of regular expression.

=item * B<ignore_case> => I<bool>

Whether to ignore case.

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<limit> => I<uint> (default: 0)

(No description)

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<pattern>* => I<str>

Pattern or string.


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

Perl's C<split> in L<perlfunc>

L<Data::Unixish::join>

L<Data::Unixish::splice>

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
