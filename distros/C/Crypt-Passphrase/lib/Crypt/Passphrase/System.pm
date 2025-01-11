package Crypt::Passphrase::System;
$Crypt::Passphrase::System::VERSION = '0.020';
use strict;
use warnings;

use Crypt::Passphrase -encoder;

use Carp 'croak';

my @possibilities = (
	['3' , '$3$'              ,  0, '$3$$8846f7eaee8fb117ad06bdd830b7586c'],
	['',   ''                 ,  2, 'abJnggxhB/yWI' , '%s%s'],
	['_',  '_EQ0.'            ,  3, '_EQ0.jzhSVeUyoSqLupI', '%s%s'],
	['1' , '$1$'              ,  6, '$1$aaaaaa$FuYJ957Lgsw.eVsENqOok1'                                                                ],
	['md5', '$md5,rounds=5000$', 6, '$md5,rounds=5000$GUBv0xjJ$$PI9W.MLvhYh0hQMCkz1CH/', '%s%s$'],
	['sha1', '$sha1$40000$'   ,  6, '$sha1$40000$jtNX3nZ2$hBNaIXkt4wBI2o5rsi8KejSjNqIq'],
	['5' , '$5$rounds=535000$', 12, '$5$aaaaaa$9hHgJfCniK4.dU43ykArHVETrhKDDElbS.cioeCajw.'                                           ],
	['6' , '$6$rounds=656000$', 12, '$6$aaaaaa$RgJSheuY/DBadaBm/5gQ.s3M9a/2n8gubwCE41kMiz1P4KcxORD6LxY2NUCuOQNZawfiD8tWWfRKg9v0CQjbH0'],
	['2x', '$2x$12$'          , 16, '$2x$08$......................qrjEXaz4RUVmquy3IT5eLKXLB28ahI2'                                    ],
	['2a', '$2a$12$'          , 16, '$2a$08$......................qrjEXaz4RUVmquy3IT5eLKXLB28ahI2'                                    ],
	['2y', '$2y$12$'          , 16, '$2y$08$......................qrjEXaz4RUVmquy3IT5eLKXLB28ahI2'                                    ],
	['2b', '$2b$12$'          , 16, '$2b$08$......................qrjEXaz4RUVmquy3IT5eLKXLB28ahI2'                                    ],
	['7' , '$7$DU..../....'   , 16, '$7$AU..../....2Q9obwLhin8qvQl6sisAO/$E1HizYWxBmnIH4sdPkd1UOML9t62Gf.wvNTnt5XFzs8'                ],
	['gy', '$gy$j8T$'         , 16, '$gy$j9T$......................$5.2XCu2DhNfGzpifM7X8goEG2Wkio9cWIMtyWnX4tp2'                      ],
	['y' , '$y$j8T$'          , 16, '$y$j9T$F5Jx5fExrKuPp53xLKQ..1$tnSYvahCwPBHKZUspmcxMfb0.WiB9W.zEaKlOBL35rC'                       ],
);

my (%algorithm, $default);

for my $row (@possibilities) {
	my ($name, $setting, $salt_size, $value, $format) = @{$row};
	my $hash = eval { crypt 'password', $value };
	if (defined $hash and $hash eq $value) {
		$algorithm{$name} = { settings => $setting, salt_size => $salt_size, format => $format };
		$default = $name;
	}
}

sub new {
	my ($class, %args) = @_;

	my ($settings, $salt_size, $format);
	if (defined($settings = $args{settings})) {
		if ($settings eq '') {
			($salt_size, $format) = (2, '%s%s');
		} elsif ($settings eq '_') {
			($salt_size, $format) = (3, '%s%s');
		} else {
			my $type = $settings =~ /\A \$ ([^\$]+) \$ /x or croak "Invalid settings string '$settings'";
			$salt_size = $args{salt_size} // $algorithm{$type}{salt_size} // 16;
			$format = $args{format} // $algorithm{$type}{format} // '%s%s$';
		}
	}
	else {
		my $type = $args{type} // $default // croak 'No known crypt type found';
		$settings = $algorithm{$type}{settings} // croak "No such crypt type '$type' known";
		$salt_size = $args{salt_size} // $algorithm{$type}{salt_size};
		$format = $args{format} // $algorithm{$type}{format} // '%s%s$';
	}

	return bless {
		settings  => $settings,
		salt_size => $salt_size,
		format    => $format,
	}, $class;
}

