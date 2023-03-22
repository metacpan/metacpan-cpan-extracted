package Crypt::Passphrase::System;
$Crypt::Passphrase::System::VERSION = '0.012';
use strict;
use warnings;

use Crypt::Passphrase -encoder;

use Carp 'croak';
use MIME::Base64 qw/encode_base64/;

my @possibilities = (
	[1   , '$1$'              ,  6, '$1$aaaaaa$FuYJ957Lgsw.eVsENqOok1'                                                                ],
	[5   , '$5$rounds=535000$', 12, '$5$aaaaaa$9hHgJfCniK4.dU43ykArHVETrhKDDElbS.cioeCajw.'                                           ],
	[6   , '$6$rounds=656000$', 12, '$6$aaaaaa$RgJSheuY/DBadaBm/5gQ.s3M9a/2n8gubwCE41kMiz1P4KcxORD6LxY2NUCuOQNZawfiD8tWWfRKg9v0CQjbH0'],
	['2x', '$2x$12$'          , 16, '$2x$08$......................qrjEXaz4RUVmquy3IT5eLKXLB28ahI2'                                    ],
	['2a', '$2a$12$'          , 16, '$2a$08$......................qrjEXaz4RUVmquy3IT5eLKXLB28ahI2'                                    ],
	['2y', '$2y$12$'          , 16, '$2y$08$......................qrjEXaz4RUVmquy3IT5eLKXLB28ahI2'                                    ],
	['2b', '$2b$12$'          , 16, '$2b$08$......................qrjEXaz4RUVmquy3IT5eLKXLB28ahI2'                                    ],
	[7   , '$7$DU..../....'   , 16, '$7$AU..../....2Q9obwLhin8qvQl6sisAO/$E1HizYWxBmnIH4sdPkd1UOML9t62Gf.wvNTnt5XFzs8'                ],
	['gy', '$gy$j8T$'         , 18, '$gy$j9T$......................$5.2XCu2DhNfGzpifM7X8goEG2Wkio9cWIMtyWnX4tp2'                      ],
	['y' , '$y$j8T$'          , 18, '$y$j9T$F5Jx5fExrKuPp53xLKQ..1$tnSYvahCwPBHKZUspmcxMfb0.WiB9W.zEaKlOBL35rC'                       ],
);

my (%algorithm, %salt_for, $default);
for my $row (@possibilities) {
	my ($name, $setting, $salt_size, $value) = @{$row};
	my $hash = eval { crypt('password', $value) };
	if (defined $hash and $hash eq $value) {
		$algorithm{$name} = { settings => $setting, salt_size => $salt_size };
		$default = $name;
	}
}

sub _get_parameters {
	my %args = @_;

	if (defined(my $settings = $args{settings})) {
		return ('', 2) if $settings eq '';

		my ($type) = $settings =~ /\A \$ ([^\$]+) \$ /x or croak "Invalid settings string '$settings'";
		croak "Unsupported algorithm $type" if not $algorithm{$type};
		return ($settings, $args{salt_size} // $algorithm{$type}{salt_size});
	}
	elsif (my $type = $args{type} // $default) {
		$settings = $algorithm{$type}{settings} // croak "No such crypt type $type known";
		return ($settings, $args{salt_size} // $algorithm{$type}{salt_size});
	}
	else {
		return ('', 2);
	}
}

sub new {
	my ($class, %args) = @_;

	my ($settings, $salt_size) = _get_parameters(%args);
	return bless {
		settings  => $settings,
		salt_size => $salt_size,
	}, $class;
}

sub hash_password {
	my ($self, $password) = @_;
	my $salt = $self->random_bytes($self->{salt_size});
	(my $encoded_salt = encode_base64($salt, "")) =~ tr{A-Za-z0-9+/=}{./0-9A-Za-z}d;
	return crypt($password, "$self->{settings}$encoded_salt\$");
}

my $descrypt = qr{ \A [./0-9A-Za-z]{13} \z }x;

sub accepts_hash {
	my ($self, $hash) = @_;
	return $hash =~ $descrypt || $self->SUPER::accepts_hash($hash);
}

sub crypt_subtypes {
	return sort keys %algorithm;
}

sub needs_rehash {
	my ($self, $hash) = @_;
	return length $self->{settings} ? substr($hash, 0, length $self->{settings}) ne $self->{settings} : $hash !~ $descrypt;
}

sub verify_password {
	my ($class, $password, $hash) = @_;
	my $new_hash = crypt($password, $hash);
	return $class->secure_compare($hash, $new_hash);
}

#ABSTRACT: An system crypt() encoder for Crypt::Passphrase

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::System - An system crypt() encoder for Crypt::Passphrase

=head1 VERSION

version 0.012

=head1 SYNOPSIS

 my $passphrase = Crypt::Passphrase->new(encoder => 'System');

=head1 DESCRIPTION

This class implements a Crypt::Passphrase encoder around your system's C<crypt()> function.

Note that the supported algorithms depend entirely on your platform. The only option portable among unices (descrypt) is not considered safe at all. It will try to pick a good default among the supported options. Because the different algorithms take different parameters they will have to be passed as a settings string if anything else is desired.

By default it uses the first supported algorithm in this list: C<yescript>, C<scrypt>, C<bcrypt>, C<SHAcrypt>, C<MD5crypt> and C<descrypt>.

=head1 METHODS

=head2 new(%args)

This creates a new crypt encoder, it takes named parameters that are all optional.

=over 4

=item * type

The type of hash, this must be one of the values returned by the C<crypt_subtypes> method. If none is given it is picked as described above.

=item * settings

The settings used for hashing the password, e.g. C<'$1$'>, C<'$2b$12$'>, C<'$6$rounds=65600$'>, C<'$7$DU..../....'> or C<'$y$j9T$'>. If you don't know what these mean you probably shouldn't touch this parameter. It defaults to something appropriate for your chosen / default algorithm.

=item * salt_size

This sets the salt size for algorithm, it defaults to something that should be sensible for your algorithm.

=back

=head2 hash_password($password)

This hashes the passwords with argon2 according to the specified settings and a random salt (and will thus return a different result each time).

=head2 needs_rehash($hash)

This returns true if the hash uses a different cipher, or if any of the parameters are different than desired by the encoder.

=head2 crypt_subtypes()

This returns whatever crypt types it can discover on your system.

=head2 verify_password($password, $hash)

This will check if a password matches linux crypt hash.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
