package Business::WebMoney;

use 5.008000;
use strict;
use warnings;
use utf8;

our $VERSION = '0.11';

use Carp;
use LWP::UserAgent;
use XML::LibXML;
use HTTP::Request;
use File::Spec;
use POSIX();

sub new
{
	my ($class, @args) = @_;

	my $opt = parse_args(\@args, {
		p12_file => 'mandatory',
		p12_pass => undef,
		timeout => 20,
		ca_file => undef,
	});

	my $ca_file = $opt->{ca_file};
	$ca_file or ($ca_file) = grep(-r $_, map(File::Spec->catdir($_, qw(Business WebMoney WebMoneyCA.crt)), @INC));
	$ca_file or warn "Business/WebMoney/WebMoneyCA.crt missing";

	my $self = {
		p12_file => $opt->{p12_file},
		p12_pass => $opt->{p12_pass},
		timeout => $opt->{timeout},
		ca_file => $ca_file,
	};

	return bless $self, $class;
}

sub parse_args
{
	my ($args_list, $fields) = @_;

	if (@$args_list % 2) {

		croak 'Unpaired arguments';
	}

	my %args;

	while (@$args_list) {

		my $key = shift @$args_list;
		my $value = shift @$args_list;

		exists($fields->{$key}) or croak "Unknown argument $key";
		exists($args{$key}) and croak "Argument $key specified multiple times";

		$args{$key} = $value;
	}

	while (my ($key, $value) = each(%$fields)) {

		unless (exists($args{$key})) {

			if ($value && $value eq 'mandatory') {

				croak "Mandatory argument $key not specified";

			} else {

				$args{$key} = $value;
			}
		}
	}

	return \%args;
}

sub request
{
	my ($self, %args) = @_;

	my $old_locale = POSIX::setlocale(&POSIX::LC_ALL, 'C');

	my $res = $self->do_request(%args);

	POSIX::setlocale(&POSIX::LC_ALL, $old_locale);

	return $res;
}

sub do_request
{
	my ($self, %args) = @_;

	$self->{errstr} = undef;
	$self->{errcode} = undef;

	my $req_fields = parse_args($args{args}, { %{$args{arg_rules}}, debug_response => undef });

	my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');

	my $request = $doc->createElement('w3s.request');
	$doc->setDocumentElement($request);

	my $node = $doc->createElement('reqn');
	$request->appendChild($node);
	$node->appendChild($doc->createTextNode($req_fields->{reqn}));
	delete $req_fields->{reqn};

	my $data_node = $doc->createElement($args{req_tagname});
	$request->appendChild($data_node);

	while (my ($key, $value) = each %$req_fields) {

		next unless defined $value;
		next if $key eq 'debug_response';

		my $node = $doc->createElement($key);
		$data_node->appendChild($node);
		$node->appendChild($doc->createTextNode($value));
	}

	my $res = eval {

		local $SIG{__DIE__};
       
		# Warning! Thread unsafe!

		local %ENV = %ENV;

		$ENV{HTTPS_PKCS12_FILE} = $self->{p12_file};
		$ENV{HTTPS_PKCS12_PASSWORD} = $self->{p12_pass};
		$ENV{HTTPS_CA_FILE} = $self->{ca_file};

		my $req_data = $doc->serialize;

		utf8::encode($req_data) if utf8::is_utf8($req_data);

		my $res_content;

		unless ($res_content = $req_fields->{debug_response}) {

			my $ua = LWP::UserAgent->new;
			$ua->timeout($self->{timeout} + 1);

			my $req = HTTP::Request->new;
			$req->method('POST');
			$req->uri("https://w3s.wmtransfer.com/asp/XML$args{func}Cert.asp");
			$req->content($req_data);

			my ($res, $timeout);

			eval {
				local $SIG{__DIE__};
				local $SIG{ALRM} = sub {
					$timeout = 1;
				};

				alarm($self->{timeout});
				$res = $ua->request($req);
				alarm(0);
			};

			if ($timeout) {

				$self->{errcode} = -1001;
				$self->{errstr} = 'Connection timeout';
				return undef;

			} elsif (!$res->is_success) {

				$self->{errcode} = $res->code;
				$self->{errstr} = $res->message;
				return undef;
			}

			$res_content = $res->content;
		}

		my $parser = XML::LibXML->new;

		my $doc = $parser->parse_string($res_content);

		if (my $retval = $doc->findvalue('/w3s.response/retval')) {

			$self->{errcode} = $retval;
			$self->{errstr} = $doc->findvalue('/w3s.response/retdesc');
			return undef;
		}

		my ($result_node) = $doc->getElementsByTagName($args{result_tag});

		if ($args{result_format} eq 'list') {

			[ map { result_node($_) } grep { $_->isa('XML::LibXML::Element') } $result_node->childNodes ];

		} elsif ($args{result_format} eq 'hash') {

			result_node($result_node);

		} else {

			1;
		}
	};

	if ($@) {

		$self->{errcode} = -1000;
		$self->{errstr} = $@;
		return undef;
	}

	return $res;
}

