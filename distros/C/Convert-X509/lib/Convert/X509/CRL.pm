package Convert::X509::CRL;

=head1 NAME

Convert::X509::CRL parses X509 CertificateRevocationLists

=cut

use Exporter;
use Convert::X509;
use Convert::X509::Parser;

@ISA = qw(Convert::X509);

use strict;
use warnings;

sub new {
	my ($class,$data,$debug)=@_;
	return undef unless $data;
	my $self = Convert::X509->new(\$data, $class, $debug);
	return undef unless $self;
	$self->{'crl'}		= {};
	$self->{'issuer'}	= Convert::X509::Parser::_decode_rdn($self->{'data'}->{'tbsCertList'}{'issuer'}{'rdnSequence'});
	$self->{'from'}	= $self->{'data'}->{'tbsCertList'}{'thisUpdate'};
	$self->{'to'}		= $self->{'data'}->{'tbsCertList'}{'nextUpdate'};
	$self->{'extensions'}	= Convert::X509::Parser::_decode_ext ( $self->{'data'}->{'tbsCertList'}{'crlExtensions'} );
	$self->{'signature'}		= {
		'sign'		=> $self->{'data'}->{'signatureValue'}[0], # bits
		'length'		=> $self->{'data'}->{'signatureValue'}[1],
		'algorithm'	=> $self->{'data'}->{'signatureAlgorithm'}{'algorithm'},
		'params'		=> $self->{'data'}->{'signatureAlgorithm'}{'parameters'},
	};
	for my $entry ( @{ $self->{'data'}->{'tbsCertList'}{'revokedCertificates'} } ){
		my $serial = Convert::X509::Parser::_int2hexstr( $entry->{'userCertificate'} );
		$self->{'crl'}{$serial}{'date'} = $entry->{'revocationDate'};
		$self->{'crl'}{$serial}{'ext'} =
		 Convert::X509::Parser::_decode_ext( $entry->{'crlEntryExtensions'} )
		if $entry->{'crlEntryExtensions'};
	}
	delete $self->{'data'};
	return (bless $self, $class);
}

sub reason {
  my $self = shift;
  return Convert::X509::Parser::_crlreason(
    $self->{'crl'}{ lc($_[0]) }{'ext'}{'2.5.29.21'}{'value'}
  );
}

sub next {
	my $time = (exists $_[0]->{'extensions'}{'1.3.6.1.4.1.311.21.4'} ?
		$_[0]->{'extensions'}{'1.3.6.1.4.1.311.21.4'}{'value'}{'utcTime'}
		: undef);
	return (wantarray ? () : '') unless $time;
	return Convert::X509::Parser::_ansi_now($time);
}

1;
