package App::StatisticsUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-15'; # DATE
our $DIST = 'App-StatisticsUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'CLI utilities related to statistics',
};

$SPEC{z2pct} = {
    v => 1.1,
    summary => 'Convert z-score to percentile (for standard normal distribution)',
    args_as => 'array',
    args => {
        z => {
            schema => 'float*',
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
    examples => [
        {
            args => {z=>0},
            result => 50,
        },
    ],
};
sub z2pct {
    require Statistics::Standard_Normal;
    Statistics::Standard_Normal::z_to_pct(shift);
}

$SPEC{pct2z} = {
    v => 1.1,
    summary => 'Convert percentile to z-score (for standard normal distribution)',
    args_as => 'array',
    args => {
        pct => {
            schema => ['float*', xbetween=>[0,100]],
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
    examples => [
        {
            args => {pct=>50},
            result => 0,
        },
    ],
};
sub pct2z {
    require Statistics::Standard_Normal;
    Statistics::Standard_Normal::pct_to_z(shift);
}

1;
# ABSTRACT: CLI utilities related to statistics

__END__

=pod

=encoding UTF-8

=head1 NAME

App::StatisticsUtils - CLI utilities related to statistics

=head1 VERSION

This document describes version 0.001 of App::StatisticsUtils (from Perl distribution App-StatisticsUtils), released on 2021-01-15.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<pct2z>

=item * L<z2pct>

=back

=head1 FUNCTIONS


=head2 pct2z

Usage:

 pct2z($pct) -> any

Convert percentile to z-score (for standard normal distribution).

Examples:

=over

=item * Example #1:

 pct2z(50); # -> 0

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$pct>* => I<float>


=back

Return value:  (any)



=head2 z2pct

Usage:

 z2pct($z) -> any

Convert z-score to percentile (for standard normal distribution).

Examples:

=over

=item * Example #1:

 z2pct(0); # -> 50

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$z>* => I<float>


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-StatisticsUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-StatisticsUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-StatisticsUtils/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
