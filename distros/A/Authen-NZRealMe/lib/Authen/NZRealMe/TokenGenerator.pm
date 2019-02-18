package Authen::NZRealMe::TokenGenerator;
$Authen::NZRealMe::TokenGenerator::VERSION = '1.18';
use strict;
use warnings;

use Digest::MD5  qw(md5_hex);


# Use urandom if available (it's called "random" on FreeBSD)

my($random_device) = grep { -r $_ } qw( /dev/urandom /dev/random );


sub new {
    my $class = shift;
    return bless {}, $class;
}


sub saml_id {
    my $self = shift;

    return $self->strong_token || $self->weak_token(@_);
}


sub strong_token {
    return unless $random_device;
    my $required = 20;
    open my $fh, '<', $random_device or die "open($random_device): $!";
    my $bytes = '';
    while(length($bytes) < $required) {
        my $cur = length($bytes);
        sysread($fh, $bytes, $required - $cur, $cur)
            or die "Error reading from $random_device: $!";
    }
    return ('a'..'f')[rand(6)]  # id string must start with a letter
           . unpack('H*', $bytes);
}


sub weak_token {
    return ('a'..'f')[rand(6)]  # id string must start with a letter
           . md5_hex( join(',', "@_", caller(), time(), rand(), $$) );
}


1;

__END__

=head1 NAME

Authen::NZRealMe::TokenGenerator - generate SAML ID strings

=head1 DESCRIPTION

This class is responsible for generating random ID tokens such as:

  e5111f121b7b5f8533d18d98e1ec8ade294c62cc3

Although the methods are described below, the preferred way to use this class
is via the ServiceProvider:

  $sp->generate_saml_id( args );

Any arguments provided will be ignored if C<strong_token> is used (see below)
or will be passed to C<weak_token> for the fallback implementation.

=head1 METHODS

=head2 new

Constructor.  Should not be called directly.  Instead, call:

  Authen::NZRealMe->token_generator();

=head2 saml_id

Generates and returns a hex-encoded random token (guaranteed to start with a
letter) using C<strong_token> if possible and C<weak_token> otherwise.

=head2 strong_token

On systems where the device F</dev/urandom> is available, it will be used.
This method will read 20 bytes from the random device and return a hex-encoded
representation of those bytes.

Otherwise, returns undef.

=head2 weak_token

Will be called if C<strong_token> is not able to find a strong source of random
data.  As this method uses Perl's built-in C<rand> function, which is not a
cryptographically strong source of randomness, its use should be avoided.

If your platform does not provide F</dev/urandom>, you are advised to use the
C<< Authen::NZRealMe->register_class >> method to provide an alternative
implementation for C<'token_generator'>.


=head1 SEE ALSO

See L<Authen::NZRealMe> for documentation index.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014-2019 Enrolment Services, New Zealand Electoral Commission

Written by Grant McLean E<lt>grant@catalyst.net.nzE<gt>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

