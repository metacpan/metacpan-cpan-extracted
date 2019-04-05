package Authen::Passphrase::Argon2;

use 5.006;
use strict;
use warnings;
use Crypt::Argon2 qw/argon2id_pass argon2id_verify/;
use MIME::Base64 qw(decode_base64 encode_base64);
use Data::GUID;
use Carp qw/croak/;
use Syntax::Construct qw( ?<> /a );

use parent 'Authen::Passphrase';

our $VERSION = '0.06';

our (%salts, %hashes, @argons);
BEGIN {
	@argons = (
		['salt'],
		[qw/cost 3/],
		[qw/factor 32M/],
		[qw/parallelism 1/],
		[qw/size 16/]
	);
	%salts = (
		salt => sub {
			$_[0] = $salts{salt_random}() if "$_[0]" eq 'random';
			$_[0] =~ m#\A[\x00-\xff]{6}.*\z#
				or croak sprintf("%s is not a valid raw salt", $_[0]);
			$_[0];
		},
		salt_hex => sub {
			$_[0] = $salts{salt}($_[0]);
			unpack("H*", $_[0]);
		},
		salt_base64 => sub {
			$_[0] = $salts{salt}($_[0]);
			encode_base64($_[0]);
		},
		salt_random => sub {
			Data::GUID->new->as_string;
		},
	);
	%hashes = (
		hash => sub {
			$_[0] =~ m/^
				\$argon2id
				\$v=\d+
				\$m=(?<factor>\d+),
				t=(?<cost>\d+),
				p=(?<parallelism>\d+)
				\$
			/ax or croak sprintf "not a valid raw hash - %s", $_[0];
			("$_[0]", %+);
		},
		hash_base64 => sub {
			($_[0]) = $hashes{hash}($_[0]);
			encode_base64($_[0]);
		},
		hash_hex => sub {
			($_[0]) = $hashes{hash}($_[0]);
			unpack("H*", $_[0]);
		}
	);
}

sub new {
	my ($class, %args) = (shift, (scalar @_ == 1 ? %{$_[0]} : @_));

	my $self = bless({ algorithm => 'Argon2' }, $class);

	$args{crypt} = delete $args{passphrase} if $args{passphrase};

	exists $args{$_} ? ! $self->{salt}
		? do { $self->{salt} = $salts{$_}->($args{$_}) }
		: croak sprintf "salt specified redundantly - %s", $_
	: next foreach (keys %salts);

	foreach (qw/hash base64 hex/) {
		if (exists $args{"stored_$_"}) {
			($args{"hash_$_"}) = delete $args{crypt};
			last;
		}
	}

	$self->{$_->[0]} = $self->{$_->[0]}
		|| $args{$_->[0]}
		|| $_->[1]
	foreach @argons;

	unless ($args{crypt}) {
		exists $args{$_} ? ! $self->{crypt}
			? $self->$_($args{$_})
		 	: croak sprintf "hash specified redundantly - %s", $_
		: next foreach (keys %hashes);
	} else {
		$self->{crypt} = $self->_hash_of($args{crypt});
	}

	return $self;
}

sub match {
	my ($self, $passphrase) = @_;

	return argon2id_verify($self->{crypt}, $passphrase);
}

sub from_crypt {
	my ($self, $crypt, $info) = (@_, {});
	return $self->new(%{ $info }, 'passphrase', $hashes{hash}($crypt));
}

sub from_rfc2307 {
	my ( $class, $rfc2307, $info) = (@_, {});

	croak "invalid Argon2 RFC2307 format" unless $rfc2307 =~ m/^{ARGON2}(.*)$/;

	return $class->from_crypt($1, $info);
}

sub as_crypt {
	my ($self, $val) = @_;

	$self->{crypt} = $self->_hash_of($val) if defined $val;

	return $self->{crypt};
}

sub as_hex {
	goto &hash_hex;
}

sub as_base64 {
	goto &hash_base64;
}

sub as_rfc2307 {
	my ($self, $val) = @_;

	return '{ARGON2}' . $self->as_crypt($val);
}

sub algorithm {
	my($self) = @_;

	return $self->{algorithm};
}

sub salt {
	my($self, $val) = @_;
	$self->{salt} = $salts{salt}($val) if $val;
	$self->{salt};
}

sub salt_hex {
	my($self, $val) = @_;
	$salts{salt_hex}($self->salt($val ? pack("H*", $val) : ()));
}

sub salt_base64 {
	my($self, $val) = @_;
	$salts{salt_base64}($self->salt($val ? decode_base64($val) : ()));
}

