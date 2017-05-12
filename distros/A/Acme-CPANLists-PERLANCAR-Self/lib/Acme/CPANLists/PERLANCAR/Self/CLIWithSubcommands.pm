package Acme::CPANLists::PERLANCAR::Self::CLIWithSubcommands;

our $DATE = '2017-01-06'; # DATE
our $VERSION = '0.002'; # VERSION

our @Module_Lists = (
    {
        summary => 'Distributions that contain CLI scripts with subcommands',
        entries => [
            {module => 'App::AcmeCpanlists' , scripts => ['acme-cpanlists']},
            {module => 'App::CPAN::Changes' , scripts => ['cpan-changes']},
            {module => 'App::dux'           , scripts => ['dux']}, # NOT PERICMD
            {module => 'App::GitUtils'      , scripts => ['gu']},
            {module => 'App::lcpan'         , scripts => ['lcpan']},
            {module => 'App::pause'         , scripts => ['pause']},
            {module => 'App::PDRUtils'      , scripts => ['pdrutil', 'pdrutil-multi']},
            {module => 'App::reposdb'       , scripts => ['reposdb']},
            {module => 'App::rimetadb'      , scripts => ['rimetadb']},
            {module => 'App::shcompgen'     , scripts => ['shcompgen']},
            {module => 'App::short'         , scripts => ['short']},
            {module => 'App::TableDataUtils', scripts => ['gen-rand-table']},
            {module => 'App::trash::u'      , scripts => ['trash-u']},
            {module => 'App::upf'           , scripts => ['upf']},
            {module => 'App::wp::xmlrpc'    , scripts => ['wp-xmlrpc']},
            {module => 'Git::Bunch'         , scripts => ['gitbunch']},
            {module => 'phpBB2::Simple'     , scripts => ['phpbb2']},
        ],
    },
);

1;
# ABSTRACT: Distributions that contain CLI scripts with subcommands

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::Self::CLIWithSubcommands - Distributions that contain CLI scripts with subcommands

=head1 VERSION

This document describes version 0.002 of Acme::CPANLists::PERLANCAR::Self::CLIWithSubcommands (from Perl distribution Acme-CPANLists-PERLANCAR-Self), released on 2017-01-06.

=head1 MODULE LISTS

=head2 Distributions that contain CLI scripts with subcommands

=over

=item * L<App::AcmeCpanlists>

=item * L<App::CPAN::Changes>

=item * L<App::dux>

=item * L<App::GitUtils>

=item * L<App::lcpan>

=item * L<App::pause>

=item * L<App::PDRUtils>

=item * L<App::reposdb>

=item * L<App::rimetadb>

=item * L<App::shcompgen>

=item * L<App::short>

=item * L<App::TableDataUtils>

=item * L<App::trash::u>

=item * L<App::upf>

=item * L<App::wp::xmlrpc>

=item * L<Git::Bunch>

=item * L<phpBB2::Simple>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANLists-PERLANCAR-Self>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANLists-PERLANCAR-Self>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANLists-PERLANCAR-Self>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANLists> - about the Acme::CPANLists namespace

L<acme-cpanlists> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
