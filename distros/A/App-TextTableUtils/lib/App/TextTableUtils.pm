package App::TextTableUtils;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-10'; # DATE
our $DIST = 'App-TextTableUtils'; # DIST
our $VERSION = '0.009'; # VERSION

1;
# ABSTRACT: CLI utilities related to text tables

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TextTableUtils - CLI utilities related to text tables

=head1 VERSION

This document describes version 0.009 of App::TextTableUtils (from Perl distribution App-TextTableUtils), released on 2023-03-10.

=head1 DESCRIPTION

This distributions provides the following command-line utilities related to
text tables:

=over

=item 1. L<csv2ansitable>

=item 2. L<csv2asciitable>

=item 3. L<csv2dd>

=item 4. L<csv2json>

=item 5. L<csv2mdtable>

=item 6. L<csv2orgtable>

=item 7. L<csv2texttable>

=item 8. L<dd2ansitable>

=item 9. L<dd2asciitable>

=item 10. L<dd2csv>

=item 11. L<dd2mdtable>

=item 12. L<dd2orgtable>

=item 13. L<dd2texttable>

=item 14. L<dd2tsv>

=item 15. L<ini2ansitable>

=item 16. L<ini2asciitable>

=item 17. L<ini2csv>

=item 18. L<ini2mdtable>

=item 19. L<ini2orgtable>

=item 20. L<ini2texttable>

=item 21. L<ini2tsv>

=item 22. L<iod2ansitable>

=item 23. L<iod2asciitable>

=item 24. L<iod2csv>

=item 25. L<iod2mdtable>

=item 26. L<iod2orgtable>

=item 27. L<iod2texttable>

=item 28. L<iod2tsv>

=item 29. L<json2ansitable>

=item 30. L<json2asciitable>

=item 31. L<json2csv>

=item 32. L<json2mdtable>

=item 33. L<json2orgtable>

=item 34. L<json2texttable>

=item 35. L<json2tsv>

=item 36. L<texttableutils-convert>

=item 37. L<tsv2ansitable>

=item 38. L<tsv2asciitable>

=item 39. L<tsv2dd>

=item 40. L<tsv2json>

=item 41. L<tsv2mdtable>

=item 42. L<tsv2orgtable>

=item 43. L<tsv2texttable>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2019, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-TextTableUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
