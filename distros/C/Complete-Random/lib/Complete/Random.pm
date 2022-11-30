package Complete::Random;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-08'; # DATE
our $DIST = 'Complete-Random'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(
                       complete_random_string
               );


our %SPEC;

$SPEC{complete_random_string} = {
    v => 1.1,
    summary => 'Complete from a list of random string',
    args => {
        len => {
            summary => 'Length of random string to produce',
            schema => 'int*',
            default => 10,
        },
        num => {
            summary => 'Number of random string answers to generate',
            description => <<'_',

Will observe `COMPLETE_RANDOM_STRING_NUM` environment variable for the default,
or fall back to 50.

_
        },
    },
};
sub complete_random_string {
    require Complete::Util;

    my %args = @_;
    my $len = $args{len} // 10;
    my $num = $args{num} // $ENV{COMPLETE_RANDOM_STRING_NUM} // 50;

    my @ary;
    for (1..$num) {
        my $str = join('', map {chr(65+rand(26))} 1..$len);
        push @ary, $str;
    }

    Complete::Util::complete_array_elem(
        array => \@ary,
        word => $args{word},
    );
}

1;
# ABSTRACT: Complete from a list of random string

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Random - Complete from a list of random string

=head1 VERSION

This document describes version 0.001 of Complete::Random (from Perl distribution Complete-Random), released on 2022-09-08.

=head1 DESCRIPTION

This module is mainly for testing.

=head1 FUNCTIONS


=head2 complete_random_string

Usage:

 complete_random_string(%args) -> [$status_code, $reason, $payload, \%result_meta]

Complete from a list of random string.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<len> => I<int> (default: 10)

Length of random string to produce.

=item * B<num> => I<any>

Number of random string answers to generate.

Will observe C<COMPLETE_RANDOM_STRING_NUM> environment variable for the default,
or fall back to 50.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=for Pod::Coverage .+

=head1 ENVIRONMENT

=head2 COMPLETE_RANDOM_STRING_NUM

Uint. Number of completion answers to produce.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Random>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Random>.

=head1 SEE ALSO

L<Complete>

Other C<Complete::*> modules.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Random>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
