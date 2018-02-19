=encoding utf-8

=head1 NAME

Business::cXML::Transmission - cXML transmission

=head1 SYNOPSIS

	use Business::cXML::Transmission;
	$msg = parse Business::cXML::Transmission $incoming_cxml_string;

=head1 DESCRIPTION

Parser and compiler for cXML transmissions.

See: L<http://xml.cxml.org/current/cXMLUsersGuide.pdf>

The creation of these transmissions should normally be left to
L<Business::cXML>, which does some handy initialization for you.  Of main
concern for manual processing is our L</payload()>.

=cut

use 5.014;
use strict;

package Business::cXML::Transmission;

use Business::cXML::Credential;
use Business::cXML::Utils qw(current_datetime cxml_timestamp);
use XML::LibXML;
use Clone qw(clone);
use DateTime;
use HTML::Entities;
use MIME::Base64;
use Sys::Hostname;

use constant {
	CXML_CLASS_MESSAGE  => 1,
	CXML_CLASS_REQUEST  => 2,
	CXML_CLASS_RESPONSE => 3,
};

=head1 METHODS

=over

=item C<B<new>( [I<$input>] )>

Without I<C<$input>>, returns an empty L<Business::cXML::Transmission> ready
to be populated.

With I<C<$input>>, returns a L<Business::cXML::Transmission> if parsing was
possible, or an arrayref with two elements if there was an error.  The first
element is a status code, and the second contains a string with more details,
if available.  Input is expected to be a full XML document string, optionally
encoded in Base64 (i.e. the contents of a C<cxml-base64> form variable).

Possible codes:

=over

=item C<406>

The input XML is invalid

=item C<400>

The input XML is valid, but the cXML structure is incomprehensible

=back

=cut

sub new {
	my ($class, $input) = @_;

	my $now = current_datetime();
	my $self = {
		string      => undef,
		xml_doc     => undef,
		xml_root    => undef,
		_xml_payload => undef,
		_payload     => undef,
		_timestamp   => cxml_timestamp($now),
		epoch       => $now->strftime('%s'),
		hostname    => hostname,
		randint     => int(rand(99999999)),
		pid         => $$,
		test        => 0,
		_lang        => 'en-US',
		_id          => undef,
		_inreplyto   => undef,
		status      => {
			code        => 200,
			text        => 'OK',
			description => '',
		},
		class  => '',
		_type   => '',
		_from   => undef,
		_to     => undef,
		_sender => undef,
	};
	bless $self, $class;

	if ($input) {
		my $doc;
		$input = decode_base64($input) unless ($input =~ /^\s*</);
		eval {
			$self->{xml_doc} = ($doc = XML::LibXML->load_xml(string => $input));
		};
		return [ 400, $@ ] if $@;
		eval {
			$doc->validate();
			$self->{xml_root} = ($doc = $doc->documentElement);
		};
		return [ 406, $@ ] if $@;

		$doc->ferry($self, {
			version          => '__UNIMPLEMENTED',
			payloadID        => '_id',
			# timestamp is implicit
			signatureVersion => '__UNIMPLEMENTED',
			'xml:lang'       => '_lang',
			Header           => {
				From             => [ '_from',   'Business::cXML::Credential' ],
				To               => [ '_to',     'Business::cXML::Credential' ],
				Sender           => [ '_sender', 'Business::cXML::Credential' ],
				Path             => '__UNIMPLEMENTED',
				OriginalDocument => '__UNIMPLEMENTED',
			},
			Request        => [ '__IGNORE', \&_new_payload ],
			Response       => [ '__IGNORE', \&_new_payload ],
			Message        => [ '__IGNORE', \&_new_payload ],
			'ds:Signature' => '__UNIMPLEMENTED',
		});
		$self->_rebuild_payload();
	} else {
		# Create a brand new XML document from scratch.
		my $doc = $self->{xml_doc} = XML::LibXML::Document->new('1.0', 'UTF-8');
		$doc->createInternalSubset('cXML', undef, "http://xml.cxml.org/schemas/cXML/" . $Business::cXML::CXML_VERSION . "/cXML.dtd");
		my $root = $self->{xml_root} = $doc->createElement('cXML');
		$self->{_id} = $self->{epoch} . '.' . $self->{pid} . '.' . $self->{randint} . '@' . $self->{hostname};  # payloadID/inReplyTo
		$root->attr(
			payloadID  => $self->{_id},
			timestamp  => $self->{_timestamp},
			'xml:lang' => $self->{_lang},
		);
		# UNIMPLEMENTED cXML: version? signatureVersion?
		$doc->setDocumentElement($root);

		# Something initially valid which will be replaced by the user
		$self->{_xml_payload} = $doc->createElement('ProfileRequest');
		$self->{class} = CXML_CLASS_REQUEST;
		$self->{_type} = 'Profile';
	};
	$self->{_from}   = Business::cXML::Credential->new('From')   unless defined $self->{_from};
	$self->{_to}     = Business::cXML::Credential->new('To')     unless defined $self->{_to};
	$self->{_sender} = Business::cXML::Credential->new('Sender') unless defined $self->{_sender};

	return $self;
}

