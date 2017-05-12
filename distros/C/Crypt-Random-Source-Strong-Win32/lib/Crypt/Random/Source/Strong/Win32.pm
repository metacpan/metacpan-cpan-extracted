package Crypt::Random::Source::Strong::Win32;
use 5.008;
use Any::Moose;
use Win32;
use Win32::API;
use Win32::API::Type;

our $VERSION = '0.07';

extends qw(
    Crypt::Random::Source::Strong
    Crypt::Random::Source::Base
);

has 'rtlgenrand' => (is => 'ro', isa => 'Win32::API', lazy_build => 1);

# For Windows 2000 only.
has 'crypt_context' => (is => 'ro', isa => 'Int', lazy_build => 1);
has 'cryptacquirecontext' => (is => 'ro', isa => 'Win32::API', 
                              lazy_build => 1);
has 'cryptgenrandom' => (is => 'ro', isa => 'Win32::API', lazy_build => 1);

# The type of cryptographic service provider we want to use.
# This doesn't really matter for our purposes, so we just pick
# PROV_RSA_FULL, which seems reasonable. For more info, see
# http://msdn.microsoft.com/en-us/library/aa380244(v=VS.85).aspx
use constant PROV_RSA_FULL => 1;

# Flags for CryptGenRandom:
# Don't ever display a UI to the user, just fail if one would be needed.
use constant CRYPT_SILENT => 64;
# Don't require existing public/private keypairs.
use constant CRYPT_VERIFYCONTEXT => 0xF0000000;

# For some reason, BOOLEAN doesn't work properly as a return type with Win32::API.
use constant RTLGENRANDOM_PROTO => <<END;
INT SystemFunction036(
  PVOID RandomBuffer,
  ULONG RandomBufferLength
)
END

our $IS_WIN2K;
BEGIN {
    my ($major, $minor) = (Win32::GetOSVersion())[1,2];
    $IS_WIN2K = ($major == 5 and $minor == 0) ? 1 : 0;
}

# This should be preferred over other generators, on Windows.
sub rank { 10 }

sub available {
    return 0 if !($^O eq 'MSWin32' or $^O eq 'cygwin');

    my $major = (Win32::GetOSVersion())[1];

    # Major 5 is Windows 2000 and above.
    return 0 if $major < 5;

    return 1;
}

sub get {
    my ($self, $n) = @_;

    my $buffer = chr(0) x $n;

    # Win2K requires a slower, bulkier solution.
    if ($IS_WIN2K) {
        my $context = $self->crypt_context;
        my $result = $self->cryptgenrandom->Call($context, $n, $buffer);
        if (!$result) {
            die "CryptGenRandom failed: $^E";
        }
        return $buffer;
    }

    my $result = $self->rtlgenrand->Call($buffer, $n);
    if (!$result) {
        die "RtlGenRand failed: $^E";
    }
    return $buffer;
}

sub _build_rtlgenrand {
    my $func = Win32::API->new('advapi32', RTLGENRANDOM_PROTO);
    if (!defined $func) {
        die "Could not import SystemFunction036: $^E";
    }
    return $func;
}

sub _build_cryptgenrandom {
    my $func = Win32::API->new("advapi32", 'CryptGenRandom', 'NNP', 'I');
    if (!defined $func) {
        die "Could not import CryptGenRandom: $^E" 
    }
    return $func;
}

sub _build_cryptacquirecontext {
    my $func = Win32::API->new("advapi32", 'CryptAcquireContextA', 'PPPNN', 'I');
    if (!defined $func) {
        die "Could not import CryptAcquireContext: $^E"
    }
    return $func;
}

sub _build_crypt_context {
    my ($self) = @_;
    my $func = $self->cryptacquirecontext;
    my $context = chr(0) x Win32::API::Type->sizeof('PULONG');
    my $result = $func->Call($context, 0, 0, PROV_RSA_FULL, 
                             CRYPT_SILENT | CRYPT_VERIFYCONTEXT);
    my $pack_type = Win32::API::Type::packing('PULONG');
    $context = unpack($pack_type, $context);
    if (!$result) {
        die "CryptAcquireContext failed: $^E";
    }
    return $context;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Crypt::Random::Source::Strong::Win32 - Get random data from the Windows API.

=head1 SYNOPSIS

 use Crypt::Random::Source::Strong::Win32;
 my $p = Crypt::Random::Source::Strong::Win32->new;
 my $data = $p->get(1024);

=head1 DESCRIPTION

This is a source of random data that uses the RtlGenRandom function on
Windows XP and above, and CryptGenRandom on Windows 2000.

This is considered to be a strong source of random data, as the CryptGenRandom
function, which is backed by RtlGenRandom, is documented as being a strong
source of random data.

If you are on Windows, this is the recommended way of getting random data.

=head1 METHODS

The same as L<Crypt::Random::Source::Base>. There is no need to seed this
source.

=head1 AUTHOR

Max Kanat-Alexander <mkanat@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 BugzillaSource, Inc.

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0. For details, see the
full text of the license at 
L<http://opensource.org/licenses/artistic-license-2.0.php>.

This program is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
or implied warranties. For details, see the full text of the
license at L<http://opensource.org/licenses/artistic-license-2.0.php>.
