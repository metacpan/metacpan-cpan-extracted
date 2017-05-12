package Dancer::Plugin::EncodeID;

use strict;
use warnings;
our $VERSION = '0.02';

use Dancer ':syntax';
use Dancer::Plugin;
use Crypt::Blowfish;

my $cipher = undef ;
my $padding_character = '!';

sub _create_cipher {
	## Crate a new cipher, based on the 'secret' in the configuration
	my $settings = plugin_setting or
		die "Configuration Error: can't find plugin settings for Dancer::Plugin::EncodeID. Please see documentation regarding proper configuration.";

	my $secret = $settings->{secret} or
		die "Configuration Error: can't find 'secret' key settings for Dancer::Plugin::EncodeID. Please see documentation regarding proper configuration.";

	$padding_character = $settings->{padding_character} || '!';
	die "Configuration error: padding_character must be 1 character long for Dancer::Plugin::EncodeID. Please see documentation regarding proper configuration." unless length($padding_character)==1;

	$cipher = new Crypt::Blowfish ( $secret ) ;
}

register encode_id => sub {
	my $cleartext_id = shift;
	die "Missing Clear text ID parameter" unless defined $cleartext_id;

	## Prefix is optional, can be undef
	my $prefix = shift ;
	$cleartext_id = $prefix . $cleartext_id if defined $prefix;

	_create_cipher() unless $cipher;

	my $hash_id = "" ;

	#Special case - user asked to encode an empty string
	$cleartext_id = $padding_character x '8' if length($cleartext_id)==0;

	while ( length($cleartext_id)>0 ) {
		my $sub_text = substr($cleartext_id,0,8,'');
		my $padded_str_id = $sub_text;
		if (length($sub_text)<8) {
			$padded_str_id = ( $padding_character x (8- length($sub_text) % 8 ) ). $sub_text ;
		};
		#print STDERR "Encoding '$padded_str_id'\n";
		my $ciphertext = $cipher->encrypt($padded_str_id);
		$hash_id .= unpack('H*', $ciphertext ) ;
	}
	return $hash_id;
};

register valid_encoded_id => sub {
	my $encoded_id = shift or die "Missing Encoded ID parameter";

	return 0 unless $encoded_id =~ /^[0-9A-F]+$/i;
	return 0 unless length($encoded_id)%16==0;
	return 1;
};

register decode_id => sub {
	my $encoded_id = shift or die "Missing Encoded ID parameter";
	my $orig_encoded_id = $encoded_id;

	## Prefix is optional, can be undef
	my $prefix = shift ;

	_create_cipher() unless $cipher;

	die "Invalid Hash-ID value ($encoded_id)" unless $encoded_id =~ /^[0-9A-F]+$/i;
	die "Invalid Hash-ID value ($encoded_id) - must be a multiple of 8 bytes (16 hex digits)"
		unless length($encoded_id)%16==0;

	my $cleartext = "";

	while ( length($encoded_id)>0 ) {
		my $sub_text = substr($encoded_id,0,16,'');
		my @list = $sub_text =~ /([0-9A-F]{2})/gi;
		#print STDERR "Decoding: '$sub_text'\n";
		my $ciphertext = pack('H2' x scalar(@list), @list) ;

		my $text = $cipher->decrypt($ciphertext);
		$text =~ s/^$padding_character+//;
		#print STDERR "Decoded: '$text'\n";
		$cleartext .= $text;
	};

	if (defined $prefix) {
		## Ensure the decoded ID contains the prefix
		my $i = index $cleartext,$prefix;
		if ($i != 0) {
			die "Invalid Hash-ID value ($orig_encoded_id) - bad prefix" ;
		}
		#skip the prefix;
		$cleartext = substr $cleartext, length($prefix);
	}

	return $cleartext;
};

register_plugin;

# ABSTRACT: A Dancer plugin for Encoding/Obfuscating IDs in URLs

1;
__END__
=pod

=head1 NAME

Dancer::Plugin::EncodeID - Encode/Decode (or obfuscate) IDs in URLs

=head1 VERSION

version 0.02

=head1 SYNOPSIS

	use Dancer;
	use Dancer::Plugin::EncodeID;

	set show_errors => true;

	# Set the secret key (better yet: put this in your config.yml)
	setting plugins => { EncodeID => { secret => 'my_secret_key' } };

	# Generate an encoded/obfuscaed ID in URL
	#
	# When the user visits this page, she will see URLs such as:
	#   http://myserver.com/item/c98ea08a8e8ad715
	# instead of
	#   http://myserver.com/item/42
	#
	get '/' => sub {

		# Any ID (numeric or alpha-numeric) you want to obfuscate
		my $clear_text_id = int(rand(42)+1);

		# Encode the ID, generate the URL
		my $encoded_id = encode_id($clear_text_id);
		my $url = request->uri_for("/item/$encoded_id");

		return "Link for Item $clear_text_id: <a href=\"$url\">$url</a>";
	};

	#
	# Decode a given ID, show the requested item
	#
	get '/item/:encoded_id' => sub {
		# Decode the ID back to clear-text
		my $clear_text_id = decode_id( params->{encoded_id} ) ;

		return "Showing item '$clear_text_id'";
	};

	dance;

=head1 FUNCTIONS

C<encode_id(ID [,PREFIX])> - Encodes the given ID, returns the encoded hash value.
			     If "PREFIX" is given, it will be added to the ID before encoding.
			     It can be used when decoding to verify the decoded value is valid.

C<decode_id(ID [,PREFIX])> - Decodes the given ID, returns the original (cleartext) ID value.
			     If "PREFIX" is given, it will be used to verify the validity of the ID.

=head1 DESCRIPTION

This module aims to make it as easy as possible to obfuscate internal IDs
when using them in a URL given to users. Instead of seeing L<http://myserver.com/item/42>
users will see L<http://myserver.com/item/c98ea08a8e8ad715> .
This will prevent nosy users from trying to iterate all items based on a simple ID in the URL.

=head1 CONFIGURATION

Configuration requires a secret key at a minimum.

Either put this in your F<config.yml> file:

    plugins:
      EncodeID:
        secret: 'my_secret_password'

Or set the secret key at run time, with:

    setting plugins => { EncodeID => { secret => 'my_secret_code' } };

=head1 AUTHOR

Assaf Gordon, C<< <gordon at cshl.edu> >>

=head1 BUGS

=over

=item THIS MODULE IS NOT SECURE. The encoded ID are not strongly encrypted in any way. The goal is obfuscation, not security.

=item A possible improvement would be to use L<Crypt::CBC> on top of L<Crypt::Blowfish>, but that would generate IDs that are at least 48 characters long.

=item The secret key can not be changed once loaded.

=back

Please report any bugs or feature requests to
L<https://github.com/agordon/Dancer-Plugin-EncodeID/issues>

=head1 SEE ALSO

A fully functional command-line tool to encode/decode IDs is available in the C<./eg/> folder.

L<Dancer>, L<Dancer::Plugin>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::EncodeID

=head1 ACKNOWLEDGEMENTS

Idea and implementation for this module were greatly influenced by similar mechanism used in the Galaxy project (L<http://usegalaxy.org>).

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Assaf Gordon.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
