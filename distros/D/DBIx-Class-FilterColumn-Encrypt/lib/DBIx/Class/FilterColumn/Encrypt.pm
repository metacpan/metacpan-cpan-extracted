package DBIx::Class::FilterColumn::Encrypt;
$DBIx::Class::FilterColumn::Encrypt::VERSION = '0.001';
use strict;
use warnings;

use parent 'DBIx::Class';
__PACKAGE__->load_components(qw/FilterColumn/);

use Crypt::AuthEnc::GCM;
use Crypt::URandom;

my $format = 'w a16 a16 a*';

sub register_column {
	my ($self, $column, $info, @rest) = @_;

	$self->next::method($column, $info, @rest);
	return unless my $encrypt = $info->{encrypt};
	my %keys = %{ $encrypt->{keys} };
	my $active = $encrypt->{active_key} || (sort { $b <=> $a } keys %keys)[0];
	my $cipher = $encrypt->{cipher} || 'AES';

	$self->filter_column(
		$column => {
			filter_to_storage => sub {
				my (undef, $plaintext) = @_;
				my $iv = Crypt::URandom::urandom_ub(16);
				my $encrypter = Crypt::AuthEnc::GCM->new($cipher, $keys{$active}, $iv);
				my $ciphertext = $encrypter->encrypt_add($plaintext);
				my $tag = $encrypter->encrypt_done;
				return pack $format, $active, $iv, $tag, $ciphertext;
			},
			filter_from_storage => sub {
				my (undef, $raw) = @_;
				my ($key_id, $iv, $expected_tag, $ciphertext) = unpack $format, $raw;
				my $key = $keys{$key_id} or return undef;
				my $decrypter = Crypt::AuthEnc::GCM->new($cipher, $key, $iv);
				my $plaintext = $decrypter->decrypt_add($ciphertext);
				my $received_tag = $decrypter->decrypt_done;
				return $received_tag eq $expected_tag ? $plaintext : undef;
			},
		},
	);
}

1;

# ABSTRACT: Transparently encrypt columns in DBIx::Class

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::FilterColumn::Encrypt - Transparently encrypt columns in DBIx::Class

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 __PACKAGE__->load_components(qw/FilterColumn::Encrypt/);

 __PACKAGE__->add_columns(
     id => {
         data_type         => 'integer',
         is_auto_increment => 1,
     },
     data => {
         data_type => 'text',
         encrypt   => {
			keys     => {
				0      => pack('H*', ...),
			},
		},
     },
 );

 __PACKAGE__->set_primary_key('id');


 # in application code
 $rs->create({ data => 'some secret' });

=head1 DESCRIPTION

This components transparently encrypts any value with the currently active key, or decrypts them with any known value. This is useful when needing read/write access to values that are too sensitive to store in plaintext, such as credentials for other services. For passwords you should be using L<DBIx::Class::CryptColumn|DBIx::Class::CryptColumn> instead of this module.

To enable encryption, C<encrypt> must be a hash containing the key C<keys>, which shall be a hash mapping numberic identifiers to keys. An optional argument <active_key> may be given which one will be used for encrypting, otherwise the key with the highest numeric value will be used automatically; this allows you to rotate the active key. Also a C<cipher> command may be passed if a cipher other than AES is desired.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
