package Acme::CPANModules::DiffWrappers;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-DiffWrappers'; # DIST
our $VERSION = '0.004'; # VERSION

require Acme::CPANModules::CLI::Wrapper::UnixCommand;
my $srclist = $Acme::CPANModules::CLI::Wrapper::UnixCommand::LIST;

sub _includes {
    my ($list, $item) = @_;
    ref $list eq 'ARRAY' ? ((grep {$_ eq $item} @$list) ? 1:0) : ($list eq $item);
}

our $LIST = {
    summary => "List of wrappers for the diff Unix command",
    entries => [
        grep { _includes($_->{'x.command'}, 'diff') } @{ $srclist->{entries} }
    ],
};

1;
# ABSTRACT: List of wrappers for the diff Unix command

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::DiffWrappers - List of wrappers for the diff Unix command

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::DiffWrappers (from Perl distribution Acme-CPANModules-DiffWrappers), released on 2023-10-29.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<App::diffwc>

Wraps (or filters output of) diff to add colors and highlight words.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Scripts: L<diffwc>, L<diffwc-filter-u>

=item L<App::DiffDocText>

Diffs two office word-processor documents by first converting them to plaintext.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<diff-doc-text>

=item L<App::DiffPDFText>

Diffs two PDF files by first converting to plaintext.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<diff-pdf-text>

=item L<App::DiffXlsText>

Diffs two office spreadsheets by first converting them to directories of CSV files.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<diff-xls-text>

=item L<App::sdif>

Provides sdif (diff side-by-side with nice color theme), cdif (highlight words with nice color scheme), and watchdiff (watch command and diff output).

Author: L<UTASHIRO|https://metacpan.org/author/UTASHIRO>

Scripts: L<sdif>, L<cdif>, L<watchdiff>

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

 % cpanm-cpanmodules -n DiffWrappers

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries DiffWrappers | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=DiffWrappers -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::DiffWrappers -E'say $_->{module} for @{ $Acme::CPANModules::DiffWrappers::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-DiffWrappers>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-DiffWrappers>.

=head1 SEE ALSO

L<Acme::CPANModules::CLI::Wrapper::UnixCommand>, from which this list is
derived.

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

This software is copyright (c) 2023, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-DiffWrappers>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
