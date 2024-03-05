package Acme::CPANModules::RandomText;

use strict;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-17'; # DATE
our $DIST = 'Acme-CPANModules-RandomText'; # DIST
our $VERSION = '0.001'; # VERSION

my $text = <<'_';

For "lorem ipsum"-style text, see <pm:Text::Lorem> and its variants mentioned in
the Acme::CPANModules::LoremIpsum list.

<pm:Acme::ConspiracyTheory::Random>

Keywords: lorem ipsum, lipsum

_

our $LIST = {
    summary => 'List of modules for generating random (placeholder) text',
    description => $text,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules for generating random (placeholder) text

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::RandomText - List of modules for generating random (placeholder) text

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::RandomText (from Perl distribution Acme-CPANModules-RandomText), released on 2023-11-17.

=head1 DESCRIPTION

For "lorem ipsum"-style text, see L<Text::Lorem> and its variants mentioned in
the Acme::CPANModules::LoremIpsum list.

L<Acme::ConspiracyTheory::Random>

Keywords: lorem ipsum, lipsum

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Text::Lorem>

Author: L<ADEOLA|https://metacpan.org/author/ADEOLA>

=item L<Acme::ConspiracyTheory::Random>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

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

 % cpanm-cpanmodules -n RandomText

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries RandomText | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=RandomText -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::RandomText -E'say $_->{module} for @{ $Acme::CPANModules::RandomText::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-RandomText>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-RandomText>.

=head1 SEE ALSO

L<Acme::CPANModules::LoremIpsum>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-RandomText>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
