=head1 NAME

Authen::DecHpwd - DEC VMS password hashing

=head1 SYNOPSIS

	use Authen::DecHpwd qw(
		UAI_C_AD_II UAI_C_PURDY UAI_C_PURDY_V UAI_C_PURDY_S
		lgi_hpwd
	);

	$hash = lgi_hpwd("JRANDOM", "PASSWORD", UAI_C_PURDY_S, 1234);

	use Authen::DecHpwd qw(vms_username vms_password);

	$username = vms_username($username);
	$password = vms_password($password);

=head1 DESCRIPTION

This module implements the C<SYS$HASH_PASSWORD> password hashing function
from VMS (also known as C<LGI$HPWD>), and some associated VMS username
and password handling functions.

The password hashing function is implemented in XS, with a hideously
slow pure Perl backup version for systems that can't handle XS.

=cut

package Authen::DecHpwd;

{ use 5.006; }
use warnings;
use strict;

use Digest::CRC 0.14 qw(crc32);

our $VERSION = "2.006";

use parent "Exporter";
our @EXPORT_OK = qw(
	UAI_C_AD_II UAI_C_PURDY UAI_C_PURDY_V UAI_C_PURDY_S
	lgi_hpwd
	vms_username vms_password
);

eval { local $SIG{__DIE__};
	require XSLoader;
	XSLoader::load(__PACKAGE__, $VERSION);
};

=head1 FUNCTIONS

=over

=item UAI_C_AD_II

=item UAI_C_PURDY

=item UAI_C_PURDY_V

=item UAI_C_PURDY_S

These constants are used to identify the four password hashing algorithms
used by VMS.  They are the C<UAI$C_> constants in VMS.

C<UAI_C_AD_II> refers to a 32-bit CRC algorithm.  The CRC polynomial used
is the IEEE CRC-32 polynomial, as used in Ethernet, and in this context
is known as "AUTODIN-II".  The hash is merely the CRC of the password.

C<UAI_C_PURDY>, C<UAI_C_PURDY_V>, and C<UAI_C_PURDY_S> refer to successive
refinements of an algorithm based on Purdy polynomials.  All of these
algorithms use the salt and username parameters as salt, use the whole
password, and return an eight-byte (64-bit) hash.  The main part
of the algorithm, the Purdy polynomial, is identical in all three.
They differ in the pre-hashing, particularly in the treatment of the
username parameter.

In C<UAI_C_PURDY> the username is truncated or space-padded to 12 characters
before being hashed in.  C<UAI_C_PURDY_V> accepts a variable-length username.
C<UAI_C_PURDY_S> accepts a variable-length username and also includes the
password length in the hash.  C<UAI_C_PURDY_S> also does some extra bit
rotations when hashing in the username and password strings, in order
to avoid aliasing.

=cut

use constant UAI_C_AD_II => 0;
use constant UAI_C_PURDY => 1;
use constant UAI_C_PURDY_V => 2;
use constant UAI_C_PURDY_S => 3;

=item lgi_hpwd(USERNAME, PASSWORD, ALGORITHM, SALT)

This is the C<SYS$HASH_PASSWORD> function from VMS (also known as
C<LGI$HPWD>), but with the parameters in a different order.  It hashes
the PASSWORD string in a manner determined by the other parameters,
and returns the hash as a string of bytes.

ALGORITHM determines which hashing algorithm will be used.  It must
be the value of one of the algorithm constants supplied by this module
(see above).

SALT must be an integer in the range [0, 2^16).  It modifies the hashing
so that the same password does not always produce the same hash.

USERNAME is a string that is used as more salt.  In VMS it is the username
of the account to which the password controls access.

VMS usernames and passwords are constrained in character set and
length, and are case-insensitive.  This function does not enforce
these restrictions, nor perform canonicalisation.  If restrictions
and canonicalisation are desired then they must be applied separately.
The functions C<vms_username> and C<vms_password> described below may
be useful.

