package Database::BI::Password;

use strict;
use warnings;

our $VERSION = '0.023.1';

use Carp qw(croak);
use Digest::SHA qw(hmac_sha256);
use Exporter qw(import);
use MIME::Base64 qw(encode_base64 decode_base64);
use Database::BI::I18N ();
use Readonly;

our @EXPORT_OK = qw( hash_password verify_password is_password_hash );

# PBKDF2-HMAC-SHA256 (RFC 8018), written out because no password-hashing
# module is a prerequisite and Digest::SHA is core.  The work is in
# hmac_sha256, which is XS: 200_000 rounds take about 0.4s here, which a reader
# logging in does not notice and a guesser with a copy of the hash does.  The
# rounds are stored in the hash, so a later default does not lock anyone out.
Readonly my $DEFAULT_ROUNDS => 200_000;
Readonly my $MIN_ROUNDS     => 10_000;
Readonly my $MAX_ROUNDS     => 100_000_000;
Readonly my $SALT_BYTES     => 16;
Readonly my $KEY_BYTES      => 32;
Readonly my $SCHEME         => 'pbkdf2-sha256';
Readonly my $HASH_RE        => qr{\A\Q$SCHEME\E\$(\d{5,9})\$([A-Za-z0-9+/]{22})\$([A-Za-z0-9+/]{43})\z};

# What hash_password croaks with, for whoever calls it (the password command, a
# test), in the language Database::BI::I18N chooses from the locale.
Readonly our %MESSAGES => (
	error_password_required => 'hash_password: a password is required',
	error_password_rounds   => 'hash_password: rounds must be a whole number from %d to %d',
	error_password_salt     => 'hash_password: a salt is %d bytes',
	error_password_random   => 'hash_password: Crypt::URandom gave %d random bytes, not %d',
);

# _text($key) -> the template for $key in the current language.
sub _text { return Database::BI::I18N::text(__PACKAGE__, \%MESSAGES, $_[0]) }

# _pbkdf2($password, $salt, $rounds, $bytes) -> $key
#
# One block is all a 32-byte key needs, but the loop over blocks is kept so
# the function is the RFC's and its test vectors apply.
sub _pbkdf2 {
	my ($password, $salt, $rounds, $bytes) = @_;
	my $key = '';
	for (my $block = 1; length($key) < $bytes; $block++) {
		my $u = hmac_sha256($salt . pack('N', $block), $password);
		my $t = $u;
		for (2 .. $rounds) {
			$u = hmac_sha256($u, $password);
			$t ^= $u;
		}
		$key .= $t;
	}
	return substr($key, 0, $bytes);
}

# _random_bytes($n) -> $bytes
#
# Crypt::URandom is a prerequisite (Windows has no /dev/urandom, which this
# once fell back to), and it croaks itself when the system has no source.
sub _random_bytes {
	my ($n) = @_;
	require Crypt::URandom;
	my $bytes = Crypt::URandom::urandom($n);
	croak sprintf(_text('error_password_random'), length($bytes // ''), $n)
		unless defined $bytes && length($bytes) == $n;
	return $bytes;
}

sub _b64 {
	(my $s = encode_base64($_[0], '')) =~ s/=+\z//;
	return $s;
}

sub _unb64 {
	my ($s) = @_;
	$s .= '=' x ((4 - length($s) % 4) % 4);
	return decode_base64($s);
}

sub _octets {
	my ($password) = @_;
	utf8::encode($password) if utf8::is_utf8($password);
	return $password;
}

sub hash_password {
	my ($password, %opts) = @_;
	croak _text('error_password_required') unless defined $password && length $password;
	my $rounds = $opts{rounds} // $DEFAULT_ROUNDS;
	croak sprintf(_text('error_password_rounds'), $MIN_ROUNDS, $MAX_ROUNDS)
		unless $rounds =~ /\A\d+\z/ && $rounds >= $MIN_ROUNDS && $rounds <= $MAX_ROUNDS;
	my $salt = $opts{salt} // _random_bytes($SALT_BYTES);
	croak sprintf(_text('error_password_salt'), $SALT_BYTES) unless length($salt) == $SALT_BYTES;
	my $key = _pbkdf2(_octets($password), $salt, $rounds, $KEY_BYTES);
	return join '$', $SCHEME, $rounds, _b64($salt), _b64($key);
}

sub is_password_hash {
	my ($hash) = @_;
	return 0 unless defined $hash && !ref $hash && $hash =~ $HASH_RE;
	return $1 >= $MIN_ROUNDS && $1 <= $MAX_ROUNDS ? 1 : 0;
}

sub verify_password {
	my ($password, $hash) = @_;
	return 0 unless defined $password && length $password && is_password_hash($hash);
	my ($rounds, $salt, $want) = $hash =~ $HASH_RE;
	my $got = _pbkdf2(_octets($password), _unb64($salt), $rounds, $KEY_BYTES);
	$want = _unb64($want);

	# Every byte is compared, so the time taken says nothing about how much
	# of a guess was right.
	my $diff = length($got) ^ length($want);
	$diff |= ord(substr($got, $_, 1)) ^ ord(substr($want, $_, 1)) for 0 .. length($want) - 1;
	return $diff == 0 ? 1 : 0;
}

1;

__END__

=head1 NAME

Database::BI::Password - Hash and check the login password

=head1 VERSION

0.023.1

=head1 SYNOPSIS

    use Database::BI::Password qw(hash_password verify_password is_password_hash);

    my $hash = hash_password('correct horse battery staple');
    # pbkdf2-sha256$200000$<salt>$<key>

    verify_password('correct horse battery staple', $hash);   # 1
    verify_password('wrong', $hash);                          # 0

=head1 DESCRIPTION

The login (config C<password_hash>, see L<Database::BI/Logging in>) stores only
a hash of the password, never the password.  The hash is PBKDF2-HMAC-SHA256
(RFC 8018) with a random 16-byte salt and a 32-byte key, written as
C<pbkdf2-sha256$E<lt>roundsE<gt>$E<lt>saltE<gt>$E<lt>keyE<gt>>, the salt and key in base64
without padding.  C<script/database-bi password> makes one.

=head1 FUNCTIONS

=head2 hash_password

    my $hash = hash_password($password, rounds => 200_000);

=head3 API SPECIFICATION

=head4 INPUT

    $password: string, required, not empty (a character string is hashed as UTF-8)
    rounds:    integer, optional, 10_000 to 100_000_000 (default 200_000)
    salt:      16 bytes, optional (default random); for tests

=head4 OUTPUT

The hash string.  Croaks on a missing password, rounds out of range, or a salt
of another length; the messages are in C<%Database::BI::Password::MESSAGES>.
Crypt::URandom, which makes the salt, croaks when the system has no source of
random bytes.

=head2 verify_password

    my $ok = verify_password($password, $hash);

=head3 API SPECIFICATION

=head4 INPUT

    $password: string
    $hash:     string, as hash_password returns

=head4 OUTPUT

1 when the password is the one hashed, else 0, including for a missing
password or a hash that is not one.  Every byte of the key is compared, so the
time taken does not depend on how much of it matched.

=head2 is_password_hash

    is_password_hash($value);

=head3 API SPECIFICATION

=head4 INPUT

    $value: anything

=head4 OUTPUT

1 when the value is a hash C<verify_password> can check, else 0.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
