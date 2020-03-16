package App::lcpan::CmdBundle::cpanauthors;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-26'; # DATE
our $DIST = 'App-lcpan-CmdBundle-cpanauthors'; # DIST
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: lcpan subcommands related to Acme::CPANAuthors

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::CmdBundle::cpanauthors - lcpan subcommands related to Acme::CPANAuthors

=head1 VERSION

This document describes version 0.002 of App::lcpan::CmdBundle::cpanauthors (from Perl distribution App-lcpan-CmdBundle-cpanauthors), released on 2019-12-26.

=head1 SYNOPSIS

Install this distribution. Afterwards, the lcpan subcommands below will be
available:

 # List Acme::CPANModules modules available on CPAN
 % lcpan cpanauthors-mods

=head1 DESCRIPTION

This bundle provides the following lcpan subcommands:

=over

=item * L<lcpan cpanauthors-mods|App::lcpan::Cmd::cpanauthors_mods>

=back

This distribution packages several lcpan subcommands related to
L<Acme::CPANAuthors>. More subcommands will be added in future releases.

Some ideas:

B<cpanauthors-stats>. Number of modules/authors. We might also want to know the
average number of authors per module, total number of included authors, the most
include authors, and so on.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-cpanauthors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-cpanauthors>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-cpanauthors>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lcpan>

L<Acme::CPANAuthors>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
