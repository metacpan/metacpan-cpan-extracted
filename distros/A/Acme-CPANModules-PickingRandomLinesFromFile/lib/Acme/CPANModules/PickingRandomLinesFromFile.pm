package Acme::CPANModules::PickingRandomLinesFromFile;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-20'; # DATE
our $DIST = 'Acme-CPANModules-PickingRandomLinesFromFile'; # DIST
our $VERSION = '0.004'; # VERSION

our $LIST = {
    summary => 'List of modules to pick random lines from a file',
    tags => ['task'],
    entries => [
        {
            module=>'File::Random',
            description => <<'_',

The `random_line()` function from this module picks one or more random lines
from a specified file. The whole content of the file does not need to be slurped
into memory, but the routine requires a single-pass of reading all lines from
the file. The algorithm is as described in perlfaq (See: `perldoc -q "random
line"`).

If you pick more than one lines, then there might be duplicates.

_
        },
        {
            module=>'File::RandomLine',
            summary => 'Recommended for large files',
            description => <<'_',

This module gives you a choice of two algorithms. The first is similar to
<pm:File::Random> (the scan method), giving each line of the file equal weight.
The second algorithm is more interesting: it works by random seeking the file,
discarding the line fragment (a.k.a. searching forward for the next newline
character), reading the next line, then repeating the process until the desired
number of lines is reached. This means one doesn't have to read the whole file
and the picking process is much faster than the scan method. It might be
preferred for very large files.

Note that due to the nature of the algorithm, lines are weighted by the number
of characters. In other words, lines that have long lines immediately preceding
them will have a greater probability of being picked. Depending on your use case
or the line length variation of your file, this algorithm might or might not be
acceptable to you.

_
        },
        {
            module => 'File::Random::Pick',
            description => <<'_',

This module is an alternative to <pm:File::Random>. It offers a `random_line()`
routine that avoids duplication.

_
        },
        {
            module => 'App::PickRandomLines',
            description => <<'_',

A CLI that allows you to use <pm:File::Random::Pick> or <pm:File::RandomLine> on
the command-line.

_
        },
    ],
};

1;
# ABSTRACT: List of modules to pick random lines from a file

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PickingRandomLinesFromFile - List of modules to pick random lines from a file

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::PickingRandomLinesFromFile (from Perl distribution Acme-CPANModules-PickingRandomLinesFromFile), released on 2023-06-20.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<File::Random>

Author: L<BIGJ|https://metacpan.org/author/BIGJ>

The C<random_line()> function from this module picks one or more random lines
from a specified file. The whole content of the file does not need to be slurped
into memory, but the routine requires a single-pass of reading all lines from
the file. The algorithm is as described in perlfaq (See: C<perldoc -q "random
line">).

If you pick more than one lines, then there might be duplicates.


=item L<File::RandomLine>

Recommended for large files.

Author: L<DAGOLDEN|https://metacpan.org/author/DAGOLDEN>

This module gives you a choice of two algorithms. The first is similar to
L<File::Random> (the scan method), giving each line of the file equal weight.
The second algorithm is more interesting: it works by random seeking the file,
discarding the line fragment (a.k.a. searching forward for the next newline
character), reading the next line, then repeating the process until the desired
number of lines is reached. This means one doesn't have to read the whole file
and the picking process is much faster than the scan method. It might be
preferred for very large files.

Note that due to the nature of the algorithm, lines are weighted by the number
of characters. In other words, lines that have long lines immediately preceding
them will have a greater probability of being picked. Depending on your use case
or the line length variation of your file, this algorithm might or might not be
acceptable to you.


=item L<File::Random::Pick>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

This module is an alternative to L<File::Random>. It offers a C<random_line()>
routine that avoids duplication.


=item L<App::PickRandomLines>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

A CLI that allows you to use L<File::Random::Pick> or L<File::RandomLine> on
the command-line.


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

 % cpanm-cpanmodules -n PickingRandomLinesFromFile

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries PickingRandomLinesFromFile | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PickingRandomLinesFromFile -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PickingRandomLinesFromFile -E'say $_->{module} for @{ $Acme::CPANModules::PickingRandomLinesFromFile::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PickingRandomLinesFromFile>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PickingRandomLinesFromFile>.

=head1 SEE ALSO

L<Acme::CPANModules::PickingRandomItemsFromList>

L<Acme::CPANModules::ReadingFilesBackward>

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

This software is copyright (c) 2023, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PickingRandomLinesFromFile>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
