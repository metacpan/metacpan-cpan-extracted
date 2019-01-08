package Data::Unixish::tail;

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

our $VERSION = '1.570'; # VERSION

use Data::Unixish::Util qw(%common_args);

our %SPEC;

$SPEC{tail} = {
    v => 1.1,
    summary => 'Output the last items of data',
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
sub tail {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});
    my $n = $args{items} // 10;

    # maintain temporary buffer first
    my @buf;

    while (my ($index, $item) = each @$in) {
        push @buf, $item;
        shift @buf if @buf > $n;
    }

    # push buffer to out
    push @$out, $_ for @buf;

    [200, "OK"];
}

1;
# ABSTRACT: Output the last items of data

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::tail - Output the last items of data

=head1 VERSION

This document describes version 1.570 of Data::Unixish::tail (from Perl distribution Data-Unixish), released on 2019-01-06.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res;
 @res = lduxl(tail => (1..100)); # => (91..100)
 @res = lduxl([tail => {items=>3}], (1..100)); # => (98, 99, 100)

In command line:

 % seq 1 100 | dux tail --format=text-simple -n 5
 96
 97
 98
 99
 100

=head1 FUNCTIONS


=head2 tail

Usage:

 tail(%args) -> [status, msg, payload, meta]

Output the last items of data.

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

=head1 SEE ALSO

tail(1)

L<Data::Unixish::head>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
