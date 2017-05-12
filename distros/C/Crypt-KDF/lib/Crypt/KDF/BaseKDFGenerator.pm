package Crypt::KDF::BaseKDFGenerator;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
use Crypt::KDF::_base;

($VERSION) = sprintf '%i.%03i', split(/\./,('$Revision: 0.1 $' =~ /Revision: (\S+)\s/)[0]);  # $Date: $

require Exporter;
@EXPORT_OK = qw(baseKdf_generate);

@ISA=qw{ Crypt::KDF::_base };

=head1 NAME

Crypt::KDF::BaseKDFGenerator - Basic KDF generator for derived keys and ivs as defined by IEEE P1363a/ISO 18033.

=head1 SYNOPSIS

=head1 DESCRIPTION

This implementation is based on ISO 18033/P1363a.

=head1 FUNCTIONS

=head2 $derivedKey = baseKdf_generate( $digest, $seed, $counter, $len )

Quick functional interface to use KDF.

=cut 

sub baseKdf_generate
{
	my ($digest, $seed, $counter, $len) = @_;
	my $kdf = Crypt::KDF::BaseKDFGenerator->new(-digest => $digest, -seed => $seed, -counter => $counter);
	return $kdf->kdf($len);
}

=head1 METHODS

=head2 $kdf = Crypt::KDF::BaseKDFGenerator->new( [options] )

Construct a Basic KDF generator.

	-counter start value of counter used to derive keys.
	-digest the digest to be used as the source of derived keys.
	-digestparam optional parameters for the digest used to derive keys.
	-seed the seed to be used to derive keys.
	-iv optional iv to be used to derive keys.

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
	if(exists $opts{-counter})
	{
		$self->{-counter} = $opts{-counter};
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

Initialize the Basic KDF generator.

	-counter start value of counter used to derive keys.
	-digest the digest to be used as the source of derived keys.
	-digestparam optional parameters for the digest used to derive keys.
	-seed the seed to be used to derive keys.
	-iv optional iv to be used to derive keys.

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
	if(exists $opts{-counter})
	{
		$self->{-counter} = $opts{-counter};
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
	my $ct=$self->{-counter};
	while(length($out)<$len)
	{
		my $d;
		if(exists $self->{-digestparam})
		{
			$d = $self->{-digest}->new(@{ $self->{-digestparam} });
		}
		else
		{
			$d = $self->{-digest}->new();
		}
		$d->add($self->{-seed});
		$d->add(pack('N',$ct));
		if(exists $self->{-iv})
		{
			$d->add($self->{-iv});
		}
		$out.=$d->digest();
		$ct++;
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