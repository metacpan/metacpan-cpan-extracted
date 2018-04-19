package Class::Usul::Crypt::Util;

use strict;
use warnings;

use Class::Usul::Constants qw( FALSE NUL TRUE );
use Class::Usul::Crypt     qw( decrypt default_cipher encrypt );
use Class::Usul::Functions qw( merge_attributes throw );
use Exporter 5.57          qw( import  );
use File::DataClass::IO;
use Try::Tiny;

our @EXPORT_OK = qw( decrypt_from_config encrypt_for_config
                     get_cipher is_encrypted );

my $_args_cache = {};

# Private functions
my $_extract_crypt_params = sub { # Returns cipher and encrypted text
   # A single scalar arg not matching the pattern is just a cipher
   # It really is better this way round. Leave it alone
   return $_[ 0 ] && $_[ 0 ] =~ m{ \A [{] (.+) [}] (.*) \z }mx
        ? ($1, $2) : $_[ 0 ] ? ($_[ 0 ]) : (default_cipher, $_[ 0 ]);
};

my $_get_crypt_args = sub { # Sets cipher, salt, and seed keys in args hash
   my ($config, $cipher) = @_; my $params = {};

   # Works if config is an object or a hash
   merge_attributes $params, $config,
      [ qw( ctrldir prefix read_secure salt seed seed_file ) ];

   my $args = { cipher => $cipher,
                salt   => $params->{salt} // $params->{prefix} // NUL };
   my $file = $params->{seed_file} // $params->{prefix} // 'seed';

   if ($params->{seed}) { $args->{seed} = $params->{seed} }
   elsif (defined $_args_cache->{ $file }) {
      $args->{seed} = $_args_cache->{ $file };
   }
   elsif ($params->{read_secure}) {
      my $cmd = $params->{read_secure}." ${file}";

      try   { $args->{seed} = $_args_cache->{ $file } = qx( $cmd ) }
      catch { throw "Reading secure file ${file}: ${_}" }
   }
   else {
      my $path = io $file;

      $path->exists and ($path->stat->{mode} & 0777) == 0600
         and $args->{seed} = $_args_cache->{ $file } = $path->all;

      not $args->{seed}
         and $path = io( [ $params->{ctrldir} // NUL, "${file}.key" ] )
         and $path->exists and ($path->stat->{mode} & 0777) == 0600
         and $args->{seed} = $_args_cache->{ $file } = $path->all;
   }

   return $args;
};

# Public functions
sub decrypt_from_config ($$) {
   my ($config, $encrypted) = @_;

   my ($cipher, $cipher_text) = $_extract_crypt_params->( $encrypted );
   my $args = $_get_crypt_args->( $config, $cipher );

   return $cipher_text ? decrypt $args, $cipher_text : $encrypted;
}

sub encrypt_for_config ($$;$) {
   my ($config, $plain_text, $encrypted) = @_;

   $plain_text or return $plain_text;

   my ($cipher) = $_extract_crypt_params->( $encrypted );
   my $args     = $_get_crypt_args->( $config, $cipher );

   return "{${cipher}}".(encrypt $args, $plain_text);
}

sub get_cipher ($) {
   my ($cipher) = $_extract_crypt_params->( $_[ 0 ] ); return $cipher;
}

sub is_encrypted ($) {
   return $_[ 0 ] =~ m{ \A [{] .+ [}] .* \z }mx ? TRUE : FALSE;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Class::Usul::Crypt::Util - Decrypts / encrypts passwords from / to configuration files

=head1 Synopsis

   use Class::Usul::Crypt::Util qw(decrypt_from_config);

   $password = decrypt_from_config( $encrypted_value_from_file );

=head1 Description

Decrypts/Encrypts password from/to configuration files

=head1 Configuration and Environment

Implements a functional interface

=head1 Subroutines/Functions

=head2 decrypt_from_config

   $plain_text = decrypt_from_config( $params, $password );

Strips the C<{Twofish2}> prefix and then decrypts the password

=head2 encrypt_for_config

   $encrypted_value = encrypt_for_config( $params, $plain_text );

Returns the encrypted value of the plain value prefixed with C<{Twofish2}>
for storage in a configuration file

=head2 get_cipher

   $cipher = get_cipher( $encrypted_value );

Returns the name of the cipher used to encrypt the value

=head2 is_encrypted

   $bool = is_encrypted( $password_or_encrypted_value );

Return true if the passed argument matches the pattern for an
encrypted value

=head2 __extract_crypt_params

   ($cipher, $password) = __extract_crypt_params( $encrypted_value );

Extracts the cipher name and the encrypted password from the value stored
in the configuration file. Returns the default cipher and null if the
encrypted value does not match the proper pattern. The default cipher is
specified by the L<default cipher|Class::Usul::Crypt/default_cipher> function

=head2 __get_crypt_args

   \%crypt_args = __get_crpyt_args( $params, $cipher );

Returns the argument hash ref passed to L<Class::Usul::Crypt/encrypt>
and L<Class::Usul::Crypt/decrypt>

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=item L<Try::Tiny>

=item L<Exporter>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2018 Peter Flanigan. All rights reserved

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
