package App::lcpan::CmdBundle::cpanmodules;

our $DATE = '2019-11-19'; # DATE
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: lcpan subcommands related to Acme::CPANModules

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::CmdBundle::cpanmodules - lcpan subcommands related to Acme::CPANModules

=head1 VERSION

This document describes version 0.001 of App::lcpan::CmdBundle::cpanmodules (from Perl distribution App-lcpan-CmdBundle-cpanmodules), released on 2019-11-19.

=head1 SYNOPSIS

Install this distribution, then the lcpan subcommands below will be available:

 # List Acme::CPANModules modules available on CPAN
 % lcpan cpanmodules-mods

=head1 DESCRIPTION

This bundle provides the following lcpan subcommands:

=over

=item * L<lcpan cpanmodules-mods|App::lcpan::Cmd::cpanmodules_mods>

=back

This distribution packages several lcpan subcommands related to
L<Acme::CPANModules>. More subcommands will be added in future releases.

Some ideas:

B<cpanmodules-stats>. Number of modules/lists. We might also want to know the
total number of entries, average number of entries per list, total number of
mentioned modules, the most mentioned modules, and so on.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-cpanmodules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-cpanmodules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-cpanmodules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lcpan>

L<Acme::CPANModules> and L<cpanmodules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
