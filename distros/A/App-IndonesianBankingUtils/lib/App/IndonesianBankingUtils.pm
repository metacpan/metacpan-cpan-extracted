package App::IndonesianBankingUtils;

use 5.010001;

our $DATE = '2021-08-26'; # DATE
our $VERSION = '0.146'; # VERSION

1;
# ABSTRACT: CLIs related to Indonesian banking

__END__

=pod

=encoding UTF-8

=head1 NAME

App::IndonesianBankingUtils - CLIs related to Indonesian banking

=head1 VERSION

This document describes version 0.146 of App::IndonesianBankingUtils (from Perl distribution App-IndonesianBankingUtils), released on 2021-08-26.

=head1

This distribution contains several CLI's related to Indonesian banking:

=over

=item * L<download-bca>

=item * L<download-mandiri>

=item * L<list-bca-branches>

=item * L<list-id-bank-cards>

=item * L<list-idn-banks>

=item * L<list-mandiri-branches>

=item * L<parse-bca-account>

=item * L<parse-bca-statement>

=item * L<parse-bprks-statement>

=item * L<parse-mandiri-account>

=item * L<parse-mandiri-statement>

=back



=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-IndonesianBankingUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-IndonesianBankingUtils>.

=head1 SEE ALSO

L<Finance::Bank::ID::BCA>

L<Finance::Bank::ID::BPRKS>

L<Finance::Bank::ID::Mandiri>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-IndonesianBankingUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
