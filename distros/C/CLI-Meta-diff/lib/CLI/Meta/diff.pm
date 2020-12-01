package CLI::Meta::diff;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-12-01'; # DATE
our $DIST = 'CLI-Meta-diff'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our $META = {
    opts => {
    normal => undef,
    'brief|q' => undef,
    'report-identical-files|s' => undef,
    'c' => undef,
    'context|C' => undef,
    'u' => undef,
    'unified|U' => undef,
    'ed|e' => undef,
    'rcs|n' => undef,
    'side-by-side|y' => undef,
    'width|W=i' => undef,
    'left-column' => undef,
    'suppress-common-lines' => undef,
    'show-c-function|p' => undef,
    'show-function-line|F=s' => undef,
    'label=s' => undef,
    'expand-tabs|t' => undef,
    'initial-tab|T' => undef,
    'tabsize=i' => undef,
    'suppress-blank-empty' => undef,
    'paginate|l' => undef,
    'recursive|r' => undef,
    'new-file|N' => undef,
    'unidirectional-new-file' => undef,
    'ignore-file-name-case!' => undef,
    'exclude|x=s' => undef,
    'exclude-from|X=s' => undef, # filename
    'starting-file|S' => undef, # filename
    'from-file=s' => undef, # filename
    'to-file=s' => undef, # filename
    'ignore-case|i' => undef,
    'ignore-tab-expansion|E' => undef,
    'ignore-trailing-space|Z' => undef,
    'ignore-space-change|b' => undef,
    'ignore-all-space|w' => undef,
    'ignore-blank-lines|B' => undef,
    'ignore-matching-lines|I=s' => undef,
    'text|a' => undef,
    'strip-trailing-cr' => undef,
    'ifdef|D=s' => undef,
    'GTYPE-group-format=s' => undef,
    'line-format=s' => undef,
    'LTYPE-line-format=s' => undef,
    'minimal|d' => undef,
    'horizon-lines=i' => undef,
    'speed-large-files' => undef,
    'help' => undef,
    'version|v' => undef,
    },
};

1;
# ABSTRACT: Metadata for diff CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

CLI::Meta::diff - Metadata for diff CLI

=head1 VERSION

This document describes version 0.001 of CLI::Meta::diff (from Perl distribution CLI-Meta-diff), released on 2020-12-01.

=head1 SYNOPSIS

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CLI-Meta-diff>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CLI-Meta-diff>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CLI-Meta-diff>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
