package Acme::CPANModules::DescribeAModuleBadly;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-23'; # DATE
our $DIST = 'Acme-CPANModules-DescribeAModuleBadly'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'The Acme::CPANModules::DescribeAModuleBadly namespace',
    description => <<'_',

Acme::CPANModules::DescribeAModuleBadly::* modules should contain lists of
modules that are being described badly. Inspired by Jimmy Fallon's Twitter
hashtag #DescribeAMovieBadly (Feb 4, 2020), the idea is to give an accurate
description of a certain element or aspect of the module but somehow miss the
whole point of it.

_
    entries => [
    ],
};

1;
# ABSTRACT: The Acme::CPANModules::DescribeAModuleBadly namespace

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::DescribeAModuleBadly - The Acme::CPANModules::DescribeAModuleBadly namespace

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::DescribeAModuleBadly (from Perl distribution Acme-CPANModules-DescribeAModuleBadly), released on 2020-02-23.

=head1 DESCRIPTION

The Acme::CPANModules::DescribeAModuleBadly namespace.

Acme::CPANModules::DescribeAModuleBadly::* modules should contain lists of
modules that are being described badly. Inspired by Jimmy Fallon's Twitter
hashtag #DescribeAMovieBadly (Feb 4, 2020), the idea is to give an accurate
description of a certain element or aspect of the module but somehow miss the
whole point of it.

=head1 INCLUDED MODULES

=over

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries DescribeAModuleBadly | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=DescribeAModuleBadly -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-DescribeAModuleBadly>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-DescribeAModuleBadly>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-DescribeAModuleBadly>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
