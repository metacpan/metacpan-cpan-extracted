
use strict;
use warnings;

package Authen::SASL::Perl::SCRAM_SHA_512;

=head1 NAME

Authen::SASL::Perl::SCRAM_SHA_512 - SCRAM-SHA-512 support for Authen::SASL

=head1 VERSION

0.04

=head1 SYNOPSIS

   # with Authen::SASL::SCRAM installed
   use Authen::SASL;

   my $client = Authen::SASL->new(
        username => 'user',
        password => 'pass',
        mechanism => 'SCRAM-SHA-512'
   );
   # authenticates using SCRAM SHA-512 hash

=cut

use parent 'Authen::SASL::SCRAM';

our @VERSION = '0.04';

sub _order { 12 }

sub digest {
    return 'SHA-512';
}

=head1 BUGS

Please report bugs via
L<https://github.com/ehuelsmann/authen-sasl-scram/issues>.

=head1 SEE ALSO

L<Authen::SASL>, L<Authen::SASL::SCRAM>, L<Authen::SCRAM>

=head1 AUTHOR

Erik Huelsmann <ehuels@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2023 Erik Huelsmann. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

1;
