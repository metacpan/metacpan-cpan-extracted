package Acme::CPANModules::GrepVariants;

use strict;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-14'; # DATE
our $DIST = 'Acme-CPANModules-GrepVariants'; # DIST
our $VERSION = '0.008'; # VERSION

my $description = <<'_';
This list catalogs various grep-like tools.

**1. Reimplementations**

grep (from <pm:PerlPowerTools>) simply tries to reimplement grep in Perl, as
part of the project to reimplement many Unix utilities in Perl. It has few
practical uses; mainly educational. The portability advantage of Perl is
probably minor as grep and many Unix utilities are now available on other
platforms including Windows.


**2a. Improvements in recursive searching against files**

<prog:ack>. Created in 2005 by Andy Lester, <pm:ack> is the granddaddy of
grep-like programs that try to improve the experience of using grep to search
for text in source code. ack skips VCS directories like `.git` or `.svn`, and
understands file types so it doesn't look into giant `.mp4`s and other binaries
by default. ack has spurred the development of its improvements (mostly in speed
aspect) like The Silver Searcher (`ag`) (implemented in C) or `ripgrep`
(implemented in Rust). `git` also now includes a `git-grep` utility (implemented
in C). ack has a website: <https://beyondgrep.com>. See also
<https://betterthanack.com>.

<prog:gre> (from <pm:App::Gre>) is a "grep clone using Perl regexp's with better
file filtering, defaults, speed, and presentation". It seems to focus on
providing many options to filter files (from including/excluding by file
extension, by matching against filename, by first line, by maximum directory
depth, and so on). It also offers some alternative output styles.


**2b. Improvements in specifying multiple patterns**

Normally with the regular grep, to search for all 'foo' and 'bar', you either
have to do something like:

    % grep --color=always foo FILES | grep bar

or:

    % grep -P 'foo.*bar|bar.*foo' FILES

both of which get unwieldy if the number of patterns get higher. Or you can use
look-ahead:

    % grep -P '(?=.*foo)(?=.*bar)' FILES

but this does not capture (thus highlight) the patterns. To do that, you can
pipe to grep once more:

    % grep -P '(?=.*foo)(?=.*bar)' FILES | grep -P '(foo|bar)'

but you introduce the complications of double filtering (e.g. filenames in
FILES is now the subject of the second grep).

Note that searching for multiple patterns in particular order ('foo.*bar'), or
searching for aternates from multiple patterns ('foo|bar') is no problem in
grep.

Some tools have been written to make it easier to specify multiple patterns:

<prog:abgrep> (from <pm:App::abgrep>) sports a `--all` option to require all
patterns to appear in a line (in no particular order). Normally, when multiple
patterns are given (via multiple `-e` or `--regexp` options), grep will include
lines that just contain at least one of the patterns.

<prog:greple> (from <pm:App::Greple>). By default, greple only display lines
that contain all patterns, instead of just one. greple also has a few other
tricks up its sleeve, like configuration file to define complex regexes,
matching across lines, and Japanese text support.

<prog:grep-terms> (from <pm:App::GrepUtils>) is a grep wrapper to convert
multiple terms into a chain of look-ahead patterns like described above. This
allows you to use the standard grep.


**3. Variants: alternate ways of specifying regex**

Instead of specifying a pattern, with C<prog:rpgrep> (from <pm:App::rpgrep>) you
can specify a pattern name in a <pm:Regexp::Pattern>::* module instead.


**4a. Variants: alternate source: repository (version control system) content and history**

For git, the abovementioned `git-grep` can search for files in the work tree as
well as commit content. For Mercurial, `hg grep` accomplishes the same.
Alternatively you can dump the history then use the standard `grep` to go
through it.

**4b. Variants: alternate source: Perl source code**

<prog:pmgrep> (from <pm:App::pmgrep>) lets you grep over locally installed Perl
modules. It's basically a shortcut for something like this:

    % pmlist -Rx | xargs grep PAT
    % grep PAT $(pmlist -Rx)

<prog:cpangrep> (from <pm:App::cpangrep>) is a CLI for web service
<https://cpan.grep.me>, which is no longer operating. To grep from files on
CPAN, use <https://metacpan.org>.

<prog:grepl> (from <pm:App::Grepl>) uses <pm:PPI> to let you grep over Perl
*documents*; it allows you to do things like: search only in Perl code comments
or inside string literals.

<prog:podgrep> (from <pm:pmtools>) greps from POD sections of Perl source.


**4b. Variants: alternate source: CSV**

<prog:csvgrep> (from <pm:csvgrep>)

<prog:csv-grep> (from <pm:App::CSVUtils>) allows you to apply Perl code against
rows of CSV.


**4c. Variants: alternate source: word lists**

<prog:wordlist> (from <pm:App::wordlist>) greps words from wordlist modules
(modules that contains word lists, see WordList).


**4d. Variants: other alternate sources**

