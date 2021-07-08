package Acme::PERLANCAR::Dummy::ModuleFeatures::User1;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-22'; # DATE
our $DIST = 'Acme-PERLANCAR-Dummy'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

our %FEATURES = (
    Dummy => {
        feature2 => 1,
        feature3 => 'a',
    },
);

1;
# ABSTRACT: A user module for Module::Features::Dummy

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::PERLANCAR::Dummy::ModuleFeatures::User1 - A user module for Module::Features::Dummy

=head1 VERSION

This document describes version 0.002 of Acme::PERLANCAR::Dummy::ModuleFeatures::User1 (from Perl distribution Acme-PERLANCAR-Dummy), released on 2021-02-22.

=head1 DESCRIPTION

This is a dummy module for testing. It declares features from the
L<Dummy|Module::Features::Dummy> feature set.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-PERLANCAR-Dummy>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-PERLANCAR-Dummy>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-PERLANCAR-Dummy/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
