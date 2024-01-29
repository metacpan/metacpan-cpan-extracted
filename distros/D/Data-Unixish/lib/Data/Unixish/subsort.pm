package Data::Unixish::subsort;

use 5.010;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-23'; # DATE
our $DIST = 'Data-Unixish'; # DIST
our $VERSION = '1.573'; # VERSION

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
        routine_args => {
            summary => 'Pass arguments for Sort::Sub routine',
            schema=>['hash*', of=>'str*'],
            cmdline_aliases => {a=>{}},
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
    my $routine_args = $args{routine_args} // {};
    my $reverse = $args{reverse};
    my $ci      = $args{ci};

    no warnings;
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
    my @buf;

    # special case
    while (my ($index, $item) = each @$in) {
        push @buf, $item;
    }

    require "Sort/Sub/$routine.pm"; ## no critic: Modules::RequireBarewordIncludes
    my $gen_sorter = \&{"Sort::Sub::$routine\::gen_sorter"};
    my $sorter = $gen_sorter->($reverse, $ci, $routine_args);

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

This document describes version 1.573 of Data::Unixish::subsort (from Perl distribution Data-Unixish), released on 2023-09-23.

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

 % echo -e 'a::\nb:\nc::::\nd:::' | dux subsort by_count -a pattern=:
 b:
 a::
 d:::
 c::::

=head1 FUNCTIONS


=head2 subsort

Usage:

 subsort(%args) -> [$status_code, $reason, $payload, \%result_meta]

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

=item * B<routine_args> => I<hash>

Pass arguments for Sort::Sub routine.


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

L<subsort> (from L<App::subsort>)

sort(1)

L<psort> (from L<App::psort>)

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

This software is copyright (c) 2023, 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
