package Crypt::KDF::OpenSSLPBEGenerator;

use strict;
use Digest::MD5;
use vars qw($VERSION @ISA @EXPORT_OK);
use Crypt::KDF::_base;

($VERSION) = sprintf '%i.%03i', split(/\./,('$Revision: 0.1 $' =~ /Revision: (\S+)\s/)[0]);  # $Date: $

require Exporter;
@EXPORT_OK = qw(opensslpbekdf_generate);

@ISA=qw{ Crypt::KDF::_base };

=head1 NAME

Crypt::KDF::OpenSSLPBEGenerator - OpenSSL Password-Based-Encryption generator for derived keys and ivs as exercised by OpenSSL.

=head1 SYNOPSIS

=head1 DESCRIPTION

This implementation is based on the Bouncycastle Java Implementation.

=head1 FUNCTIONS

=head2 $derivedKey = opensslpbekdf_generate( $digest, $password, $salt, $len )

Quick functional interface to use OpenSSL PBE KDF.

=cut 

sub opensslpbekdf_generate
{
	my ($digest, $seed, $iv, $len) = @_;
	my $kdf = Crypt::KDF::OpenSSLPBEGenerator->new(-digest => $digest, -seed => $seed, -iv => $iv);
	return $kdf->kdf($len);
}

=head1 METHODS

=head2 $kdf = Crypt::KDF::BaseKDFGenerator->new( [options] )

Construct a OpenSSL PBE KDF generator.

	-digest the digest to be used as the source of derived keys.
	-digestparam optional parameters for the digest used to derive keys.
	-seed the seed/password to be used to derive keys.
	-iv optional iv/salt to be used to derive keys.

=cut

sub new
{
	my $class = shift @_;
	my $self = {};
	bless($self, (ref($class) ? ref($class) : $class));
	my %opts = @_;
	if(exists $opts{-digest})
	{
		$self->{-digest} = (ref($opts{-digest}) ? ref($opts{-digest}) : $opts{-digest});
	}
	if(exists $opts{-digestparam})
	{
		$self->{-digestparam} = $opts{-digestparam};
	}
	if(exists $opts{-seed})
	{
		$self->{-seed} = $opts{-seed};
	}
	if(exists $opts{-iv})
	{
		$self->{-iv} = $opts{-iv};
	}
	return $self;
}

=head2 $kdf->init( [options] )

Initialize the OpenSSL PBE KDF generator.

	-digest the digest to be used as the source of derived keys.
	-digestparam optional parameters for the digest used to derive keys.
	-seed the seed/password to be used to derive keys.
	-iv optional iv/salt to be used to derive keys.

=cut

sub init
{
	my $self = shift @_;
	my %opts = @_;
	if(exists $opts{-digest})
	{
		$self->{-digest} = (ref($opts{-digest}) ? ref($opts{-digest}) : $opts{-digest});
	}
	if(exists $opts{-digestparam})
	{
		$self->{-digestparam} = $opts{-digestparam};
	}
	if(exists $opts{-seed})
	{
		$self->{-seed} = $opts{-seed};
	}
	if(exists $opts{-iv})
	{
		$self->{-iv} = $opts{-iv};
	}
	return $self;
}

=head2 $derivedKey = $kdf->kdf( $length )

Return length bytes generated from the derivation function.

=cut

sub kdf
{
	my $self = shift @_;
	my $len = 16;
	if($_[0])
	{
		$len = $_[0];
	}
	my $out='';
	my $last='';
	while(length($out)<$len)
	{
		my $d;
		if(!exists $self->{-digest})
		{
			$self->{-digest} = 'Digest::MD5';
		}
		if(exists $self->{-digestparam})
		{
			$d = $self->{-digest}->new(@{ $self->{-digestparam} });
		}
		else
		{
			$d = $self->{-digest}->new();
		}
		if($last ne '')
		{
			$d->add($last);
		}
		$d->add($self->{-seed});
		if(exists $self->{-iv})
		{
			$d->add($self->{-iv});
		}
		$last=$d->digest();
		$out.=$last;
	}
	return substr($out,0,$len);
}

1;

__END__

=head2 ( $derivedKey, $derivedIV ) = $kdf->kdf_iv( $kLen, $ivLen )

Return length bytes generated from the derivation function.

=head1 EXAMPLES

=head1 SEE ALSO

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHORS 

=cut