package Data::Unixish::splice;

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

$SPEC{splice} = {
    v => 1.1,
    summary => 'Perform Perl splice() on array',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
        %common_args,
        offset => {
            schema  => 'uint*',
            req     => 1,
            pos     => 0,
        },
        length => {
            schema  => 'uint*',
            pos => 1,
        },
        list => {
            schema  => ['array*', of=>'str*'], # actually it does not have to be array of str, we just want ease of specifying on the cmdline for now
            pos => 2,
            slurpy => 1,
        },
    },
    tags => [qw/datatype-in:array itemfunc/],
};
sub splice {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    while (my ($index, $item) = each @$in) {
        my @ary = ref $item eq 'ARRAY' ? @$item : ($item);
        if (defined $args{list}) {
            CORE::splice(@ary, $args{offset}, $args{length}, @{ $args{list} });
        } elsif (defined $args{length}) {
            CORE::splice(@ary, $args{offset}, $args{length});
        } else {
            CORE::splice(@ary, $args{offset});
        }
        push @$out, \@ary;
    }

    [200, "OK"];
}

sub _splice_item {
    my ($item, $args) = @_;

    my @ary = ref $item eq 'ARRAY' ? @$item : ($item);
    if (defined $args->{list}) {
        CORE::splice(@ary, $args->{offset}, $args->{length}, @{ $args->{list} });
    } elsif (defined $args->{length}) {
        CORE::splice(@ary, $args->{offset}, $args->{length});
    } else {
        CORE::splice(@ary, $args->{offset});
    }
    \@ary;
}

1;
# ABSTRACT: Perform Perl splice() on array

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::splice - Perform Perl splice() on array

=head1 VERSION

This document describes version 1.574 of Data::Unixish::splice (from Perl distribution Data-Unixish), released on 2025-02-24.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 @res = lduxl([splice => {offset=>1}], ["a","b","c"], ["d","e"],"f,g");
 # => (["a"], ["d"], [])

=head1 FUNCTIONS


=head2 splice

Usage:

 splice(%args) -> [$status_code, $reason, $payload, \%result_meta]

Perform Perl splice() on array.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<length> => I<uint>

(No description)

=item * B<list> => I<array[str]>

(No description)

=item * B<offset>* => I<uint>

(No description)

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

Perl's C<splice> in L<perlfunc>

L<Data::Unixish::split>

L<Data::Unixish::join>

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
