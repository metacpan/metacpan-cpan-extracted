# no code
## no critic: TestingAndDebugging::RequireUseStrict
package App::fsql;

our $VERSION = '0.232'; # VERSION
our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-29'; # DATE
our $DIST = 'App-fsql'; # DIST

1;
# ABSTRACT: Perform SQL queries against {CSV/TSV/LTSV/JSON/YAML files,TableData modules}

__END__

=pod

=encoding UTF-8

=head1 NAME

App::fsql - Perform SQL queries against {CSV/TSV/LTSV/JSON/YAML files,TableData modules}

=head1 VERSION

This document describes version 0.232 of App::fsql (from Perl distribution App-fsql), released on 2023-12-29.

=head1 SYNOPSIS

See the command-line script L<fsql>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-fsql>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-fsql>.

=head1 SEE ALSO

L<tsql> (from L<App::tsql>) a fork which uses SQLite as backend instead of
L<DBD::CSV> and L<SQL::Statement>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Charles Bailey Kevan Benson Steven Haryanto

=over 4

=item *

Charles Bailey <bailey.charles@gmail.com>

=item *

Kevan Benson <kentrak@gmail.com>

=item *

Steven Haryanto <stevenharyanto@gmail.com>

=back

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

This software is copyright (c) 2023, 2021, 2019, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-fsql>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
