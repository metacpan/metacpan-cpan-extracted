package Business::BankList;

our $VERSION = '0.011'; # VERSION

1;
# ABSTRACT: List banks/financial institutions


__END__
=pod

=head1 NAME

Business::BankList - List banks/financial institutions

=head1 VERSION

version 0.011

=head1 SYNOPSIS

=head1 DESCRIPTION

B<NOTE: This module is still empty without implementation.>

This module provides a way to get a list of banks/financial institutions. The
primary use is to get SWIFT code/BIC/IBAN or the like. This module is meant to
be a "master" module. There will be submodules for each country, e.g.
L<Business::BankList::Indonesia>, and so on. Each country can provide additional
information like country-specific codes.

=head1 SEE ALSO

L<Business::BankList::Indonesia>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