sub errcode
{
	my ($self) = @_;

	return $self->{errcode};
}

sub errstr
{
	my ($self) = @_;

	return $self->{errstr};
}

sub result_node
{
	my ($node) = @_;

	my %result;

	for my $attr ($node->attributes) {

		my $key = $attr->name;

		$result{$key} = $attr->value;
	}

	for my $child (grep { $_->isa('XML::LibXML::Element') } $node->childNodes) {

		my $key = $child->nodeName;

		$result{$key} = $child->textContent;
	}

	return \%result;
}

sub get_operations
{
	my ($self, @args) = @_;

	return $self->request(
		func => 'Operations',
		args => \@args,
		arg_rules => {
			reqn => 'mandatory',
			purse => 'mandatory',
			wmtranid => undef,
			tranid => undef,
			wminvid => undef,
			orderid => undef,
			datestart => 'mandatory',
			datefinish => 'mandatory',
		},
		req_tagname => 'getoperations',
		result_format => 'list',
		result_tag => 'operations',
	);
}

sub invoice
{
	my ($self, @args) = @_;

	return $self->request(
		func => 'Invoice',
		args => \@args,
		arg_rules => {
			reqn => 'mandatory',
			orderid => 'mandatory',
			customerwmid => 'mandatory',
			storepurse => 'mandatory',
			amount => 'mandatory',
			desc => 'mandatory',
			address => '',
			period => '0',
			expiration => '0',
		},
		req_tagname => 'invoice',
		result_format => 'hash',
		result_tag => 'invoice',
	);
}

sub get_out_invoices
{
	my ($self, @args) = @_;

	return $self->request(
		func => 'OutInvoices',
		args => \@args,
		arg_rules => {
			reqn => 'mandatory',
			purse => 'mandatory',
			wminvid => undef,
			orderid => undef,
			datestart => 'mandatory',
			datefinish => 'mandatory',
		},
		req_tagname => 'getoutinvoices',
		result_format => 'list',
		result_tag => 'outinvoices',
	);
}

sub get_in_invoices
{
	my ($self, @args) = @_;

	return $self->request(
		func => 'InInvoices',
		args => \@args,
		arg_rules => {
			reqn => 'mandatory',
			wmid => 'mandatory',
			wminvid => undef,
			datestart => 'mandatory',
			datefinish => 'mandatory',
		},
		req_tagname => 'getininvoices',
		result_format => 'list',
		result_tag => 'ininvoices',
	);
}

sub reject_protect
{
	my ($self, @args) = @_;

	return $self->request(
		func => 'RejectProtect',
		args => \@args,
		arg_rules => {
			reqn => 'mandatory',
			wmtranid => 'mandatory',
		},
		req_tagname => 'rejectprotect',
		result_format => 'hash',
		result_tag => 'operation',
	);
}

sub finish_protect
{
	my ($self, @args) = @_;

	return $self->request(
		func => 'FinishProtect',
		args => \@args,
		arg_rules => {
			reqn => 'mandatory',
			wmtranid => 'mandatory',
			pcode => 'mandatory',
		},
		req_tagname => 'finishprotect',
		result_format => 'hash',
		result_tag => 'operation',
	);
}