my $base64_digits = './0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
sub _encode_crypt64 {
	my $bytes = shift;
	my $nbytes = length $bytes;
	my $npadbytes = 2 - ($nbytes + 2) % 3;
	$bytes .= "\0" x $npadbytes;
	my $digits = '';
	for (my $i = 0; $i < $nbytes; $i += 3) {
		my $v = ord(substr $bytes, $i, 1) |
			(ord(substr $bytes, $i + 1, 1) << 8) |
			(ord(substr $bytes, $i + 2, 1) << 16);
			$digits .= substr($base64_digits, $v & 0x3f, 1) .
			substr($base64_digits, ($v >> 6) & 0x3f, 1) .
			substr($base64_digits, ($v >> 12) & 0x3f, 1) .
			substr($base64_digits, ($v >> 18) & 0x3f, 1);
	}
	substr $digits, -$npadbytes, $npadbytes, '';
	return $digits;
}


sub hash_password {
	my ($self, $password) = @_;
	my $salt = $self->random_bytes($self->{salt_size});
	my $encoded_salt = _encode_crypt64($salt);
	substr $encoded_salt, 2, 1, '' if $self->{salt_size} == 2; # descrypt

	my $settings = sprintf $self->{format}, $self->{settings}, $encoded_salt;
	return crypt $password, $settings;
}

my $descrypt = qr{ \A [./0-9A-Za-z]{13}  \z }x;

my @formats;
push @formats, $descrypt if $algorithm{''};
push @formats, qr{ \A _[./0-9A-Za-z]{19} \z }x if $algorithm{'_'};

sub accepts_hash {
	my ($self, $hash) = @_;
	return 1 if $self->SUPER::accepts_hash($hash);
	for my $format (@formats) {
		return 1 if $hash =~ $format;
	}
	return 0;
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
	my $new_hash = crypt $password, $hash;
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

version 0.020

=head1 SYNOPSIS

 my $passphrase = Crypt::Passphrase->new(encoder => 'System');

=head1 DESCRIPTION

This class implements a Crypt::Passphrase encoder around your system's C<crypt()> function.

Note that the supported algorithms depend entirely on your platform. The only option portable among unices (descrypt) is not considered safe at all. It will try to pick a good default among the supported options. Because the different algorithms take different parameters they will have to be passed as a settings string if anything else is desired.

By default it uses the first supported algorithm in this list: C<yescript>, C<scrypt>, C<bcrypt>, C<SHA512crypt>, C<SHA256crypt>, C<SHA1crypt>, C<MD5crypt>, extended C<descrypt>, C<descrypt> and C<NTHASH>.

=head2 Configuration

It takes the following arguments for configuration:

=over 4

=item * type

The type of hash, this must be one of the values supported by the system. If none is given it is picked as described above.

=over 4

=item * C<'y'> / C<'gy'>

C<yescrypt>

This is known to be supported on linux systems using C<libxcrypt>. C<'y'> is typically the default for system passwords on such systems.

=item * C<'7'>

C<scrypt>

This is known to be supported on linux systems using C<libxcrypt>, FreeBSD and Solaris.

=item * C<'2b'> / C<'2a'> / C<'2y'> / C<'2x'>

C<bcrypt>

This is the traditional default algoritm of BSD systems. Difference between these types is in obscure edge-cases, C<'2b'> should be prefered unless another variant is required. This is also supported on linux systems using C<libxcrypt> and Solaris.

=item * C<'6'>

C<SHA512crypt>

This algorithm originated on Linux but is also supported on some BSDs and Solaris.

=item * C<'5'>

C<SHA256crypt>

This algorithm originated on Linux but is also supported on some BSDs and Solaris.

=item * C<'sha1'>

C<SHA1crypt>

This algorithm is supported on NetBSD and Linux systems using C<libxcrypt>.

=item * C<'1'>

C<MD5crypt>

This is supported on Linux, many BSDs and Solaris.

=item * C<'md5'>

Solaris C<MD5crypt>.

This is supported on Solaris and Linux systems using C<libxcrypt>.

=item * C<'_'>

Extended C<descrypt>.

This is supported on Linux, BSD and Mac OS.

=item * C<''>

C<descrypt>

This is the only algorithm that is universally supported. Unfortunately it's also incredably unsafe and should not be used in production.

Note that unlike all other supported algorithms this lacks a crypt header.

=item * C<'$3$'>

C<NTHASH>

This saltless algorithm originates in the Microsoft world. It's supported on FreeBSD and Linux systems using C<libxcrypt>.

=back

=item * settings

The settings used for hashing the password, combining the type above with a type specific information, e.g. C<'$1$'>, C<'$2b$12$'>, C<'$6$rounds=65600$'>, C<'$7$DU..../....'> or C<'$y$j9T$'>. If you don't know what these mean you probably shouldn't touch this parameter. It defaults to something appropriate for the selected algorithm.

=item * salt_size

This sets the salt size for algorithm, it defaults to something that should be sensible for your algorithm.

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
