package Data::Unixish::rand;

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);
our $VERSION = '1.570'; # VERSION

our %SPEC;

$SPEC{rand} = {
    v => 1.1,
    summary => 'Generate a stream of random numbers',
    args => {
        %common_args,
        min => {
            summary => 'Minimum possible value (inclusive)',
            schema => ['float*', default=>0],
            cmdline_aliases => { a=>{} },
        },
        max => {
            summary => 'Maximum possible value (inclusive)',
            schema => ['float*', default=>1],
            cmdline_aliases => { b=>{} },
        },
        int => {
            schema => ['bool*', default=>0],
            cmdline_aliases => { i=>{} },
        },
        num => {
            summary => 'Number of numbers to generate, -1 means infinite',
            schema => ['int*', default=>1],
            cmdline_aliases => { n=>{} },
        },
    },
    tags => [qw/datatype:num gen-data/],
    "x.dux.is_stream_output" => 1, # for duxapp < 1.41, will be removed later
    'x.app.dux.is_stream_output' => 1,
};
sub rand {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});

    # XXX schema
    my $min = $args{min} // 0;
    my $max = $args{max} // 1;
    my $int = $args{int};
    my $num = $args{num} // 1;

    my $i = 0;
    while (1) {
        last if $num >= 0 && ++$i > $num;
        my $rand = $min + rand()*($max-$min);
        $rand = sprintf("%.0f", $rand) if $int;
        push @$out, $rand;
    }

    [200, "OK"];
}

1;
# ABSTRACT: Generate a stream of random numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::rand - Generate a stream of random numbers

=head1 VERSION

This document describes version 1.570 of Data::Unixish::rand (from Perl distribution Data-Unixish), released on 2019-01-06.

=head1 SYNOPSIS

In command line:

 % dux rand
 0.0744685671097649

 % dux rand --min 1 --max 10 --num 5 --int
 3
 4
 1
 1
 5

=head1 FUNCTIONS


=head2 rand

Usage:

 rand(%args) -> [status, msg, payload, meta]

Generate a stream of random numbers.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<int> => I<bool> (default: 0)

=item * B<max> => I<float> (default: 1)

Maximum possible value (inclusive).

=item * B<min> => I<float> (default: 0)

Minimum possible value (inclusive).

=item * B<num> => I<int> (default: 1)

Number of numbers to generate, -1 means infinite.

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