sub message
{
	my ($self, @args) = @_;

	return $self->request(
		func => 'SendMsg',
		args => \@args,
		arg_rules => {
			reqn => 'mandatory',
			receiverwmid => 'mandatory',
			msgsubj => 'mandatory',
			msgtext => 'mandatory',
		},
		req_tagname => 'message',
		result_format => 'hash',
		result_tag => 'message',
	);
}

sub get_balance
{
	my ($self, @args) = @_;

	return $self->request(
		func => 'Purses',
		args => \@args,
		arg_rules => {
			reqn => 'mandatory',
			wmid => 'mandatory',
		},
		req_tagname => 'getpurses',
		result_format => 'list',
		result_tag => 'purses',
	);
}

sub money_back
{
	my ($self, @args) = @_;

	return $self->request(
		func => 'TransMoneyback',
		args => \@args,
		arg_rules => {
			reqn => 'mandatory',
			inwmtranid => 'mandatory',
			amount => 'mandatory',
		},
		req_tagname => 'trans',
		result_format => 'hash',
		result_tag => 'operation',
	);
}

sub transfer
{
	my ($self, @args) = @_;

	return $self->request(
		func => 'Trans',
	       	args => \@args,
		arg_rules => {
			reqn => 'mandatory',
			tranid => 'mandatory',
			pursesrc => 'mandatory',
			pursedest => 'mandatory',
			amount => 'mandatory',
			period => 0,
			pcode => undef,
			desc => 'mandatory',
			wminvid => 0,
		},
		req_tagname => 'trans',
		result_format => 'hash',
		result_tag => 'operation',
	);
}

1;

__END__

=head1 NAME

Business::WebMoney - Perl API to WebMoney

=head1 SYNOPSIS

  use Business::WebMoney;

  my $wm = Business::WebMoney->new(
    p12_file => '/path/to/key.p12',
    p12_pass => 'secret',
  );

  my $inv = $wm->invoice(
    reqn => 10,
    orderid => 1,
    customerwmid => '000000000000',
    storepurse => 'Z000000000000',
    amount => 100,
    desc => 'Camel',
    address => 'Delivery address',
    expiration => 3,
  ) or die $wm->errstr;

  my $invs = $wm->get_out_invoices(
    reqn => 11,
    purse => 'Z000000000000',
    datestart => '20080101 00:00:00',
    datefinish => '20090101 00:00:00',
  ) or die $wm->errstr;

  my $ops = $wm->get_operations(
    reqn => 12,
    purse => 'Z000000000000',
    datestart => '20080101 00:00:00',
    datefinish => '20090101 00:00:00',
  ) or die $wm->errstr;

  $wm->reject_protect(
    reqn => 13,
    wmtranid => '123123123',
  ) or die $wm->errstr;

  $wm->finish_protect(
    reqn => 14,
    wmtranid => '123123123',
    pcode => 'secret',
  ) or die $wm->errstr;

  my $invs = $wm->get_in_invoices(
    reqn => 15,
    wmid => '000000000000',
    datestart => '20080101 00:00:00',
    datefinish => '20090101 00:00:00',
  ) or die $wm->errstr;

  my $purses = $wm->get_balance(
    reqn => 16,
    wmid => '000000000000',
  ) or die $wm->errstr;

  $wm->transfer(
    reqn => 17,
    tranid => 2,
    pursesrc => 'Z000000000000',
    pursedest => 'Z000000000000',
    amount => 100,
    desc => 'Camel',
  ) or die $wm->errstr;

  $wm->message(
    reqn => 18,
    receiverwmid => '000000000000',
    msgsubj => 'Foo',
    msgtext => 'Bar',
  ) or die $wm->errstr;

  $wm->money_back(
    reqn => 19,
    inwmtranid => '123123123',
    amount => 100,
  ) or die $wm->errstr;

=head1 DESCRIPTION

Business::WebMoney provides simple API to the WebMoney transfer system. It
requires the SSL private key and certificate from your WM Keeper Light
account (PKCS12 file). WM Keeper Classic keys are not supported yet.