sub _new_payload {
	my ($self, $msg) = @_;
	my $status;

	$self->is_test(1) if (exists $msg->{deploymentMode} && $msg->{deploymentMode} eq 'test');
	$self->{_inreplyto} = $msg->{inReplyTo} if exists $msg->{inReplyTo};
	# UNIMPLEMENTED Message/Request/Response: Id?

	foreach ($msg->childNodes) {
		if ($_->nodeName eq 'Status') {
			$status = $_;
		} elsif ($_->nodeType == XML_ELEMENT_NODE) {
			$self->{_xml_payload} = $msg = $_;
		};
	};
	my $className;
	($self->{_type}, $className) = $msg->nodeName =~ /^(.*)(Request|Response|Message)$/;
	$self->{class} = CXML_CLASS_MESSAGE  if $className eq 'Message';
	$self->{class} = CXML_CLASS_REQUEST  if $className eq 'Request';
	$self->{class} = CXML_CLASS_RESPONSE if $className eq 'Response';

	if ($status) {
		$self->status($status->{code}, $status->textContent);
	} else {
		$self->status(200);
	};

	return undef;
}

sub _rebuild_payload {
	my ($self) = @_;

	return if defined $self->{_payload};

	my $class = 'Message';
	$class = 'Request' if $self->is_request;
	$class = 'Response' if $self->is_response;

	$class = 'Business::cXML::' . $class . '::' . $self->type;

	eval {
		my $file = $class;
		$file =~ s|::|/|g;
		require "$file.pm";
		$self->{_payload} = $class->new($self->{_xml_payload});
	};
	# Payload remains safely undef for unknown classes-types.
}

=item C<B<toForm>( I<%arguments> )>

In a scalar context, returns an HTML string representation of the current cXML
data structure, in cXML "URL-Form-Encoding" (a C<form> with a hidden
C<cxml-base64> value).  Returns an empty string if we have an internal error.

To help identify problems, in a list context it returns an error string (or
C<undef>) and the HTML string (probably empty, depending on the type of error).

Possible I<C<%arguments>> keys:

=over

=item C<B<url>>

Mandatory, should be from a C<PunchOutSetupRequest/BrowserFormPost>.

=item C<B<target>>

Optional, the HTML frame target to specify in the FORM

=item C<B<submit_button>>

Optional, override submit button HTML with your own

=back

=cut

sub toForm {
	my ($self, %args) = @_;
	my $url = encode_entities($args{url} || '');
	my $submit = '<input type="submit">';
	$submit = $args{submit_button} if exists $args{submit_button};
	my $target = '';
	$target = ' target="' . encode_entities($args{target}) . '"' if defined $args{target};

	my ($err, $msg) = $self->toString;
	return ($err, '') if defined $err;

	$msg = encode_base64($msg, '');
	return (undef, "<form method=\"post\" action=\"$url\"$target><input type=\"hidden\" name=\"cxml-base64\" value=\"$msg\">$submit</form>");
}

=item C<B<toString>()>

In a scalar context, returns an XML string representation of the current cXML
data structure.

In the event that our XML document were not valid, a hard-coded C<500> status
C<Response> with explanation will be returned instead of the prepared
transmission.

To help identify problems, in a list context it returns an error string (or
C<undef>) and the XML string.

=cut

