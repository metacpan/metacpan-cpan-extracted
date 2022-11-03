package App::TextTableUtils;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-18'; # DATE
our $DIST = 'App-TextTableUtils'; # DIST
our $VERSION = '0.008'; # VERSION

1;
# ABSTRACT: CLI utilities related to text tables

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TextTableUtils - CLI utilities related to text tables

=head1 VERSION

This document describes version 0.008 of App::TextTableUtils (from Perl distribution App-TextTableUtils), released on 2022-02-18.

=head1 DESCRIPTION

This distributions provides the following command-line utilities related to
text tables:

=over

=item * L<csv2ansitable>

=item * L<csv2asciitable>

=item * L<csv2dd>

=item * L<csv2json>

=item * L<csv2mdtable>

=item * L<csv2orgtable>

=item * L<csv2texttable>

=item * L<dd2ansitable>

=item * L<dd2asciitable>

=item * L<dd2csv>

=item * L<dd2mdtable>

=item * L<dd2orgtable>

=item * L<dd2texttable>

=item * L<dd2tsv>

=item * L<ini2ansitable>

=item * L<ini2asciitable>

=item * L<ini2csv>

=item * L<ini2mdtable>

=item * L<ini2orgtable>

=item * L<ini2texttable>

=item * L<ini2tsv>

=item * L<iod2ansitable>

=item * L<iod2asciitable>

=item * L<iod2csv>

=item * L<iod2mdtable>

=item * L<iod2orgtable>

=item * L<iod2texttable>

=item * L<iod2tsv>

=item * L<json2ansitable>

=item * L<json2asciitable>

=item * L<json2csv>

=item * L<json2mdtable>

=item * L<json2orgtable>

=item * L<json2texttable>

=item * L<json2tsv>

=item * L<texttableutils-convert>

=item * L<tsv2ansitable>

=item * L<tsv2asciitable>

=item * L<tsv2dd>

=item * L<tsv2json>

=item * L<tsv2mdtable>

=item * L<tsv2orgtable>

=item * L<tsv2texttable>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-TextTableUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-TextTableUtils>.

=head1 SEE ALSO

L<App::texttable>

L<App::TableDataUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Markus Koch

Markus Koch <mail@markusko.ch>

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

This software is copyright (c) 2022, 2021, 2019, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-TextTableUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
