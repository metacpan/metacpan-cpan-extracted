package Convert::X509::Certificate;

=head1 NAME

Convert::X509::Certificate parses X509 certificates

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
	$self->{'subject'}= Convert::X509::Parser::_decode_rdn($self->{'data'}->{'tbsCertificate'}{'subject'}{'rdnSequence'});
	$self->{'issuer'}= Convert::X509::Parser::_decode_rdn($self->{'data'}->{'tbsCertificate'}{'issuer'}{'rdnSequence'});
	$self->{'from'}= $self->{'data'}->{'tbsCertificate'}{'validity'}{'notBefore'};
	$self->{'to'}= $self->{'data'}->{'tbsCertificate'}{'validity'}{'notAfter'};
	$self->{'serial'}= Convert::X509::Parser::_int2hexstr($self->{'data'}->{'tbsCertificate'}{'serialNumber'});
	$self->{'extensions'}= Convert::X509::Parser::_decode_ext ( $self->{'data'}->{'tbsCertificate'}{'extensions'} );
	$self->{'signature'}= {
		 'sign'		=> $self->{'data'}->{'signature'}[0], # bits
		 'length'		=> $self->{'data'}->{'signature'}[1],
		 'algorithm'	=> $self->{'data'}->{'signatureAlgorithm'}{'algorithm'},
		 'params'		=> $self->{'data'}->{'signatureAlgorithm'}{'parameters'},
		};
	$self->{'pkinfo'}= {
		 'algorithm'	=> $self->{'data'}->{'tbsCertificate'}{'subjectPKInfo'}{'algorithm'}{'algorithm'}, # yes, 2 times
		 'params'	=> $self->{'data'}->{'tbsCertificate'}{'subjectPKInfo'}{'algorithm'}{'parameters'},
		 'length'	=> $self->{'data'}->{'tbsCertificate'}{'subjectPKInfo'}{'subjectPublicKey'}[1],
		 'key'		=> $self->{'data'}->{'tbsCertificate'}{'subjectPKInfo'}{'subjectPublicKey'}[0],
		};
	delete $self->{'data'};
	return (bless $self, $class);
}

sub aia {
	my $aiaext = '1.3.6.1.5.5.7.1.1';
	return (
	exists $_[0]->{'extensions'}{$aiaext} ?
	 map { values %{$_->{'accessLocation'}} }
	 @{ $_[0]->{'extensions'}{$aiaext}{'value'} }
	: undef
	);
}

1;
