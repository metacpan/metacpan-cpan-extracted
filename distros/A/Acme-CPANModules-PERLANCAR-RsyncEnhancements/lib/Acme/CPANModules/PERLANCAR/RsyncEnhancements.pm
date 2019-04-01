package Acme::CPANModules::PERLANCAR::RsyncEnhancements;

our $DATE = '2019-04-01'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'List of my enhancements for rsync',
    description => <<'_',

Rsync is one of my favorite tools in the whole wide world. There are a few
things that I want rsync to do but doesn't so I made some enhancements for it.
Currently all of the enhancements are in the form of wrapper, because it is the
easiest and most straightforward, implementation-wise.

_
    entries => [
        {
            module => "App::rsync::new2old",
            description => <<'_',

Rsync is a one-way syncing tool, as two-way syncing can be much slower (because
it requires recording states in both sides) or requires more specific tools
(like version control system). In simpler cases, when updates only happen in one
side, you can perform two-way syncing by just checking that: the side that has
the newest file "wins" (is sync-ed to the "losing" side). This script checks
that condition.

_
        },
        {
            module => "App::rsync::retry",
            description => <<'_',

Rsync can resume a partial sync, but does not automatically retries. An annoying
thing is invoking an rsync command to sync a large tree, leaving the computer
for the day, then returning the following day hoping the transfer would be
completed, only to see that it failed early because of a network hiccup. This
wrapper automatically retries rsync when there is a transfer error.

_
        },
        {
            module => "App::rsynccolor",
            description => <<'_',

This wrapper adds some color to the rsync output, particularly giving a red to
deletion, so you can spot deletion more easily. Particularly handy if you use it
with the `-n` (`--dry-run`) option.

_
        },
    ],
};

1;
# ABSTRACT: List of my enhancements for rsync

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::RsyncEnhancements - List of my enhancements for rsync

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::PERLANCAR::RsyncEnhancements (from Perl distribution Acme-CPANModules-PERLANCAR-RsyncEnhancements), released on 2019-04-01.

=head1 DESCRIPTION

List of my enhancements for rsync.

Rsync is one of my favorite tools in the whole wide world. There are a few
things that I want rsync to do but doesn't so I made some enhancements for it.
Currently all of the enhancements are in the form of wrapper, because it is the
easiest and most straightforward, implementation-wise.

=head1 INCLUDED MODULES

=over

=item * L<App::rsync::new2old>

Rsync is a one-way syncing tool, as two-way syncing can be much slower (because
it requires recording states in both sides) or requires more specific tools
(like version control system). In simpler cases, when updates only happen in one
side, you can perform two-way syncing by just checking that: the side that has
the newest file "wins" (is sync-ed to the "losing" side). This script checks
that condition.


=item * L<App::rsync::retry>

Rsync can resume a partial sync, but does not automatically retries. An annoying
thing is invoking an rsync command to sync a large tree, leaving the computer
for the day, then returning the following day hoping the transfer would be
completed, only to see that it failed early because of a network hiccup. This
wrapper automatically retries rsync when there is a transfer error.


=item * L<App::rsynccolor>

This wrapper adds some color to the rsync output, particularly giving a red to
deletion, so you can spot deletion more easily. Particularly handy if you use it
with the C<-n> (C<--dry-run>) option.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PERLANCAR-RsyncEnhancements>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PERLANCAR-RsyncEnhancements>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PERLANCAR-RsyncEnhancements>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
