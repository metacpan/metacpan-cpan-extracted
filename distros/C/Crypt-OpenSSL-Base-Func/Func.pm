# ABSTRACT: Base Functions, using the OpenSSL libraries
package Crypt::OpenSSL::Base::Func;

use strict;
use warnings;


use Carp;    # Removing carp will break the XS code.

our $VERSION = '0.02';

our $AUTOLOAD;
use AutoLoader 'AUTOLOAD';

use XSLoader;
XSLoader::load 'Crypt::OpenSSL::Base::Func', $VERSION;

BEGIN {
    eval { 
        require Exporter; 
        require DynaLoader; 
    };
}            ## no critic qw(RequireCheckingReturnValueOfEval);

our @ISA = qw(Exporter DynaLoader); 
our @EXPORT = qw( aes_cmac ecdh PKCS12_key_gen PKCS5_PBKDF2_HMAC ); 

1;

__END__
