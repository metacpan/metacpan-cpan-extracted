package Acme::CPANModules::CreatingPaletteOfVisuallyDistinctColors;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-20'; # DATE
our $DIST = 'Acme-CPANModules-CreatingPaletteOfVisuallyDistinctColors'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

my $text = <<'_';
Sometimes you want some colors that are distinct from one another, for example
when drawing line/bar graphs, but don't really care for the exact colors or
don't want to manually pick the colors. Below are some of the alternatives on
CPAN:

<pm:Chart::Colors>

<pm:Color::RGB::Util>'s `rand_rgb_colors()` function.

<pm:ColorTheme::Distinct::WhiteBG> and <pm:ColorTheme::Distinct::BlackBG>.

And below are some other alternatives:

TBD

_

our $LIST = {
    summary => 'Creating a palette of visually distinct colors',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Creating a palette of visually distinct colors

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CreatingPaletteOfVisuallyDistinctColors - Creating a palette of visually distinct colors

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::CreatingPaletteOfVisuallyDistinctColors (from Perl distribution Acme-CPANModules-CreatingPaletteOfVisuallyDistinctColors), released on 2021-01-20.

=head1 DESCRIPTION

Sometimes you want some colors that are distinct from one another, for example
when drawing line/bar graphs, but don't really care for the exact colors or
don't want to manually pick the colors. Below are some of the alternatives on
CPAN:

L<Chart::Colors>

L<Color::RGB::Util>'s C<rand_rgb_colors()> function.

L<ColorTheme::Distinct::WhiteBG> and L<ColorTheme::Distinct::BlackBG>.

And below are some other alternatives:

TBD

=head1 ACME::MODULES ENTRIES

=over

=item * L<Chart::Colors>

=item * L<Color::RGB::Util>

=item * L<ColorTheme::Distinct::WhiteBG>

=item * L<ColorTheme::Distinct::BlackBG>

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

    % cpanmodules ls-entries CreatingPaletteOfVisuallyDistinctColors | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=CreatingPaletteOfVisuallyDistinctColors -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::CreatingPaletteOfVisuallyDistinctColors -E'say $_->{module} for @{ $Acme::CPANModules::CreatingPaletteOfVisuallyDistinctColors::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CreatingPaletteOfVisuallyDistinctColors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CreatingPaletteOfVisuallyDistinctColors>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-CreatingPaletteOfVisuallyDistinctColors/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
