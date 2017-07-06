package Business::BankList;

our $VERSION = '0.012'; # VERSION

1;
# ABSTRACT: List banks/financial institutions

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::BankList - List banks/financial institutions

=head1 VERSION

This document describes version 0.012 of Business::BankList (from Perl distribution Business-BankList), released on 2017-07-04.

=head1 SYNOPSIS

=head1 DESCRIPTION

B<NOTE: This module is still empty without implementation.>

This module provides a way to get a list of banks/financial institutions. The
primary use is to get SWIFT code/BIC/IBAN or the like. This module is meant to
be a "master" module. There will be submodules for each country, e.g.
L<Business::BankList::Indonesia>, and so on. Each country can provide additional
information like country-specific codes.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Business-BankList>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Business-BankList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business-BankList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Business::BankList::Indonesia>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
