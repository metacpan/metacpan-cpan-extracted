package Crypt::Scrypt;

use strict;
use warnings;

use Carp qw(croak);
use XSLoader;

our $VERSION    = '0.05';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

XSLoader::load(__PACKAGE__, $XS_VERSION);

my @errors = (
   'success',
   'getrlimit or sysctl(hw.usermem) failed',
   'clock_getres or clock_gettime failed',
   'error computing derived key',
   'could not read salt from /dev/urandom',
   'error in OpenSSL',
   'malloc failed',
   'data is not a valid scrypt-encrypted block',
   'unrecognized scrypt format',
   'decrypting input would take too much memory',
   'decrypting input would take too long',
   'key is incorrect',
   'error writing output file',
   'error reading input file',
);

my %defaults = (
    max_mem      => 0,
    max_mem_frac => 0.125,
    max_time     => 5,
);

sub new {
    my ($class, @params) = @_;
    my %params = (@params % 2) ? (key => @params) : @params;

    croak q('key' is required) unless defined $params{key};

    return bless \%params, $class;
}

sub encrypt {
    my ($self, $data, @params) = @_;
    my %params = (@params % 2) ? (key => @params) : @params;

    croak 'plaintext must be a scalar or scalar ref'
        if ref $data and 'SCALAR' ne ref $data;

    if (ref $self) {
        %params = (%defaults, %$self, %params);
    }
    else {
        croak q('key' is required) unless defined $params{key};
        %params = (%defaults, %params);
    }

    my ($status, $out) = _encrypt(
        $data, @params{qw(key max_mem max_mem_frac max_time)},
    );
    croak $errors[$status] || 'unknown scrypt error' if $status;

    return $out;
}

sub decrypt {
    my ($self, $data, @params) = @_;
    my %params = (@params % 2) ? (key => @params) : @params;

    croak 'ciphertext must be a scalar or scalar ref'
        if ref $data and 'SCALAR' ne ref $data;

    if (ref $self) {
        %params = (%defaults, %$self, %params);
    }
    else {
        croak q('key' is required) unless defined $params{key};
        %params = (%defaults, %params);
    }

    my ($status, $out) = _decrypt(
        $data, @params{qw(key max_mem max_mem_frac max_time)},
    );
    croak $errors[$status] || 'unknown scrypt error' if $status;

    return $out;
}


1;

__END__

=head1 NAME

Crypt::Scrypt - Perl interface to the scrypt key derivation function

=head1 SYNOPSIS

    use Crypt::Scrypt;

    my $scrypt = Crypt::Scrypt->new(
        key          => $key,
        max_mem      => $bytes,
        max_mem_frac => $fraction,
        max_time     => $seconds
    );
    my $ciphertext = $scrypt->encrypt($plaintext);
    my $plaintext  = $scrypt->decrypt($ciphertext);

    # or using class methods:
    my $ciphertext = Crypt::Scrypt->encrypt($plaintext,  key => $key, %args);
    my $plaintext  = Crypt::Scrypt->decrypt($ciphertext, key => $key, %args);

=head1 DESCRIPTION

The C<Crypt::Scrypt> module provides an interface to the scrypt key
derivation function. It is designed to be far more secure against hardware
brute-force attacks than alternative functions such as PBKDF2 or bcrypt.

=head1 CONSTRUCTOR

=head2 new

    $scrypt = Crypt::Scrypt->new(
        key          => $key,
        max_mem      => $bytes,
        max_mem_frac => $fraction,
        max_time     => $seconds
    );

=over

=item * key

The key used to encrypt the plaintext. This parameter is required.

=item * max_mem

The maximum number of bytes of memory to use for computation. If set to 0,
no maximum will be enforced; any other value less than 1 MiB will be treated
as 1 MiB.

Defaults to 0.

=item * max_mem_frac

The maximum fraction of available memory to use for computation. If this
value is set to 0 or more than 0.5 it will be treated as 0.5; this value
will never cause a limit of less than 1 MiB to be enforced.

Defaults to 0.125.

=item * max_time

The maximum number of seconds of CPU time for computation.

Defaults to 5 seconds.

=back

When encrypting, the key strength is maximized subject to the specified
limits; when decrypting, an error is returned if decrypting the data is not
possible within the specified limits.

=head1 METHODS

=head2 encrypt

    $ciphertext = $scrypt->encrypt($plaintext, %args)

Encrypts the plaintext and returns the ciphertext. The plaintext can be
either a scalar or scalar reference. Additional named arguments can override
any value provided to the constructor. Croaks on failure.

=head2 decrypt

    $plaintext  = $scrypt->decrypt($ciphertext, %args)

Decrypts the ciphertext and and returns the plaintext. The ciphertext can be
either a scalar or scalar reference. Additional named arguments can override
any value provided to the constructor. Croaks on failure.

=head1 SEE ALSO

L<http://www.tarsnap.com/scrypt.html>

L<http://git.chromium.org/gitweb/?p=chromiumos/third_party/libscrypt.git;a=tree>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Crypt-Scrypt>.  I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::Scrypt

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/crypt-scrypt>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-Scrypt>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-Scrypt>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Crypt-Scrypt>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-Scrypt/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
