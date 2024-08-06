package App::IndonesianNumberUtils;

use strict;
use 5.010001;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-08-05'; # DATE
our $DIST = 'App-IndonesianNumberUtils'; # DIST
our $VERSION = '0.033'; # VERSION

1;
# ABSTRACT: CLIs related to Indonesian numbers (NIK, NOPPBB, NPWP, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::IndonesianNumberUtils - CLIs related to Indonesian numbers (NIK, NOPPBB, NPWP, etc)

=head1 VERSION

This document describes version 0.033 of App::IndonesianNumberUtils (from Perl distribution App-IndonesianNumberUtils), released on 2024-08-05.

=head1

This distribution contains several CLI's related to Indonesian numbers:

=over

=item 1. L<parse-bpom-reg-code>

=item 2. L<parse-idn-vehicle-plate-number>

=item 3. L<parse-nik>

=item 4. L<parse-nkk>

=item 5. L<parse-nop-pbb>

=item 6. L<parse-npwp>

=item 7. L<parse-pom-reg-code>

=item 8. L<parse-sim>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-IndonesianNumberUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-IndonesianNumberUtils>.

=head1 SEE ALSO

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2023, 2019, 2018, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-IndonesianNumberUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
