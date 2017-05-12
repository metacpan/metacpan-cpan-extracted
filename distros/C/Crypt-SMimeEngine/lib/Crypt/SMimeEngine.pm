package Crypt::SMimeEngine;
use 5.008001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( &init
                     &sign
                     &verify
                     &getFingerprint
                     &getCertInfo
                     &ossl_version
                     &ossl_path
                     &load_privk
                     &getErrStr 
                     &digest );

our $VERSION = '0.06';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);


# COSTRUTTORE
#  IN:   opz. boolean - true nessun log, false altrimenti
#  OUT:  rif. oggetto se ok, stringa d'errore
#        altrimenti
#
sub init($$$$$;$) {
        my $cert_dir  = shift;
        my $cert      = shift;
        my $key       = shift;
        my $other_cert= shift;
        my $engine    = shift;
        my $pathso_eng= shift || '';

    $engine = 'openssl' if !defined $engine;
    $other_cert = [] if(!defined $other_cert or ref($other_cert) ne 'ARRAY');

    return initialize(  $cert_dir,
                        $cert,
                        $key,
                        $other_cert,
                        $engine,
                        $pathso_eng);
}

sub ossl_version {
    return ossl_param(0);
}

sub ossl_path {
    return ossl_param(5);
}

1;
__END__




=head1 NAME

Crypt::SMimeEngine - Interface to OpenSSL for SMIME commands with hardware 
engines support.

=head1 SYNOPSIS

  use Crypt::SMimeEngine qw(&init 
                            &sign 
                            &verify 
                            &getFingerprint 
                            &getCertInfo 
                            &load_privk
                            &getErrStr 
                            &digest
                            &ossl_version);

  $cert_dir = 'certs/';           # path trusted certificate
  $cert = 'certs/cert.pem';       # path signer certificate
  $key = 'certs/key.pem';         # path private key
  $other_cert = [];               # certs to add
  $file = 'files/testfile.bin';   # path file
  
  # let me inizialize the module with openssl engine (no hw engine)
  $engine_type = 'openssl';
  $out = init($cert_dir, $cert, $key, $other_cert, $engine_type);
  die "Errore in initialize process: ".getErrStr()."\n" if $out;
  print "Init OK\n";

  # now inizialize the module with a hardware engine.
  # You can load every engine openssl compatible;
  # if you want a list of these engines try this command on your server
  # openssl engine
  #  
  # ex: if you choose nCipher hardware engine support
  # try the next snip
  
  # XXX REMENBER
  # XXX this module is tested from me only upon nCipher netHsm!!!
  # XXX Please let me know if you try with succesfully with other hw engine

  $engine_type = 'chil';
  $engine_lib  = '/opt/nfast/toolkits/hwcrhk/libnfhwcrhk.so'; # XXX verify on your installation!!!
  $out = init($cert_dir, $cert, $key, $other_cert, $engine_type, $engine_lib);
  die "Errore in initialize process: ".getErrStr()."\n" if $out;
  print "Init OK\n";
  
  # SIGN
  $mail_in = 'MAIL/mail.txt';
  $mail_out = 'MAIL/mail.txt.signed';
  $out  = sign($mail_in, $mail_out);
  print $out ? "Error sign: ".getErrStr()."\n":"Sign OK\n";

  # VERIFY
  $noverify = 1; # true no verify the chain, false otherwise
  $out  = verify($mail_out, $cert, $noverify);
  print $out ? "Verify: ".getErrStr()."\n":"Verify OK\n";
  
  # LOAD NEW KEY-CERTIFICATE
  $out = load_privk($new_key, $new_cert);
  print $out ? "Error to load new key-cert: ".getErrStr()."\n":"load_privk OK\n";
  
  # get the certificate fingerprint 
  $schema = 'sha1';
  $out = getFingerprint($cert, $schema);
  if(defined $out){
    print "Fingerprint ($cert): $out\n";
  }else{
    print "Errore to get fingerprint: ".getErrStr(),"\n";
  }
  
  # get the file digest
  $schema = 'sha1';
  $out = digest($file, $schema);
  if(defined $out){
    print "Digest ($file): $out\n";
  }else{
    print "Errore to get digest: ".getErrStr(),"\n";
  }

  # get the CERTIFICATE INFORMATION
  $obj = getCertInfo($cert);
  if(ref($obj)){
    print "Cert information:\n";
    print "ISSUER: ".$obj->{'issuer'},"\n";
    print "SUBJECT: ".$obj->{'subject'},"\n";
    print "SERIAL: ".$obj->{'serial'},"\n";
    print "STARTDATE: ".$obj->{'startdate'},"\n";
    print "ENDDATE: ".$obj->{'enddate'},"\n";
    print "EMAIL: ".$obj->{'v3_email'},"\n";
  }else{
    print "Error in getCertInfo: ".getErrStr(),"\n" ;
  }

=head1 DESCRIPTION

