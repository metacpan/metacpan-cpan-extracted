package Acme::CPANModules::ModifiedHashes;

use strict;

use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-10'; # DATE
our $DIST = 'Acme-CPANModules-ModifiedHashes'; # DIST
our $VERSION = '0.001'; # VERSION

my $text = <<'MARKDOWN';
These modules allow you to create hashes that don't behave like a normal Perl hash.


**Accessing hash values using approximate keys (fuzzy hash)**

<pm:Tie::Hash::Approx>


**Allowing key aliases (multiple keys that refer to the same value)**

<pm:Tie::Alias::Hash>

<pm:Tie::Hash::Abbrev>


**Allowing multiple keys (list of keys)**

<pm:Tie::Hash::MultiKey>


**Allowing references as keys**

<pm:Hash::ExtendedKeys>


**Case-insensitive hash keys**

<pm:Tie::CPHash>


**Encrypting values**

<pm:Tie::EncryptedHash>


**Ordered**

There are several modules that provide ordered hash, see separate list mentioned
in SEE ALSO section.


**Remembering keys only temporarily**

Keywords: cache

<pm:Tie::Hash::Expire>


**Remembering only a certain number of keys**

Keywords: cache

<pm:Tie::CacheHash>

<pm:Tie::Cache>

<pm:Tie::Cache::LRU>


**Restricted keys**

Hashes that only allow certain keys and not others.

<pm:Hash::RestrictedKeys>


**Using regular expressions as hash keys**

<pm:Tie::RegexpHash>

<pm:Tie::Hash::Regex>

<pm:Tie::Hash::RegexKeys>


**Others**

<pm:Tie::Hash::Log>

<pm:Tie::Hash::NoOp>

MARKDOWN

our $LIST = {
    summary => "List of modules that provide hashes with modified behaviors",
    description => $text,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description();

1;
# ABSTRACT: List of modules that provide hashes with modified behaviors

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ModifiedHashes - List of modules that provide hashes with modified behaviors

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::ModifiedHashes (from Perl distribution Acme-CPANModules-ModifiedHashes), released on 2024-07-10.

=head1 DESCRIPTION

These modules allow you to create hashes that don't behave like a normal Perl hash.

B<Accessing hash values using approximate keys (fuzzy hash)>

L<Tie::Hash::Approx>

B<Allowing key aliases (multiple keys that refer to the same value)>

L<Tie::Alias::Hash>

L<Tie::Hash::Abbrev>

B<Allowing multiple keys (list of keys)>

L<Tie::Hash::MultiKey>

B<Allowing references as keys>

L<Hash::ExtendedKeys>

B<Case-insensitive hash keys>

L<Tie::CPHash>

B<Encrypting values>

L<Tie::EncryptedHash>

B<Ordered>

There are several modules that provide ordered hash, see separate list mentioned
in SEE ALSO section.

B<Remembering keys only temporarily>

Keywords: cache

L<Tie::Hash::Expire>

B<Remembering only a certain number of keys>

Keywords: cache

L<Tie::CacheHash>

L<Tie::Cache>

L<Tie::Cache::LRU>

B<Restricted keys>

Hashes that only allow certain keys and not others.

L<Hash::RestrictedKeys>

B<Using regular expressions as hash keys>

L<Tie::RegexpHash>

L<Tie::Hash::Regex>

L<Tie::Hash::RegexKeys>

B<Others>

L<Tie::Hash::Log>

L<Tie::Hash::NoOp>

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Tie::Hash::Approx>

Author: L<BRIAC|https://metacpan.org/author/BRIAC>

=item L<Tie::Alias::Hash>

Author: L<DAVIDNICO|https://metacpan.org/author/DAVIDNICO>

=item L<Tie::Hash::Abbrev>

Author: L<FANY|https://metacpan.org/author/FANY>

=item L<Tie::Hash::MultiKey>

Author: L<MIKER|https://metacpan.org/author/MIKER>

=item L<Hash::ExtendedKeys>

Author: L<LNATION|https://metacpan.org/author/LNATION>

=item L<Tie::CPHash>

Author: L<CJM|https://metacpan.org/author/CJM>

=item L<Tie::EncryptedHash>

Author: L<VIPUL|https://metacpan.org/author/VIPUL>

=item L<Tie::Hash::Expire>

Author: L<JEFFY|https://metacpan.org/author/JEFFY>

=item L<Tie::CacheHash>

Author: L<JAMCC|https://metacpan.org/author/JAMCC>

=item L<Tie::Cache>

Author: L<CHAMAS|https://metacpan.org/author/CHAMAS>

=item L<Tie::Cache::LRU>

Author: L<MSCHWERN|https://metacpan.org/author/MSCHWERN>

=item L<Hash::RestrictedKeys>

Author: L<LNATION|https://metacpan.org/author/LNATION>

=item L<Tie::RegexpHash>

Author: L<ALTREUS|https://metacpan.org/author/ALTREUS>

=item L<Tie::Hash::Regex>

Author: L<DAVECROSS|https://metacpan.org/author/DAVECROSS>

=item L<Tie::Hash::RegexKeys>

Author: L<FDULAU|https://metacpan.org/author/FDULAU>

=item L<Tie::Hash::Log>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Tie::Hash::NoOp>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=back

=head1 BENCHMARK NOTES

L<Hash::Ordered> has strong performance in iterating and returning keys, while
L<List::Unique::DeterministicOrder> is strong in insertion and deletion (or
L<Tie::Hash::Indexed> if you're looking for actual hash type).

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n ModifiedHashes

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries ModifiedHashes | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ModifiedHashes -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::ModifiedHashes -E'say $_->{module} for @{ $Acme::CPANModules::ModifiedHashes::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ModifiedHashes>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ModifiedHashes>.

=head1 SEE ALSO

L<Acme::CPANModules::OrderedHash>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ModifiedHashes>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
