package Acme::CPANModules::PERLANCAR::Task::PickingRandomLinesFromFile;

our $DATE = '2019-01-06'; # DATE
our $VERSION = '0.004'; # VERSION

our $LIST = {
    summary => 'Picking random lines from a file',
    tags => ['task'],
    entries => [
        {
            module=>'File::Random',
            description => <<'_',

The `random_line()` function from this module picks one or more random lines
from a specified file. The whole content of the file need not be slurped into
memory, but the routine requires a single-pass of reading all lines from the
file. The algorithm is as described in perlfaq (See: `perldoc -q "random
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
# ABSTRACT: Picking random lines from a file

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::Task::PickingRandomLinesFromFile - Picking random lines from a file

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::PERLANCAR::Task::PickingRandomLinesFromFile (from Perl distribution Acme-CPANModulesBundle-PERLANCAR), released on 2019-01-06.

=head1 DESCRIPTION

Picking random lines from a file.

=head1 INCLUDED MODULES

=over

=item * L<File::Random>

The C<random_line()> function from this module picks one or more random lines
from a specified file. The whole content of the file need not be slurped into
memory, but the routine requires a single-pass of reading all lines from the
file. The algorithm is as described in perlfaq (See: C<perldoc -q "random
line">).

If you pick more than one lines, then there might be duplicates.


=item * L<File::RandomLine> - Recommended for large files

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


=item * L<File::Random::Pick>

This module is an alternative to L<File::Random>. It offers a C<random_line()>
routine that avoids duplication.


=item * L<App::PickRandomLines>

A CLI that allows you to use L<File::Random::Pick> or L<File::RandomLine> on
the command-line.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModulesBundle-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModulesBundle-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModulesBundle-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
