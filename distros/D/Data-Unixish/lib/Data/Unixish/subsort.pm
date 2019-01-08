package Data::Unixish::subsort;

our $DATE = '2019-01-06'; # DATE
our $VERSION = '1.570'; # VERSION

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);

our %SPEC;

$SPEC{subsort} = {
    v => 1.1,
    summary => 'Sort items using Sort::Sub routine',
    args => {
        %common_args,
        routine => {
            summary => 'Sort::Sub routine name',
            schema=>['str*', match=>qr/\A\w+\z/],
            req => 1,
            pos => 0,
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
    },
    tags => [qw/ordering/],
};
sub subsort {
    my %args = @_;
    my ($in, $out) = ($args{in}, $args{out});
    my $routine = $args{routine} or return [400, "Please specify routine"];
    my $reverse = $args{reverse};
    my $ci      = $args{ci};

    no warnings;
    no strict 'refs';
    my @buf;

    # special case
    while (my ($index, $item) = each @$in) {
        push @buf, $item;
    }

    require "Sort/Sub/$routine.pm";
    my $gen_sorter = \&{"Sort::Sub::$routine\::gen_sorter"};
    my $sorter = $gen_sorter->($reverse, $ci);

    @buf = sort {$sorter->($a, $b)} @buf;

    push @$out, $_ for @buf;

    [200, "OK"];
}

1;
# ABSTRACT: Sort items using Sort::Sub routine

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::subsort - Sort items using Sort::Sub routine

=head1 VERSION

This document describes version 1.570 of Data::Unixish::subsort (from Perl distribution Data-Unixish), released on 2019-01-06.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(subsort);
 my @res;
 @res = lduxl([subsort => {routine=>"naturally"}], "t1","t10","t2"); # => ("t1","t2","t10")

In command line:

 % echo -e "t1\nt10\nt2" | dux subsort naturally
 t1
 t2
 t10

=head1 FUNCTIONS


=head2 subsort

Usage:

 subsort(%args) -> [status, msg, payload, meta]

Sort items using Sort::Sub routine.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 0)

Whether to ignore case.

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<reverse> => I<bool> (default: 0)

Whether to reverse sort result.

=item * B<routine>* => I<str>

Sort::Sub routine name.

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

L<subsort> (from L<App::subsort>)

sort(1)

L<psort> (from L<App::psort>)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
