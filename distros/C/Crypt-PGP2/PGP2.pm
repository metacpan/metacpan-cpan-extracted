package Crypt::PGP2;

use strict;
use diagnostics;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use vars qw / $VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK /;

@ISA = qw(Exporter);

%EXPORT_TAGS = ( );

@EXPORT = qw ( encrypt PGP_ERR_SUCCESS PGP_ERR_FAIL PGP_ERR_BAD_OPTIONS PGP_ERR_MISSING_KEY PGP_ERR_MISSING_TEXT );

@EXPORT_OK = ();

use IPC::Open3;

$VERSION = '0.03';

1;

sub PGP_ERR_SUCCESS { 0 }

sub PGP_ERR_FAIL { 1 }

sub PGP_ERR_BAD_OPTIONS { 2 }

sub PGP_ERR_MISSING_KEY { 3 }

sub PGP_ERR_MISSING_TEXT { 4 }

# Program: encrypt
# Author : James Briggs
# Date   : 2001 01 22
# Version: see $VERSION
# Purpose: generate PGP ciphertext using external pgp utility
# Env    : Perl5 and IPC::Open3
# Usage  : my ($ciphertext, $msg, $error) = Crypt::PGP2::encrypt($plaintext,'my secret text','at');
# Returns: list with 3 elements (see POD for details)
# Notes  : see the POD documentation also
#          - Perl signals should not be used to monitor the pipes as they are unsafe
#            However, the $msg return will give the pgp status code, if available.
#          - Only 3 files are needed to encrypt a file with a public key:
#            pubring.pgp, randseed.bin, and config.txt (chmod 400 *) ?
#          - permissions on tmp, .pgp must be set correctly (chmod 100 .pgp) ?
#          - PGP generates temp files. The names of these files can be seen when +verbose=3
#          - You must use more than 512 bit keys to be secure.

sub encrypt {
   # retrieve arguments
   my ($plaintext, $key, $options) = @_;

   return ('', '', PGP_ERR_MISSING_KEY) if not defined $key or $key eq '';
   return ('', '', PGP_ERR_MISSING_TEXT) if not defined $plaintext or $plaintext eq '';

   # set explicit path to PGP binary
   my $pgp = '/usr/local/bin/pgp';

   $ENV{'PGPPATH'} = '/.pgp';

   my $ciphertext = '';
   my $msg        = '';
   my $error      = '';

   # assign defaults if blank options

   # -a means ASCII armour
   # -t means portable text newlines

   $options = 'at' if not defined $options or $options eq '';

   # only allow certain pgp options
   return ('', '', PGP_ERR_BAD_OPTIONS) if $options !~ /^[at]+$/;

   # this module needs leading '-' and pgp filter option 'fe'
   $options = '-fe' . $options;

   my $pid = open3 \*WRITE, \*READ, \*ERROR, $pgp, $options, $key;

   return ('', '', PGP_ERR_FAIL) if ! $pid;
   
   print WRITE $plaintext;

   close WRITE;
      
   $ciphertext = join '', <READ>;

   close READ;
   
   $msg = "$pgp $options $key\n";

   $msg .= join '', <ERROR>;

   close ERROR;
      
   return ($ciphertext, $msg, PGP_ERR_SUCCESS);
}
__END__

=head1 NAME

Crypt::PGP2 - module for programmatic PGP 2.x on Unix

=head1 DESCRIPTION

Perl module wrapper for Unix PGP 2.x

You can get PGP from ftp://ftp.cert.dfn.de/pub/tools/crypt/pgp/pgpi/2.x/src/

This module:

=over 4

=item *

is a wrapper that does parameter validation and provides application
isolation from the external pgp program

=item *

returns the PGP banner and error constants.

=back

=head1 PARAMETERS

The parameters are positional:

   $plaintext   Plaintext that you want to encrypt.
		(mandatory)

   $key         keyring id of recipient who has a public key.
		(mandatory)

   $options     PGP options you want, limited to any combination of 'a', and 't'.
                # -a means ASCII armour, needed when emailing ciphertext
                # -t means portable text newlines, needed for portability
		(Optional - default is -feat)

=head1 RETURN CODES

 encrypt returns a list of 3 scalars like this: ($ciphertext, $message, $error)

 $ciphertext    Ciphertext result of encrypting $Plaintext.

 $message       pgp statement and pgp banner returned from external program

 $error         error status from this program

 PGP_ERR_SUCCESS       - success
 PGP_ERR_FAIL          - failure to start external command
 PGP_ERR_BAD_OPTIONS   - optional pgp options invalid
 PGP_ERR_MISSING_KEY   - mandatory keyring ID missing
 PGP_ERR_MISSING_TEXT  - mandatory plaintext missing

=head1 SAMPLE PROGRAM

 #!/usr/bin/perl -Tw

 $ENV{'PATH'} = '';

 use strict;      # must scope all symbols
 use diagnostics; # lint checking and verbose warnings

 use Crypt::PGP2;

 my $plaintext = 'Sample plaintext';
 my ($ciphertext, $msg, $error) = encrypt($plaintext,'james','at');

 if ($error == PGP_ERR_SUCCESS) {
    print "Ciphertext: $ciphertext\nMsg: $msg\nError: $error\n";
 }
 else {
    print "PGP error: $error\n";
 }

=head1 NOTES

 PGP creates temporary work files, but we don't have
 control over this. This may be a security and reliability problem
 that you should investigate.

 Note that to encrypt a message, the only key required is the
 public key of the recipient. No private keys are required,
 so not even your private keyring needs to be on the same
 machine as the webserver. Only when signing a message or
 deciphering a message is a private key or keyring required.

 Your minimum key length should be 1024 bits and should be changed 
 regularly.

=head1 BUGS

See Notes for general concerns. This module relies on Open3, which may not be supported on Windows NT. Only recent versions of Open3 do not leak memory.

=head1 AUTHORS

james@rf.net

=head1 VERSION

See $VERSION

=cut