=cut

unless(defined &lgi_hpwd) { { local $SIG{__DIE__}; eval q{

use warnings;
use strict;

use Data::Integer 0.003 qw(
	natint_bits
	uint_shl uint_shr uint_rol
	uint_and uint_or
	uint_madd uint_cadd
);
use Scalar::String 0.000 qw(sclstr_is_downgraded sclstr_downgraded);

my $u32_mask = 0xffffffff;

sub _u32_shl($$) {
	if(natint_bits == 32) {
		return &uint_shl;
	} else {
		return uint_and(&uint_shl, $u32_mask);
	}
}

*_u32_shr = \&uint_shr;

*_u32_and = \&uint_and;

sub _u32_rol($$) {
	if(natint_bits == 32) {
		return &uint_rol;
	} else {
		return $_[0] if $_[1] == 0;
		return uint_and(uint_or(uint_shl($_[0], $_[1]),
					uint_shr($_[0], 32-$_[1])),
				$u32_mask);
	}
}

sub _u32_madd($$) { uint_and(&uint_madd, $u32_mask) }

sub _u32_cadd($$$) {
	if(natint_bits == 32) {
		return &uint_cadd;
	} else {
		my(undef, $val) = uint_cadd($_[0], $_[1], $_[2]);
		return (uint_and(uint_shr($val, 32), 1),
			uint_and($val, $u32_mask));
	}
}

my $u16_mask = 0xffff;

sub _u16_madd($$) { uint_and(&uint_madd, $u16_mask) }

my $u8_mask = 0xff;

sub _u8_madd($$) { uint_and(&uint_madd, $u8_mask) }

sub _addUnalignedWord($$) {
	$_[0] = pack("v", _u16_madd(unpack("v", $_[0]), $_[1]));
}

use constant _PURDY_USERNAME_LENGTH => 12;

use constant _A => 59;
use constant _DWORD_MAX => 0xffffffff;
use constant _P_D_LOW => _DWORD_MAX - _A + 1;
use constant _P_D_HIGH => _DWORD_MAX;

use constant _N0 => 0xfffffd;
use constant _N1 => 0xffffc1;
use constant _Na => 448;
use constant _Nb => 37449;

use constant _MASK => 7;

use constant _C1 => pack("VV", 0xffffffad, 0xffffffff);
use constant _C2 => pack("VV", 0xffffff4d, 0xffffffff);
use constant _C3 => pack("VV", 0xfffffeff, 0xffffffff);
use constant _C4 => pack("VV", 0xfffffebd, 0xffffffff);
use constant _C5 => pack("VV", 0xfffffe95, 0xffffffff);

sub _PQMOD_R0($) {
	my($low, $high) = unpack("VV", $_[0]);
	if($high == _P_D_HIGH && $low >= _P_D_LOW) {
		$_[0] = pack("VV", _u32_madd($low, _A), 0);
	}
}

sub _ROL1($) { $_[0] = pack("V", _u32_rol(unpack("V", $_[0]), 1)); }

sub _QROL1($) {
	_ROL1(substr($_[0], 0, 4));
	_ROL1(substr($_[0], 4, 4));
}

sub _EMULQ($$$) {
	my($a, $b, undef) = @_;
	my $hi = _u32_shr($a, 16) * _u32_shr($b, 16);
	my $lo = _u32_and($a, 0xffff) * _u32_and($b, 0xffff);
	my $carry;
	my $p = _u32_shr($a, 16) * _u32_and($b, 0xffff);
	($carry, $lo) = _u32_cadd($lo, _u32_shl($p, 16), 0);
	($carry, $hi) = _u32_cadd($hi, _u32_shr($p, 16), $carry);
	$p = _u32_and($a, 0xffff) * _u32_shr($b, 16);
	($carry, $lo) = _u32_cadd($lo, _u32_shl($p, 16), 0);
	($carry, $hi) = _u32_cadd($hi, _u32_shr($p, 16), $carry);
	$_[2] = pack("VV", $lo, $hi);
}

sub _PQADD_R0($$$) {
	my($u, $y, undef) = @_;
	my($ulo, $uhi) = unpack("VV", $u);
	my($ylo, $yhi) = unpack("VV", $y);
	my($carry, $rlo, $rhi);
	($carry, $rlo) = _u32_cadd($ulo, $ylo, 0);
	($carry, $rhi) = _u32_cadd($uhi, $yhi, $carry);
	while($carry) {
		($carry, $rlo) = _u32_cadd($rlo, _A, 0);
		($carry, $rhi) = _u32_cadd($rhi, 0, $carry);
	}
	$_[2] = pack("VV", $rlo, $rhi);
}

sub _COLLAPSE_R2($$$) {
	my($s, undef, $isPurdyS) = @_;
	for(my $p = length($s); $p != 0; $p--) {
		my $pp = $p & _MASK;
		substr($_[1], $pp, 1) = pack("C",
			_u8_madd(unpack("C", substr($_[1], $pp, 1)),
				unpack("C", substr($s, -$p, 1))));
		if($isPurdyS && $pp == _MASK) { _QROL1($_[1]); }
	}
}

sub _PQLSH_R0($$) {
	my($u, undef) = @_;
	my($ulo, $uhi) = unpack("VV", $u);
	my $stack = pack("VV", 0, 0);
	my $x = pack("VV", 0, 0);
	_EMULQ($uhi, _A, $stack);
	$x = pack("VV", 0, $ulo);
	_PQADD_R0($x, $stack, $_[1]);
}

sub _PQMUL_R2($$$) {
	my($u, $y, undef) = @_;
	my($ulo, $uhi) = unpack("VV", $u);
	my($ylo, $yhi) = unpack("VV", $y);
	my $stack = pack("VV", 0, 0);
	my $part1 = pack("VV", 0, 0);
	my $part2 = pack("VV", 0, 0);
	my $part3 = pack("VV", 0, 0);
	_EMULQ($uhi, $yhi, $stack);
	_PQLSH_R0($stack, $part1);
	_EMULQ($uhi, $ylo, $stack);
	_EMULQ($ulo, $yhi, $part2);
	_PQADD_R0($stack, $part2, $part3);
	_PQADD_R0($part1, $part3, $stack);
	_PQLSH_R0($stack, $part1);
	_EMULQ($ulo, $ylo, $stack);
	_PQADD_R0($part1, $stack, $_[2]);
}

sub _PQEXP_R3($$$) {
	my($u, $n, undef) = @_;
	my $y = pack("VV", 0, 0);
	my $z = pack("VV", 0, 0);
	my $z1 = pack("VV", 0, 0);
	my $yok = 0;
	$z = $u;
	while($n != 0) {
		if($n & 1) {
			if($yok) {
				_PQMUL_R2($y, $z, $_[2]);
			} else {
				$_[2] = $z;
				$yok = 1;
			}
			if($n == 1) { return; }
			$y = $_[2];
		}
		$n >>= 1;
		$z1 = $z;
		_PQMUL_R2($z1, $z1, $z);
	}
	$_[2] = pack("VV", 1, 0);
}

sub _Purdy($) {
	my $t1 = pack("VV", 0, 0);
	my $t2 = pack("VV", 0, 0);
	my $t3 = pack("VV", 0, 0);

	_PQEXP_R3($_[0], _Na, $t1);
	_PQEXP_R3($t1, _Nb, $t2);
	_PQEXP_R3($_[0], (_N0 - _N1), $t1);
	_PQADD_R0($t1, _C1, $t3);
	_PQMUL_R2($t2, $t3, $t1);

	_PQMUL_R2($_[0], _C2, $t2);
	_PQADD_R0($t2, _C3, $t3);
	_PQMUL_R2($_[0], $t3, $t2);
	_PQADD_R0($t2, _C4, $t3);

	_PQADD_R0($t1, $t3, $t2);
	_PQMUL_R2($_[0], $t2, $t1);
	_PQADD_R0($t1, _C5, $_[0]);

	_PQMOD_R0($_[0]);
}

sub lgi_hpwd($$$$) {
	my($username, $password, $alg, $salt) = @_;
	if($alg > UAI_C_PURDY_S) {
		die "algorithm value $alg is not recognised";
	}
	$salt = uint_and($salt, 0xffff);
	# This string downgrading is necessary for correct behaviour on
	# perl 5.6 and 5.8.  It is not necessary on 5.10, but will still
	# slightly improve performance.
	$username = sclstr_downgraded($username, 1);
	$password = sclstr_downgraded($password, 1);
	die "input must contain only octets"
		unless sclstr_is_downgraded($username) &&
			sclstr_is_downgraded($password);
	if($alg == UAI_C_AD_II) {
		return pack("VV", Digest::CRC::crc32($password)^0xffffffff, 0);
	}
	my $isPurdyS = $alg == UAI_C_PURDY_S;
	my $output = pack("VV", 0, 0);
	if($alg == UAI_C_PURDY) {
		$username .= " " x 12;
		$username = substr($username, 0, _PURDY_USERNAME_LENGTH);
	} elsif($alg == UAI_C_PURDY_S) {
		_addUnalignedWord(substr($output, 0, 2), length($password));
	}
	_COLLAPSE_R2($password, $output, $isPurdyS);
	_addUnalignedWord(substr($output, 3, 2), $salt);
	_COLLAPSE_R2($username, $output, $isPurdyS);
	_Purdy($output);
	return $output;
}

1;

}; } die $@ if $@ ne "" }

