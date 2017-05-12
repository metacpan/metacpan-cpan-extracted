package Crypt::Libmcrypt;
#ABSTRACT: Perl extension for libmcrypt,the mcrypt cryptographic library
use 5.006000;
use strict;
use warnings;
use Carp;

require Exporter;
use SelfLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Crypt::Libmcrypt ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	MCRYPT_API_VERSION
	MCRYPT_FAILED
	mcrypt_check_version
	mcrypt_enc_get_state
	mcrypt_enc_get_supported_key_sizes
	mcrypt_enc_mode_has_iv
	mcrypt_enc_set_state
	mcrypt_free
	mcrypt_free_p
	mcrypt_generic
	mcrypt_generic_deinit
	mcrypt_generic_end
	mcrypt_generic_init
	mcrypt_module_algorithm_version
	mcrypt_module_close
	mcrypt_module_get_algo_block_size
	mcrypt_module_get_algo_key_size
	mcrypt_module_get_algo_supported_key_sizes
	mcrypt_module_is_block_algorithm
	mcrypt_module_is_block_algorithm_mode
	mcrypt_module_is_block_mode
	mcrypt_module_mode_version
	mcrypt_module_open
	mcrypt_module_self_test
	mcrypt_module_support_dynamic
	mcrypt_perror
	mcrypt_strerror
	mdecrypt_generic
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	MCRYPT_API_VERSION
	MCRYPT_FAILED
);

our $VERSION = '1.0.5';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Crypt::Libmcrypt::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Crypt::Libmcrypt', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__DATA__
# Below is stub documentation for your module. You'd better edit it!

=pod

=encoding utf8

=head1 NAME

Crypt::Libmcrypt

=head1 VERSION

version 1.0.5

=head1 SYNOPSIS

  use Crypt::Libmcrypt;
  

=head1 DESCRIPTION

Perl extension for libmcrypt,the mcrypt cryptographic library.

=head2 EXPORT

None by default.

=head2 Exportable constants

  MCRYPT_API_VERSION
  MCRYPT_FAILED

=head2 Exportable functions

  const char * mcrypt_check_version( const char *)
  int mcrypt_enc_get_state(MCRYPT td, void *st, int *size)
  int *mcrypt_enc_get_supported_key_sizes(MCRYPT td, int *len)
  int mcrypt_enc_mode_has_iv(MCRYPT td)
  int mcrypt_enc_set_state(MCRYPT td, void *st, int size)
  void mcrypt_free(void *ptr)
  void mcrypt_free_p(char **p, int size)
  int mcrypt_generic(MCRYPT td, void *plaintext, int len)
  int mcrypt_generic_deinit(const MCRYPT td)
  int mcrypt_generic_end(const MCRYPT td)
  int mcrypt_generic_init(const MCRYPT td, void *key, int lenofkey, void *IV)
  int mcrypt_module_algorithm_version(char *algorithm,char *a_directory)
  int mcrypt_module_close(MCRYPT td)
  int mcrypt_module_get_algo_block_size(char *algorithm,char *a_directory)
  int mcrypt_module_get_algo_key_size(char *algorithm, char *a_directory)
  int *mcrypt_module_get_algo_supported_key_sizes(char *algorithm,char *a_directory,int *len)
  int mcrypt_module_is_block_algorithm(char *algorithm,char *a_directory)
  int mcrypt_module_is_block_algorithm_mode(char *mode,char *m_directory)
  int mcrypt_module_is_block_mode(char *mode, char *m_directory)
  int mcrypt_module_mode_version(char *mode, char *a_directory)
  MCRYPT mcrypt_module_open(char *algorithm,char *a_directory, char *mode,char *m_directory)
  int mcrypt_module_self_test(char *algorithm, char *a_directory)
  int mcrypt_module_support_dynamic(void)
  void mcrypt_perror(int err)
  const char* mcrypt_strerror(int err)
  int mdecrypt_generic(MCRYPT td, void *plaintext, int len)


=head1 SEE ALSO

L<MCrypt|http://mcrypt.sourceforge.net>

=head1 AUTHOR

Li ZHOU, E<lt>lzh@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Li ZHOU

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