This module is a simple interface with native function of openssl for 
SMIME manipulation. 
It can be work with compatible openssl hardware engines.
At this time the module does not realize encription/description functions.
Write to the author if you are interested.

=head1 FUNCTIONS

=over 4

=item init ( CAPATH, CERTSIGNER, KEY, CERTFILE, ENGINE, LIBRARY )

Initializes the module. It has to be called only one time before to call the 
other functions.

=over 4

=item CAPATH

Trusted certificates directory.

=item CERTSIGNER

Signer certificate file.

=item KEY

Private key.

=item ENGINE

It has to be a hardware device openssl compatible (ex: 'chil').
For an exaustive list try this snip on your server installation:
openssl engine.

My openssl installation says (OpenSSL 0.9.7i 14 Oct 2005)
(dynamic) Dynamic engine loading support
(cswift) CryptoSwift hardware engine support
(chil) nCipher hardware engine support
(atalla) Atalla hardware engine support
(nuron) Nuron hardware engine support
(ubsec) UBSEC hardware engine support
(aep) Aep hardware engine support
(sureware) SureWare hardware engine support
(4758cca) IBM 4758 CCA hardware engine support

If you have not any hardware device put it as undef or 'openssl'.

=item LIBRARY

Set it with your library engine implementation or undef if you have not a 
hardware device.
For example, if you have a standard installation of nCipher HSM you can 
fill it with '/opt/nfast/toolkits/hwcrhk/libnfhwcrhk.so'

=back

=item sign ( MAIL2SIGN, MAILSIGNED )

Sign an email.
Return 0 if ok, 1 otherwise.
If you get 1 call getErrStr() for an error description.

=over 4

=item MAIL2SIGN

Path mail to sign.

=item MAILSIGNED

Path mail signed.

=back

=item verify ( MAILSIGNED, CERTSIGNER, NOVERIFY )

Verify signed message.
Return 0 if ok, 1 otherwise.
If you get 1 call getErrStr() for an error description.

=over 4

=item MAILSIGNED

Path mail signed to verify.

=item CERTSIGNER

Path signer certificate file.

=item NOVERIFY

if 1 (or true value) don't verify signers certificate; if 0 (or false ) 
otherwise.

=back

=item getFingerprint ( CERT, SCHEMA )

Return the certificate fingerprint.
Return undef if an error occur; call getErrStr() for an error description.

=over 4

=item CERT

Path of certificate.

=item SCHEMA

Hash schema type; it can be 'md2' or 'md5' or 'sha1'.

=back

=item digest ( FILE, SCHEMA )

Return the message digest of a supplied file in hexadecimal form.
Return undef if an error occur; call getErrStr() for an error description.

=over 4

=item FILE

Path of the file to get HASH.

=item SCHEMA

Hash schema type; it has to be openssl schema supported, see openssl dgst --help
Ex: 'md4', 'md5', 'md2', 'sha', 'sha1', 'ripemd160', 'sha224', 'sha256', 'sha384', 'sha512' or 'whirlpool'

=back

=item getCertInfo ( CERT )

Return a hash ref of the certificate information.
The key are:
issuer (issuer DN)
subject (subject DN)
serial (serial number value)
startdate (notBefore field)
enddate (notAfter field)
email (email address/es) 

=over 4

=item CERT

Path of certificate.

=back

=item load_privk ( NEWPRIVKEY, NEWCERT )

Load a new private key / certificate pair.
Return 0 if ok, 1 otherwise.
If you get 1 call getErrStr() for an error description.

=over 4

=item NEWPRIVKEY

New private key.

=item NEWCERT

New signer certificate file.

=back

=item getErrStr

Return an error description of the last failed command.
Return undef otherwise.

=item ossl_version

Return the openssl version (ex: 'OpenSSL 0.9.7i 14 Oct 2005')

=back

=head1 BUGS

Let me know...

=head1 SUPPORT

Try to contact the author.

=head1 AUTHOR

    Flavio Fanton
    EXEntrica s.r.l. - Aruba PEC
    flavio.fanton@staff.aruba.it
    http://www.exentrica.it

=head1 THANKS TO

    Luca Di Vizio
    EXEntrica s.r.l. - Aruba PEC
    luca.divizio@staff.aruba.it
    http://www.exentrica.it

    Lorenzo Gaggini
    EXEntrica s.r.l. - Aruba PEC
    lorenzo.gaggini@staff.aruba.it
    http://www.exentrica.it

    Emanuele Tomasi
    EXEntrica s.r.l. - Aruba PEC
    et@libersoft.it
    http://www.exentrica.it

	=head1 COPYRIGHT

    Copyright (c) 2006-2014 EXEntrica s.r.l.
    All rights reserved.

    You may distribute under the terms of the GNU General Public License.

    The full text of the license can be found in the LICENSE file included
    with this module.


=head1 SEE ALSO

openssl(1).

=cut
