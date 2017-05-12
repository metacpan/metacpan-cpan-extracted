package Class::Usul::Crypt;

use strict;
use warnings;

use Class::Usul::Constants qw( NUL );
use Class::Usul::Functions qw( create_token is_coderef is_hashref );
use Crypt::CBC;
use English                qw( -no_match_vars );
use Exporter 5.57          qw( import );
use MIME::Base64;
use Sys::Hostname;

our @EXPORT_OK = qw( cipher_list decrypt default_cipher encrypt );

my $DEFAULT = 'Twofish2'; my $SEED = do { local $RS = undef; <DATA> };

# Private functions
my $_decode = sub {
   my $v = $_[ 0 ]; $v =~ tr{ \t}{01}; pack 'b*', $v;
};

my $_prepare = sub {
   my $v = $_[ 0 ]; my $pad = " \t" x 8; $v =~ s{^$pad|[^ \t]}{}g; $v;
};

my $_dref = sub {
   (is_coderef $_[ 0 ]) ? ($_[ 0 ]->() // NUL) : ($_[ 0 ] // NUL);
};

my $_eval = sub {
   my $v = $_prepare->( $_[ 0 ] ); $v ? ((eval $_decode->( $v )) || NUL) : NUL;
};

my $_cipher_name = sub {
   (is_hashref $_[ 0 ]) ? $_[ 0 ]->{cipher} || $DEFAULT : $DEFAULT;
};

my $_compose = sub {
   $_eval->( $_dref->( $_[ 0 ]->{seed} ) || $SEED ).$_dref->( $_[ 0 ]->{salt} );
};

my $_new_crypt_cbc = sub {
   Crypt::CBC->new( -cipher => $_[ 0 ], -key => $_[ 1 ] );
};

my $_token = sub {
   create_token( $_compose->( $_[ 0 ] || {} ) );
};

my $_wards = sub {
   (is_hashref $_[ 0 ]) || !$_[ 0 ] ? $_token->( $_[ 0 ] ) : $_[ 0 ];
};

my $_cipher = sub {
   $_new_crypt_cbc->( $_cipher_name->( $_[ 0 ] ), $_wards->( $_[ 0 ] ) );
};

# Public functions
sub cipher_list () {
   return ( qw( Blowfish Rijndael Twofish2 ) );
}

sub decrypt (;$$) {
   return $_cipher->( $_[ 0 ] )->decrypt( decode_base64( $_[ 1 ] ) );
}

sub default_cipher () {
   return $DEFAULT;
}

sub encrypt (;$$) {
   return encode_base64( $_cipher->( $_[ 0 ] )->encrypt( $_[ 1 ] ), NUL );
}

1;

=pod

=head1 Name

Class::Usul::Crypt - Encryption / decryption functions

=head1 Synopsis

   use Class::Usul::Crypt qw(decrypt encrypt);

   my $args = q(); # OR
   my $args = 'salt'; # OR
   my $args = { salt => 'salt', seed => 'whiten this' };

   $args->{cipher} = 'Twofish2'; # Optionally

   my $base64_encrypted_text = encrypt( $args, $plain_text );

   my $plain_text = decrypt( $args, $base64_encrypted_text );

=head1 Description

Exports a pair of functions to encrypt / decrypt data. Obfuscates the default
encryption key

=head1 Configuration and Environment

The C<$key> can be a string (including the null string) or a hash reference
with I<salt> and I<seed> keys. The I<seed> attribute can be a code reference in
which case it will be called with no argument and the return value used

Lifted from L<Acme::Bleach> the default seed for the key generator has been
whitened and included in this source file

The seed is C<eval>'d in string context and then the salt is concatenated onto
it before being passed to L<create token|Class::Usul::Functions/create_token>.
Uses this value as the key for a L<Crypt::CBC> object

=head1 Subroutines/Methods

=head2 decrypt

   my $plain = decrypt( $salt || \%params, $encoded );

Decodes and decrypts the C<$encoded> argument and returns the plain
text result. See the L</encrypt> method

=head2 encrypt

   my $encoded = encrypt( $salt || \%params, $plain );

Encrypts the plain text passed in the C<$plain> argument and returns
it Base64 encoded. By default L<Crypt::Twofish2> is used to do the
encryption. The optional C<< $params->{cipher} >> attribute overrides this

=head2 cipher_list

   @list_of_ciphers = cipher_list();

Returns the list of ciphers supported by L<Crypt::CBC>. These may not
all be installed

=head2 default_cipher

   $ciper_name = default_cipher();

Returns I<Twofish2>

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Crypt::CBC>

=item L<Crypt::Twofish2>

=item L<Exporter>

=item L<MIME::Base64>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:

__DATA__
			  	   
  		 	 	 
 		 	 			
  	   			
 	     	 
		 				 	
	 		  			
   	 			 
 			 		 	
    		 	 
		 		 	 	
  		  			
 	  			  
	   	 		 
	  	 		 	
 	  		 	 
			  	  
