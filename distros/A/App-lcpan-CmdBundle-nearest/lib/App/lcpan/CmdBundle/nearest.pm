package App::lcpan::CmdBundle::nearest;

our $DATE = '2017-01-20'; # DATE
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: lcpan nearest-* subcommands

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::CmdBundle::nearest - lcpan nearest-* subcommands

=head1 VERSION

This document describes version 0.002 of App::lcpan::CmdBundle::nearest (from Perl distribution App-lcpan-CmdBundle-nearest), released on 2017-01-20.

=head1 SYNOPSIS

Install this distribution, then the lcpan subcommands below will be available:

 # List modules with name nearest to Lingua::Stop::War
 % lcpan nearest-mods Lingua::Stop::War

 # List dists with name nearest to Lingua-Stop-War
 % lcpan nearest-dists Lingua-Stop-War

 # List authors with CPAN ID nearest to PERL
 % lcpan nearest-authors PERL

=head1 DESCRIPTION

This bundle provides the following lcpan subcommands:

=over

=item * L<lcpan nearest-mods|App::lcpan::Cmd::nearest_mods>

=item * L<lcpan nearest-authors|App::lcpan::Cmd::nearest_authors>

=item * L<lcpan nearest-dists|App::lcpan::Cmd::nearest_dists>

=back

This distribution packages several lcpan subcommands named nearest-*.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-nearest>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-nearest>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-nearest>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lcpan>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
