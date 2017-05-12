package Business::OnlinePayment::PaperlessTrans;
use 5.008;
use strict;
use warnings;

our $VERSION = '0.001006'; # VERSION

use parent 'Business::OnlinePayment';

use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use Module::Load   qw( load         );
use File::ShareDir qw( dist_file    );
use Carp           qw( carp confess );

my $dist = 'Business-OnlinePayment-PaperlessTrans';
my $ns   = 'Business::PaperlessTrans::';

sub submit { ## no critic ( ProhibitExcessComplexity )
	my ( $self ) = @_;

	$self->required_fields(qw( amount currency login password ));

	my %content = $self->content;
	my $action  = lc $content{action};
	my $trans_t = lc $self->transaction_type;
	my $token   = $self->_content_to_token( %content );
	my $ident   = $self->_content_to_ident( %content );
	my $address = $self->_content_to_address( %content );

	$self->{debug} = $content{debug} ? $content{debug} : 0;

	my %args = (
		Amount       => $content{amount},
		Currency     => $content{currency},
		Token        => $token,
		TestMode     => $self->test_transaction ? 'true' : 'false',
		CustomFields => {},
	);

	my %payment_content = (
		%content,
		identification => $ident,
		address        => $address,
	);

	if ( $trans_t eq 'cc' ) {
		$args{CardPresent} = $content{track1} ? 1 : 0;
	    $args{Card} = $self->_content_to_card( %payment_content );
	}
	elsif ( $trans_t eq 'echeck' ) {
		$args{CheckNumber} = $content{check_number};
		$args{Check} = $self->_content_to_check( %payment_content );
	}

	## determine appropriate request class
	my $type;
	if ( $action eq 'authorization only' && $trans_t eq 'cc' ){
		$type = 'AuthorizeCard';
	}
	elsif ( $action eq 'normal authorization' && $trans_t eq 'cc' ) {
		$type = 'ProcessCard';
	}
	elsif ( $action eq 'normal authorization' && $trans_t eq 'echeck' ) {
		$type = 'ProcessACH';
	}

	my $response = $self->_transmit( \%args, $type );

	# code != 0 is a transmission error
	if ( $response->{ResponseCode} == 0 ) {
		# in future should consider making thse the same api?
		if ( _bool( $response->{IsApproved} )
			|| _bool( $response->{IsAccepted} )
			) {
			$self->is_success(1);
		}
		else {
			$self->is_success(0);
			$self->error_message( $response->{Message} );
		}
	}
	else {
		confess $response->{Message};
	}

	$self->authorization( $response->{Authorization} );

	$self->order_number( $response->{TransactionID} );

	return;
}

sub _bool {
	my $val = shift;

	return 1 if defined $val && lc $val eq 'true';
	return 0;
}

sub _transmit {
	my ( $self, $request, $type ) = @_;

	my %request = ( req => $request );

	if ($self->{debug} >= 1 ) {
		load 'Data::Dumper', 'Dumper';
		carp Dumper( \%request );
	}

	my ( $answer, $trace ) = $self->_get_call( $type )->( %request );

	carp "REQUEST >\n"  . $trace->request->as_string  if $self->{debug} > 1;
	carp "RESPONSE <\n" . $trace->response->as_string if $self->{debug} > 1;

	if ( $self->{debug} >= 1 ) {
		carp Dumper( $answer );
	}

	return $answer->{parameters}{$type . 'Result'};
}

sub _get_call {
	my ( $self, $type ) = @_;

	return $self->{calls}{$type} if defined $self->{calls}{$type};

	$self->_build_calls;

	return $self->_get_call( $type );
}

sub _build_calls {
	my $self = shift;

	my @calls = qw( AuthorizeCard ProcessCard ProcessACH );

	my %calls;
	foreach my $call ( @calls ) {
		$calls{$call} = $self->_wsdl->compileClient( $call );
	}
	$self->{calls} = \%calls;

	return;
}

sub _wsdl {
	my $self = shift;

	my $wsdl
		= XML::Compile::WSDL11->new(
			dist_file( $dist, 'svc.paperlesstrans.wsdl')
		);

	foreach my $xsd ( $self->_list_xsd_files ) {
		$wsdl->importDefinitions( $xsd );
	}

	return $wsdl;
}

