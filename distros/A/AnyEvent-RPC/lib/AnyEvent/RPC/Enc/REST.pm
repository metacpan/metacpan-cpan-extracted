package AnyEvent::RPC::Enc::REST;

use common::sense 2;
m{
	use strict;
	use warnings;
}; # Until cpants will know it make strict
use parent 'AnyEvent::RPC::Enc';
use Carp;

require AnyEvent::RPC; our $VERSION = $AnyEvent::RPC::VERSION;

=head1 NAME

AnyEvent::RPC::Enc::REST - XML Encoder for AE::RPC

=head1 DESCRIPTION

Uses XML <-> HASH structures like provided by L<XML::Hash::LX>

=head1 SYNOPSIS

    use AnyEvent::RPC;
    
    my $rpc = AnyEvent::RPC->new(
        ...
        type => 'REST', # or type => '+AnyEvent::RPC::Enc::REST',
    )

=cut


BEGIN {
	#if (eval { require XML::Fast; 1; } ) {
	#	*xml2hash = \&XML::Fast::xml2hash;
	#	*hash2xml = \&XML::Fast::hash2xml;
	#}
	if(eval { require XML::Hash::LX; 1; }) {
		*xml2hash = \&XML::Hash::LX::xml2hash;
		*hash2xml = \&XML::Hash::LX::hash2xml;
	}
	else {
		#croak "Cant load either XML::Fast or XML::Hash::LX for XML processing. Install one, or create your own encoder";
		croak "Cant load XML::Hash::LX for XML processing. Install one, or create your own encoder";
	}
}


our %H2X = (
	arrs   => 0,
	attr   => '-',
#	text   => '~',
	join   => '',
	trim   => 1,
	cdata  => undef,
	comm   => undef,
);

sub request {
	my $self = shift;
	my $rpc = shift;
	my %args = @_;
	$args{data} = hash2xml( $args{data}, %H2X ) if $args{data} and ref $args{data};
	$args{headers}{'Content-Type'} = 'text/xml';
	$self->next::method($rpc,%args);
}

sub decode_response {
	my $self = shift;
	my $res = shift;
	my $data = $res->decoded_content( charset => 'none' );
	if ( my $doc = eval { xml2hash($data, %H2X) } ) {
		return $doc;
	} else {
		die "$@";
	}
}

1;
