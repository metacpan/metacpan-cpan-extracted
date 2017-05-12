# Apache::AppSamurai::Session::Serialize::CryptBase64 - Apache::Session
#                                Serialize module.  Replaces Base64 serializer
#                                with one that uses Crypt::CBC to
#                                encrypt the Base64 encoded and frozen data
#                                before encoding into Base64 for final delivery

# $Id: CryptBase64.pm,v 1.18 2008/04/30 21:40:12 pauldoom Exp $

##
# Copyright (c) 2008 Paul M. Hirsch (paul@voltagenoir.org).
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
##

package Apache::AppSamurai::Session::Serialize::CryptBase64;
use strict;
use warnings;

use Crypt::CBC 2.17;
use MIME::Base64;
use Storable qw(nfreeze thaw);

use vars qw($VERSION);
$VERSION = substr(q$Revision: 1.18 $, 10, -1);

# Set keylength in hex chars (bytes x 2) - This should stay 64 (256bits)
# at least.  Note that the session key generator must have the same
# size output
my $keylength = 64;

# Only listed ciphers are allowed
my @allowedciphers = (
		      'Crypt::OpenSSL::AES',
		      'Crypt::Rijndael',
		      'Crypt::Twofish',
		      'Crypt::Blowfish',
		      );

# A cipher lookup table
my %allowedcl = map { $_ => 1 } @allowedciphers;


sub serialize {
    my $session = shift;
    
    # Setup crypt engine
    my $c = &setup_crypt($session);
    
    # Turn off Crypt::CBC automatic salt creation - (Note: This is done to
    # avoid a taint bug related to Crypt::CBC and some cipher modules.
    # Eventually this should be fixed and all salt handling should be done
    # by Crypt::CBC)
    $c->{make_random_salt} = 0;
    
    # Use existing salt or create one if not set
    unless ($session->{args}->{salt}) {
	$session->{args}->{salt} = $c->random_bytes(8);
    }
    
    # Check for valid salt and untaint
    ($session->{args}->{salt} =~ /^(.{8})$/s) or die "Invalid salt value (must be 8 bytes)";
    $c->salt($1);
    
    # Enfruzen!! Enkryptor!!!  Enmimeor!!!  (Crypt it then Base64 encode)
    (my $serialized = encode_base64($c->encrypt(nfreeze($session->{data})),'')) or die "Problem while serializing data: $!";
    
    $session->{serialized} = $serialized;
}

sub unserialize {
    my $session = shift;
    my $data = '';
    
    # Setup key and crypt instance
    my $c = &setup_crypt($session);
    
    # Demimeor! Dekryptor! Unfruzen! (Demime, decrypt, thaw, rock!)
    ($data = thaw($c->decrypt(decode_base64($session->{serialized})))) or die "Problem while unserializing data: $!";
    
    $session->{data} = $data;
    
    # Save salt value (value is maintained per session - this does not
    # pass over the hostile network, so I THINK it is not an issue. Comment
    # this code out for a per-write new salt to be generated
    ($session->{args}->{salt} = $c->salt()) or die "Could not retrive salt value for session";
    
}

# Create symmetric key and create encryption instance
sub setup_crypt {
    my $session = shift;
    
    # Very basic key checks
    (defined($session->{args}->{ServerKey}) && ($session->{args}->{ServerKey} =~ /^[a-f0-9]{$keylength}$/)) or die "ServerKey not set or invalid for use with this module";
    (defined($session->{args}->{key}) && ($session->{args}->{key} =~ /^[a-f0-9]{$keylength}$/)) or die "Session authentication key not set or invalid for use with this module $session->{args}->{key}";
    
    # Build the full key by concatenating server and auth key.
    my $k = $session->{args}->{ServerKey} . $session->{args}->{key};
    
    if (!defined($session->{args}->{SerializeCipher})) {
	# Currently, a pre-configured crypt module is required.
	# find_crypt() could just as easily do it here, but making the
	# extenal code calling this module define it seems more appropriate.
	die "No session SerializeCipher defined!  Configure one of: " . join(',', @allowedciphers);

    # Check passed in cipher against list of supported ciphers.
    # (No, I will not allow you to use Crypt::DES.  So sorry.)
    } elsif (!exists($allowedcl{$session->{args}->{SerializeCipher}})) {
	die "Bad session SerializeCipher defined: \"" . $session->{args}->{SerializeCipher} . "\".  CryptBase64 requires one of: " . join(',', @allowedciphers);
    }
    
    # Only allow a specific set of 
    # Try to setup the encryptor.  (Note - key and block sizes are NOT
    # hardcoded below.  The default IV generator from Crypt::CBC is used.)
    my $c = Crypt::CBC->new(
			    -key => $k,
			    -cipher => $session->{args}->{SerializeCipher},
			    -header => 'salt'
			    );
    
    ($c) or die "Failed to create CBC encrypt/decrypt instance: $!";
    
    return $c;
}

