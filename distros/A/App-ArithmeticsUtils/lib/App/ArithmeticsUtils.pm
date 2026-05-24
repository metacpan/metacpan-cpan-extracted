package App::ArithmeticsUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use List::Util qw(max);
use POSIX qw(floor);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-02-26'; # DATE
our $DIST = 'App-ArithmeticsUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to arithmetics',
};

$SPEC{calc_divide_remainder} = {
    v => 1.1,
    summary => 'A simple shortcut to calculate division (a / b) and remainder in one step',
    description => <<'MARKDOWN',

Keywords: modulo

MARKDOWN
    args => {
        a => { schema => 'float*', req=>1, pos=>0 },
        b => { schema => 'float*', req=>1, pos=>1 },
    },
    examples => [
        {argv=>["140", "6"]},
    ],
    result_naked => 1,
    #result => {
    #    schema => [array => elems => ['int*', 'float*']],
    #},
};
sub calc_divide_remainder {
    my %args = @_;
    my $a = $args{a};
    my $b = $args{b};

    my $res = int($a / $b);
    my $remainder = $a - $res*$b;
    [$res, $remainder];
}

1;
# ABSTRACT: Utilities related to arithmetics

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ArithmeticsUtils - Utilities related to arithmetics

=head1 VERSION

This document describes version 0.001 of App::ArithmeticsUtils (from Perl distribution App-ArithmeticsUtils), released on 2026-02-26.

=head1 DESCRIPTION

This distribution provides the following command-line utilities related to
arithmetics:

=over

=item * L<calc-divide-remainder>

=back

=head1 FUNCTIONS


=head2 calc_divide_remainder

Usage:

 calc_divide_remainder(%args) -> any

A simple shortcut to calculate division (a E<sol> b) and remainder in one step.

Examples:

=over

=item * Example #1:

 calc_divide_remainder(a => 140, b => 6); # -> [23, 2]

=back

Keywords: modulo

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a>* => I<float>

(No description)

=item * B<b>* => I<float>

(No description)


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ArithmeticsUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ArithmeticsUtils>.

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ArithmeticsUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
