package Bencher::Scenarios::DataSah;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.07'; # VERSION

1;
# ABSTRACT: A collection of bencher scenarios to benchmark Data::Sah

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenarios::DataSah - A collection of bencher scenarios to benchmark Data::Sah

=head1 VERSION

This document describes version 0.07 of Bencher::Scenarios::DataSah (from Perl distribution Bencher-Scenarios-DataSah), released on 2017-01-25.

=head1 DESCRIPTION

This distribution contains the following L<Bencher> scenario modules:

=over

=item * L<Bencher::Scenario::DataSah::extract_subschemas>

=item * L<Bencher::Scenario::DataSah::gen_coercer>

=item * L<Bencher::Scenario::DataSah::Validate>

=item * L<Bencher::Scenario::DataSah::normalize_schema>

=item * L<Bencher::Scenario::DataSah::Coerce>

=item * L<Bencher::Scenario::DataSah::gen_validator>

=item * L<Bencher::Scenario::DataSah::Startup>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataSah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-DataSah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataSah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah>

L<Bencher::Scenarios::DataSahVSTypeTiny> - split to keep the number of
benchmarks for a single distribution small (and minimize building time).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
