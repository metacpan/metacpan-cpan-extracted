package Acme::CPANModules::ColorThemed;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-12-14'; # DATE
our $DIST = 'Acme-CPANModules-ColorThemed'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

our $LIST = {
    summary => "Modules that has color theme support",
    description => <<'_',

**ColorTheme**

Modules which support color themes and follow the <pm:ColorTheme> specification.

<pm:JSON::Color>

<pm:Text::ANSITable>

**Others**

_
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Modules that has color theme support

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ColorThemed - Modules that has color theme support

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::ColorThemed (from Perl distribution Acme-CPANModules-ColorThemed), released on 2020-12-14.

=head1 DESCRIPTION

B<ColorTheme>

Modules which support color themes and follow the L<ColorTheme> specification.

L<JSON::Color>

L<Text::ANSITable>

B<Others>

=head1 ACME::MODULES ENTRIES

=over

=item * L<ColorTheme>

=item * L<JSON::Color>

=item * L<Text::ANSITable>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries ColorThemed | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ColorThemed -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ColorThemed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ColorThemed>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-ColorThemed/issues>

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