<prog:grep-from-bash-history> (from <pm:App::BashHistoryUtils>).

<prog:grep-from-iod> (from <pm:App::IODUtils>).

<prog:grep-from-ini> (from <pm:App::INIUtils>).

<prog:grep-from-coin> (from <pm:App::CryptoCurrencyUtils>).

<prog:grep-from-exchange> (from <pm:App::CryptoCurrencyUtils>).

<prog:jgrep> (from <pm:App::JsonLogUtils>).

<prog:pdfgrep> (alias: <prog:grep-from-pdf>) (from <pm:App::PDFUtils>) searches
against text in PDF files (it's a wrapper for `pdftotext` utility and grep).

<prog:ptargrep> (from <pm:Archive::Tar>) searches against table of contents of
tar files.


**5a. Variants: searching URLs**

<prog:grep-url> (from <pm:App::grep::url>) greps URLs from lines of input. You
don't have to manually specify regex that matches URLs yourself; you can just
add additional criteria for the URLs, e.g. whether the host part must contain
some text, or whether a certain query parameter must match some pattern.


**5b. Variants: searching dates**

<prog:grep-date> (from L<App::grep::date>) greps for dates in lines of text.

<prog:dategrep> (from L<App::dategrep>) prints lines matching a date range.

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

This document describes version 0.008 of Acme::CPANModules::GrepVariants (from Perl distribution Acme-CPANModules-GrepVariants), released on 2021-11-14.

=head1 DESCRIPTION

This list catalogs various grep-like tools.

B<1. Reimplementations>

grep (from L<PerlPowerTools>) simply tries to reimplement grep in Perl, as
part of the project to reimplement many Unix utilities in Perl. It has few
practical uses; mainly educational. The portability advantage of Perl is
probably minor as grep and many Unix utilities are now available on other
platforms including Windows.

B<2a. Improvements in recursive searching against files>

L<ack>. Created in 2005 by Andy Lester, L<ack> is the granddaddy of
grep-like programs that try to improve the experience of using grep to search
for text in source code. ack skips VCS directories like C<.git> or C<.svn>, and
understands file types so it doesn't look into giant C<.mp4>s and other binaries
by default. ack has spurred the development of its improvements (mostly in speed
aspect) like The Silver Searcher (C<ag>) (implemented in C) or C<ripgrep>
(implemented in Rust). C<git> also now includes a C<git-grep> utility (implemented
in C). ack has a website: L<https://beyondgrep.com>. See also
L<https://betterthanack.com>.

L<gre> (from L<App::Gre>) is a "grep clone using Perl regexp's with better
file filtering, defaults, speed, and presentation". It seems to focus on
providing many options to filter files (from including/excluding by file
extension, by matching against filename, by first line, by maximum directory
depth, and so on). It also offers some alternative output styles.

B<2b. Improvements in specifying multiple patterns>

Normally with the regular grep, to search for all 'foo' and 'bar', you either
have to do something like:

 % grep --color=always foo FILES | grep bar

or:

 % grep -P 'foo.*bar|bar.*foo' FILES

both of which get unwieldy if the number of patterns get higher. Or you can use
look-ahead:

 % grep -P '(?=.*foo)(?=.*bar)' FILES

but this does not capture (thus highlight) the patterns. To do that, you can
pipe to grep once more:

 % grep -P '(?=.*foo)(?=.*bar)' FILES | grep -P '(foo|bar)'

but you introduce the complications of double filtering (e.g. filenames in
FILES is now the subject of the second grep).

Note that searching for multiple patterns in particular order ('foo.*bar'), or
searching for aternates from multiple patterns ('foo|bar') is no problem in
grep.

Some tools have been written to make it easier to specify multiple patterns:

L<abgrep> (from L<App::abgrep>) sports a C<--all> option to require all
patterns to appear in a line (in no particular order). Normally, when multiple
patterns are given (via multiple C<-e> or C<--regexp> options), grep will include
lines that just contain at least one of the patterns.

L<greple> (from L<App::Greple>). By default, greple only display lines
that contain all patterns, instead of just one. greple also has a few other
tricks up its sleeve, like configuration file to define complex regexes,
matching across lines, and Japanese text support.

L<grep-terms> (from L<App::GrepUtils>) is a grep wrapper to convert
multiple terms into a chain of look-ahead patterns like described above. This
allows you to use the standard grep.

B<3. Variants: alternate ways of specifying regex>

Instead of specifying a pattern, with CL<rpgrep> (from L<App::rpgrep>) you
can specify a pattern name in a L<Regexp::Pattern>::* module instead.

B<4a. Variants: alternate source: repository (version control system) content and history>

For git, the abovementioned C<git-grep> can search for files in the work tree as
well as commit content. For Mercurial, C<hg grep> accomplishes the same.
Alternatively you can dump the history then use the standard C<grep> to go
through it.

B<4b. Variants: alternate source: Perl source code>

L<pmgrep> (from L<App::pmgrep>) lets you grep over locally installed Perl
modules. It's basically a shortcut for something like this:

 % pmlist -Rx | xargs grep PAT
 % grep PAT $(pmlist -Rx)

L<cpangrep> (from L<App::cpangrep>) is a CLI for web service
L<https://cpan.grep.me>, which is no longer operating. To grep from files on
CPAN, use L<https://metacpan.org>.

L<grepl> (from L<App::Grepl>) uses L<PPI> to let you grep over Perl
I<documents>; it allows you to do things like: search only in Perl code comments
or inside string literals.

L<podgrep> (from L<pmtools>) greps from POD sections of Perl source.

B<4b. Variants: alternate source: CSV>

L<csvgrep> (from L<csvgrep>)

L<csv-grep> (from L<App::CSVUtils>) allows you to apply Perl code against
rows of CSV.

B<4c. Variants: alternate source: word lists>

L<wordlist> (from L<App::wordlist>) greps words from wordlist modules
(modules that contains word lists, see WordList).

B<4d. Variants: other alternate sources>

L<grep-from-bash-history> (from L<App::BashHistoryUtils>).

L<grep-from-iod> (from L<App::IODUtils>).

L<grep-from-ini> (from L<App::INIUtils>).

L<grep-from-coin> (from L<App::CryptoCurrencyUtils>).

L<grep-from-exchange> (from L<App::CryptoCurrencyUtils>).

L<jgrep> (from L<App::JsonLogUtils>).

L<pdfgrep> (alias: L<grep-from-pdf>) (from L<App::PDFUtils>) searches
against text in PDF files (it's a wrapper for C<pdftotext> utility and grep).

L<ptargrep> (from L<Archive::Tar>) searches against table of contents of
tar files.

B<5a. Variants: searching URLs>

L<grep-url> (from L<App::grep::url>) greps URLs from lines of input. You
don't have to manually specify regex that matches URLs yourself; you can just
add additional criteria for the URLs, e.g. whether the host part must contain
some text, or whether a certain query parameter must match some pattern.

B<5b. Variants: searching dates>

L<grep-date> (from L<App::grep::date>) greps for dates in lines of text.

L<dategrep> (from L<App::dategrep>) prints lines matching a date range.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<PerlPowerTools> - BSD utilities written in pure Perl

Author: L<BDFOY|https://metacpan.org/author/BDFOY>

=item * L<ack>

=item * L<App::Gre> - A grep clone using Perl regexp's with better file filtering, defaults, speed, and presentation

Author: L<JACOBG|https://metacpan.org/author/JACOBG>

=item * L<App::abgrep> - Print lines matching a pattern

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::Greple> - extensible grep with lexical expression and region handling

Author: L<UTASHIRO|https://metacpan.org/author/UTASHIRO>

=item * L<App::GrepUtils> - CLI utilities related to the Unix command 'grep'

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::rpgrep> - Print lines matching a Regexp::Pattern pattern

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Regexp::Pattern> - Convention/framework for modules that contain collection of regexes

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::pmgrep> - Print lines from installed Perl module sources matching a pattern

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::cpangrep> - Grep CPAN from the command-line using grep.cpan.me

Author: L<TSIBLEY|https://metacpan.org/author/TSIBLEY>

=item * L<App::Grepl> - PPI-powered grep

Author: L<OVID|https://metacpan.org/author/OVID>

=item * L<PPI> - Parse, Analyze and Manipulate Perl (without perl)

Author: L<MITHALDU|https://metacpan.org/author/MITHALDU>

=item * L<pmtools> - Perl Module Tools

Author: L<MLFISHER|https://metacpan.org/author/MLFISHER>

=item * L<csvgrep>

Author: L<NEILB|https://metacpan.org/author/NEILB>

=item * L<App::CSVUtils> - CLI utilities related to CSV

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::wordlist> - Grep words from WordList::*

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::BashHistoryUtils> - CLI utilities related to bash history file

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::IODUtils> - IOD utilities

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::INIUtils> - INI utilities

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::CryptoCurrencyUtils> - CLI utilities related to cryptocurrencies

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::JsonLogUtils> - Command line utilities for dealing with JSON-formatted log files

Author: L<JEFFOBER|https://metacpan.org/author/JEFFOBER>

=item * L<App::PDFUtils> - Command-line utilities related to PDF files

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Archive::Tar> - module for manipulations of tar archives

Author: L<BINGOS|https://metacpan.org/author/BINGOS>

=item * L<App::grep::url> - Print lines having URL(s) (optionally of certain criteria) in them

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

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

 % cpanm-cpanmodules -n GrepVariants

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries GrepVariants | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=GrepVariants -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::GrepVariants -E'say $_->{module} for @{ $Acme::CPANModules::GrepVariants::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-GrepVariants>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-GrepVariants>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

L<Acme::CPANModules::GoodInterfaces>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-GrepVariants>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
