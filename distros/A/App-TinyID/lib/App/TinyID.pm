package App::TinyID;
$App::TinyID::VERSION = '1.1.0';
#ABSTRACT: Command line tool to encrypt and encrypt integer using Integer::Tiny

use strict;
use warnings;
use v5.10;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TinyID - Command line tool to encrypt and encrypt integer using Integer::Tiny

=head1 VERSION

version 1.1.0

=head1 SYNOPSIS

    # Encrypt number (using default key)
    tinyid -t 82323723  # => EuEuE0ul0

    # Decrypt encrypted value (using default key)
    tinyid -t EuEuE0ul0 -d  # => 82323723
    
    # Encrypt with non-default key
    tinyid -k uywn -e -t 90012  # => yyynnwynu

    # Decrypt with non-default key
    tinyid -k uywn -d -t yyynnwynu  # => 90012

=head1 DESCRIPTION

Encrypts and decrypts numeric using Integer::Tiny.

By default, the encryption key is: WEl0v3you

=head2 OPTIONS

=over 4

=item [-t|--text]

Text to encrypt and decrypt. You can only include integer values when encrypting.

=item [-e|--encrypt]

This encrypts integer values. Note that --text/-t must be included too.

=item [-d|--decrypt]

This decrypts the encrypted text. Note that --text/-t must be included too.

=item [-k|--key]

Overrides default key value: 'WEl0v3you'.

Note, that you cannot have more than one same character in the key.

    # Wrong
    tinyid -k tangzotangzo2929 -t 98273 -e

    # Right
    tinyid -k tangzo29 -t 828273 -e

=back

=head1 SEE MORE

L<Integer::Tiny>

=head1 AUTHOR

faraco <skelic3@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by faraco.

This is free software, licensed under:

  The MIT (X11) License

=cut
