package Crypt::OpenSSL3::HPKE::Context;
$Crypt::OpenSSL3::HPKE::Context::VERSION = '0.010';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: Hybrid Public Key Encryption (RFC 9180) context

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::HPKE::Context - Hybrid Public Key Encryption (RFC 9180) context

=head1 VERSION

version 0.010

=head1 SYNOPSIS

 my $sender = $suite->new_sender;
 my $encap = $sender->encapsulate($public, $info);
 my $sealed1 = $sender->seal($payload, $aad);

 my $receiver = $suite->new_receiver;
 $receiver->decapsulate($encap);
 my $unsealed = $receiver->open($sealed1, $aad);

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=head2 decapsulate

=head2 encapsulate

=head2 export

=head2 get_seq

=head2 open

=head2 seal

=head2 set_authpriv

=head2 set_authpub

=head2 set_ikme

=head2 set_psk

=head2 set_seq

=head1 CONSTANTS

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Leon Timmermans.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
