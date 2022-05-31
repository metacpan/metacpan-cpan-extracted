package Bencher::Scenarios::Games::Wordlist;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-20'; # DATE
our $DIST = 'Bencher-Scenarios-Games-Wordlist'; # DIST
our $VERSION = '0.051'; # VERSION

our $scenario = {
    summary => 'Benchmark startup overhead of Games::Word::Wordlist::* modules',
    module_startup => 1,
    participants => [
        {module=>'Games::Word::Wordlist::Country'},
        {module=>'Games::Word::Wordlist::CountrySingleWord'},
        {module=>'Games::Word::Wordlist::Enable'},
        {module=>'Games::Word::Wordlist::KBBI'},
        {module=>'Games::Word::Wordlist::SGB'},
        {module=>'Games::Word::Phraselist::Proverb::KBBI'},
        {module=>'Games::Word::Phraselist::Proverb::TWW'},
    ],
};

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenarios::Games::Wordlist

=head1 VERSION

This document describes version 0.051 of Bencher::Scenarios::Games::Wordlist (from Perl distribution Bencher-Scenarios-Games-Wordlist), released on 2022-03-20.

=head1 DESCRIPTION

This distribution contains the following L<Bencher> scenario modules:

=over

=item * L<Bencher::Scenario::Games::Wordlist::startup>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Games-Wordlist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Games-Wordlist>.

=head1 SEE ALSO

L<Bencher::Scenarios::WordList>

L<Bencher::Scenarios::Crypt::Diceware::Wordlist>

L<Bencher::Scenarios::ArrayData>

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

This software is copyright (c) 2022, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Games-Wordlist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
