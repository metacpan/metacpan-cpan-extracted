package App::XWindowManagerUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-05-18'; # DATE
our $DIST = 'App-XWindowManagerUtils'; # DIST
our $VERSION = '0.005'; # VERSION

1;
# ABSTRACT: Utilities related to "X Window Manager"

__END__

=pod

=encoding UTF-8

=head1 NAME

App::XWindowManagerUtils - Utilities related to "X Window Manager"

=head1 VERSION

This document describes version 0.005 of App::XWindowManagerUtils (from Perl distribution App-XWindowManagerUtils), released on 2026-05-18.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to "X Window Manager":

=over

=item * L<get-window-kde-activity>

=item * L<get-xwm-window-kde-activity>

=item * L<list-windows>

=item * L<list-xwm-windows>

=item * L<move-windows-to-kde-activity>

=item * L<move-windows-to-this-kde-activity>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-XWindowManagerUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-XWindowManagerUtils>.

=head1 SEE ALSO

L<Desktop::XWindowManager::Util>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords perlancar

perlancar <perlancar@gmail.com>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-XWindowManagerUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
