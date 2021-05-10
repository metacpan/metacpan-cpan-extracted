package App::IndonesianBankingUtils;

use 5.010001;

our $DATE = '2021-05-07'; # DATE
our $VERSION = '0.145'; # VERSION

1;
# ABSTRACT: CLIs related to Indonesian banking

__END__

=pod

=encoding UTF-8

=head1 NAME

App::IndonesianBankingUtils - CLIs related to Indonesian banking

=head1 VERSION

This document describes version 0.145 of App::IndonesianBankingUtils (from Perl distribution App-IndonesianBankingUtils), released on 2021-05-07.

=head1

This distribution contains several CLI's related to Indonesian banking:

=over

=item * L<download-bca>

=item * L<download-mandiri>

=item * L<list-bca-branches>

=item * L<list-idn-bank-cards>

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-IndonesianBankingUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Finance::Bank::ID::BCA>

L<Finance::Bank::ID::BPRKS>

L<Finance::Bank::ID::Mandiri>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
