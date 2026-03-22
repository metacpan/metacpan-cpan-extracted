package Crypt::Passphrase::Scrypt;
$Crypt::Passphrase::Scrypt::VERSION = '0.005';
use strict;
use warnings;

use parent 'Crypt::Passphrase::Encoder';

use Carp 'croak';
use Crypt::Passphrase::Util::Crypt64 ':all';
use Crypt::ScryptKDF qw/scrypt_b64 scrypt_raw/;
use MIME::Base64 qw/encode_base64 decode_base64/;
our @CARP_NOT = 'Crypt::Passphrase';

sub new {
	my ($class, %args) = @_;

	my $format = $args{format} // 'passlib';
	die "Invalid format $format" unless $format eq 'passlib' or $format eq 'libcrypt';

	return bless {
		cost        => $args{cost}        // 16,
		block_size  => $args{block_size}  //  8,
		parallel    => $args{parallel}    //  1,
		salt_size   => $args{salt_size}   // 16,
		output_size => $args{output_size} // 32,
		format      => $format,
	}, $class;
}

sub hash_password {
	my ($self, $password) = @_;
	my $salt = $self->random_bytes($self->{salt_size});
	if ($self->{format} eq 'passlib') {
		my $hash = scrypt_b64($password, $salt, 1 << $self->{cost}, $self->{block_size}, $self->{parallel}, $self->{output_size});
		return sprintf '$scrypt$ln=%d,r=%d,p=%d$%s$%s', $self->{cost}, $self->{block_size}, $self->{parallel}, encode_base64($salt, ''), $hash;
	} else {
		my $encoded_salt = encode_crypt64($salt);
		my $hash = scrypt_raw($password, $encoded_salt, 1 << $self->{cost}, $self->{block_size}, $self->{parallel}, $self->{output_size});
		my $encoded_hash = encode_crypt64($hash);

		my $cost = encode_crypt64_number($self->{cost}, 1);
		my $block_size = encode_crypt64_number($self->{block_size}, 5);
		my $parallel = encode_crypt64_number($self->{parallel}, 5);
		my $header = join '', $cost, $block_size, $parallel, $encoded_salt;

		return sprintf '$7$%s$%s', $header, $encoded_hash;
	}
}

my $decode_regex = qr/ \A \$ scrypt \$ ln=(\d+),r=(\d+),p=(\d+) \$ ([^\$]+) \$ ([^\$]*) \z /x;
my $char64 = qr{[./0-9A-Za-z]};
my $regex7 = qr/ ^ \$7\$ ($char64) ($char64{5}) ($char64{5}) ([^\$]{22}) \$ ([^\$]*) /x;

sub needs_rehash {
	my ($self, $hash) = @_;
	if ($self->{format} eq 'passlib') {
		my ($cost, $block_size, $parallel, $salt64, $hash64) = $hash =~ $decode_regex or return 1;
		return !!1 if $cost != $self->{cost} or $block_size != $self->{block_size} or $parallel != $self->{parallel};
		return !!1 if length decode_base64($salt64) != $self->{salt_size} or length decode_base64($hash64) != $self->{output_size};
	} else {
		my ($encoded_cost, $encoded_block_size, $encoded_parallel, $salt, $encoded_hash) = $hash =~ $regex7 or return 1;
		my ($cost, $block_size, $parallel) = map { decode_crypt64_number($_) } $encoded_cost, $encoded_block_size, $encoded_parallel;
		return !!1 if $cost != $self->{cost} or $block_size != $self->{block_size} or $parallel != $self->{parallel};
		return !!1 if length decode_crypt64($salt) != $self->{salt_size} or length decode_crypt64($encoded_hash) != $self->{output_size};
	}
	return !!0;
}

sub crypt_subtypes {
	return ('scrypt', '7');
}

sub verify_password {
	my ($class, $password, $hash) = @_;
	if (my ($cost, $block_size, $parallel, $salt64, $hash64) = $hash =~ $decode_regex) {
		my $old_hash = decode_base64($hash64);
		my $new_hash = scrypt_raw($password, decode_base64($salt64), 1 << $cost, $block_size, $parallel, length $old_hash);
		return $class->secure_compare($new_hash, $old_hash);
	}
	elsif (my ($encoded_cost, $encoded_block_size, $encoded_parallel, $salt, $encoded_hash) = $hash =~ $regex7) {
		my ($cost, $block_size, $parallel) = map { decode_crypt64_number($_) } $encoded_cost, $encoded_block_size, $encoded_parallel;
		my $old_hash = decode_crypt64($encoded_hash);
		my $new_hash = scrypt_raw($password, $salt, 1 << $cost, $block_size, $parallel, length $old_hash);
		return $class->secure_compare($new_hash, $old_hash);
	}
	return !!0;
}

sub recode_hash {
	my ($self, $hash) = @_;
	return $hash if $self->{format} eq 'libcrypt';
	if (my ($encoded_cost, $encoded_block_size, $encoded_parallel, $salt, $encoded_hash) = $hash =~ $regex7) {
		my ($cost, $block_size, $parallel) = map { decode_crypt64_number($_) } $encoded_cost, $encoded_block_size, $encoded_parallel;
		my $decoded = decode_crypt64($encoded_hash);
		my $recoded_hash = encode_base64($decoded, '');
		return sprintf '$scrypt$ln=%d,r=%d,p=%d$%s$%s', $cost, $block_size, $parallel, encode_base64($salt, ''), $recoded_hash;
	}
	return $hash;
}

1;

#ABSTRACT: A scrypt encoder for Crypt::Passphrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::Scrypt - A scrypt encoder for Crypt::Passphrase

=head1 VERSION

version 0.005

=head1 DESCRIPTION

This class implements an scrypt encoder for Crypt::Passphrase. If one wants a memory-hard password scheme Argon2 is recommended instead.

=head2 Configuration.

It takes the following arguments

=over 4

=item * format

This module supports formats: B<passlib> (C<$scrypt$>) and B<libcrypt> (C<$7>), with the former being the default.

=item * cost

This is the cost factor that is used to hash passwords, it scales exponentially. It currently defaults to B<16>, but this may change in any future version. Note that unlike many hash algorithms, increasing the rounds value will increase both the time and memory required to hash a password.

=item * block_size

This defaults to B<8>.

=item * parallelism

The number of threads used for the hash. This defaults to B<1>, but this number may change in any future version.

=item * output_size

The size of a hashed value. This defaults to B<32> bytes.

=item * salt_size

The size of the salt. This defaults to B<16> bytes, which should be more than enough for any use-case.

=back

Note that some defaults are likely to change at some point in the future, as computers get progressively more powerful and cryptoanalysis gets more advanced.

=head2 Supported crypt types

This class supports the following crypt types: C<scrypt> and C<7>, matching the C<passlib> and C<libcrypt> formats.

=head1 SYNOPSIS
 my $passphrase = Crypt::Passphrase->new(
   encoder => {
     module      => 'Scrypt',
       format      => 'passlib',
       cost        => 16,
       parallelism =>  1,
       output_size => 32,
   },
 );

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