sub hash {
	my($self, $val) = @_;
	return $val ? $self->as_crypt($hashes{hash}($val)) : $self->{crypt};
}

sub hash_hex {
	my($self, $val) = @_;
	return $hashes{hash_hex}($self->as_crypt($val ? pack("H*", $val) : ()));
}

sub hash_base64 {
	my($self, $val) = @_;
	return $hashes{hash_base64}($self->as_crypt($val ? decode_base64($val) : ()));
}

sub _hash_of {
	my ($self, $pass, @params) = @_;
	return $pass if ($pass =~ m/\$argon2/);
	!$self->{$_->[0]} ? croak "$_->[0] not set" : push @params, $self->{$_->[0]} for @argons;
	return argon2id_pass($pass, @params);
}

1;

__END__

=head1 NAME

Authen::Passphrase::Argon2 - Store and check password using Argon2

=head1 VERSION

Version 0.06

=cut

=head1 SYNOPSIS

	use Authen::Passphrase::Argon2;

	$ppr = Authen::Passphrase::Argon2->new(
		salt_random => 1,
		hash_hex => '246172676f6e326924763d3139246d3d33323736382c743d332c703d312459574a6a5a47566d5a7a45794d7724435348383332634a6330347376516f7656492f754441',
	);

	$algorithm = $ppr->algorithm;
	$salt = $ppr->salt;
	$salt_hex = $ppr->salt_hex;
	$hash = $ppr->hash;
	$hash_hex = $ppr->hash_hex;

	if($ppr->match($passphrase)) {
		...
	}

	$userPassword = $ppr->as_crypt;

	.....

	__PACKAGE__->add_columns(

	);

=cut

=head2 NOTE

This is an attempt to make L<Crypt::Argon2> compliant with L<Authen::Passphrase>.
The term **hash** is loosely used in this documentation and implementation. Really when we say hash/hex we are dealing with an Argon2 cryptographic key. consistency.

=cut

=head1 Methods

=cut

=head2 Authen::Passphrase::Argon2->new

params

	# Only one of these must be defined for the salt value. An error will be thrown if none or more than one is defined.
	salt - plain text salt value
	salt_hex - salt in hex value that gets decoded.
	salt_base64 - salt value encoded in base64 that gets decoded.
	salt_random - a random salt will be generated using Data::GUID.

	# Only one of these must be defined for the crypt value. An error will be thrown if none or more than one is defined.
	passphrase - plain text passpord that will be converted to argon2
	hash - plain text argon2 value
	hash_base64 - base64 encoded argon2 value
	hash_hex - hex decimal argon2 value

	# optional params
	cost - optional - default 3 - This is the time-cost factor, typically a small integer that can be derived as explained above.
	factor - optional - default '32M' - This is the memory costs factor. This must be given as a integer followed by an order of magnitude (k, M or G for kilobytes, megabytes or gigabytes respectively), e.g. '64M'.
	parallelism - optional - default 1 - This is the number of threads that are used in computing it.
	size - optional - default 16 - This is the size of the raw result in bytes. Typical values are 16 or 32.

=cut

=head2 $ppr->algorithm

Returns the algorithm, in the same form as supplied to the constructor. Which will always be Argon2

=cut

=head2 $ppr->salt

Returns the salt, in raw form.

=cut

=head2 $ppr->salt_hex

Returns the salt, as a string of hexadecimal digits.

=cut

=head2 $ppr->salt_base64

Returns the salt, as a string encoded in base64.

=cut

=head2 $ppr->as_crypt

Returns the raw argon2 formatted string.

=cut

=head2 $ppr->as_hex

Returns the raw argon2 formatted string in hex format.

=cut

=head2 $ppr->as_base64

Returns the raw argon2 formatted string encdoed in base64.

=cut

=head2 $ppr->hash

Returns the hash value, in raw form.

(lets keep consistency but it's just an alias for as_crypt, perhaps I have some misunderstanding /o\)

=cut

=head2 $ppr->hash_hex

Returns the hash value, as a string of hexadecimal digits.

=cut

=head2 $ppr->hash_base64

Returns the hash value, as a string in base64.

=cut

=head2 $ppr->match($passphrase)

Check whether passphrases match.

=cut

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-authen-passphrase-argon2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Authen-Passphrase-Argon2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Authen::Passphrase::Argon2


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Authen-Passphrase-Argon2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Authen-Passphrase-Argon2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Authen-Passphrase-Argon2>

=item * Search CPAN

L<http://search.cpan.org/dist/Authen-Passphrase-Argon2/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2018 lnation.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

