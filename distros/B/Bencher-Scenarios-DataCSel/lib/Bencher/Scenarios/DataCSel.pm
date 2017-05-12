package Bencher::Scenarios::DataCSel;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.04'; # VERSION

1;
# ABSTRACT: Scenarios related to Data::CSel

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenarios::DataCSel - Scenarios related to Data::CSel

=head1 VERSION

This document describes version 0.04 of Bencher::Scenarios::DataCSel (from Perl distribution Bencher-Scenarios-DataCSel), released on 2017-01-25.

=head1 DESCRIPTION

This distribution contains the following L<Bencher> scenario modules:

=over

=item * L<Bencher::Scenario::DataCSel::Parsing>

=item * L<Bencher::Scenario::DataCSel::Selection>

=item * L<Bencher::Scenario::DataCSel::Startup>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DataCSel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DataCSel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DataCSel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::CSel>

L<Bencher::Scenarios::MojoDOM> uses roughly equivalent HTML tree datasets so you
can compare the selection speed of Mojo::DOM vs Data::CSel.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
