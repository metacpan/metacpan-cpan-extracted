package Acme::CPANModules::FooThis;

our $DATE = '2021-05-22'; # DATE
our $VERSION = '0.002'; # VERSION

our $LIST = {
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
};

1;
# ABSTRACT: Export your directory over various channels

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::FooThis - Export your directory over various channels

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::FooThis (from Perl distribution Acme-CPANModules-FooThis), released on 2021-05-22.

=head1 DESCRIPTION

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<App::HTTPThis>

=item * L<App::HTTPSThis>

=item * L<App::DAVThis>

=item * L<App::FTPThis>

=item * L<App::CGIThis>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n FooThis

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries FooThis | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=FooThis -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::FooThis -E'say $_->{module} for @{ $Acme::CPANModules::FooThis::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-FooThis>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-FooThis>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-FooThis/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
