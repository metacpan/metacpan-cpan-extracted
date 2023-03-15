package Crypt::Passphrase::Yescrypt;
$Crypt::Passphrase::Yescrypt::VERSION = '0.001';
use strict;
use warnings;

use parent 'Crypt::Passphrase::Encoder';

use Crypt::Yescrypt qw/yescrypt yescrypt_needs_rehash yescrypt_check/;

sub new {
	my ($class, %args) = @_;

	return bless {
		flags       => $args{flags}       // 0xb6,
		block_count => $args{block_count} //   12,
		block_size  => $args{block_size}  //   32,
		parallelism => $args{parallelism} //    1,
		time        => $args{time}        //    0,
		upgrades    => $args{upgrades}    //    0,
		salt_size   => $args{salt_size}   //   16,
	}, $class;
}

sub hash_password {
	my ($self, $password) = @_;
	my $salt = $self->random_bytes($self->{salt_size});
	return yescrypt($password, $salt, @{$self}{qw/flags block_count block_size parallelism time upgrades/});
}

sub needs_rehash {
	my ($self, $hash) = @_;
	return yescrypt_needs_rehash($hash, @{$self}{qw/flags block_count block_size parallelism time upgrades/});
}

sub crypt_subtypes {
	return qw/y 7/;
}

sub verify_password {
	my ($class, $password, $hash) = @_;
	return yescrypt_check($password, $hash);
}

1;

#ABSTRACT: A yescrypt encoder for Crypt::Passphrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::Yescrypt - A yescrypt encoder for Crypt::Passphrase

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This class implements an yescrypt encoder for Crypt::Passphrase. yescrypt was one of the finalists of 2015's Password Hash Competition and as such is considered a safe algorithm for passwords.

=head1 METHODS

=head2 new(%args)

This creates a new yescrypt encoder, it takes named parameters that are all optional. Note that some defaults are likely to change at some point in the future, as computers get progressively more powerful and cryptoanalysis gets more advanced.

=over 4

=item * block_size

The number of 128 byte units in a block. Reasonable values are from C<8> to C<96>. It default to C<32> (C<4kiB>).

=item * block_count

The log₂ of the number of blocks that will be used. It defaults to C<12> for C<4096> blocks and may change in the future.

=item * parallelism

The number of threads used for the hash. This defaults to C<1>, and you're unlikely to want to change this.

=item * time

This is the time parameter that the algorithm to use up more time. This default to C<0> and should only be used when using more memory isn't an option.

=item * flags

This flags that determine the flavor of yescrypt. It defaults to C<0xb6> and unless you know what you're doing you shouldn't be touching this.

=item * salt_size

The size of the salt. This defaults to C<16> bytes, which should be more than enough for any use-case.

=back

Note: there is no wrong or right configuration, it all depends on your own particular circumstances.

=head2 hash_password($password)

This hashes the passwords with yescrypt according to the specified settings and a random salt (and will thus return a different result each time).

=head2 needs_rehash($hash)

This returns true if the hash uses a different cipher or subtype, or if any of the parameters are different from that desired by the encoder.

=head2 crypt_types()

This class supports the following crypt types: C<y> and C<7>.

=head2 verify_password($password, $hash)

This will check if a password matches a yescrypt hash.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
