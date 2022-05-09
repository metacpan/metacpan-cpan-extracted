package App::lcpan::CmdBundle::metacpan;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-27'; # DATE
our $DIST = 'App-lcpan-CmdBundle-metacpan'; # DIST
our $VERSION = '0.008'; # VERSION

our $db_schema_spec = {
    component_name => 'metacpan',
    provides => [
        'metacpan_favorite',
    ],
    latest_v => 1,
    install => [
        'CREATE TABLE metacpan_favorite (
             time INT NOT NULL,
             dist VARCHAR(90) NOT NULL, -- XXX references dist(name)
             id VARCHAR(90) NOT NULL,
             total INT NOT NULL,
             rec_ctime INT,
             rec_mtime INT
         )',
        'CREATE INDEX ix_metacpan_favorite__time ON metacpan_favorite(time)',
        'CREATE INDEX ix_metacpan_favorite__dist ON metacpan_favorite(dist)',
        'CREATE INDEX ix_metacpan_favorite__rec_ctime ON metacpan_favorite(rec_ctime)',
        'CREATE INDEX ix_metacpan_favorite__rec_mtime ON metacpan_favorite(rec_mtime)',
    ],
};

1;
# ABSTRACT: More lcpan subcommands related to MetaCPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::CmdBundle::metacpan - More lcpan subcommands related to MetaCPAN

=head1 VERSION

This document describes version 0.008 of App::lcpan::CmdBundle::metacpan (from Perl distribution App-lcpan-CmdBundle-metacpan), released on 2022-03-27.

=head1 SYNOPSIS

=head1 DESCRIPTION

This bundle provides the following lcpan subcommands:

=over

=item * L<lcpan metacpan-mod|App::lcpan::Cmd::metacpan_mod>

=item * L<lcpan metacpan-script|App::lcpan::Cmd::metacpan_script>

=item * L<lcpan metacpan-dist|App::lcpan::Cmd::metacpan_dist>

=item * L<lcpan metacpan-author|App::lcpan::Cmd::metacpan_author>

=item * L<lcpan metacpan-pod|App::lcpan::Cmd::metacpan_pod>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-metacpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-metacpan>.

=head1 SEE ALSO

L<lcpan>

L<https://metacpan.org>

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

This software is copyright (c) 2022, 2019, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-metacpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
