package App::WeaverUtils;

our $DATE = '2016-01-18'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;

1;
# ABSTRACT: Collection of CLI utilities for Pod::Weaver

__END__

=pod

=encoding UTF-8

=head1 NAME

App::WeaverUtils - Collection of CLI utilities for Pod::Weaver

=head1 VERSION

This document describes version 0.05 of App::WeaverUtils (from Perl distribution App-WeaverUtils), released on 2016-01-18.

=head1 DESCRIPTION

This distribution provides the following command-line utilities related to
L<Pod::Weaver>:

=over

=item * L<list-weaver-bundle-contents>

=item * L<list-weaver-bundles>

=item * L<list-weaver-plugins>

=item * L<list-weaver-roles>

=item * L<list-weaver-sections>

=back

=head1 FAQ

=head2 What is the purpose of this distribution? Haven't other similar utilities existed?

For example, L<mpath> from L<Module::Path> distribution is similar to L<pmpath>
in L<App::PMUtils>, and L<mversion> from L<Module::Version> distribution is
similar to L<pmversion> from L<App::PMUtils> distribution, and so on.

True. The main point of these utilities is shell tab completion, to save
typing.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-WeaverUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-WeaverUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-WeaverUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Below is the list of distributions that provide CLI utilities for various
purposes, with the focus on providing shell tab completion feature.

L<App::DistUtils>, utilities related to Perl distributions.

L<App::DzilUtils>, utilities related to L<Dist::Zilla>.

L<App::GitUtils>, utilities related to git.

L<App::IODUtils>, utilities related to L<IOD> configuration files.

L<App::LedgerUtils>, utilities related to Ledger CLI files.

L<App::PlUtils>, utilities related to Perl scripts.

L<App::PMUtils>, utilities related to Perl modules.

L<App::ProgUtils>, utilities related to programs.

L<App::WeaverUtils>, utilities related to L<Pod::Weaver>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
