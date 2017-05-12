package Bencher::Scenarios::CPANInstallers;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

1;
# ABSTRACT: Scenarios to benchmark CPAN installers

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenarios::CPANInstallers - Scenarios to benchmark CPAN installers

=head1 VERSION

This document describes version 0.003 of Bencher::Scenarios::CPANInstallers (from Perl distribution Bencher-Scenarios-CPANInstallers), released on 2017-01-25.

=head1 DESCRIPTION

This distribution contains the following L<Bencher> scenario modules:

=over

=item * L<Bencher::Scenario::CPANInstallers::cpanm_local>

=back

=head1 TODO

I very much like to compare L<cpm> vs L<cpanm> when installing against a local
filesystem mirror, but C<cpm> currently needs to resolve using cpanmetadb and
doesn't have the equivalent for C<cpanm>'s C<--mirror-only> option.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-CPANInstallers>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-CPANInstallers>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-CPANInstallers>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
