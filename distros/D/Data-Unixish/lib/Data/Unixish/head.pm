package Data::Unixish::head;

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

$SPEC{head} = {
    v => 1.1,
    summary => 'Output the first items of data',
    args => {
        %common_args,
        items => {
            summary => 'Number of items to output',
            schema=>['int*' => {default=>10}],
            tags => ['main'],
            cmdline_aliases => { n=>{} },
        },
    },
    tags => [qw/filtering/],
};
sub head {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});
    my $n = $args{items} // 10;

    while (my ($index, $item) = each @$in) {
        last if $index >= $n;
        push @$out, $item;
    }

    [200, "OK"];
}

1;
# ABSTRACT: Output the first items of data

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::head - Output the first items of data

=head1 VERSION

This document describes version 1.574 of Data::Unixish::head (from Perl distribution Data-Unixish), released on 2025-02-24.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish::head;
 my @res;
 @res = dux("head", 1..100); # => (1..10)
 @res = dux([head => {items=>3}], 1..100); # => (1, 2, 3)

In command line:

 % seq 1 100 | dux head -n 20 | dux tail --format=text-simple -n 5
 16
 17
 18
 19
 20

=head1 FUNCTIONS


=head2 head

Usage:

 head(%args) -> [$status_code, $reason, $payload, \%result_meta]

Output the first items of data.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<items> => I<int> (default: 10)

Number of items to output.

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

=head1 SEE ALSO

head(1)

L<Data::Unixish::tail>

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
