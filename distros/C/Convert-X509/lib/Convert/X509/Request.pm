package Convert::X509::Request;

=head1 NAME

Convert::X509::Request parses X509 requests for certificates

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
	$self->{'subject'}	= Convert::X509::Parser::_decode_rdn(
		$self->{'data'}->{'certificationRequestInfo'}{'subject'}{'rdnSequence'}
	);
	$self->{'attributes'}= {};
	$self->{'signature'}	= {
		'sign'		=> $self->{'data'}->{'signature'}[0], # bits
		'length'		=> $self->{'data'}->{'signature'}[1],
		'algorithm'	=> $self->{'data'}->{'signatureAlgorithm'}{'algorithm'},
		'params'		=> $self->{'data'}->{'signatureAlgorithm'}{'parameters'},
	};
	$self->{'pkinfo'}	= {
		'algorithm'	=> $self->{'data'}->{'certificationRequestInfo'}{'subjectPKInfo'}{'algorithm'}{'algorithm'}, # yes, 2 times
		'params'	=> $self->{'data'}->{'certificationRequestInfo'}{'subjectPKInfo'}{'algorithm'}{'parameters'},
		'length'	=> $self->{'data'}->{'certificationRequestInfo'}{'subjectPKInfo'}{'subjectPublicKey'}[1],
		'key'		=> $self->{'data'}->{'certificationRequestInfo'}{'subjectPKInfo'}{'subjectPublicKey'}[0],
	};
#	$self->{'signature'}->{'hex'} = uc( unpack('H*',$self->{'signature'}->{'sign'}) );

#	by "for" - more readable
	for my $attr ( @{ $self->{'data'}->{'certificationRequestInfo'}{'attributes'} } ){
		$self->{'attributes'}{ $attr->{'type'} } =
		 Convert::X509::Parser::_decode( $attr->{'type'} , @{$attr->{'values'}} ) 
		;
	}

	$self->{'extensions'}	=
	 Convert::X509::Parser::_decode_ext (
	  $self->{'attributes'}{'1.3.6.1.4.1.311.2.1.14'},
	  $self->{'attributes'}{'1.2.840.113549.1.9.14'}
	);

#	$self->{'extensions'}{'2.5.29.17'} =
#	 Convert::X509::Parser::_decode_rdn($self->{'extensions'}{'2.5.29.17'}{'value'});

	delete $self->{'data'};
	return (bless $self, $class);
}

1;
