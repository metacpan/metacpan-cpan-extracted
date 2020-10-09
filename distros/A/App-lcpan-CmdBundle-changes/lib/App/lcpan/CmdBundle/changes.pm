package App::lcpan::CmdBundle::changes;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-04'; # DATE
our $DIST = 'App-lcpan-CmdBundle-changes'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: lcpan subcommands related to Changes file

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::CmdBundle::changes - lcpan subcommands related to Changes file

=head1 VERSION

This document describes version 0.001 of App::lcpan::CmdBundle::changes (from Perl distribution App-lcpan-CmdBundle-changes), released on 2020-10-04.

=head1 SYNOPSIS

Install this distribution. Afterwards, the lcpan subcommands below will be
available:

 # show latest entry of a distribution release's Changes file
 % lcpan changes-entry App-lcpan

 # show specific version's entry of a distribution release's Changes file
 % lcpan changes-entry App-lcpan 1.000

=head1 DESCRIPTION

This bundle provides the following lcpan subcommands:

=over

=item * L<lcpan changes-entry|App::lcpan::Cmd::changes_entry>

=back

This distribution packages several lcpan subcommands related to
CPAN Changes file.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-changes>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-changes>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-changes>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lcpan>, L<App::lcpan>

L<CPAN::Changes>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
