package Acme::PERLANCAR::DumpImportArgs;

our $DATE = '2019-01-31'; # DATE
our $DIST = 'Acme-PERLANCAR-DumpImportArgs'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use Data::Dump;

sub import {
    print "Import arguments: ";
    dd @_;
}

1;
# ABSTRACT: Dump import arguments

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::PERLANCAR::DumpImportArgs - Dump import arguments

=head1 VERSION

This document describes version 0.001 of Acme::PERLANCAR::DumpImportArgs (from Perl distribution Acme-PERLANCAR-DumpImportArgs), released on 2019-01-31.

=head1 SYNOPSIS

 use Acme::PERLANCAR::DumpImportArgs 1, {2=>3};

will print:

 Import arguments: (1, {2 => 3})

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-PERLANCAR-DumpImportArgs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-PERLANCAR-DumpImportArgs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-PERLANCAR-DumpImportArgs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
