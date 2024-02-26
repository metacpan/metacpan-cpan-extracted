package Acme::CPANModules::RsyncWrappers;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-31'; # DATE
our $DIST = 'Acme-CPANModules-RsyncWrappers'; # DIST
our $VERSION = '0.002'; # VERSION

require Acme::CPANModules::CLI::Wrapper::UnixCommand;
my $srclist = $Acme::CPANModules::CLI::Wrapper::UnixCommand::LIST;

sub _include {
    my ($list, $item) = @_;
    ref $list eq 'ARRAY' ? ((grep {$_ eq $item} @$list) ? 1:0) : ($list eq $item);
}

our $LIST = {
    summary => "List of wrappers for the rsync command",
    entries => [
        grep { _include($_->{'x.command'}, 'rsync') } @{ $srclist->{entries} }
    ],
};

1;
# ABSTRACT: List of wrappers for the rsync command

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::RsyncWrappers - List of wrappers for the rsync command

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::RsyncWrappers (from Perl distribution Acme-CPANModules-RsyncWrappers), released on 2023-10-31.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<App::rsynccolor>

Wraps rsync to add color to output, particularly highlighting deletion.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<rsynccolor>

=item L<App::rsync::new2old>

Wraps rsync to check that source is newer than target.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Script: L<rsync-new2old>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n RsyncWrappers

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries RsyncWrappers | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=RsyncWrappers -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::RsyncWrappers -E'say $_->{module} for @{ $Acme::CPANModules::RsyncWrappers::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-RsyncWrappers>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-RsyncWrappers>.

=head1 SEE ALSO

L<Acme::CPANModules::CLI::Wrapper::UnixCommand>, from which this list is
derived.

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

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

This software is copyright (c) 2023, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-RsyncWrappers>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
