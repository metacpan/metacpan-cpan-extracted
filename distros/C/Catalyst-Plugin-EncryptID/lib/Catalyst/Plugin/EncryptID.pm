package Catalyst::Plugin::EncryptID;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Crypt::Blowfish;

=head1 NAME

Catalyst::Plugin::EncryptID - Obfuscate IDs/string in URLs

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 DESCRIPTION

This module makes easy to obfuscate internal IDs when using them in a URL given to users.
Instead of seeing L<http://example.com/item/42>
users will see L<http://example.com/item/c98ea08a8e8ad715> .
This will prevent nosy users from trying to iterate all items based on a simple ID in the URL.

=head1 CONFIGURATION

Configuration requires a secret key at a minimum.

Or set the secret key at run time, with:

    BEGIN {
		TestApp->config(
			name    => 'TestApp',
			EncryptID => {
				secret => 'abc123xyz',
				padding_character => '!'
			}
		);
    }

=cut

sub _padding_character {
	my ( $c ) = @_;
	my $config = $c->config->{EncryptID};
	return $config->{padding_character} || '!'	
}

sub _secret {
	my ( $c ) = @_;
	my $config = $c->config->{EncryptID};
	my $secret = $config->{secret} || ':-) - :-)';
	die "Key must be 8 byte long" if length($secret) < 8;
	return $secret;
}

sub _cipher {
	my ( $c ) = @_;
	my $secret = _secret($c);
	return Crypt::Blowfish->new($secret);
}

=head1 SYNOPSIS

	package TestApp;

	use strict;
	use warnings;

	use Catalyst qw/EncryptID/;

	TestApp->config(
		name    => 'TestApp',
		EncryptID => {
			secret => 'abc123xyz',
			padding_character => '!'
		}
	);

	1;

In Controller

	package TestApp::Controller::Root;
	use base 'Catalyst::Controller';

	__PACKAGE__->config->{namespace} = '';

	sub index : Private {
	    my ( $self, $c ) = @_;
	    $c->res->body('root index');
	}

	sub encrypt : Global Args(1) {
	    my ( $self, $c, $id ) = @_;
	    my $encripted_hash = $c->encrypt_data($id);
	    ...
	}

	sub decrypt : Global Args(1) {
	    my ( $self, $c, $hashid ) = @_;
	    my $decrypted_string = $c->decrypt_data($hashid);
	    ...
	}

	sub validhash : Global Args(1) {
	    my ( $self, $c, $hashid ) = @_;
	    my $status = $c->is_valid_encrypt_hash($hashid);
	    ...
	}

	1;

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 encrypt_data

C<encrypt_data(ID [,PREFIX])> - Encrypt the given ID, returns the encoded hash value.
			     If "PREFIX" is given, it will be added to the ID before encoding.
			     It can be used when decoding to verify the decoded value is valid.

=cut

sub encrypt_data {
	my( $c, $text, $prefix ) = @_;

	warn "Missing Clear text ID parameter" unless defined $text;
	return unless defined $text;

	## Prefix is optional, can be undef
	$text = $prefix . $text if defined $prefix;

	my $min_length = 8;
	my $ciphertext_hash = '';

	#encode an empty string
	$text = _padding_character($c) x $min_length if length($text) < 1;

	while ( length($text) > 0 ) {
		my $sub_text = substr($text,0,$min_length,'');
		if ( length($sub_text) < 8 ) {
			my $left = $min_length - length($sub_text);
			$sub_text = ( _padding_character($c) x ($left % $min_length) ). $sub_text;
		};

		my $ciphertext = _cipher($c)->encrypt($sub_text);
		$ciphertext_hash .= unpack('H16', $ciphertext ) ;
	}

	return $ciphertext_hash;
}

=head2 decrypt_data

C<decrypt_data(ID)> - Decrypt the given ID, returns the original (text) ID value.

=cut

sub decrypt_data {
	my( $c, $encrypted_hash ) = @_;

	return unless is_valid_encrypt_hash( $c, $encrypted_hash );

	my $padding_character = _padding_character($c);
	my $ciphertext = '';

	while ( length($encrypted_hash) > 0 ) {
		my $sub_text   = substr($encrypted_hash,0,16,'');
		my $cipherhash = pack('H16', $sub_text );
		my $text = _cipher($c)->decrypt($cipherhash);

		$text =~ s/^$padding_character+//;
		$ciphertext .= $text;
	};
	return $ciphertext
}

=head2 is_valid_encrypt_hash

C<is_valid_encrypt_hash(HASH)> - Return true if given encrypt has is valid

=cut

sub is_valid_encrypt_hash {
	my( $c, $encrypted_hash ) = @_;
	return 0 unless length($encrypted_hash);
	return 0 unless length($encrypted_hash)%16 == 0;
	return 0 unless $encrypted_hash =~ /^[0-9A-F]+$/i;
	return 1;
}

=head1 AUTHOR

Rakesh Kumar Shardiwal, C<< <rakesh.shardiwal at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-encryptid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-EncryptID>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::EncryptID


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-EncryptID>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-EncryptID>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-EncryptID>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-EncryptID/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Rakesh Kumar Shardiwal.

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

1; # End of Catalyst::Plugin::EncryptID
