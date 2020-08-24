package Acme::CPANModules::RsyncWrappers;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-22'; # DATE
our $DIST = 'Acme-CPANModules-RsyncWrappers'; # DIST
our $VERSION = '0.001'; # VERSION

require Acme::CPANModules::CLI::Wrapper::UnixCommand;
my $srclist = $Acme::CPANModules::CLI::Wrapper::UnixCommand::LIST;

our $LIST = {
    summary => "Wrappers for the rsync command",
    entries => [
        grep { $_->{'x.command'} eq 'rsync' } @{ $srclist->{entries} }
    ],
};

1;
# ABSTRACT: Wrappers for the rsync command

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::RsyncWrappers - Wrappers for the rsync command

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::RsyncWrappers (from Perl distribution Acme-CPANModules-RsyncWrappers), released on 2020-08-22.

=head1 INCLUDED MODULES

=over

=item * L<App::rsynccolor> - Wraps rsync to add color to output, particularly highlighting deletion

=item * L<App::rsync::new2old> - Wraps rsync to check that source is newer than target

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries RsyncWrappers | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=RsyncWrappers -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-RsyncWrappers>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-RsyncWrappers>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-RsyncWrappers>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules::CLI::Wrapper::UnixCommand>, from which this list is
derived.

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
