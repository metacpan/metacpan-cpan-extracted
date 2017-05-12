package Bencher::Scenarios::AppHr;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.02'; # VERSION

1;
# ABSTRACT: A collection of scenarios to benchmark App::hr

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenarios::AppHr - A collection of scenarios to benchmark App::hr

=head1 VERSION

This document describes version 0.02 of Bencher::Scenarios::AppHr (from Perl distribution Bencher-Scenarios-AppHr), released on 2017-01-25.

=head1 DESCRIPTION

This distribution contains the following L<Bencher> scenario modules:

=over

=item * L<Bencher::Scenario::AppHr::Runtime>

=item * L<Bencher::Scenario::AppHr::Completion>

=back

L<hr> from L<App::hr> is an example of a simple
L<Perinci::CmdLine::Inline>-based application which I benchmark to give a rough
idea of the minimal/baseline startup overhead a Perinci::CmdLine application can
have.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-AppHr>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-AppHr>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-AppHr>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::hr>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