sub _valid_string {
	my ($self) = @_;
	eval {
		$self->{xml_doc}->validate();
	};
	if ($@) {
		return ($@, qq(<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE cXML SYSTEM "http://xml.cxml.org/schemas/cXML/) . $Business::cXML::CXML_VERSION . qq(/cXML.dtd">\n<cXML timestamp=") . $self->{_timestamp} . qq(" payloadID=") . $self->{_id} .  qq(" xml:lang="en-US"><Response><Status code="500" text="Internal Server Error">) . encode_entities($@) . qq(</Status></Response></cXML>));
	};
	return (undef, $self->{xml_doc}->toString);
}

sub toString {
	my ($self) = @_;

	return (undef, $self->{string}) if defined $self->{string};

	$_->unbindNode() foreach ($self->{xml_root}->childNodes);  # Start from guaranteed empty doc


	unless ($self->is_response) {
		my $header = $self->{xml_root}->add('Header');
		$header->add($self->{_from}->to_node($header));
		$header->add($self->{_to}->to_node($header));
		$self->{_sender}->secret(undef) if $self->is_message;  # No SharedSecret in Message
		$header->add($self->{_sender}->to_node($header));
		# UNIMPLEMENTED: (Path OriginalDocument)?
	};

	my $wrapper;
	my $className;
	$className = 'Message'  if $self->is_message;
	$className = 'Request'  if $self->is_request;
	$className = 'Response' if $self->is_response;
	$wrapper = $self->{xml_root}->add($className);
	$wrapper->attr(deploymentMode => ($self->{test} ? 'test' : 'production')) unless $self->is_response;
	$wrapper->attr(inReplyTo => $self->{_inreplyto}) if $self->is_message && $self->{_inreplyto};
	# UNIMPLEMENTED Message/Request/Response: Id?

	if ($self->is_response || ($self->is_message && $self->{status}{code} != 200)) {
		$wrapper->add('Status', $self->{status}{description},
			code => $self->{status}{code},
			'xml:lang' => 'en-US',  # Our status descriptions are always in English
			text => $self->{status}{text}
		);
	};

	# No payload on error or ping response
	return $self->_valid_string if $self->{status}{code} >= 300 || $self->{status}{description} eq 'Pong!';

	if (ref $self->{_payload}) {
		# Optional native payload has precedence over XML payload.
		$self->{_xml_payload} = $self->{_payload}->to_node($self->{xml_root});
	};
	$self->{_xml_payload}->setNodeName($self->{_type} . $className);
	$wrapper->addChild($self->{_xml_payload});

	return $self->_valid_string;
}

=item C<B<freeze>()>

Store the results of L</toString()> internally and return it (in a scalar
context).  This is what L</toString()> will always return until L</thaw()> is
eventually called.  Has no effect if the transmission is already frozen.

This helps comply with cXML's recommendation that multiple attempts to deliver
a transmission have the same C<payloadID> and C<timestamp> values.

To help identify problems, in a list context it returns an error string (or
C<undef>) and the XML string.  Note that multiple calls will only yield an error
(if any) on the first call, and C<undef> thereafter.

=cut

sub freeze {
	my ($self) = @_;
	my $err;
	my $str;
	($err, $str) = $self->toString;
	$self->{string} = $str;
	return ($err, $self->{string});
}

=item C<B<thaw>()>

Destroy the internally stored results of L</toString()>.  Modifications to
internal data will once again produce changes in what L</toString()> returns.

=cut

sub thaw {
	my ($self) = @_;
	$self->{string} = undef;
}

=item C<B<reply_to>( REQUEST )>

Initialize L</type>, L</inreplyto>, L</from>, L</to> and L</sender> in
reciprocity with request data.

=cut

sub reply_to {
	my ($self, $req) = @_;

	$self->{_type} = $req->{_type};

	$self->inreplyto($req->{_id});
	$self->is_test($req->is_test);

	$self->sender->copy($req->to);
	$self->sender->contact(undef);
	$self->sender->secret($req->sender->secret);

	$self->from->copy($req->to);
	$self->from->contact(undef);

	$self->to->copy($req->from);
	$self->to->contact(undef);
}

=item C<B<from>( [I<%properties>] )>

=item C<B<to>( [I<%properties>] )>

=item C<B<sender>( [I<%properties>] )>

Returns the associated L<Business::cXML::Credential> object.

With I<C<%properties>>, it first calls
L<Business::cXML::Credential::set()|Business::cXML::Credential/set>.  In the
case of C<from()>, sets both C<from> and C<sender> objects, therefore if you
need to override this behavior, be sure to set C<sender> after C<from>.

