package Acme::CPANModules::Org;

our $DATE = '2020-01-12'; # DATE
our $VERSION = '0.003'; # VERSION

our $LIST = {
    summary => "Modules related to Org format",
    description => <<'_',


_
    entries => [
        {module=>'App::org2wp'},
        {module=>'App::orgsel'},
        {module=>'App::OrgUtils'},
        {module=>'Data::CSel'},
        {module=>'Data::Dmp::Org'},
        {module=>'Org::Dump'},
        {module=>'Org::Examples'},
        {module=>'Org::Parser'},
        {module=>'Org::Parser::Tiny'},
        {module=>'Org::To::HTML'},
        {module=>'Org::To::HTML::WordPress'},
        {module=>'Org::To::Pod'},
        {module=>'Org::To::Text'},
        {module=>'Org::To::VCF'},
        {module=>'Text::Table::Org'},
    ],
};

1;
# ABSTRACT: Modules related to Org format

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Org - Modules related to Org format

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::Org (from Perl distribution Acme-CPANModules-Org), released on 2020-01-12.

=head1 DESCRIPTION

Modules related to Org format.

=head1 INCLUDED MODULES

=over

=item * L<App::org2wp>

=item * L<App::orgsel>

=item * L<App::OrgUtils>

=item * L<Data::CSel>

=item * L<Data::Dmp::Org>

=item * L<Org::Dump>

=item * L<Org::Examples>

=item * L<Org::Parser>

=item * L<Org::Parser::Tiny>

=item * L<Org::To::HTML>

=item * L<Org::To::HTML::WordPress>

=item * L<Org::To::Pod>

=item * L<Org::To::Text>

=item * L<Org::To::VCF>

=item * L<Text::Table::Org>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries Org | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Org -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Org>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Org>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Org>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://orgmode.org>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