The main features of the library are:

=over 4

=item * Create outgoing invoice (X1)

=item * Transfer money (X2)

=item * Get the list of operations (X3)

=item * Check invoice status (X4)

=item * Enter protection code (X5)

=item * Send a message via WM mail (X6)

=item * Check purses balance (X9)

=item * Get incoming invoices list (X10)

=item * Reject protected payment (X13)

=item * Return money without commission (X14)

=back

=head1 INTERFACE

Every function in the library corresponds to the single WebMoney interface.
Function arguments are translated to corresponding request fields.

An example:

  $wm->get_operations(
    reqn => 1,
    purse => 'R000000000000',
    datestart => '20081001 00:00:00',
    datefinish => '20090101 00:00:00',
  );

This call is translated to the XML request:

  <w3s.request>
    <reqn>1</reqn>
    <getoperations>
      <purse>R000000000000</purse>
      <datestart>20081001 00:00:00</datestart>
      <datefinish>20090101 00:00:00</datefinish>
    </getoperations>
  </w3s.request>

Interfaces returning single XML element correspond to functions returning
reference to hash. Interfaces returning list of XML elements correspond to
functions returning reference to array of hashes. Attributes and subelements
of XML response are translated into hash fields.

An example:

  <?xml version="1.0"?>
  <w3s.response>
    <reqn>1</reqn>
    <operations cnt="8" cntA="8">
      <operation id="150977211" ts="150977211">
	<pursesrc>R000000000000</pursesrc>
	<pursedest>R000000000000</pursedest>
	<amount>18000.00</amount>
	<comiss>0.00</comiss>
	<opertype>0</opertype>
	<wminvid>0</wminvid>
	<orderid>0</orderid>
	<tranid>0</tranid>
	<period>0</period>
	<desc>Camel</desc>
	<datecrt>20081103 08:26:20</datecrt>
	<dateupd>20081103 08:26:20</dateupd>
	<corrwm>000000000000</corrwm>
	<rest>18000.00</rest>
      </operation>
      <operation id="150977212" ts="150977212">
        <pursesrc>R000000000000</pursesrc>
        <pursedest>R000000000000</pursedest>
        <amount>18000.00</amount>
        <comiss>0.00</comiss>
        <opertype>0</opertype>
        <wminvid>0</wminvid>
        <orderid>0</orderid>
        <tranid>0</tranid>
        <period>0</period>
        <desc>Camel 2</desc>
        <datecrt>20081103 08:26:25</datecrt>
        <dateupd>20081103 08:26:25</dateupd>
        <corrwm>000000000000</corrwm>
        <rest>36000.00</rest>
      </operation>
    </operations>
  </w3s.response>

This is a response to Operations request. Method C<get_operations> will convert it to the following structure:

  [                                       
    {
      'id' => '150977211',
      'ts' => '150977211',
      'pursesrc' => 'R000000000000',
      'pursedest' => 'R000000000000',
      'amount' => '18000.00',
      'comiss' => '0.00',
      'opertype' => '0',
      'wminvid' => '0'
      'orderid' => '0',
      'tranid' => '0',
      'period' => '0',
      'desc' => 'Camel',
      'datecrt' => '20081103 08:26:20',
      'dateupd' => '20081103 08:26:20',
      'corrwm' => '000000000000',
      'rest' => '18000.00',
    },
    {
      'id' => '150977212',
      'ts' => '150977212',
      'pursesrc' => 'R000000000000',
      'pursedest' => 'R000000000000',
      'amount' => '18000.00',
      'comiss' => '0.00',
      'opertype' => '0',
      'wminvid' => '0'
      'orderid' => '0',
      'tranid' => '0',
      'period' => '0',
      'desc' => 'Camel 2',
      'datecrt' => '20081103 08:26:25',
      'dateupd' => '20081103 08:26:25',
      'corrwm' => '000000000000',
      'rest' => '36000.00',
    }
  ];

Every request has a C<reqn> - request number. It must be greater than the previous money transfer reqn.

All dates are specified in C<YYYYMMDD HH:MM:SS> format.