sub _list_xsd_files {
	my @xsd;
	foreach my $i ( 0..6 ) {
		push @xsd, dist_file( $dist, "svc.paperlesstrans.$i.xsd");
	}
	return @xsd;
}

sub _content_to_ident {
	my ( $self, %content ) = @_;

	return unless $content{license_num};

	my %mapped = (
		IDType => 1, # B:OP 3.02 there is only drivers license
		Number => $content{license_num},
	);

	return \%mapped;
}

sub _content_to_token {
	my ( $self, %content ) = @_;

	my %mapped = (
		TerminalID  => $content{login},
		TerminalKey => $content{password},
	);

	return \%mapped;
}

sub _content_to_address {
	my ( $self, %content ) = @_;

	my %mapped = (
		Street  => $content{address},
		City    => $content{city},
		State   => $content{state},
		Zip     => $content{zip},
		Country => $content{country},
	);

	return \%mapped;
}

sub _content_to_check {
	my ( $self, %content ) = @_;

	$self->required_fields(qw( routing_code account_number account_name ));

	my %mapped = (
		NameOnAccount  => $content{account_name},
		AccountNumber  => $content{account_number},
		RoutingNumber  => $content{routing_code},
		Identification => $content{identification} || {},
		Address        => $content{address},
		EmailAddress   => $content{email},
	);

	return \%mapped;
}

sub _content_to_card {
	my ( $self, %content ) = @_;

	$self->required_fields(qw( expiration name card_number ));
	# expiration api is bad but conforms to Business::OnlinePayment 3.02 Spec
	$content{expiration} =~ m/^(\d\d)(\d\d)$/xms;
	my ( $exp_month, $exp_year ) = ( $1, $2 ); ## no critic ( ProhibitCaptureWithoutTest )

	my %mapped = (
		NameOnAccount   => $content{name},
		CardNumber      => $content{card_number},
		SecurityCode    => $content{cvv2},
		Identification  => $content{identification} || {},
		Address         => $content{address},
		EmailAddress    => $content{email},
		ExpirationMonth => $exp_month,
		ExpirationYear  => '20' . $exp_year,
	);

	$mapped{TrackData} = $content{track1} . $content{track2}
		if $content{track1} && $content{track2};

	return \%mapped;
}

1;

# ABSTRACT: Interface to Paperless Transaction Corporation BackOffice API

__END__

=pod

=head1 NAME

Business::OnlinePayment::PaperlessTrans - Interface to Paperless Transaction Corporation BackOffice API

=head1 VERSION

version 0.001006

=head1 SYNOPSIS

	use Try::Tiny;
	use Business::OnlinePayment;

	my $tx = Business::OnlinePayment->new('PaperlessTrans');

	$tx->test_transaction(1);

	$tx->content(
		login          => 'TerminalID',
		password       => 'TerminalKey',
		debug          => '1', # 0, 1, 2
		type           => 'ECHECK',
		action         => 'Normal Authorization',
		check_number   => '132',
		amount         => 1.32,
		currency       => 'USD',
		routing_code   => 111111118,
		account_name   => 'Caleb Cushing',,
		account_number => 12121214,
		name           => 'Caleb Cushing',
		address        => '400 E. Royal Lane #201',
		city           => 'Irving',
		state          => 'TX',
		zip            => '75039-2291',
		country        => 'US',
	);

	try {
		$tx->submit;
	}
	catch {
		# log errors
	};

	if ( $tx->is_success ) {
		# do stuff with
		$tx->order_number;
		$tx->authorization;
	}
	else {
		# log
		$tx->error_message;
	}

	# start all over again credit cards
	$tx->content(
		login       => 'TerminalID',
		password    => 'TerminalKey',
		debug       => '1', # 0, 1, 2
		type        => 'CC',
		action      => 'Authorization Only',
		amount      => 1.00,
		currency    => 'USD',
		name        => 'Caleb Cushing',
		card_number => '5454545454545454',
		expiration  => '1215',
		cvv2        => '111',
	);

	## ...

=head1 SEE ALSO

=over

=item L<BackOffice API|http://support.paperlesstrans.com/api-overview.php>

=item L<Business::OnlinePayment>

=item L<Business::PaperlessTrans>

=back

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
