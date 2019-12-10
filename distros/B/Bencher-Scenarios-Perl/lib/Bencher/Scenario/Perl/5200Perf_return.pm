package Bencher::Scenario::Perl::5200Perf_return;

our $DATE = '2019-10-20'; # DATE
our $VERSION = '0.050'; # VERSION

our $scenario = {
    summary => 'Benchmark return() being optimized away',
    default_precision => 0.001,
    participants => [
        {name=>'return', code_template => 'my $var = 1; return $var'},
    ],
};

1;
# ABSTRACT: Benchmark return() being optimized away

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Perl::5200Perf_return - Benchmark return() being optimized away

=head1 VERSION

This document describes version 0.050 of Bencher::Scenario::Perl::5200Perf_return (from Perl distribution Bencher-Scenarios-Perl), released on 2019-10-20.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Perl::5200Perf_return

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

From L<perl5200delta>: In certain situations, when return is the last statement
in a subroutine's main scope, it will be optimized out. This means code like:

 sub baz { return $cat; }

will now behave like:

 sub baz { $cat; }

which is notably faster.

[perl #120765].

=head1 BENCHMARK PARTICIPANTS

=over

=item * return (perl_code)

Code template:

 my $var = 1; return $var



=back

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

L<perl5200delta>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
