package Acme::CPANModules::DiffWrappers;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-27'; # DATE
our $DIST = 'Acme-CPANModules-DiffWrappers'; # DIST
our $VERSION = '0.003'; # VERSION

require Acme::CPANModules::CLI::Wrapper::UnixCommand;
my $srclist = $Acme::CPANModules::CLI::Wrapper::UnixCommand::LIST;

sub _includes {
    my ($list, $item) = @_;
    ref $list eq 'ARRAY' ? ((grep {$_ eq $item} @$list) ? 1:0) : ($list eq $item);
}

our $LIST = {
    summary => "Wrappers for the diff Unix command",
    entries => [
        grep { _includes($_->{'x.command'}, 'diff') } @{ $srclist->{entries} }
    ],
};

1;
# ABSTRACT: Wrappers for the diff Unix command

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::DiffWrappers - Wrappers for the diff Unix command

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::DiffWrappers (from Perl distribution Acme-CPANModules-DiffWrappers), released on 2020-10-27.

=head1 MODULES INCLUDED IN THIS ACME::CPANMODULE MODULE

=over

=item * L<App::diffwc> - Wraps (or filters output of) diff to add colors and highlight words

=item * L<App::DiffDocText> - Diffs two office word-processor documents by first converting them to plaintext

=item * L<App::DiffXlsText> - Diffs two office spreadsheets by first converting them to directories of CSV files

=item * L<App::sdif> - Provides sdif (diff side-by-side with nice color theme), cdif (highlight words with nice color scheme), and watchdiff (watch command and diff output)

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries DiffWrappers | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=DiffWrappers -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-DiffWrappers>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-DiffWrappers>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-DiffWrappers>

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
