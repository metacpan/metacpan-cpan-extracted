package Acme::CPANModules::GrepVariants;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-16'; # DATE
our $DIST = 'Acme-CPANModules-GrepVariants'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

my $description = <<'_';
**Improvements**

Created in 2005 by Andy Lester, <pm:ack> is the granddaddy of grep-like programs
that try to improve the experience of using grep to search for text in source
code. ack skips VCS directories like `.git` or `.svn`, and understands file
types so it doesn't look into giant `.mp4`s and other binaries by default. ack
has spurred the development of other ack improvements (mostly in speed aspect)
like The Silver Searcher (`ag`) or `ripgrep`. `git` also now includes a
`git-grep` utility. ack has a website: <https://beyondgrep.com>. See also
<https://betterthanack.com>.

<pm:App::Greple> and <pm:App::abgrep> try to make searching for multiple
patterns in grep easier. To search for all 'foo' and 'bar' in grep in no
particular order, you either have to do something like:

    % grep --color=always foo FILES | grep bar

or:

    % grep -P 'foo.*bar|bar.*foo' FILES

both of which get unwieldy if the number of patterns get higher. Or you can use
look-ahead:

    % grep -P '(?=.*foo)(?=.*bar)' FILES

but this does not capture (thus highlight) the patterns.

Note that searching for multiple patterns in particular order ('foo.*bar'), or
searching for aternates from multiple patterns ('foo|bar') is no problem in
grep.

greple also has a few other tricks up its sleeve, like configuration file to
define complex regexes, matching across lines, and Japanese text support.

Instead of specifying a pattern, with <pm:App::rpgrep> you can specify a pattern
name in a <pm:Regexp::Pattern>::* module instead.

**Reimplementations**

grep for <pm:PerlPowerTools> simply tries to reimplement grep in Perl, as part
of the project to reimplement many Unix utilities in Perl. It has few practical
uses.

**Searching Perl source code**

<pm:App::pmgrep> lets you grep over locally installed Perl modules. It's
basically a shortcut for something like this:

    % pmlist -Rx | grep PAT
    % grep PAT `pmlist -Rx`

<pm:App::Grepl> uses <pm:PPI> to let you grep over Perl *documents*; it allows
you to do things like: search only in Perl code comments or inside string
literals.

**Searching other than files: **

TODO

_

our $LIST = {
    summary => 'Grep-like CLI utilities available on CPAN',
    description => $description,
    entries => [
    ],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Grep-like CLI utilities available on CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::GrepVariants - Grep-like CLI utilities available on CPAN

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::GrepVariants (from Perl distribution Acme-CPANModules-GrepVariants), released on 2020-04-16.

=head1 DESCRIPTION

Grep-like CLI utilities available on CPAN.

B<Improvements>

Created in 2005 by Andy Lester, L<ack> is the granddaddy of grep-like programs
that try to improve the experience of using grep to search for text in source
code. ack skips VCS directories like C<.git> or C<.svn>, and understands file
types so it doesn't look into giant C<.mp4>s and other binaries by default. ack
has spurred the development of other ack improvements (mostly in speed aspect)
like The Silver Searcher (C<ag>) or C<ripgrep>. C<git> also now includes a
C<git-grep> utility. ack has a website: L<https://beyondgrep.com>. See also
L<https://betterthanack.com>.

L<App::Greple> and L<App::abgrep> try to make searching for multiple
patterns in grep easier. To search for all 'foo' and 'bar' in grep in no
particular order, you either have to do something like:

 % grep --color=always foo FILES | grep bar

or:

 % grep -P 'foo.*bar|bar.*foo' FILES

both of which get unwieldy if the number of patterns get higher. Or you can use
look-ahead:

 % grep -P '(?=.*foo)(?=.*bar)' FILES

but this does not capture (thus highlight) the patterns.

Note that searching for multiple patterns in particular order ('foo.*bar'), or
searching for aternates from multiple patterns ('foo|bar') is no problem in
grep.

greple also has a few other tricks up its sleeve, like configuration file to
define complex regexes, matching across lines, and Japanese text support.

Instead of specifying a pattern, with L<App::rpgrep> you can specify a pattern
name in a L<Regexp::Pattern>::* module instead.

B<Reimplementations>

grep for L<PerlPowerTools> simply tries to reimplement grep in Perl, as part
of the project to reimplement many Unix utilities in Perl. It has few practical
uses.

B<Searching Perl source code>

L<App::pmgrep> lets you grep over locally installed Perl modules. It's
basically a shortcut for something like this:

 % pmlist -Rx | grep PAT
 % grep PAT C<pmlist -Rx>

L<App::Grepl> uses L<PPI> to let you grep over Perl I<documents>; it allows
you to do things like: search only in Perl code comments or inside string
literals.

I<*Searching other than files: *>

TODO

=head1 INCLUDED MODULES

=over

=item * L<ack>

=item * L<App::Greple>

=item * L<App::abgrep>

=item * L<App::rpgrep>

=item * L<Regexp::Pattern>

=item * L<PerlPowerTools>

=item * L<App::pmgrep>

=item * L<App::Grepl>

=item * L<PPI>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries GrepVariants | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=GrepVariants -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-GrepVariants>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-GrepVariants>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-GrepVariants>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

L<Acme::CPANModules::GoodInterfaces>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
