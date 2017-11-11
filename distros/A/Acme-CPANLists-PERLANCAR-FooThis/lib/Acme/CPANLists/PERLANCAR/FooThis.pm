package Acme::CPANLists::PERLANCAR::FooThis;

our $DATE = '2017-11-10'; # DATE
our $VERSION = '0.002'; # VERSION

our @Module_Lists = (
    {
        summary => "Export your directory over various channels",
        entries => [
            {
                module => 'App::HTTPThis',
                script => 'http_this',
            },
            {
                module => 'App::HTTPSThis',
                script => 'https_this',
            },
            {
                module => 'App::DAVThis',
                script => 'dav_this',
            },
            {
                module => 'App::FTPThis',
                script => 'ftp_this',
            },
            {
                module => 'App::CGIThis',
                script => 'cgi_this',
            },
        ],
    },
);

1;
# ABSTRACT: Export your directory over various channels

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::FooThis - Export your directory over various channels

=head1 VERSION

This document describes version 0.002 of Acme::CPANLists::PERLANCAR::FooThis (from Perl distribution Acme-CPANLists-PERLANCAR-FooThis), released on 2017-11-10.

=head1 DESCRIPTION

=head1 MODULE LISTS

=head2 Export your directory over various channels

=over

=item * L<App::HTTPThis>

=item * L<App::HTTPSThis>

=item * L<App::DAVThis>

=item * L<App::FTPThis>

=item * L<App::CGIThis>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANLists-PERLANCAR-FooThis>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANLists-PERLANCAR-FooThis>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANLists-PERLANCAR-FooThis>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANLists> - about the Acme::CPANLists namespace

L<acme-cpanlists> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
