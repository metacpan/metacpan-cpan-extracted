package Acme::Test::LocaleTextDomainIfEnv;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-26'; # DATE
our $DIST = 'Acme-Test-LocaleTextDomainIfEnv'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Locale::TextDomain::IfEnv 'Acme-Test-LocaleTextDomainIfEnv';

use Exporter qw(import);
our @EXPORT_OK = qw(hello);

sub hello {
    print __ "Hello, world\n";
}

1;
# ABSTRACT: Text Locale::TextDomain::IfEnv

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Test::LocaleTextDomainIfEnv - Text Locale::TextDomain::IfEnv

=head1 VERSION

This document describes version 0.001 of Acme::Test::LocaleTextDomainIfEnv (from Perl distribution Acme-Test-LocaleTextDomainIfEnv), released on 2019-12-26.

=head1 DESCRIPTION

This distribution is created for testing L<Locale::TextDomain::IfEnv>.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-Test-LocaleTextDomainIfEnv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-Test-LocaleTextDomainIfEnv>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-Test-LocaleTextDomainIfEnv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Locale::TextDomain::IfEnv>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
