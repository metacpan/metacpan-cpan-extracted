package Crypt::Credentials;
$Crypt::Credentials::VERSION = '0.005';
use strict;
use warnings;

use Carp 'croak';
use Crypt::AuthEnc::GCM qw/gcm_encrypt_authenticate gcm_decrypt_verify/;
use Crypt::SysRandom 'random_bytes';
use File::Basename 'dirname';
use File::Path 'make_path';
use File::Slurper qw/read_binary write_binary/;
use File::Spec::Functions qw/catdir catfile curdir updir abs2rel rel2abs/;
use YAML::PP;

sub new {
	my ($class, %args) = @_;

	my $dir = rel2abs($args{dir} // catdir(curdir, 'credentials'));

	my $check_file = catfile($dir, 'check.enc');

	my $real_key;

	if (-f $check_file) {
		for my $key (@{ $args{keys} }) {
			my $length = length $key;
			croak "Invalid key size($length)" if $length != 16 && $length != 24 && $length != 32;
			if (eval { $class->_get($check_file, $key) } // '' eq 'OK') {
				$real_key = $key;
				last;
			}
		}
	} else {
		($real_key) = @{ $args{keys} };
		my $length = length $real_key;
		croak "Invalid key size($length)" if $length != 16 && $length != 24 && $length != 32;
		make_path($dir);
		$class->_put($check_file, $real_key, 'OK');
	}
	croak 'No working key found' unless defined $real_key;

	return bless {
		key => $real_key,
		dir => $dir,
	}, $class;
}

my $ypp = YAML::PP->new;
my $format = 'a16 a16 a*';

sub _put {
	my ($self, $filename, $key, $plaintext) = @_;
	my $iv = random_bytes(16);
	my ($ciphertext, $tag) = gcm_encrypt_authenticate('AES', $key, $iv, '', $plaintext);
	my $payload = pack $format, $iv, $tag, $ciphertext;
	write_binary($filename, $payload);
}

sub put {
	my ($self, $name, $plaintext) = @_;
	my $filename = catfile($self->{dir}, "$name.yml.enc");
	my $dirname = dirname($filename);
	make_path($dirname);
	$self->_put($filename, $self->{key}, $plaintext);
	return;
}

sub put_yaml {
	my ($self, $name, @content) = @_;
	my $plaintext = $ypp->dump_string(@content);
	return $self->put($name, $plaintext);
}

sub _get {
	my ($self, $filename, $key) = @_;
	my $raw = read_binary($filename);
	my ($iv, $tag, $ciphertext) = unpack $format, $raw;
	my $plaintext = gcm_decrypt_verify('AES', $key, $iv, '', $ciphertext, $tag);
	croak 'Could not decrypt credentials file' if not defined $plaintext;
	return $plaintext;
}

sub get {
	my ($self, $name) = @_;
	my $filename = catfile($self->{dir}, "$name.yml.enc");
	croak "No such credentials '$name'" if not -f $filename;
	return $self->_get($filename, $self->{key});
}

sub get_yaml {
	my ($self, $name) = @_;
	my $plaintext = $self->get($name);
	return $ypp->load_string($plaintext);
}

sub has {
	my ($self, $name) = @_;

	return -f catfile($self->{dir}, "$name.yml.enc");
}

sub _recode_dir {
	my ($self, $dir, $new_key) = @_;

	opendir my $dh, $dir or croak "Could not open dir: $!";
	while (my $file = readdir $dh) {
		next if $file eq curdir || $file eq updir;
		my $filename = catfile($dir, $file);

		if (-d $filename) {
			$self->_recode_dir($filename, $new_key);
		} elsif (-f $filename) {
			next unless $file =~ /\.yml\.enc$/;
			my $plaintext = $self->_get($filename, $self->{key});
			$self->_put($filename, $new_key, $plaintext);
		}
	}
}

sub recode {
	my ($self, $new_key) = @_;

	my $key_length = length $new_key;
	croak "Invalid key size($key_length)" if $key_length != 16 && $key_length != 24 && $key_length != 32;

	$self->_recode_dir($self->{dir}, $new_key);

	my $check_file = catfile($self->{dir}, 'check.enc');
	$self->_put($check_file, $new_key, 'OK');
	$self->{key} = $new_key;

	return;
}

sub remove {
	my ($self, $name) = @_;
	my $filename = catfile($self->{dir}, "$name.yml.enc");
	return unlink($filename);
}

sub _list_dir {
	my ($self, $base, $dir) = @_;
	opendir my $dh, $dir or croak "No such dir $dir: $!";
	my @files;
	while (my $file = readdir $dh) {
		next if $file eq curdir || $file eq updir;
		my $filename = catfile($dir, $file);

		if (-d $filename) {
			push @files, $self->_list_dir($base, $filename);
		} elsif (-f $filename and $filename =~ s/\.yml\.enc$//) {
			push @files, abs2rel($filename, $base);
		}
	}
	return @files;
}

sub list {
	my ($self, $base) = @_;
	my $dir = $base ? catdir($self->{dir}, $base) : $self->{dir};
	return if not -d $dir;

	return $self->_list_dir($self->{dir}, $dir);
}

1;

# ABSTRACT: Manage credential files

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Credentials - Manage credential files

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 my $credentials = Crypt::Credentials->new(
   dir => $dir,
   keys => split /:/, $ENV{CREDENTIAL_KEYS},
 );

 my $password = $credentials->get('password');

=head1 DESCRIPTION

This module implements a credentials store. Essentially it allows you to expand one secret (the key of the store) into any number of secrets.

=head1 METHODS

=head2 new

 $self->new(keys => \@keys, dir => $dir)

This creates a new C<Crypt::Credentials> object. It takes two named arguments: C<@keys> (mandatory) are the cryptographic keys used to encrypt the credentials, they must be either 16, 24, or 32 bytes long. If multiple keys are given they're tried until the right one is found, this facilitates key rotation. C<$dir> is optional for the directory in which the credentials are stored, it defaults to F<./credentials>.

=head2 get

 $self->get($name)

This reads the credentials entry for C<$name>, or throws an exception if it can't be opened for any reason.

=head2 get_yaml

 $self->get_yaml($name)

Like the above, except it will decode the payload as YAML.

=head2 put

 $self->put($name, $value)

This will write the values to the named credentials entry.

=head2 put_yaml

 $self->put_yaml($name, \%values)

Like the above, but it will encode the value to YAML first.

=head2 has

 $self->has($name)

This checks if a credentials entry exists

=head2 remove

 $self->remove($name)

This removes a credentials entry. It will silently succeed if no such entry exists.

=head2 list

 $self->list

This will list all credential entries.

=head2 recode

 $self->recode($new_key)

This will recode all credential entries from the current key to the new one.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
