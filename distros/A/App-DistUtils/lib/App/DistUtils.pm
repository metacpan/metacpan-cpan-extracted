package App::DistUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-25'; # DATE
our $DIST = 'App-DistUtils'; # DIST
our $VERSION = '0.153'; # VERSION

our %dist_arg_single = (
    dist => {
        schema => 'perl::distname*',
        req => 1,
        pos => 0,
        completion => sub {
            require Complete::Dist;
            my %args = @_;
            Complete::Dist::complete_dist(word=>$args{word});
        },
    },
);

our %dist_arg_multiple = (
    dist => {
        schema => ['array*', of=>'perl::distname*', min_len=>1],
        req => 1,
        pos => 0,
        greedy => 1,
        element_completion => sub {
            require Complete::Dist;
            my %args = @_;
            Complete::Dist::complete_dist(word=>$args{word});
        },
    },
);

1;
# ABSTRACT: Collection of utilities related to Perl distributions

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DistUtils - Collection of utilities related to Perl distributions

=head1 VERSION

This document describes version 0.153 of App::DistUtils (from Perl distribution App-DistUtils), released on 2023-02-25.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to Perl
distributions:

=over

=item 1. L<dir2dist>

=item 2. L<dir2mod>

=item 3. L<dist-dir>

=item 4. L<dist-has-deb>

=item 5. L<dist2deb>

=item 6. L<dist2mod>

=item 7. L<list-dist-contents>

=item 8. L<list-dist-modules>

=item 9. L<list-dists>

=item 10. L<mod2dist>

=item 11. L<packlist-for>

=item 12. L<parse-release-file-name>

=item 13. L<pwd2dist>

=item 14. L<pwd2mod>

=item 15. L<uninstall-dist>

=back

The main feature of these utilities is tab completion.

=head1 FAQ

=head2 What is the purpose of this distribution? Haven't other similar utilities existed?

For example, L<mpath> from L<Module::Path> distribution is similar to L<pmpath>
in L<App::PMUtils>, and L<mversion> from L<Module::Version> distribution is
similar to L<pmversion> from L<App::PMUtils> distribution, and so on.

True. The main point of these utilities is shell tab completion, to save
typing.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-DistUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DistUtils>.

=head1 SEE ALSO

Below is the list of distributions that provide CLI utilities for various
purposes, with the focus on providing shell tab completion feature.

L<App::DistUtils>, utilities related to Perl distributions.

L<App::DzilUtils>, utilities related to L<Dist::Zilla>.

L<App::GitUtils>, utilities related to git.

L<App::IODUtils>, utilities related to L<IOD> configuration files.

L<App::LedgerUtils>, utilities related to Ledger CLI files.

L<App::PerlReleaseUtils>, utilities related to Perl distribution releases.

L<App::PlUtils>, utilities related to Perl scripts.

L<App::PMUtils>, utilities related to Perl modules.

L<App::ProgUtils>, utilities related to programs.

L<App::WeaverUtils>, utilities related to L<Pod::Weaver>.

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

This software is copyright (c) 2023, 2022, 2020, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DistUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
