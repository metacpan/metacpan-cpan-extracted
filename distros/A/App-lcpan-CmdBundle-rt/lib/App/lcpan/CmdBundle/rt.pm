package App::lcpan::CmdBundle::rt;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-27'; # DATE
our $DIST = 'App-lcpan-CmdBundle-rt'; # DIST
our $VERSION = '0.004'; # VERSION

1;
# ABSTRACT: More lcpan subcommands related to rt.cpan.org

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::CmdBundle::rt - More lcpan subcommands related to rt.cpan.org

=head1 VERSION

This document describes version 0.004 of App::lcpan::CmdBundle::rt (from Perl distribution App-lcpan-CmdBundle-rt), released on 2022-03-27.

=head1 SYNOPSIS

=head1 DESCRIPTION

This bundle provides the following lcpan subcommands:

=over

=item * L<lcpan rt-open|App::lcpan::Cmd::rt_open>

=item * L<lcpan rt-tickets|App::lcpan::Cmd::rt_tickets>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-rt>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-rt>.

=head1 SEE ALSO

L<lcpan>

L<https://rt.cpan.org/>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-rt>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
