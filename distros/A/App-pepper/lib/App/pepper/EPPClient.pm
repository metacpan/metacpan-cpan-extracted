package App::pepper::EPPClient;
use base qw(Net::EPP::Simple);
use XML::Parser;
use strict;

sub new {
	my ($package, %params) = @_;

	my $self = $package->SUPER::new(%params);

	$self->{'pretty_parser'} = XML::Parser->new(
		'Style' => 'Stream',
		'Pkg' => 'App::pepper::Highlighter',
	);

	return $self;
}

sub get_frame {
	my $self = shift;
	my $response = $self->SUPER::get_frame;
	$self->{'pretty_parser'}->{'lineprefix'} = 'S: ';
	$self->{'pretty_parser'}->parse($response->toString) if (!$self->{'quiet'} && $response && ($response->isa('XML::LibXML::Document') || $response->isa('Net::EPP::Frame::Response')));
	return $response;
}

sub send_frame {
	my ($self, $frame, $wfcheck) = @_;

	$self->{'pretty_parser'}->{'lineprefix'} = 'C: ';
	$self->{'pretty_parser'}->parse($frame->toString) if (!$self->{'quiet'} && ($frame->isa('XML::LibXML::Document') || $frame->isa('Net::EPP::Frame')));

	return $self->SUPER::send_frame($frame, $wfcheck);
}

1;
