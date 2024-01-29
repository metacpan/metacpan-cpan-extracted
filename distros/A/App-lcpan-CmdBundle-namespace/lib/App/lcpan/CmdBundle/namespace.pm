package App::lcpan::CmdBundle::namespace;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-09'; # DATE
our $DIST = 'App-lcpan-CmdBundle-namespace'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: lcpan subcommands related to namespaces

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::CmdBundle::namespace - lcpan subcommands related to namespaces

=head1 VERSION

This document describes version 0.001 of App::lcpan::CmdBundle::namespace (from Perl distribution App-lcpan-CmdBundle-namespace), released on 2024-01-09.

=head1 SYNOPSIS

Install this distribution, then the lcpan subcommands below will be available:

 # List namespaces with the most number of modules
 % lcpan top-namespaces-by-module-count

 # List authors in a namespace, sorted by number of modules
 % lcpan namespace-authors App

=head1 DESCRIPTION

This bundle provides the following lcpan subcommands:

=over

=item * L<lcpan namespace-authors|App::lcpan::Cmd::namespace_authors>

=item * L<lcpan top-namespaces-by-module-count|App::lcpan::Cmd::top_namespaces_by_module_count>

=back

This distribution packages several lcpan subcommands related to namespaces.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-namespace>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-namespace>.

=head1 SEE ALSO

L<lcpan>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-namespace>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
