package AnyEvent::RPC::Enc::YAML;

use common::sense 2;
m{
	use strict;
	use warnings;
}; # Until cpants will know it make strict
use parent 'AnyEvent::RPC::Enc';
use Carp;
require AnyEvent::RPC; our $VERSION = $AnyEvent::RPC::VERSION;

=head1 NAME

AnyEvent::RPC::Enc::YAML - YAML Encoder for AE::RPC

=head1 DESCRIPTION

Uses YAML::Syck in unicode mode for encoding requests end decode response

=head1 SYNOPSIS

    use AnyEvent::RPC;
    
    my $rpc = AnyEvent::RPC->new(
        ...
        type => 'YAML', # or type => '+AnyEvent::RPC::Enc::YAML',
    )

=cut

BEGIN {
	if (eval {require YAML::Syck; 1}) {
		$YAML::Syck::ImplicitUnicode = 1;
		*Dump = \&YAML::Syck::Dump;
		*Load = \&YAML::Syck::Load;
	} else {
		croak "Cant load YAML::Syck. Install one to use YAML encoder";
	}
}


sub request {
	my $self = shift;
	my $rpc = shift;
	my %args = @_;
	$args{data} = Dump( $args{data} ) if $args{data} and ref $args{data};
	$args{headers}{'Content-Type'} = 'text/x-yaml';
	$self->next::method($rpc,%args);
}

sub decode_response {
	my $self = shift;
	my $res = shift;
	my $data = $res->decoded_content( charset => 'none' );
	if ( my $doc = eval { Load( $data ) } ) {
		return $doc;
	} else {
		die "$@";
	}
}

1;
