package CLI::Meta::cp;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-14'; # DATE
our $DIST = 'CLI-Meta-cp'; # DIST
our $VERSION = '0.001'; # VERSION

our $META = {
    opts => {
        'archive|a' => undef,
        'attributes-only' => undef,
        'backup=s' => {completion=>[qw/none off numbered t existing nil simple never/]},
        'b' => undef,
        'copy-contents' => undef,
        'd' => undef,
        'force|f' => undef,
        'interactive|i' => undef,
        'H' => undef,
        'link|l' => undef,
        'dereference|L' => undef,
        'no-clobber|n' => undef,
        'no-dereference|P' => undef,
        'p' => undef,
        'preserve=s' => undef,
        'no-preserve=s' => undef,
        'parents' => undef,
        'recursive|R|r' => undef,
        'reflink=s' => {completion=>[qw/auto always never/]},
        'strip-trailing-slashes' => undef,
        'symbolic-link|s' => undef,
        'suffix|S=s' => undef,
        'target-directory|t=s' => undef,
        'no-target-directory|T' => undef,
        'update|u' => undef,
        'verbose|v' => undef,
        'one-file-system|x' => undef,
        'Z' => undef,
        'context=s' => undef,
        'help' => undef,
        'version' => undef,
    },
};

1;
# ABSTRACT: Metadata for 'cp' Unix commnd

__END__

=pod

=encoding UTF-8

=head1 NAME

CLI::Meta::cp - Metadata for 'cp' Unix commnd

=head1 VERSION

This document describes version 0.001 of CLI::Meta::cp (from Perl distribution CLI-Meta-cp), released on 2021-11-14.

=head1 SYNOPSIS

=head1 DESCRIPTION

Based on cp from GNU coreutils 8.30.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CLI-Meta-cp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CLI-Meta-cp>.

=head1 SEE ALSO

L<CLI::Meta::mv>

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

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CLI-Meta-cp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
