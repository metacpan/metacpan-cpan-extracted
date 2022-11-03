package App::pause;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-02'; # DATE
our $DIST = 'App-pause'; # DIST
our $VERSION = '0.659'; # VERSION

our %cli_attrs = do {
    my $p = '/WWW/PAUSE/Simple/';

    (
        script_summary => 'A CLI for PAUSE',
        url => '/WWW/PAUSE/Simple/',
        subcommands => {
            upload       => { url => "${p}upload_files" },
            ls           => { url => "${p}list_files" },
            "ls-dists" => { url => "${p}list_dists" },
            "ls-mods"  => { url => "${p}list_modules" },
            rm           => { url => "${p}delete_files" },
            undelete     => { url => "${p}undelete_files" },
            reindex      => { url => "${p}reindex_files" },
            #password     => { url => "${p}set_password" },
            #'account-info' => { url => "${p}set_account_info" },
            cleanup      => { url => "${p}delete_old_releases" },
        },
        log => 1,
        # since we are also run as pause-unpacked or pause-fatpacked, but want
        # to share config, we hardcode the name here
        config_filename => ['pause.conf'],
    );
};

1;
# ABSTRACT: A CLI for PAUSE

__END__

=pod

=encoding UTF-8

=head1 NAME

App::pause - A CLI for PAUSE

=head1 VERSION

This document describes version 0.659 of App::pause (from Perl distribution App-pause), released on 2022-11-02.

=head1 DESCRIPTION

See included script L<pause>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-pause>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-pause>.

=head1 SEE ALSO

L<WWW::PAUSE::Simple>

L<pause>

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

This software is copyright (c) 2022, 2021, 2020, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-pause>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