Note that you could also pass a single L<Business::cXML::Credential> object,
in which case it would replace the current one outright.  In the case of
C<from()>, note that the object reference will be given to C<sender> intact
and a clone will be copied into C<from()>.

=cut

sub from {
	my ($self, %props) = @_;
	if (ref($_[1])) {
		$self->{_from} = clone($self->{_sender} = $_[1]);
	} elsif (%props) {
		$self->{_sender}->set(%props);
		$self->{_from}->set(%props);
	};
	return $self->{_from};
}

sub to {
	my ($self, %props) = @_;
	if (ref($_[1])) {
		$self->{_to} = $_[1];
	} elsif (%props) {
		$self->{_to}->set(%props);
	};
	return $self->{_to};
}

sub sender {
	my ($self, %props) = @_;
	if (ref($_[1])) {
		$self->{_sender} = $_[1];
	} elsif (%props) {
		$self->{_sender}->set(%props);
	};
	return $self->{_sender};
}

=item C<B<is_test>( [I<$bool>] )>

Get/set whether this transmission is in test mode (vs production).

=cut

sub is_test {
	my ($self, $test) = @_;
	$self->{test} = ($test ? 1 : 0) if @_ > 1;
	return $self->{test};
}

=item C<B<timestamp>>

Read-only, the transmission's creation date/time.

=cut

sub timestamp { shift->{_timestamp} };

=item C<B<id>>

Read-only, the transmission's payload ID.

=cut

sub id { shift->{_id} };

=item C<B<inreplyto>( [I<$id>] )>

Get/set the payload ID of the transmission we're responding to.

=cut

sub inreplyto {
	my ($self, $id) = @_;
	$self->{_inreplyto} = $id if @_ > 1;
	return $self->{_inreplyto};
}

=item C<B<is_message>( [I<$bool>] )>

=item C<B<is_request>( [I<$bool>] )>

=item C<B<is_response>( [I<$bool>] )>

Get/set whether this transmission is a C<Message>, C<Request> or C<Response>.
The transmission's class is only modified when I<C<$bool>> is true.

Setting any of these loses any data currently in L</payload>, so be sure to do
it early!

=cut

sub is_message {
	my ($self, $bool) = @_;
	if ($bool) {
		$self->{class} = CXML_CLASS_MESSAGE;
		$self->{_payload} = undef;
	};
	return $self->{class} == CXML_CLASS_MESSAGE;
}

sub is_request {
	my ($self, $bool) = @_;
	if ($bool) {
		$self->{class} = CXML_CLASS_REQUEST;
		$self->{_payload} = undef;
	};
	return $self->{class} == CXML_CLASS_REQUEST;
}

sub is_response {
	my ($self, $bool) = @_;
	if ($bool) {
		$self->{class} = CXML_CLASS_RESPONSE;
		$self->{_payload} = undef;
	};
	return $self->{class} == CXML_CLASS_RESPONSE;
}

=item C<B<lang>( [I<$code>] )>

Get/set the language for displayable strings included in this transmission.
Can be changed, but cannot be unset.  Default: C<en-US>.  For an incoming
transmission, this should be a hint to the user's preferred display language.

=cut

sub lang {
	my ($self, $lang) = @_;
	if (defined $lang) {
		$self->{_lang} = $lang;
		$self->{xml_root}->attr('xml:lang' => $lang);
	};
	return $self->{_lang};
}

=item C<B<type>( [I<$name>] )>

Get/set the type of document.  Can be changed, but cannot be unset.  For
example: C<Profile> or C<PunchOutSetup>.

B<Caution:> Setting a type loses any data currently in L</payload>, so be sure
to do it early!

=cut

sub type {
	my ($self, $type) = @_;
	if (defined $type) {
		$self->{_type} = $type;
		$self->{_payload} = undef;
	};
	return $self->{_type};
}

=item C<B<payload>>

Read-only.  If a native implementation for the current transmission type is
available (i.e. L<Business::cXML::Request::PunchOutSetup>), it is made
available ready-to-use via this property.  For incoming transmission, it is
fully populated with parsed data.

If accessed after previously using L</xml_payload>, this would cause the
native payload to be recreated from the XML payload as it currently stands,
preserving any (valid) changes done on the XML side into the native version.

=cut

