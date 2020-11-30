package Acme::CPANModules::ModulesThatJustContainData;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-01'; # DATE
our $DIST = 'Acme-CPANModules-ModulesThatJustContainData'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

my $text = <<'_';

Modules under <pm:WordList>::* contain lists of words.
<pm:Games::Word::Wordlist::*> modules also contain lists of words.

Modules under <pm:Tables>::* contains table data.

<pm:DataDist>::* distributions also contain mostly data.

_

our $LIST = {
    summary => 'Modules that just contain data',
    description => $text,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Modules that just contain data

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ModulesThatJustContainData - Modules that just contain data

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::ModulesThatJustContainData (from Perl distribution Acme-CPANModules-ModulesThatJustContainData), released on 2020-06-01.

=head1 DESCRIPTION

Modules under L<WordList>::* contain lists of words.
L<Games::Word::Wordlist::*> modules also contain lists of words.

Modules under L<Tables>::* contains table data.

L<DataDist>::* distributions also contain mostly data.

=head1 INCLUDED MODULES

=over

=item * L<WordList>

=item * L<Tables>

=item * L<DataDist>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries ModulesThatJustContainData | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ModulesThatJustContainData -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ModulesThatJustContainData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ModulesThatJustContainData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ModulesThatJustContainData>

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
