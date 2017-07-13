package App::pause;

our $DATE = '2017-07-10'; # DATE
our $DIST = 'App-pause'; # DIST
our $VERSION = '0.63'; # VERSION

our %cli_attrs = do {
    my $p = '/WWW/PAUSE/Simple/';

    (
        summary => 'A CLI for PAUSE',
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

This document describes version 0.63 of App::pause (from Perl distribution App-pause), released on 2017-07-10.

=head1 DESCRIPTION

See included script L<pause>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-pause>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-pause>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-pause>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WWW::PAUSE::Simple>

L<pause>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