# Search through list of allowed ciphers for one present on this system.
# (This should be called once per-run at most per-process. You don't want to be
# module searching on every call!)
sub find_cipher {
    
    # Search in order, returning the first found
    foreach (@allowedciphers) {
	if (eval "require $_") {
	    return $_;
	}
    }

    # Oh well.... nothing found
    return undef;
}

1; # End of Apache::AppSamurai::Session::Serialize::CryptBase64

__END__

=head1 NAME

Apache::AppSamurai::Session::Serialize::CryptBase64 - Storable, AES,
and MIME::Base64 for session serializer

=head1 SYNOPSIS

 use Apache::AppSamurai::Session::Serialize::CryptBase64;
 
 # You must choose a Crypt::CBC compatible cipher. (See the DESCRIPTION
 # section for the supported list.)  This can be done either by
 # setting a specific value (the recommended way):
 $s->{args}->{SerializeCipher} = 'Crypt::OpenSSL::AES';

 # ... or by using the find_cipher() utility method:
 $s->{args}->{SerializeCipher} = Apache::AppSamurai::Session::Serialize::CryptBase64::find_cipher

 # serialize and unserialze take a single hash reference with required
 # subhashes.  {args} must include two 256 bit hex string key/value pairs:
 # key = Session authentication key
 # ServerKey = Server key
 # (Examples keys are examples.  Don't use them!
 $s->{args}->{ServerKey} = "628b49d96dcde97a430dd4f597705899e09a968f793491e4b704cae33a40dc02";
 $s->{args}->{key} = "c44474038d459e40e4714afefa7bf8dae9f9834b22f5e8ec1dd434ecb62b512e";

 # serialize() operates on the ->{data} subhash
 $s->{data}->{test} = "Testy!";
 $zipped = Apache::Session::Serialize::Base64::serialize($s);

 # unserialize works on the ->{serialized} subhash
 $s->{serialized} = $zipped;
 $data = Apache::Session::Serialize::Base64::unserialize($s);

=head1 DESCRIPTION

This module fulfils the serialization interface of
L<Apache::Session|Apache::Session> and
L<Apache::AppSamurai::Session|Apache::AppSamurai::Session>.
It serializes the data in the session object by use of L<Storable|Storable>'s
C<nfreeze()> function.  Then, using the configured cipher module
in {args}->{SerializeCipher}, the passed in {args}->{key}, (session
authentication key), and the passed in {args}->{ServerKey}, (server key),
it encrypts using the C<encrypt()> method of L<Crypt::CBC|Crypt::CBC>. 
Finally, MIME::Base64 encode is used on the ciphertext for safe storage.

The unserialize method uses a combination of MIME::Base64's C<decode_base64>,
Crypt::CBC's decrypt, and Storable's thaw methods to decode, decrypt,
and reconstitute the data.

The serialized data is ASCII text, suitable for storage in backing stores that
don't handle binary data gracefully, such as Postgres.  The following
Crypt modules are currently supported:

 Crypt::Rijndael     - AES implementation
 Crypt::OpenSSL::AES - OpenSSL AES wrapper
 Crypt::Twofish      - Twofish implementation
 Crypt::Blowfish     - Blowfish implementation

The configured module must be installed before use.  For efficiency, it
is recommended that you staticly set the SerializeCipher argument when
calling this module.  That said, for convenience, a simple utility method,
find_cipher() is provided.

=head1 SEE ALSO

L<Apache::AppSamurai::Session>, L<Storable>, L<MIME::Base64>, 
L<Apache::Session>, L<Crypt::CBC>, L<Crypt::Rijndael>,
L<Crypt::OpenSSL::AES>, L<Crypt::Twofish>, L<Crypt::Blowfish>

=head1 AUTHOR

Paul M. Hirsch, C<< <paul at voltagenoir.org> >>

=head1 BUGS

See L<Apache::AppSamurai> for information on bug submission and tracking.

=head1 SUPPORT

See L<Apache::AppSamurai> for support information.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Paul M. Hirsch, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