On failure functions return C<undef>. Error code and description are available via C<< $wm->errcode >> and C<< $wm->errstr >> accordingly.

=head1 METHODS

=head2 Constructor

  my $wm = Business::WebMoney->new(
    p12_file => '/path/to/key.p12',	# Path to PKCS12 WebMoney file (mandatory)
    p12_pass => 'secret',		# Encryption password for p12_file (mandatory if encrypted)
    ca_file => '/path/to/CA.crt',	# WebMoney certification authority file (optional)
    timeout => 30,			# Request timeout in seconds (optional, default 20)
  );

=head2 get_operations - history of transactions for the given purse (Interface X3)

  my $ops = $wm->get_operations(
    reqn => 1,
    purse => 'Z000000000000',		# Purse to query (mandatory)
    datestart => '20080101 00:00:00',	# Interval beginning (mandatory)
    datefinish => '20080201 00:00:00',	# Interval end (mandatory)
    wmtranid => 123123123,		# Transaction ID (in the WebMoney system, optional)
    tranid => 123,			# Transaction ID (in your system, optional)
    wminvid => 345345345,		# Invoice ID (in the WebMoney system, optional)
    orderid => 345,			# Order ID (invoice in your system, optional)
  );

On error returns C<undef>. On success returns reference to array of transactions. Each transaction is a hash:

=over 4

=item * C<id> - a unique number of an transaction in the WebMoney system 

=item * C<ts> - a service number of an transaction in the WebMoney system 

=item * C<tranid> - Transfer number set by the sender; an integer; it should be unique for each trasaction (the same tranid should not be used for two transactions)

=item * C<pursesrc> - Sender's purse number

=item * C<pursedest> - Recipient's purse number

=item * C<amount> - money amount

=item * C<comiss> - Fee charged

=item * C<opertype> - 0 - simple (completed), 4 - protected (not completed), 12 - protected (refunded)

=item * C<period> - Protection period in days (0 means no protection)

=item * C<wminvid> - Invoice number (in the WebMoney system) of the transaction (0 means without invoice)

=item * C<orderid> - Serial invoice number set by the store (0 means without invoice)

=item * C<desc> - Description of product or service

=item * C<datecrt> - Date and time of transaction

=item * C<dateupd> - Date and time of transaction status change

=item * C<corrwm> - Correspondent WMID

=item * C<rest> - Rest after transaction

=back

=head2 invoice - create outgoing invoice (Interface X1)

  my $inv = $wm->invoice(
    reqn => 1,
    orderid => 1,			# Invoice serial number. Should be set by the store. An integer (mandatory)
    customerwmid => '000000000000',	# Customer's WMID (mandatory)
    storepurse => 'Z000000000000',	# Number of the purse where funds will be sent to (mandatory)
    amount => 100,			# Amount that the customer has to pay (mandatory)
    desc => 'Camel',			# Description of product or service (max 255 characters; without spaces in the beginning and in the end, mandatory)
    address => 'Delivery address',	# Delivery address (max 255 characters; without spaces in the beginning and in the end, optional)
    period => 3,			# Maximum period of protection in days (An integer in the range: 0 - 255; zero means that no protection should be used, optional)
    expiration => 3,			# Maximum valid period in days (An integer in the range: 0 - 255; zero means that the valid period is not defined, optional)
  );

On error returns C<undef>. On success returns reference to confirmation hash.

=head2 get_out_invoices - check invoices status (Interface X4)

  my $invs = $wm->get_out_invoices(
    reqn => 11,
    purse => 'Z000000000000',		# Number of the purse where the invoice should be paid to (mandatory)
    datestart => '20080101 00:00:00',	# Minimum time and date of invoice creation (mandatory)
    datefinish => '20090101 00:00:00',	# Maximum time and date of invoice creation (mandatory)
    wminvid => 123123123,		# Invoice number (in the WebMoney system, optional)
    orderid => 123,			# Serial invoice number set by the store (optional)
  ) or die $wm->errstr;

On error returns C<undef>. On success returns reference to array of invoices. Each invoice is a hash:

=over 4

=item * C<id> - a unique number of a invoice in the WebMoney system 

