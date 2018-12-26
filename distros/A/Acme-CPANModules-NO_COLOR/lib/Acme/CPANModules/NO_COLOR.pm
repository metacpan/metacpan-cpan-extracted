package Acme::CPANModules::NO_COLOR;

our $DATE = '2018-12-22'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "Modules that follow the NO_COLOR convention",
    description => <<'_',

The NO_COLOR convention (see https://no-color.org) lets user disable color
output of console programs by defining an environment variable called NO_COLOR.
The existence of said environment variable, regardless of its value, signals
that programs should not use colored output.

_
    entries => [
        {module=>'Color::ANSI::Util'},
        {module=>'Data::Dump::Color'},
        {module=>'Debug::Print'},
        {module=>'Term::ANSIColor::Conditional'},
        {module=>'Term::ANSIColor::Patch::Conditional'},
        {module=>'Term::App::Roles'},
        {module=>'Text::ANSITable'},
    ],
    links => [
        {url=>'pm:Acme::CPANModules::NO_COLOR::NonCompliant'},
        {url=>'pm:Acme::CPANModules::COLOR'},
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

This document describes version 0.001 of Acme::CPANModules::NO_COLOR (from Perl distribution Acme-CPANModules-NO_COLOR), released on 2018-12-22.

=head1 DESCRIPTION

Modules that follow the NO_COLOR convention.

The NO_COLOR convention (see https://no-color.org) lets user disable color
output of console programs by defining an environment variable called NO_COLOR.
The existence of said environment variable, regardless of its value, signals
that programs should not use colored output.

=head1 INCLUDED MODULES

=over

=item * L<Color::ANSI::Util>

=item * L<Data::Dump::Color>

=item * L<Debug::Print>

=item * L<Term::ANSIColor::Conditional>

=item * L<Term::ANSIColor::Patch::Conditional>

=item * L<Term::App::Roles>

=item * L<Text::ANSITable>

=back

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

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
