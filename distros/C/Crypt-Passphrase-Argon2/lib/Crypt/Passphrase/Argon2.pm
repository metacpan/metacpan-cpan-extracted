package Crypt::Passphrase::Argon2;
$Crypt::Passphrase::Argon2::VERSION = '0.009';
use strict;
use warnings;

use Crypt::Passphrase 0.010 -encoder;

use Carp 'croak';
use Crypt::Argon2 0.017 qw/argon2_pass argon2_needs_rehash argon2_verify argon2_types/;

my %settings_for = (
	interactive => {
		time_cost   => 2,
		memory_cost => '64M',
	},
	moderate => {
		time_cost   => 3,
		memory_cost => '256M',
	},
	sensitive => {
		time_cost   => 4,
		memory_cost => '1G',
	}
);

my %valid_types = map { ($_ => 1) } argon2_types;

sub _settings_for {
	my %args = @_;
	my $subtype     =  $args{subtype}     // 'argon2id';
	croak "Unknown subtype $subtype" unless $valid_types{$subtype};
	my $profile     =  $args{profile}     // 'moderate';
	croak "Unknown profile $profile" unless $settings_for{$profile};
	return {
		memory_cost => $args{memory_cost} // $settings_for{$profile}{memory_cost},
		time_cost   => $args{time_cost}   // $settings_for{$profile}{time_cost},
		parallelism => $args{parallelism} //  1,
		output_size => $args{output_size} // 32,
		salt_size   => $args{salt_size}   // 16,
		subtype     => $subtype,
	};
}

sub new {
	my ($class, %args) = @_;
	return bless _settings_for(%args), $class;
}

sub hash_password {
	my ($self, $password) = @_;
	my $salt = $self->random_bytes($self->{salt_size});
	return argon2_pass($self->{subtype}, $password, $salt, @{$self}{qw/time_cost memory_cost parallelism output_size/});
}

sub needs_rehash {
	my ($self, $hash) = @_;
	return argon2_needs_rehash($hash, @{$self}{qw/subtype time_cost memory_cost parallelism output_size salt_size/});
}

sub crypt_subtypes {
	return argon2_types;
}

sub verify_password {
	my ($class, $password, $hash) = @_;
	return argon2_verify($hash, $password);
}

#ABSTRACT: An Argon2 encoder for Crypt::Passphrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::Argon2 - An Argon2 encoder for Crypt::Passphrase

=head1 VERSION

version 0.009

=head1 SYNOPSIS

 my $passphrase = Crypt::Passphrase->new(
   encoder => {
     module  => 'Argon2',
     profile => 'interactive',
   },
 );

=head1 DESCRIPTION

This class implements an Argon2 encoder for Crypt::Passphrase. It is the recommended password encoder as of 2023.

The default settings are taken from the moderate profile of libsodium's password hashing. If you want to use your own settings Crypt::Argon2 contains a C<argon2-calibrate> tool to assist you in this.

=head1 METHODS

=head2 new(%args)

This creates a new Argon2 encoder, it takes named parameters that are all optional. Note that some defaults are likely to change at some point in the future, as computers get progressively more powerful and cryptoanalysis gets more advanced.

=over 4

=item * profile

This sets the default values for the C<memory_cost> and C<time_cost> values. The default profile is C<moderate>, but this may change in any future version.

=over 4

=item * interactive

This sets the defaults for C<memory_cost> and C<time_cost> to C<2> and C<'64M'> respectively.

=item * moderate

This sets the defaults for C<memory_cost> and C<time_cost> to C<3> and C<'256M'> respectively.

=item * sensitive

This sets the defaults for C<memory_cost> and C<time_cost> to C<4> and C<'1G'> respectively.

=back

=item * memory_cost

Maximum memory (in bytes) that may be used to compute the Argon2 hash.

=item * time_cost

Maximum amount of time it may take to compute the Argon2 hash.

=item * parallelism

The number of lanes (and potentially threads) used for the hash. This defaults to C<1>, but this number may change in any future version.

=item * output_size

The size of a hashed value. This defaults to 32 bytes.

=item * salt_size

The size of the salt. This defaults to 16 bytes, which should be more than enough for any use-case.

=item * subtype

This choses the argon2 subtype. It defaults to C<argon2id>, and unless you know what you're doing you should probably keep it at that. This may change in any future version (but is unlikely to do so unless C<argon2id> is cryptographically broken).

=over 4

=item * C<argon2id>

This is the default. It's a hybrid of C<argon2i> and C<argon2d> that largely combines the advantages of both.

=item * C<argon2i>

This is optimized against timing attacks, but more vulnerable against other cryptographic attacks. It must not be used with a C<time_cost> lower than 3.

=item * C<argon2d>

This is optimized for resistance to GPU cracking attacks but not against timing based side-channel attacks.

=back

=back

Note: there is no wrong or right configuration, it all depends on your own particular circumstances. I recommend using the algorithm described in L<Crypt::Argon2|Crypt::Argon2/RECOMMENDED-SETTINGS> to pick the right settings for you.

=head2 hash_password($password)

This hashes the passwords with argon2 according to the specified settings and a random salt (and will thus return a different result each time).

=head2 needs_rehash($hash)

This returns true if the hash uses a different cipher or subtype, or if any of the parameters is lower that desired by the encoder.

=head2 crypt_types()

This class supports the following crypt types: C<argon2id>, C<argon2i> and C<argon2d>.

=head2 verify_password($password, $hash)

This will check if a password matches an argon2 hash.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