=item * C<ts> - a service number of a invoice in the WebMoney system 

=item * C<orderid> - Invoice number set by the sender

=item * C<customerwmid> - Customer's WMID

=item * C<storepurse> - Number of the purse where funds will be sent to

=item * C<amount> - Amount that the customer is to pay

=item * C<desc> - Description of product or service

=item * C<address> - Delivery address

=item * C<period> - Maximum period of protection in days

=item * C<expiration> - Maximum valid period in days

=item * C<state> - 0 - unpaid, 1 - paid with protection, 2 - paid, 3 - rejected

=item * C<datecrt> - Date and time of the invoice creation

=item * C<dateupd> - Date and time of the invoice status change

=item * C<wmtranid> - Transaction number in the WebMoney system, if the invoice was paid

=item * C<customerpurse> - Payer purse, if the invoice was paid

=back

=head2 transfer - transfer money (Interface X2)

  $wm->transfer(
    reqn => 1,
    tranid => 2,			# Transaction number set by the sender; an integer; it should be unique for each trasaction (the same tranid should not be used for two transactions, mandatory)
    pursesrc => 'Z000000000000',	# Sender's purse number (mandatory)
    pursedest => 'Z000000000000',	# Recipient's purse number (mandatory)
    amount => 100,			# Amount. A floating-point number, for example, 10.5; 9; 7.36 (mandatory)
    period => 3,			# Protection period in days (An integer in the range: 0 - 255; zero means that no protection should be used, optional)
    pcode => 'secret',			# Protection code (In the range 0 - 255 characters; without spaces in the beginning and in the end, optional)
    desc => 'Camel',			# Description of product or service (In the range 0 - 255 characters; without spaces in the beginning and in the end, mandatory)
    wminvid => 123123123,		# Invoice number (in the WebMoney system). 0 means that transfer is made without invoice (optional)
  ) or die $wm->errstr;

On error returns C<undef>. On success returns reference to confirmation hash:

=over 4

=item * C<id> - a unique number of a transaction in the WebMoney System

=item * C<ts> - a service number of a transaction in the WebMoney System 

=item * C<tranid> - Serial transaction number set by the sender; an integer; it should be unique for each trasaction (the same tranid should not be used for two transactions)

=item * C<pursesrc> - Sender's purse number

=item * C<pursedesc> - Recipient's purse number

=item * C<amount> - Amount

=item * C<comiss> - Fee charged

=item * C<opertype> - Transfer type: 0 - simple (completed), 4 - protected (incomplete)

=item * C<period> - Protection period in days

=item * C<wminvid> - Invoice number (in the WebMoney system). 0 means that transfer is made without invoice

=item * C<orderid> - Serial invoice number set by the store. 0 means that transfer is made without invoice

=item * C<desc> - Description of product or service

=item * C<datecrt> - Date and time of transaction

=item * C<dateupd> - Date and time of transaction status change

=back

=head2 finish_protect - complete code-protected transaction (Interface X5)

  $wm->finish_protect(
    reqn => 14,
    wmtranid => '123123123',		# Transfer number in the WebMoney system (mandatory)
    pcode => 'secret',			# Protection code. In the range 0 - 255 characters; without spaces in the beginning and in the end (mandatory)
  ) or die $wm->errstr;

On error returns C<undef>. On success returns reference to confirmation hash:

=over 4

=item * C<id> - a unique number of transfer in the WebMoney system

=item * C<td> - a service number of transfer in the WebMoney system 

=item * C<opertype> - 0 - simple (completed), 12 - protected (funds were refunded)

=item * C<dateupd> - Date and time of transaction status change

=back

=head2 reject_protect - reject code-protected transaction (Interface X13)

  $wm->reject_protect(
    reqn => 13,
    wmtranid => '123123123',		# Transfer number in the WebMoney system (mandatory)
  ) or die $wm->errstr;

On error returns C<undef>. On success returns reference to confirmation hash:

=over 4

=item * C<id> - a unique number of transfer in the WebMoney system

=item * C<td> - a service number of transfer in the WebMoney system 

