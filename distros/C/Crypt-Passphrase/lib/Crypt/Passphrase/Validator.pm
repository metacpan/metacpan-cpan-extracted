package Crypt::Passphrase::Validator;
$Crypt::Passphrase::Validator::VERSION = '0.006';
use strict;
use warnings;

1;

#ABSTRACT: Base class for Crypt::Passphrase validators

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::Validator - Base class for Crypt::Passphrase validators

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This is a base class for validators. It requires any subclass to implement the following two methods:

=head1 METHODS

=head2 accepts_hash($hash)

This method returns true if this validator is able to process a hash. Typically this means that it's crypt identifier matches that of the validator.

=head2 verify_password($password, $hash)

This checks if a C<$password> satisfies C<$hash>.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
