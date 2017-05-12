package Crypt::Simple;
$Crypt::Simple::VERSION = '0.06';

=head1 NAME

Crypt::Simple - encrypt stuff simply

=head1 SYNOPSIS

  use Crypt::Simple;
  
  my $data = encrypt(@stuff);

  my @same_stuff = decrypt($data);

=head1 DESCRIPTION

Maybe you have a web application and you need to store some session data at the
client side (in a cookie or hidden form fields) but you don't want the user to
be able to mess with the data.  Maybe you want to save secret information to a
text file.  Maybe you have better ideas of what to do with encrypted stuff!

This little module will convert all your data into nice base64 text that you
can save in a text file, send in an email, store in a cookie or web page, or
bounce around the Net.  The data you encrypt can be as simple or as complicated
as you like.

=head1 KEY

If you don't pass any options when using C<Crypt::Simple> we will generate a key
for you based on the name of your module that uses this one.  In many cases this
works fine, but you may want more control over the key.  Here's how:

=over 4

=item use Crypt::Simple passphrase => 'pass phrase';

The MD5 hash of the text string "pass phrase" is used as the key.

=item use Crypt::Simple prompt => 'Please type the magic words';

The user is prompted to enter a passphrase, and the MD5 hash of the entered text
is used as the key.

=item use Crypt::Simple passfile => '/home/marty/secret';

The contents of the file /home/marty/secret are used as the pass phrase: the MD5
hash of the file is used as the key.

=item use Crypt::Simple file => '/home/marty/noise';

The contents of the file /home/marty/noise are directly used as the key.

=back

=head1 INTERNALS

C<Crypt::Simple> is really just a wrapper round a few other useful Perl
modules: you may want to read the documentation for these modules too.

We use C<FreezeThaw> to squish all your data into a concise textual
representation.  We use C<Compress::Zlib> to compress this string, and then use
C<Crypt::Blowfish> in a home-brew CBC mode to perform the encryption.
Somewhere in this process we also add a MD5 digest (using C<Digest::MD5>).
Then we throw the whole thing through C<MIME::Base64> to produce a nice bit of
text for you to play with.

Decryption, obviously, is the reverse of this process.

=head1 WARNING

Governments throughout the world do not like encryption because it makes it
difficult for them to look at all your stuff.  Each country has a different
policy designed to stop you using encryption: some governments are honest enough
to make it illegal; some think it is a dangerous weapon; some insist that you
are free to encrypt, but only evil people would want to; some make confusing and
contradictory laws because they try to do all of the above.

Although this modules itself does not include any encryption code, it does use
another module that contains encryption code, and this documentation mentions
encryption.  Downloading, using, or reading this modules could be illegal where
you live.

=head1 AUTHOR

Marty Pauley E<lt>marty@kasei.comE<gt>

=head1 COPYRIGHT

  Copyright (C) 2001 Kasei Limited

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut

use strict;
use Carp;
use Crypt::Blowfish;
use Compress::Zlib;
use MIME::Base64;
use Digest::MD5 qw(md5);
use FreezeThaw qw(freeze thaw);

sub _chunk($) { $_[0] =~ /.{1,8}/ogs }

sub import {
	my ($class, @args) = @_;
	my $caller = caller;
	my $key = $class->get_key_param(@args)
		|| $class->get_key_default($caller);
	my $cipher = Crypt::Blowfish->new($key);

	no strict 'refs';
	*{"${caller}::encrypt"} = sub {
		my $data = freeze(@_);
		my $sig = md5($data);
		my $b0 = pack('NN', 0, 0);
		my $ct = '';
		foreach my $block (_chunk($sig.compress($data))) {
			$ct .= $b0 = $cipher->encrypt($b0 ^ $block);
		}
		return encode_base64($ct, '');
	};
	*{"${caller}::decrypt"} = sub {
		my $data = decode_base64($_[0]);
		my ($sig1, $sig2, @blocks) = _chunk($data);
		my $b0 = pack('NN', 0, 0);
		my $sig = $b0 ^ $cipher->decrypt($sig1);
		$b0 = $sig1;
		$sig .= $b0 ^ $cipher->decrypt($sig2);
		$b0 = $sig2;
		my $pt = '';
		foreach my $block (@blocks) {
			$pt .= $b0 ^ $cipher->decrypt($block);
			$b0 = $block;
		}
		my $result = uncompress($pt);
		croak "message digest incorrect" unless $sig eq md5($result);
		my @data = thaw($result);
		return wantarray ? @data : $data[0];
	};

      1;
}

sub get_key_param {
	my ($class, @p) = @_;
	return md5($p[0]) if @p == 1;
	my %p = @p;
	my $key = '';
	foreach my $k ($class->get_key_methods) {
		next unless exists $p{$k};
		if (my $m = $class->can("key_from_$k")) {
			$key = $class->$m($p{$k});
			last if $key;
		}
	}
	return $key;
}

sub get_key_default {
	my ($class, $c) = @_;
	return md5("$class,$c");
}

sub get_key_methods { qw{passphrase passfile file prompt} }

sub key_from_passphrase {
	my ($class, $pass) = @_;
	return md5($pass);
}

sub read_file_contents {
	my ($class, $file) = @_;
	open my $io, $file or croak "cannot open $file: $!";
	local $/;
	my $data = <$io>;
	close $io;
	return $data;
}

sub key_from_passfile {
	my ($class, $file) = @_;
	my $pass = $class->read_file_contents($file);
	return $class->key_from_passphrase($pass);
}

sub key_from_file {
	my ($class, $file) = @_;
	return $class->read_file_contents($file);
}

sub key_from_prompt {
	my ($class, $prompt) = @_;
	print STDERR "$prompt: ";
	my $pass = <STDIN>;
	chomp $pass;
	return $class->key_from_passphrase($pass);
}

1;