=item * C<opertype> - 0 - simple (completed), 4 - protected (incomplete),  12 - protected (funds were refunded)

=item * C<dateupd> - Date and time of transaction status change

=back

=head2 message - send message to arbitrary WMID (Interface X6)

  $wm->message(
    reqn => 18,
    receiverwmid => '000000000000',	# Recipient's WMID, 12 digits (mandatory)
    msgsubj => 'Foo',			# Subject, 0 - 255 characters without spaces in the beginning and in the end (mandatory)
    msgtext => 'Bar',			# Message body, 0 - 1024 characters without spaces in the beginning and in the end (mandatory)
  ) or die $wm->errstr;

On error returns C<undef>. On success returns reference to confirmation hash.

=head2 balance - check purses balance (Interface X9)

  my $purses = $wm->get_balance(
    reqn => 16,
    wmid => '000000000000',		# WMID, 12 digits (mandatory)
  ) or die $wm->errstr;

On error returns C<undef>. On success returns reference to array of purses. Each purse is a hash:

=over 4

=item * C<id> - a unique internal number of the purse

=item * C<pursename> - Purse number, A letter prefix + 12 digits

=item * C<amount> - Purse balance

=back

=head2 get_in_invoices - get incoming invoices list (Interface X10)

  my $invs = $wm->get_in_invoices(
    reqn => 15,
    wmid => '000000000000',		# WMID (mandatory)
    wminvid => 456456456,		# Invoice number (in the WebMoney system), An integer >= 0 (optional)
    datestart => '20080101 00:00:00',	# Minimum time and date of invoice creation (mandatory)
    datefinish => '20090101 00:00:00',	# Maximum time and date of invoice creation (mandatory)
  ) or die $wm->errstr;

On error returns C<undef>. On success returns reference to array of invoices. Each invoice is a hash:

=over 4

=item * C<id> - a unique number of a invoice in the WebMoney system

=item * C<ts> - a service number of a invoice in the WebMoney system

=item * C<orderid> - Invoice number set by the sender

=item * C<storewmid> - Seller's WMID

=item * C<storepurse> - Number of the purse where funds will be sent to

=item * C<amount> - Amount that the customer is to pay

=item * C<desc> - Description of product or service

=item * C<address> - Delivery address

=item * C<period> - Maximum period of protection in days

=item * C<expiration> - Maximum valid period in days

=item * C<state> - 0 - unpaid, 1 - paid with protection, 2 - paid, 3 - rejected

=item * C<datecrt> - Date and time of the invoice creation

=item * C<dateupd> - Date and time of the invoice status change

=item * C<wmtranid> - Transaction number in the WebMoney system, if the invoice was paid

=back

=head2 money_back - return money without commission (Interface X14)

  $wm->money_back(
    reqn => 19,
    inwmtranid => '123123123',		# Transaction ID (mandatory)
    amount => 100,			# Amount of transaction (self-check). Must match the transaction being returned (mandatory)
  ) or die $wm->errstr;

On error returns C<undef>. On success returns reference to confirmation hash.

=head1 SECURITY

=over 4

=item *
The module is bundled with WebMoney CA certificate to validate identity of the WebMoney server.

=item *
Be especially careful when using certificate with money transfer permission on the production servers. Stolen certificate can be easily reimported to the browser and used to steal your money.
To prevent such threats register separate WMID and give it permission to access purses of the main WMID in read-only mode. This can be set up using L<https://security.wmtransfer.com/>

=back

=head1 ENVIRONMENT

=over 4

=item * C<HTTPS_PROXY> - proxy support, http://host_or_ip:port

=item * C<HTTPS_PROXY_USERNAME> and C<HTTPS_PROXY_PASSWORD> - proxy basic auth

=back

=head1 BUGS

The module is not thread-safe.

=head1 SEE ALSO

C<WebMoney::WMSigner> - signer module that signs any data using specified WebMoney key file

L<http://www.webmoney.ru/eng/developers/interfaces/xml/index.shtml> - WebMoney API specification

=head1 AUTHOR

Alexander Lourier, E<lt>aml@rulezz.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alexander Lourier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
