package Bencher::Scenario::Perl::5220Perf_length;

our $DATE = '2016-03-15'; # DATE
our $VERSION = '0.04'; # VERSION

our $scenario = {
    summary => 'Benchmark hash lookup',
    default_precision => 0.001,
    participants => [
        {name=>'length100', code_template => 'use bytes; my $str = <str>; for(1..100) { my $len = length($str) }' },
    ],
    datasets => [
        {name=>'str100', args => {str=>'abcd' x 25}},
    ],
};

1;
# ABSTRACT: Benchmark hash lookup

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Perl::5220Perf_length - Benchmark hash lookup

=head1 VERSION

This document describes version 0.04 of Bencher::Scenario::Perl::5220Perf_length (from Perl distribution Bencher-Scenarios-Perl), released on 2016-03-15.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Perl::5220Perf_length

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 BENCHMARK PARTICIPANTS

=over

=item * length100 (perl_code)

Code template:

 use bytes; my $str = <str>; for(1..100) { my $len = length($str) }



=back

=head1 BENCHMARK DATASETS

=over

=item * str100

=back

=head1 DESCRIPTION

From L<perl5220delta>: There is a performance improvement of up to 20% when
length is applied to a non-magical, non-tied string, and either use bytes is in
scope or the string doesn't use UTF-8 internally.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<perl5220delta>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
