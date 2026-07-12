package App::DesktopWorkspaceUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-03-29'; # DATE
our $DIST = 'App-DesktopWorkspaceUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to DesktopWorkspace',
};

1;
# ABSTRACT: Utilities related to DesktopWorkspace

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DesktopWorkspaceUtils - Utilities related to DesktopWorkspace

=head1 VERSION

This document describes version 0.001 of App::DesktopWorkspaceUtils (from Perl distribution App-DesktopWorkspaceUtils), released on 2026-03-29.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to desktop workspace
specification (L<DesktopWorkspace>):

=over

=item * L<list-desktop-workspace-items>

=item * L<open-desktop-workspace-items>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-DesktopWorkspaceUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DesktopWorkspaceUtils>.

=head1 SEE ALSO

L<DesktopWorkspace>

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DesktopWorkspaceUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
