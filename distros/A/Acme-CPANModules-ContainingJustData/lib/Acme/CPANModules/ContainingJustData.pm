package Acme::CPANModules::ContainingJustData;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-22'; # DATE
our $DIST = 'Acme-CPANModules-ContainingJustData'; # DIST
our $VERSION = '0.002'; # VERSION

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

Acme::CPANModules::ContainingJustData - Modules that just contain data

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::ContainingJustData (from Perl distribution Acme-CPANModules-ContainingJustData), released on 2020-11-22.

=head1 DESCRIPTION

Modules under L<WordList>::* contain lists of words.
L<Games::Word::Wordlist::*> modules also contain lists of words.

Modules under L<Tables>::* contains table data.

L<DataDist>::* distributions also contain mostly data.

=head1 MODULES INCLUDED IN THIS ACME::CPANMODULES MODULE

=over

=item * L<WordList>

=item * L<Tables>

=item * L<DataDist>

=back

=head1 FAQ

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanmodules> CLI (from
L<App::cpanmodules> distribution):

    % cpanmodules ls-entries ContainingJustData | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ContainingJustData -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::ContainingJustData -E'say $_->{module} for @{ $Acme::CPANModules::ContainingJustData::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ContainingJustData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ContainingJustData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ContainingJustData>

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