=item vms_username(USERNAME)

Checks whether the USERNAME string matches VMS username syntax, and
canonicalises it.  VMS username syntax is 1 to 31 characters from
case-insensitive alphanumerics, "B<_>", and "B<$>".  If the string has
correct username syntax then the username is returned in canonical form
(uppercase).  If the string is not a username then C<undef> is returned.

=cut

sub vms_username($) {
	return $_[0] =~ /\A[_\$0-9A-Za-z]{1,31}\z/ ? uc("$_[0]") : undef;
}

=item vms_password(PASSWORD)

Checks whether the PASSWORD string is an acceptable VMS password,
and canonicalises it.  VMS password syntax is 1 to 32 characters from
case-insensitive alphanumerics, "B<_>", and "B<$>".  If the string is
an acceptable password then the password is returned in canonical form
(uppercase).  If the string is not an acceptable password then C<undef>
is returned.

=cut

sub vms_password($) {
	return $_[0] =~ /\A[_\$0-9A-Za-z]{1,32}\z/ ? uc("$_[0]") : undef;
}

=back

=head1 SEE ALSO

L<VMS::User>

=head1 AUTHOR

The original C implementation of C<LGI$HPWD> was written by Shawn Clifford.
The code has since been developed by Davide Casale, Mario Ambrogetti,
Terence Lee, Jean-loup Gailly, Solar Designer, and Andrew Main (Zefram).

Mike McCauley <mikem@open.com.au> created the first version of
C<Authen::DecHpwd>, establishing the Perl interface.  This was based on
Shawn Clifford's code without the later developments.

Andrew Main (Zefram) <zefram@fysh.org> created a new C<Authen::DecHpwd>
based on the more developed C code presently used, and added ancillary
functions.

=head1 COPYRIGHT

Copyright (C) 2002 Jean-loup Gailly <http://gailly.net>

Based in part on code from John the Ripper, Copyright (C) 1996-2002
Solar Designer

Copyright (C) 2006, 2007, 2009, 2010, 2011
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

=cut

1;
