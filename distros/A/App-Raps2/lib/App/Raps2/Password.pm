package App::Raps2::Password;

use strict;
use warnings;
use 5.010;

use Carp 'confess';
use Crypt::CBC;
use Crypt::Eksblowfish;
use Crypt::Eksblowfish::Bcrypt qw(bcrypt_hash en_base64 de_base64);

our $VERSION = '0.54';

sub new {
	my ( $obj, %conf ) = @_;

	$conf{cost} //= 12;

	if ( not defined $conf{salt} ) {
		$conf{salt} = create_salt();
	}

	if ( length( $conf{salt} ) != 16 ) {
		confess('incorrect salt length');
	}

	if ( not( defined $conf{passphrase} and length $conf{passphrase} ) ) {
		confess('no passphrase given');
	}

	my $ref = \%conf;

	return bless( $ref, $obj );
}

sub create_salt {
	my ($self) = @_;
	my $salt = q{};

	for ( 1 .. 16 ) {
		$salt .= chr( 0x21 + int( rand(90) ) );
	}

	return $salt;
}

sub salt {
	my ( $self, $salt ) = @_;

	if ( defined $salt ) {
		if ( length($salt) != 16 ) {
			confess('incorrect salt length');
		}

		$self->{salt} = $salt;
	}

	return $self->{salt};
}

sub encrypt {
	my ( $self, %opt ) = @_;

	$opt{salt} //= $self->{salt};
	$opt{cost} //= $self->{cost};

	my $eksblowfish
	  = Crypt::Eksblowfish->new( $opt{cost}, $opt{salt}, $self->{passphrase}, );
	my $cbc = Crypt::CBC->new( -cipher => $eksblowfish );

	return $cbc->encrypt_hex( $opt{data} );
}

sub decrypt {
	my ( $self, %opt ) = @_;

	$opt{cost} //= $self->{cost};
	$opt{salt} //= $self->{salt};

	my $eksblowfish
	  = Crypt::Eksblowfish->new( $opt{cost}, $opt{salt}, $self->{passphrase}, );
	my $cbc = Crypt::CBC->new( -cipher => $eksblowfish );

	return $cbc->decrypt_hex( $opt{data} );
}

sub bcrypt {
	my ($self) = @_;

	return en_base64(
		bcrypt_hash(
			{
				key_nul => 1,
				cost    => $self->{cost},
				salt    => $self->{salt},
			},
			$self->{passphrase},
		)
	);
}

sub verify {
	my ( $self, $testhash ) = @_;

	my $myhash = $self->bcrypt();

	if ( $testhash eq $myhash ) {
		return 1;
	}
	confess('Passwords did not match');
}

1;

__END__

=head1 NAME

App::Raps2::Password - Password class for App::Raps2

=head1 SYNOPSIS

    use App::Raps2::Password;

    my $pass = App::Raps2::Password->new(
        passphrase => 'secret',
    );

    my $oneway_hash = $raps2->bcrypt();
    $raps2->verify($oneway_hash);

    my $twoway_hash = $raps2->encrypt('data');
    print $raps2->decrypt($twoway_hash);
    # "data"

=head1 VERSION

This manual documents B<App::Raps2::Password> version 0.54

=head1 DESCRIPTION

App::Raps2::Pasword is a wrapper around Crypt::Eksblowfish.

=head1 METHODS

=over

=item $pass = App::Raps2::Password->new(I<%conf>)

Creates a new I<App::Raps2::Password> object. You can only have one passphrase
per object. Arguments:

=over

=item B<cost> => I<int>

Cost to pass to B<Crypt::Eksblowfish>, defaults to 12.

=item B<passphrase> => I<string>

Passphrase to operate with. Mandatory.

=item B<salt> => I<string>

16-byte string to use as salt. If none is specified, B<App::Raps2::Password>
generates its own.

=back

=item $pass->create_salt()

Returns a new 16-byte salt. Contains only printable characters.

=item $pass->salt([I<salt>])

Returns the currently used salt and optionally changes it to I<salt>.

=item $pass->encrypt(B<data> => I<data>, [B<salt> => I<salt>],
[B<cost> => I<cost>])

Encrypts I<data> with the passphrase saved in the object, returns the
corresponding hexadecimal hash (as string).

By default, the salt set in B<salt> or B<new> will be used. You can override
it by specifying I<salt>.

=item $pass->decrypt(B<data> => I<hexstr>, [B<salt> => I<salt>],
[B<cost> => I<cost>])

Decrypts I<hexstr> (as created by B<encrypt>), returns its original content.

By default, the salt set in B<salt> or B<new> will be used. You can override
it by specifying I<salt>.

=item $pass->bcrypt()

Return a base64 bcrypt hash of the password, salted with the salt.

=item $pass->verify(I<hash>)

Verify a hash as returned by B<crypt>.

Returns true if it matches, dies if it doesn't.

=back

=head1 DIAGNOSTICS

When anything goes wrong, App::Raps2::Password will use Carp(3pm)'s B<confess>
method to die with a backtrace.

=head1 DEPENDENCIES

Crypt::CBC(3pm), Crypt::Eksblowfish(3pm).

=head1 BUGS AND LIMITATIONS

Unknown.

=head1 SEE ALSO

Crypt::CBC(3pm), Crypt::Eksblowfish(3pm).

=head1 AUTHOR

Copyright (C) 2011-2015 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

  0. You just DO WHAT THE FUCK YOU WANT TO.
