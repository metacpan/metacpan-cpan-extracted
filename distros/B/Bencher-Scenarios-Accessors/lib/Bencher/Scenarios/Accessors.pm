package Bencher::Scenarios::Accessors;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.14'; # VERSION

1;
# ABSTRACT: Scenarios to benchmark class accessors

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenarios::Accessors - Scenarios to benchmark class accessors

=head1 VERSION

This document describes version 0.14 of Bencher::Scenarios::Accessors (from Perl distribution Bencher-Scenarios-Accessors), released on 2017-01-25.

=head1 DESCRIPTION

This distribution contains the following L<Bencher> scenario modules:

=over

=item * L<Bencher::Scenario::Accessors::ClassStartup>

=item * L<Bencher::Scenario::Accessors::Construction>

=item * L<Bencher::Scenario::Accessors::Set>

=item * L<Bencher::Scenario::Accessors::GeneratorStartup>

=item * L<Bencher::Scenario::Accessors::Get>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Accessors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Accessors>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Accessors>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

The L<Benchmark::Perl::Formance> distribution contains various benchmarks, in
particular the C<Benchmark::Perl::Formance::Plugin::Accessors*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
