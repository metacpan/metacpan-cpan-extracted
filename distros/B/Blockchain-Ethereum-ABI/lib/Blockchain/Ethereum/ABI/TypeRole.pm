use v5.26;

use strict;
use warnings;
no indirect;
use feature 'signatures';

use Object::Pad;
# ABSTRACT: Type interface roles

package Blockchain::Ethereum::ABI::TypeRole;
role Blockchain::Ethereum::ABI::TypeRole;

our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.016';          # VERSION

method encode;

method decode;

method _configure;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::ABI::TypeRole - Type interface roles

=head1 VERSION

version 0.016

=head1 METHODS

=head2 encode

Encodes the given data to the type of the signature

=over 4

=back

ABI encoded hex string

=head2 decode

Decodes the given data to the type of the signature

=over 4

=back

check the child classes for return type

=head1 AUTHOR

Reginaldo Costa <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
