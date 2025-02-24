package Data::Unixish::sort;

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

$SPEC{sort} = {
    v => 1.1,
    summary => 'Sort items',
    description => <<'MARKDOWN',

By default sort ascibetically, unless `numeric` is set to true to sort
numerically.

MARKDOWN
    args => {
        %common_args,
        numeric => {
            summary => 'Whether to sort numerically',
            schema=>[bool => {default=>0}],
            cmdline_aliases => { n=>{} },
        },
        reverse => {
            summary => 'Whether to reverse sort result',
            schema=>[bool => {default=>0}],
            cmdline_aliases => { r=>{} },
        },
        ci => {
            summary => 'Whether to ignore case',
            schema=>[bool => {default=>0}],
            cmdline_aliases => { i=>{} },
        },
        random => {
            summary => 'Whether to sort by random',
            schema=>[bool => {default=>0}],
            cmdline_aliases => { R=>{} },
        },

        key_element => {
            summary => 'Sort using an array element',
            schema => 'uint*',
            description => <<'MARKDOWN',

If specified, `sort` will assume the item is an array and will sort using the
<key_element>'th element (zero-based) as key. If an item turns out to not be an
array, the item itself is used as key.

MARKDOWN
        },
    },
    tags => [qw/ordering/],
};
sub sort {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});
    my $numeric = $args{numeric};
    my $reverse = $args{reverse} ? -1 : 1;
    my $ci      = $args{ci};
    my $random  = $args{random};

    no warnings;
    my @buf;

    # special case
    if ($random) {
        require List::Util;
        while (my ($index, $item) = each @$in) {
            push @buf, $item;
        }
        push @$out, $_ for (List::Util::shuffle(@buf));
        return [200, "OK"];
    }

    while (my ($index, $item) = each @$in) {
        my $key;
        if (defined $args{key_element}) {
            $key = ref $item eq 'ARRAY' ? ($item->[$args{key_element}] // '') : $item;
        } else {
            $key = $item;
        }
        $key = lc($key) if $ci;
        # XXX: optimize: when !ci && !key_element, just use $item as $key so no
        # need to produce a separate $key
        push @buf, [$item, $key, $numeric ? $key+0 : undef];
    }

    my $sortsub;
    if ($numeric) {
        $sortsub = sub { $reverse * (
            ($a->[2] <=> $b->[2]) || ($a->[1] cmp $b->[1]) ) };
    } else {
        $sortsub = sub { $reverse * (
            ($a->[1] cmp $b->[1]) ) };
    }
    @buf = sort $sortsub @buf;

    push @$out, $_->[0] for @buf;

    [200, "OK"];
}

1;
# ABSTRACT: Sort items

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::sort - Sort items

=head1 VERSION

This document describes version 1.574 of Data::Unixish::sort (from Perl distribution Data-Unixish), released on 2025-02-24.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res;
 @res = lduxl('sort', 4, 7, 2, 5); # => (2, 4, 5, 7)
 @res = lduxl([sort => {reverse=>1}], 4, 7, 2, 5); # => (7, 5, 4, 2)

In command line:

 % echo -e "b\na\nc" | dux sort --format=text-simple
 a
 b
 c

=head1 FUNCTIONS


=head2 sort

Usage:

 sort(%args) -> [$status_code, $reason, $payload, \%result_meta]

Sort items.

By default sort ascibetically, unless C<numeric> is set to true to sort
numerically.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 0)

Whether to ignore case.

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<key_element> => I<uint>

Sort using an array element.

If specified, C<sort> will assume the item is an array and will sort using the
<key_element>'th element (zero-based) as key. If an item turns out to not be an
array, the item itself is used as key.

=item * B<numeric> => I<bool> (default: 0)

Whether to sort numerically.

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<random> => I<bool> (default: 0)

Whether to sort by random.

=item * B<reverse> => I<bool> (default: 0)

Whether to reverse sort result.


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

sort(1)

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
