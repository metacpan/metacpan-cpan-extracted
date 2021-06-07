package Acme::CPANModules::NO_COLOR;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-09'; # DATE
our $DIST = 'Acme-CPANModules-NO_COLOR'; # DIST
our $VERSION = '0.005'; # VERSION

our $LIST = {
    summary => "Modules that follow the NO_COLOR convention",
    description => <<'_',

The NO_COLOR convention (see https://no-color.org) lets user disable color
output of console programs by defining an environment variable called NO_COLOR.
The existence of said environment variable, regardless of its value, signals
that programs should not use colored output.

If you know of other modules that should be listed here, please contact me.

_
    entries => [
        {module=>'App::DiffTarballs'},
        {module=>'App::hr'},
        {module=>'Color::ANSI::Util'},
        {module=>'Data::Dump::Color'},
        {module=>'Debug::Print'},
        {module=>'Log::Any::Adapter::Screen'},
        {module=>'Log::ger::Output::Screen'},
        {module=>'Progress::Any::Output::TermProgressBar'},
        {module=>'Term::ANSIColor::Conditional'},
        {module=>'Term::ANSIColor::Patch::Conditional'},
        {module=>'Term::App::Roles'},
        {module=>'Text::ANSITable'},
    ],
    links => [
        {url=>'pm:Acme::CPANModules::COLOR'},
        {url=>'pm:Acme::CPANModules::ColorEnv'},
    ],
};

1;
# ABSTRACT: Modules that follow the NO_COLOR convention

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::NO_COLOR - Modules that follow the NO_COLOR convention

=head1 VERSION

This document describes version 0.005 of Acme::CPANModules::NO_COLOR (from Perl distribution Acme-CPANModules-NO_COLOR), released on 2021-05-09.

=head1 DESCRIPTION

The NO_COLOR convention (see https://no-color.org) lets user disable color
output of console programs by defining an environment variable called NO_COLOR.
The existence of said environment variable, regardless of its value, signals
that programs should not use colored output.

If you know of other modules that should be listed here, please contact me.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<App::DiffTarballs>

=item * L<App::hr>

=item * L<Color::ANSI::Util>

=item * L<Data::Dump::Color>

=item * L<Debug::Print>

=item * L<Log::Any::Adapter::Screen>

=item * L<Log::ger::Output::Screen>

=item * L<Progress::Any::Output::TermProgressBar>

=item * L<Term::ANSIColor::Conditional>

=item * L<Term::ANSIColor::Patch::Conditional>

=item * L<Term::App::Roles>

=item * L<Text::ANSITable>

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
