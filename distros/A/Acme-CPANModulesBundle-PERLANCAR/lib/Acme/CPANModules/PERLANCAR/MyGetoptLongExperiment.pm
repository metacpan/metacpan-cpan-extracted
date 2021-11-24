package Acme::CPANModules::PERLANCAR::MyGetoptLongExperiment;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-09'; # DATE
our $DIST = 'Acme-CPANModulesBundle-PERLANCAR'; # DIST
our $VERSION = '0.009'; # VERSION

our $LIST = {
    summary => 'My experiments writing Getopt::Long replacements/alternatives',
    description => <<'_',

Most of these modules provide a <pm:Getopt::Long>-compatible interface, but they
differ in some aspect: either they offer more features (or less).

_
    entries => [
        {module => 'Getopt::Long::Less'},
        {module => 'Getopt::Long::EvenLess'},
        {module => 'Getopt::Long::More'},
        {module => 'Getopt::Long::Complete'},

        {module => 'Getopt::Long::Subcommand'},

        {module => 'Getopt::Panjang'},
    ],
};

1;
# ABSTRACT: My experiments writing Getopt::Long replacements/alternatives

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::MyGetoptLongExperiment - My experiments writing Getopt::Long replacements/alternatives

=head1 VERSION

This document describes version 0.009 of Acme::CPANModules::PERLANCAR::MyGetoptLongExperiment (from Perl distribution Acme-CPANModulesBundle-PERLANCAR), released on 2021-11-09.

=head1 DESCRIPTION

Most of these modules provide a L<Getopt::Long>-compatible interface, but they
differ in some aspect: either they offer more features (or less).

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Getopt::Long::Less> - Like Getopt::Long, but with less features

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Getopt::Long::EvenLess> - Like Getopt::Long::Less, but with even less features

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Getopt::Long::More> - Like Getopt::Long, but with more stuffs

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Getopt::Long::Complete> - A drop-in replacement for Getopt::Long, with shell tab completion

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Getopt::Long::Subcommand> - Process command-line options, with subcommands and completion

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Getopt::Panjang> - Parse command-line options

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

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

 % cpanm-cpanmodules -n PERLANCAR::MyGetoptLongExperiment

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries PERLANCAR::MyGetoptLongExperiment | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PERLANCAR::MyGetoptLongExperiment -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PERLANCAR::MyGetoptLongExperiment -E'say $_->{module} for @{ $Acme::CPANModules::PERLANCAR::MyGetoptLongExperiment::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModulesBundle-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModulesBundle-PERLANCAR>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

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

This software is copyright (c) 2021, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModulesBundle-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
