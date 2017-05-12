package Data::Unixish::sort;

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);

our $VERSION = '1.55'; # VERSION

our %SPEC;

$SPEC{sort} = {
    v => 1.1,
    summary => 'Sort items',
    description => <<'_',

By default sort ascibetically, unless `numeric` is set to true to sort
numerically.

_
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
        my $rec = [$item];
        push @$rec, $ci ? lc($item) : undef; # cache lowcased item
        push @$rec, $numeric ? $item+0 : undef; # cache numeric item
        push @buf, $rec;
    }

    my $sortsub;
    if ($numeric) {
        $sortsub = sub { $reverse * (
            ($a->[2] <=> $b->[2]) ||
                ($ci ? ($a->[1] cmp $b->[1]) : ($a->[0] cmp $b->[0]))) };
    } else {
        $sortsub = sub { $reverse * (
            $ci ? ($a->[1] cmp $b->[1]) : ($a->[0] cmp $b->[0])) };
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

This document describes version 1.55 of Data::Unixish::sort (from Perl distribution Data-Unixish), released on 2016-03-16.

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


=head2 sort(%args) -> [status, msg, result, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Data-Unixish>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

sort(1)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
