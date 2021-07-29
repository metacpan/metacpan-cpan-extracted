package Acme::CPANModules::NO_COLOR;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-21'; # DATE
our $DIST = 'Acme-CPANModules-NO_COLOR'; # DIST
our $VERSION = '0.008'; # VERSION

our $LIST = {
    summary => "Modules/scripts that follow the NO_COLOR convention",
    description => <<'_',

The NO_COLOR convention (see <https://no-color.org>) lets user disable color
output of console programs by defining an environment variable called NO_COLOR.
The existence of said environment variable, regardless of its value, signals
that programs should not use colored output.

If you know of other modules that should be listed here, please contact me.

_
    entries => [
        {module=>'App::ccdiff', script=>'ccdiff'},
        {module=>'App::Codeowners', script=>'git-codeowners'},
        {module=>'App::DiffTarballs', script=>'diff-tarballs'},
        {module=>'App::HL7::Dump', script=>'hl7dump'},
        {module=>'App::hr', script=>'hr'},
        {module=>'App::Licensecheck', script=>'licensecheck'},
        {module=>'App::riap', script=>'riap'},
        {module=>'App::rsynccolor', script=>'rsynccolor'},
        {module=>'Color::ANSI::Util'},
        # ColorThemeUtil::ANSI does not count
        {module=>'Data::Dump::Color'},
        {module=>'Debug::Print'},
        {module=>'Git::Deploy', script=>'git-deploy'},
        {module=>'Indent::Form'},
        {module=>'Log::Any::Adapter::Screen'},
        {module=>'Log::ger::Output::Screen'},
        {module=>'Parse::Netstat::Colorizer', script=>'cnetstat'},
        {module=>'Proc::ProcessTable::ncps', script=>'ncps'},
        {module=>'Progress::Any::Output::TermProgressBar'},
        {module=>'Search::ESsearcher', script=>'essearcher'},
        {module=>'Spreadsheet::Read', script=>'xls2csv'},
        {module=>'String::Tagged::Terminal'},
        {module=>'Term::ANSIColor'},
        {module=>'Term::ANSIColor::Conditional'},
        {module=>'Term::ANSIColor::Patch::Conditional'},
        {module=>'Term::App::Roles'},
        {module=>'Term::App::Roles::Attrs'},
        {module=>'Term::App::Util::Color'},
        {module=>'Text::CSV_XS', script=>'csvdiff'},
        {module=>'Tree::Shell', script=>'treesh'},
    ],
    links => [
        {url=>'pm:Acme::CPANModules::COLOR'},
        {url=>'pm:Acme::CPANModules::ColorEnv'},
    ],
};

1;
# ABSTRACT: Modules/scripts that follow the NO_COLOR convention

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::NO_COLOR - Modules/scripts that follow the NO_COLOR convention

=head1 VERSION

This document describes version 0.008 of Acme::CPANModules::NO_COLOR (from Perl distribution Acme-CPANModules-NO_COLOR), released on 2021-07-21.

=head1 DESCRIPTION

The NO_COLOR convention (see L<https://no-color.org>) lets user disable color
output of console programs by defining an environment variable called NO_COLOR.
The existence of said environment variable, regardless of its value, signals
that programs should not use colored output.

If you know of other modules that should be listed here, please contact me.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<App::ccdiff> - Colored Character diff

Author: L<HMBRAND|https://metacpan.org/author/HMBRAND>

Script: L<ccdiff>

=item * L<App::Codeowners> - A tool for managing CODEOWNERS files

Author: L<CCM|https://metacpan.org/author/CCM>

Script: L<git-codeowners>

=item * L<App::DiffTarballs> - Diff contents of two tarballs

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<diff-tarballs>

=item * L<App::HL7::Dump> - Base class for hl7dump script.

Author: L<SKIM|https://metacpan.org/author/SKIM>

Script: L<hl7dump>

=item * L<App::hr> - Print horizontal bar on the terminal

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<hr>

=item * L<App::Licensecheck> - functions for a simple license checker for source files

Author: L<JONASS|https://metacpan.org/author/JONASS>

Script: L<licensecheck>

=item * L<App::riap> - Riap command-line client shell

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<riap>

=item * L<App::rsynccolor> - Add some color to rsync output

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<rsynccolor>

=item * L<Color::ANSI::Util> - Routines for dealing with ANSI colors

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Data::Dump::Color> - Like Data::Dump, but with color

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Debug::Print> - Make debugging with print() more awesome

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Git::Deploy>

Author: L<AVAR|https://metacpan.org/author/AVAR>

Script: L<git-deploy>

=item * L<Indent::Form>

Author: L<SKIM|https://metacpan.org/author/SKIM>

=item * L<Log::Any::Adapter::Screen> - Send logs to screen, with colors and some other features

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Log::ger::Output::Screen> - Output log to screen

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Parse::Netstat::Colorizer> - Searches and colorizes the output from Parse::Netstat

Author: L<VVELOX|https://metacpan.org/author/VVELOX>

Script: L<cnetstat>

=item * L<Proc::ProcessTable::ncps> - New Colorized(optional) PS, a enhanced version of PS with advanced searching capabilities

Author: L<VVELOX|https://metacpan.org/author/VVELOX>

Script: L<ncps>

=item * L<Progress::Any::Output::TermProgressBar>

=item * L<Search::ESsearcher> - Provides a handy system for doing templated elasticsearch searches.

Author: L<VVELOX|https://metacpan.org/author/VVELOX>

Script: L<essearcher>

=item * L<Spreadsheet::Read>

Author: L<HMBRAND|https://metacpan.org/author/HMBRAND>

Script: L<xls2csv>

=item * L<String::Tagged::Terminal> - format terminal output using C<String::Tagged>

Author: L<PEVANS|https://metacpan.org/author/PEVANS>

=item * L<Term::ANSIColor> - Color screen output using ANSI escape sequences

Author: L<RRA|https://metacpan.org/author/RRA>

=item * L<Term::ANSIColor::Conditional> - Colorize text only if color is enabled

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Term::ANSIColor::Patch::Conditional> - Colorize text only if color is enabled

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Term::App::Roles> - Collection of roles for terminal-based application

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Term::App::Roles::Attrs>

=item * L<Term::App::Util::Color> - Determine color depth and whether to use color or not

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Text::CSV_XS> - comma-separated values manipulation routines

Author: L<HMBRAND|https://metacpan.org/author/HMBRAND>

Script: L<csvdiff>

=item * L<Tree::Shell> - Navigate and manipulate in-memory tree objects using a CLI shell

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<treesh>

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

 % cpanm-cpanmodules -n NO_COLOR

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries NO_COLOR | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=NO_COLOR -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::NO_COLOR -E'say $_->{module} for @{ $Acme::CPANModules::NO_COLOR::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-NO_COLOR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-NO_COLOR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-NO_COLOR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
