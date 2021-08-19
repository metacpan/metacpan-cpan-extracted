package Acme::CPANModules::PortedFrom::Go;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-03-15'; # DATE
our $DIST = 'Acme-CPANModules-PortedFrom-Go'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "Modules/applications that are ported from (or inspired by) ".
        "Go",
    description => <<'_',

If you know of others, please drop me a message.

_
    entries => [
        {
            module => 'Getopt::Kingpin',
            summary => 'kingpin',
        },
    ],
};

1;
# ABSTRACT: Modules/applications that are ported from (or inspired by) Go

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PortedFrom::Go - Modules/applications that are ported from (or inspired by) Go

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::PortedFrom::Go (from Perl distribution Acme-CPANModules-PortedFrom-Go), released on 2021-03-15.

=head1 DESCRIPTION

If you know of others, please drop me a message.

=head1 ACME::MODULES ENTRIES

=over

=item * L<Getopt::Kingpin> - kingpin

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanmodules> CLI (from
L<App::cpanmodules> distribution):

    % cpanmodules ls-entries PortedFrom::Go | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PortedFrom::Go -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PortedFrom::Go -E'say $_->{module} for @{ $Acme::CPANModules::PortedFrom::Go::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PortedFrom-Go>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PortedFrom-Go>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-PortedFrom-Go/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

More on the same theme of modules ported from other languages:
L<Acme::CPANModules::PortedFrom::Clojure>,
L<Acme::CPANModules::PortedFrom::Java>,
L<Acme::CPANModules::PortedFrom::NPM>,
L<Acme::CPANModules::PortedFrom::PHP>,
L<Acme::CPANModules::PortedFrom::Python>,
L<Acme::CPANModules::PortedFrom::Ruby>.

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
