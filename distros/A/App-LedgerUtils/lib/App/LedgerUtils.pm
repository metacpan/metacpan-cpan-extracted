package App::LedgerUtils;

our $DATE = '2019-10-15'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;

our %common_args = (
    ledger => {
        summary => 'Ledger file',
        schema  => 'str*',
        req     => 1,
        pos     => 0,
        cmdline_src => 'stdin_or_file',
        tags    => ['common'],
    },
    # XXX add parser configuration arguments
);

sub _get_parser {
    require Ledger::Parser;

    my $args = shift;
    Ledger::Parser->new(
        # XXX add parser configuration arguments
    );
}

1;
# ABSTRACT: Command-line utilities related Ledger files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::LedgerUtils - Command-line utilities related Ledger files

=head1 VERSION

This document describes version 0.04 of App::LedgerUtils (from Perl distribution App-LedgerUtils), released on 2019-10-15.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
Ledger files:

=over

=item * L<parse-ledger>

=back

The main purpose of these utilities is tab completion.

=head1 FAQ

=head2 What is the purpose of this distribution? Haven't other similar utilities existed?

For example, L<mpath> from L<Module::Path> distribution is similar to L<pmpath>
in L<App::PMUtils>, and L<mversion> from L<Module::Version> distribution is
similar to L<pmversion> from L<App::PMUtils> distribution, and so on.

True. The main point of these utilities is shell tab completion, to save
typing.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-LedgerUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-LedgerUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-LedgerUtils>

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

This software is copyright (c) 2019, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
