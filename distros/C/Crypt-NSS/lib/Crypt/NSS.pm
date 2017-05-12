package Crypt::NSS;

use 5.006002;
use strict;
use warnings;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Crypt::NSS', $VERSION);

require Crypt::NSS::SSL;
require Crypt::NSS::Certificate;
require Crypt::NSS::PKCS11;
require Net::NSS::SSL;

# We must always set a password hook before we can
# do anything with NSS. Default is an undefined password.
Crypt::NSS::PKCS11->set_password_hook(sub {
    my ($retry, $password) = @_;
    if (!$retry && $password) {
        return $password;
    }
    
    return undef;
});

my $initialized = 0;
sub import {
    return if $initialized;
    
    my $config_dir;
    my $cipher_suite = "US";
    
    while(@_) {
        my $arg = shift;
        if ($arg eq "config_dir") {
            $config_dir = shift;
        }
        elsif ($arg eq "init") {
            $config_dir = $ENV{NSS_CONFIG_DIR};
            $config_dir = "." unless $config_dir;
        }
        elsif ($arg eq "cipher_suite") {
            $cipher_suite = shift;
        }
    }
    
    if ($config_dir) {
        Crypt::NSS->set_config_dir($config_dir);
        Crypt::NSS->initialize();
        Crypt::NSS::SSL->set_cipher_suite($cipher_suite);
        $initialized = 1;
    }
    
    1;
}

END {
    Crypt::NSS->shutdown();
}

1;
__END__

=head1 NAME

Crypt::NSS - Perl bindings to NSS (Netscape Security Services)
  
=head1 DESCRIPTION

This module provides an interface to Netscape Security Services (NSS) which is a set of libraries 
that Firefox, Thunderbird and several other applications uses for crypto, secure sockets, 
signing mail etc. NSS provides support for SSL v2 and v3, TLS, PKCS #5, PKCS #7, PKCS #11, PKCS #12, S/MIME, 
X.509 v3 certificates, and other security standards.

Currently this module only implements the SSL bits but in the future (patches welcome!!) most of NSS will 
be available via this module.

=head1 INTERFACE

=head2 MODULE IMPORT

During import no initalization is normally done. It's however possible to do this by passing either 
C<config_dir =E<gt> PATH> or C<init>. If the later, import checks for the environment C<NSS_CONFIG_DIR> 
and sets the config dir to that if set.

=head2 CLASS METHODS

=over 4

=item config_dir ( ) : string

Returns the path where to look for C<cert8.db>, C<key3.db> and C<secmod.db> databases upon initialization.

=item set_config_dir ( $directory : string ) : boolean

Specify the path to the directory where the C<cert8.db>, C<key3.db> and C<secmod.db> databases can be found. 
It's only allowed to set the directory prior to initialization or this method with return a false value.

=item is_initialized ( ) : boolean

Returns whether the underlying NSS library has been initialized or not.

=item initialize ( ) : integer

Initializes NSS. Returns 0 on success or an error code on failure. Initialization is usually done 
when importing this module by passing either C<config_dir =E<gt> $path> or C<init> to use 
the default config directory (C<.>).

=item shutdown ( )

Closes the certificate and key databases.

=back

=head1 ISSUES THAT ARE NOT BUGS

=over 4

=item Forking and outgoing sockets

If your script forks after it has done initialization and you try to open a outgoing socket, ie. 
one that connects to a remote host, you'll get failures like "-12215 MD5 digest function failed".

This is not a bug in this module and is a recent fix in the underlying NSS library. The PKCS#11 standard 
says that after a fork all PKCS#11 modules must be reinitialized again. So if you want to fork, make sure 
you don't initialize NSS in the parent process.

L<https://bugzilla.mozilla.org/show_bug.cgi?id=331096>

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-nss@rt.cpan.org>, 
or through the web interface at L<http://rt.cpan.org>.

=head1 SUPPORT

Commercial support is available from Versed Solutions. Contact author for details.

=head1 AUTHOR

Claes Jakobsson, Versed Solutions C<< <claesjac@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Versed Solutions C<< <info@versed.se> >>. All rights reserved.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