sub payload {
	my ($self) = @_;
	$self->_rebuild_payload();
	return $self->{_payload};
}

=item C<B<xml_payload>>

Read-only.  The L<XML::LibXML::Element> representing the "SomethingMessage",
"SomethingRequest" or "SomethingResponse" section of the transmission.

Its node name is automatically determined in L</toString()>, but you are free
to add/change other attributes and child elements.  Returns C<undef> for
incoming (parsed) transmissions.

Accessing this property causes the destruction of L</payload> if it existed.
This is in place so that your own parsing of LibXML structures takes
precedence over ours to hopefully make future updates seamless in the event of
conflicts.  Thus, while you can modify the native payload, then modify the XML
version, B<switching back again to native would lose all data>.

=cut

sub xml_payload {
	my ($self) = @_;
	$self->{_payload} = undef;
	return $self->{_xml_payload};
}

=item C<B<status>( [ I<$code>, [$description] ] )>

Get/set transmission's cXML 3-digit status code.  (None by default.)

I<C<$description>> is an optional explanatory text that may be included in the
status of a response.

cXML defines the following status codes, which are the only ones accepted.

B<Success:>

=over

=item C<200> OK

Request executed and delivered, cXML itself has no error

=item C<201> Accepted

Not yet processed, we'll send a StatusUpdate later

=item C<204> No Content

Request won't get a Response from server (i.e. punch-out cart didn't change)

=item C<280> [Described like 201]

=item C<281> [Described like 201]

=back

B<Permanent errors:>

=over

=item C<400> Bad Request

Parsed OK but unacceptable

=item C<401> Unauthorized

Request/Sender credentials not recognized

=item C<402> Payment Required

Need complete Payment element

=item C<403> Forbidden

Insufficient privileges

=item C<406> Not Acceptable

Request unacceptable, likely parsing failure

=item C<409> Conflict

Current state incompatible with Request

=item C<412> Precondition Failed

Unlike 403, the precondition was described in a previous response

=item C<417> Expectation Failed

Request implied a resource condition that was not met, such as an unknown one

=item C<450> Not Implemented

Server doesn't implement that Request (so client ignored server's profile?)

=item C<475> Signature Required

Document missing required digital signature

=item C<476> Signature Verification Failed

Failed signature or unsupported signature algorithm

=item C<477> Signature Unacceptable

Valid signature but otherwise rejected

=back

B<Transient errors:>

=over

=item C<500> Internal Server Error

Server was unable to complete the Request (temporary)

=item C<550> Unable to reach cXML server

Applies to intermediate hubs (temporary)

=item C<551> Unable to forward request

Because of supplier misconfiguration (temporary)

=item C<560> Temporary server error

Maintenance, etc. (temporary)

=back

=cut

my %CXML_STATUS_CODES = (
	200 => 'OK',
	201 => 'Accepted',
	204 => 'No Content',
	280 => '',
	281 => '',

	400 => 'Bad Request',
	401 => 'Unauthorized',
	402 => 'Payment Required',
	403 => 'Forbidden',
	406 => 'Not Acceptable',
	409 => 'Conflict',
	412 => 'Precondition Failed',
	417 => 'Expectation Failed',
	450 => 'Not Implemented',
	475 => 'Signature Required',
	476 => 'Signature Verification Failed',
	477 => 'Signature Unacceptable',

	500 => 'Internal Server Error',
	550 => 'Unable to reach cXML server',
	551 => 'Unable to forward request',
	560 => 'Temporary server error',
);

sub status {
	my ($self, $code, $desc) = @_;
	if ($code) {
		if (exists $CXML_STATUS_CODES{$code}) {
			$self->{status}{code} = $code;
			$self->{status}{text} = $CXML_STATUS_CODES{$code};
			$self->{status}{description} = $desc || '';
		} else {
			# We were given an unsupported code, this is BAD!
			$self->{status}{code} = 500;
			$self->{status}{text} = $CXML_STATUS_CODES{500};
			$self->{status}{description} = "Unsupported actual status code '$code'.";
		};
	};
	return $self->{status}{code};
}

=back

=head1 AUTHOR

Stéphane Lavergne L<https://github.com/vphantom>

=head1 ACKNOWLEDGEMENTS

Graph X Design Inc. L<https://www.gxd.ca/> sponsored this project.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2017-2018 Stéphane Lavergne L<https://github.com/vphantom>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;
