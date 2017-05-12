package AMF::Connection;

use AMF::Connection::Message;
use AMF::Connection::MessageBody;
use AMF::Connection::OutputStream;
use AMF::Connection::InputStream;

use LWP::UserAgent;
use HTTP::Cookies;

#use Data::Dumper; #for debug

use Carp;
use strict;

our $VERSION = '0.32';

our $HASMD5 = 0;
{
local $@;
eval { require Digest::MD5; };
$HASMD5 = ($@) ? 0 : 1 ;
};

our $HASUUID;
{
local $@;
eval { require Data::UUID; };
$HASUUID = ($@) ? 0 : 1 ;
}

our $HAS_LWP_PROTOCOL_SOCKS;
{
local $@;
eval { require LWP::Protocol::socks };
$HAS_LWP_PROTOCOL_SOCKS = ($@) ? 0 : 1 ;
}

sub new {
	my ($proto, $endpoint) = @_;
        my $class = ref($proto) || $proto;

	my $self = {
		'endpoint' => $endpoint,
		'headers' => [],
		'http_headers' => {},
		'http_cookie_jar' => new HTTP::Cookies(),
		'response_counter' => 0,
		'encoding' => 0, # default is AMF0 encoding
		'ua'	=> new LWP::UserAgent(),
		'append_to_endpoint' => ''
		};

	$self->{'ua'}->cookie_jar( $self->{'http_cookie_jar'} );

        return bless($self, $class);
	};

# plus add paramters, referer, user agent, authentication/credentials ( see also SecureAMFChannel stuff ), 
# plus timezone on retunred dates to pass to de-serializer - see AMF3 spec saying "it is suggested that time zone be queried independnetly as needed" - unelss local DateTime default to right locale!

# we pass the string, and let Storable::AMF to parse the options into a scalar - see Input/OutputStream and Storable::AMF0 documentation

sub setInputAMFOptions {
	my ($class, $options) = @_;

	$class->{'input_amf_options'} = $options;
	};

sub setOutputAMFOptions {
	my ($class, $options) = @_;

	$class->{'output_amf_options'} = $options;
	};

# useful when input and output options are the same
sub setAMFOptions {
	my ($class, $options) = @_;

	$class->setInputAMFOptions ($options);
	$class->setOutputAMFOptions ($options);
	};

sub getInputAMFOptions {
	my ($class) = @_;

	return $class->{'input_amf_options'};
	};

sub getOutputAMFOptions {
	my ($class) = @_;

	return $class->{'output_amf_options'};
	};

sub setEndpoint {
	my ($class, $endpoint) = @_;

	$class->{'endpoint'} = $endpoint;
	};

sub getEndpoint {
	my ($class) = @_;

	return $class->{'endpoint'};
	};

sub setHTTPProxy {
	my ($class, $proxy) = @_;

	if(	($proxy =~ m!^socks://(.*?):(\d+)!) &&
		(!$HAS_LWP_PROTOCOL_SOCKS) ) {
		croak "LWP::Protocol::socks is required for SOCKS support";
		};

	$class->{'http_proxy'} = $proxy;

	$class->{'ua'}->proxy( [qw(http https)] => $class->{'http_proxy'} );
	};

sub getHTTPProxy {
	my ($class) = @_;

	return $class->{'http_proxy'};
	};

sub setEncoding {
	my ($class, $encoding) = @_;

	croak "Unsupported AMF encoding $encoding"
		unless( $encoding==0 or $encoding==3 );

	$class->{'encoding'} = $encoding;
	};

sub getEncoding {
	my ($class) = @_;

	return $class->{'encoding'};
	};

sub addHeader {
	my ($class, $header, $value, $required) = @_;

	if( ref($header) ) {
		croak "Not a valid header $header"
			unless( $header->isa("AMF::Connection::MessageHeader") );
	} else {
		$header = new AMF::Connection::MessageHeader( $header, $value, ($required==1) ? 1 : 0  );
		};

	push @{ $class->{'headers'} }, $header;
	};

sub addHTTPHeader {
	my ($class, $name, $value) = @_;

	$class->{'http_headers'}->{ $name } = $value ;
	};

sub setUserAgent {
	my ($class, $ua) = @_;

	croak "Not a valid User-Agent $ua"
		unless( ref($ua) and $ua->isa("LWP::UserAgent") and $ua->can("post") );

	# the passed UA might have a different agent and cookie jar settings
	$class->{'ua'} = $ua;

	# make sure we set the proxy if was already set
	# NOTE - we do not re-check SOCKS support due we assume the setHTTPProxy() was called earlier
	$class->{'ua'}->proxy( [qw(http https)] => $class->{'http_proxy'} )
		if( exists $class->{'http_proxy'} and defined $class->{'http_proxy'} );

	# copy/pass over cookies too
	$class->{'ua'}->cookie_jar( $class->{'http_cookie_jar'} );
	};

sub setHTTPCookieJar {
	my ($class, $cookie_jar) = @_;

	croak "Not a valid cookies jar $cookie_jar"
		unless( ref($cookie_jar) and $cookie_jar->isa("HTTP::Cookies") );

	# TODO - copy/pass over the current cookies (in-memory by default) if any set
	$class->{'http_cookie_jar'}->scan( sub { $cookie_jar->set_cookie( @_ ); } );

	$class->{'http_cookie_jar'} = $cookie_jar;

	# tell user agent to use new cookie jar
        $class->{'ua'}->cookie_jar( $class->{'http_cookie_jar'} );
	};

sub getHTTPCookieJar {
        my ($class) = @_;
		
	return $class->{'http_cookie_jar'};
	};

# send "flex.messaging.messages.RemotingMessage"

sub call {
	my ($class, $operation, $arguments, $destination) = @_;

	my @call = $class->callBatch ({ "operation" => $operation,
					"arguments" => $arguments,
					"destination" => $destination });

	return (wantarray) ? @call : $call[0];
	};

sub callBatch {
	my ($class, @batch) = @_;

	my $request = new AMF::Connection::Message;
	$request->setEncoding( $class->{'encoding'} );

	# add AMF any request headers
	map { $request->addHeader( $_ ); } @{ $class->{'headers'} };

	# TODO - prepare HTTP/S request headers based on AMF headers received/set if any - and credentials

	foreach my $call (@batch)
          {
	    next
              unless (defined $call && ref ($call) =~ m/HASH/
		      && defined $call->{'operation'} && defined $call->{'arguments'});

	    my $operation = $call->{'operation'};
	    my $arguments = $call->{'arguments'};

	    my $body = new AMF::Connection::MessageBody;
	    $class->{'response_counter'}++;
	    $body->setResponse( "/".$class->{'response_counter'} );

	    if( $class->{'encoding'} == 3 ) { # AMF3
		$body->setTarget( 'null' );

		my (@operation) = split('\.',$operation);
		my $method = pop @operation;
		my $service = join('.',@operation);
		my $destination = (defined $call->{'destination'}) ? $call->{'destination'} : $service;

		my $remoting_message = $class->_brew_flex_remoting_message( $service, $method, {}, $arguments, $destination);

		$body->setData( [ $remoting_message ] ); # it seems we need array ref here - to be checked
	    } else {
		$body->setTarget( $operation );
		$body->setData( $arguments );
		};

	    $request->addBody( $body );
          }

	my $request_stream = new AMF::Connection::OutputStream($class->{'output_amf_options'});

	# serialize request
	$request->serialize($request_stream);

	#use Data::Dumper;
	#print STDERR Dumper( $request );

	# set any extra HTTP header
	map { $class->{'ua'}->default_header( $_ => $class->{'http_headers'}->{$_} ); } keys %{ $class->{'http_headers'} };

	my $http_response = $class->{'ua'}->post(
		$class->{'endpoint'}.$class->{'append_to_endpoint'}, # TODO - check if append to URL this really work for HTTP POST
		Content_Type => "application/x-amf",
		Content => $request_stream->getStreamData()
		);

	croak "HTTP POST error: ".$http_response->status_line."\n"
		unless($http_response->is_success);

	my $response_stream = new AMF::Connection::InputStream( $http_response->decoded_content, $class->{'input_amf_options'});
	my $response = new AMF::Connection::Message;
	$response->deserialize( $response_stream );

	#print STDERR Dumper( $response )."\n";

	# process AMF response headers
	$class->_process_response_headers( $response );

	my @all = @{ $response->getBodies() };

	# we make sure the main response is always returned first
	return (wantarray) ? @all : $all[0];
	};

# TODO
#
# sub command { } - to send "flex.messaging.messages.CommandMessage" instead
#

sub setCredentials {
	my ($class, $username, $password) = @_;

	$class->addHeader( 'Credentials', { 'userid' => $username,'password' => $password }, 0 );
	};


sub _process_response_headers {
	my ($class,$message) = @_;

	foreach my $header (@{ $message->getHeaders()}) {
		if($header->getName eq 'ReplaceGatewayUrl') { # another way used by server to keep cookies-less sessions
			$class->setEndpoint( $header->getValue )
				unless( ref($header->getValue) );
		} elsif($header->getName eq 'AppendToGatewayUrl') { # generally used for cokies-less sessions E.g. ';jsessionid=99226346ED3FF5296D08146B02ECCA28'
			$class->{'append_to_endpoint'} = $header->getValue
				unless( ref($header->getValue) );
			};
		};
	};

# just an hack to avoid rewrite class mapping local-to-remote and viceversa and make Storable::AMF happy
sub _brew_flex_remoting_message {
	my ($class,$source,$operation,$headers,$body,$destination) = @_;

	return bless( {
		'clientId' => _generateID(),
                'destination' => $destination,
                'messageId' => _generateID(),
                'timestamp' => time() . '00',
                'timeToLive' => 0,
                'headers' => ($headers) ? $headers : {},
                'body' => $body,
                'correlationId' => undef,
                'operation' => $operation,
		'source' => $source # for backwards compatibility - google for it!
                 }, 'flex.messaging.messages.RemotingMessage' );
        };

sub _generateID {
        my $uniqueid;

        if($HASUUID) {
                eval {
                        my $ug = new Data::UUID;
                        $uniqueid = $ug->to_string( $ug->create() );
                        };
        } elsif ($HASMD5) {
                eval {
                        $uniqueid = substr(Digest::MD5::md5_hex(Digest::MD5::md5_hex(time(). {}. rand(). $$)), 0, 32);
                        };
        } else {
                $uniqueid  ="";
                my $length=16;

                my $j;
                for(my $i=0 ; $i< $length ;) {
                        $j = chr(int(rand(127)));

                        if($j =~ /[a-zA-Z0-9]/) {
                                $uniqueid .=$j;
                                $i++;
                                };
                        };
                };

        return $uniqueid;
        };

1;
__END__

=head1 NAME

AMF::Connection - A simple library to write AMF clients.

=head1 SYNOPSIS

  use AMF::Connection;

  my $endpoint = 'http://myserver.com/flex/amf/'; #AMF server/gateway

  my $service = 'myService';
  my $method = 'myMethod';

  my $client = new AMF::Connection( $endpoint );

  $client->setEncoding(3); # use AMF3 default AMF0

  $client->setHTTPCookieJar( HTTP::Cookies->new(file => "/tmp/mycookies.txt", autosave => 1, ignore_discard => 1 ) );

  my @params = ( 'param1', { 'param2' => 'value2' } );
  my $response = $client->call( "$service.$method", \@params );

  if ( $response->is_success ) {
        my $result_object = $response->getData();
	# ...
  } else {
        die "Can not send remote request for $service.$method method on $endpoint\n";
        };

  my @response = $client->callBatch ( { "operation" => $service.$method", "arguments" => \@params }, ... );

=head1 DESCRIPTION

I was looking for a simple Perl module to automate data extraction from an existing Flash+Flex/AMS application, and I could not find a decent client implementation. So, this module was born based on available online documentation.

This module has been inspired to SabreAMF PHP implementation of AMF client libraries.

AMF::Connection is meant to provide a simple AMF library to write client applications for invocation of remote services as used by most flex/AIR RIAs. 

The module includes basic support for synchronous HTTP/S based RPC request-response access, where the client sends a request to the server to be processed and the server returns a response to the client containing the processing outcome. Data is sent back and forth in AMF binary format (AMFChannel). Other access patterns such as pub/sub and channels transport are out of scope of this inital release.

AMF0 and AMF3 support is provided using the Storable::AMF module. While HTTP/S requestes to the AMF endpoint are carried out using the LWP::UserAgent module. The requests are sent using the HTTP POST method as AMF0 encoded data by default. AMF3 encoding can be set using the setEncoding() method. Simple AMF3 Externalized Object support is provided on returned objects from the server. Objects returned are simply left in bless( { ... }, 'something') form and they could be mapped to local to the client abstractions if needed. 

If encoding is set to AMF3 the Flex Messaging framework is used on returned responses content (I.e. objects casted to "flex.messaging.messages.AcknowledgeMessage" and "flex.messaging.messages.ErrorMessage" are returned).

Simple batch requests and responses is provided also.

See the sample usage synopsis above to start using the module.

=head1 DATE TYPE SUPPORT

The latest 0.79 version of Storable::AMF added basic date support with the new_date() and perl_date() utilitiy functions. This is just great. Internally an AMF Date Type represents a timestamp in milliseconds since the epoch in UTC ("neutral") timezone, and since Storable::AMF version 0.79 the module shields the user from that by automatically converting Date values to Perl double (number) scalar values. Users which require AMF Date support should import the new_date() and perl_date() date manipulation functions into their code like:

 use Storable::AMF qw(new_date perl_date);

and make sure any date passed to an AMF::Connection as parameter is encoded with new_date().

=head2 OPEN ISSUES AND SHORTCOMINGS

There is still an issue when arbitrary Date structures are returned from an AMF server to an AMF::Connection (E.g. as part of values of structured AMF Objects). In this case, the AMF::Connection does not try to reparse the Perl object structure returned by Storable::AMF (see thaw()), plus the Storable::AMF module thaw() function does simply deserialise AMF Date Type as number (double) of *milli* seconds since the epoch, and the perl_date() function must be called on each returned value instead. The Storable::AMF module author says that there were other issues in enoforcing a conversion (division by 1000) of the AMF server side (and controlled) timestamp values on each thaw() automatically; hopefully future releases of the module will address this problem.

All this means that an AMF::Connection client application can not rely on those Date returned by the server as being Perl timestamps (seconds since the epoch) and will need explicitly call perl_date() or divide the timestamp by 1000 *explicitly*.

=head2 USING OLD Storable::AMF VERSIONS

In older versions (pre 0.79) of Storable::AMF there was no support for the AMF0/AFM3 Date Type, and everything was being passed as string to the server (E.g. "2010-09-22T02:34:00"). Or as double (number) if the date was in timestamp seconds since the epoch. This meant that an AMF::Connection in order to send a date (E.g. as parameter) had to multiply (or divide) by 1000 the timestamp (E.g. for $perl_timestamp=time(); my $amf_timestamp = $perl_timestamp*1000 vs. my $perl_timestamp = $amf_timestamp/1000), plus rely on the AMF server to cast timestamp AMF Numbers to Dates (I.e. which seems to work on most AMF servers in Java which cast Number to java.util.Date() or similar).

=head1 MAPPING OBJECTS

By combining the power of Perl bless {}, $package_name syntax and the Storable::AMF freeze()/thaw() interface, it is possible to pass arbitrary structured AMF Objects the corresponding AMF server can interpret. This is possible due a simple Perl object reference to an hash is serialised to an AMF Object and can be mapped back on the server side. 

This means that an AMF::Connection application can wrap all ActionScript / Flex AMF Objects around Perl Objects and get them sent; and returned into a Perl object BLOB using the power of Storable::AMF freeze()/thaw().A

For example to send a SearchQueryFx AMF Object to the server an AMF::Connection advanced search call(), the following code could be used:

my $client = new AMF::Connection ( ... );

# ... prepare parameters...

my $searchAMFObject = bless( {
                   'searchId' => $searchId,
                   'startHit' => int($startHit),
                   'searchString' => $searchString,
                   'hitsPerPage' => ($hitsPerPage) ? int($hitsPerPage) : 20,
                   'sortId' => $sortId,
       }, 'com.mycompany.application.flex.data.SearchQueryFx');

my $response = $client->call( "MySearchSevice.searchAdvanced", [ $searchAMFObject ] );

#....

For other Java to ActionScript type mappings possibilities see http://livedocs.adobe.com/blazeds/1/javadoc/flex/messaging/io/amf/ActionMessageOutput.html#writeObject(java.lang.Object)

For PHP gateways at the moment there is not a known/documented way to map client to server objects.

Future versions of AMF::Connection may add a proper configurable factory for application specific ActionScript/Flex object mappings.

=head1 METHODS

=head2 new ($endpoint)

Create new AMF::Connection object. An endpoint can be specified as the only parameter. Or set in a second moment with the setEndpoint() method.

=head2 call ($operation, $arguments)

Call the remote service method with given parameters/arguments on the set endpoint and return an AMF::Connection::MessageBody response. Or an array of responses if requsted (wantarray call scope). The $arguments is generally an array reference, but this version of the AMF::Connection code allows other object types too.

=head2 callBatch (@batch)

Call the remote service once in batch. Each element of @batch must be an hash like { "operation" => $operation, "arguments" => $arguments }, where $operation and $arguments are as specified in C<call>. The commands are called and responses returned in order as in @batch.

=head2 setEndpoint ($endpoint)

Set the AMF service endpoint.

=head2 getEndpoint ()

Return the AMF service endpoint.

=head2 setEncoding ($encoding)

Set the AMF encoding to use.

=head2 getEncoding ()

Return the AMF encoding in use.

=head2 setHTTPProxy ($proxy)

Set the HTTP/S proxy to use. If LWP::Protocol is installed SOCKS proxies are supported.

=head2 getHTTPProxy ()

Return the HTTP/S procy in use if any.

=head2 addHeader ($header[, $value, $required])

Add an AMF AMF::Connection::MessageHeader to the requests. If $header is a string the header value $value and $required flag can be specified.

=head2 addHTTPHeader ($name, $value)

Add an HTTP header to sub-sequent HTTP requests.

=head2 setUserAgent ($ua)

Allow to specify an alternative LWP::UserAgent. The $ua must support the post() method, proxy() and cookie_jar() if necessary.

=head2 setHTTPCookieJar ($cookie_jar)

Allow to specify an alternative HTTP::Cookies jar. By default AMF::Connection keeps cookies into main-memory and the cookie jar is reset when a new connection is created. When a new cookies jar is set, any existing AMF::Connection cookie is copied over.

=head2 getHTTPCookieJar ()

Return the current HTTP::Cookies jar in use.

=head2 setCredentials ($username,$password)

Minimal support for AMF authentication. Password seems to be wanted in clear.

=head2 setInputAMFOptions ($options)

Set input stream parsing options. See Storable::AMF0 for available options.

=head2 setOutputAMFOptions ($options)

Set output stream serialization options. See Storable::AMF0 for available options.

=head2 setAMFOptions ($options)

Set input and output options the same. See Storable::AMF0 for available options.

=head2 getInputAMFOptions ()

Get input stream parsing options.

=head2 getOutputAMFOptions ()

Get output stream serialization options.

=head1 CODE

See http://github.com/areggiori/AMF-Connection

=head1 SEE ALSO

 AMF::Connection::MessageBody
 Storable::AMF, Storable::AMF0, LWP::UserAgent

 Flex messaging framework / LiveCycle Data Services
  http://livedocs.adobe.com/blazeds/1/javadoc/flex/messaging/io/amf/client/package-summary.html
  http://livedocs.adobe.com/blazeds/1/javadoc/flex/messaging/io/amf/client/AMFConnection.html
  http://www.adobe.com/livedocs/flash/9.0/ActionScriptLangRefV3/flash/net/NetConnection.html
  http://help.adobe.com/en_US/LiveCycleDataServicesES/3.1/Developing/lcds31_using.pdf
  http://help.adobe.com/en_US/Flex/4.0/AccessingData/flex_4_accessingdata.pdf
  http://www.adobe.com/support/documentation/en/livecycledataservices/documentation.html
 
 Specifications
  http://download.macromedia.com/pub/labs/amf/amf0_spec_121207.pdf (AMF0)
  http://opensource.adobe.com/wiki/download/attachments/1114283/amf3_spec_05_05_08.pdf (AMF3)

 SabreAMF
  http://code.google.com/p/sabreamf/

=head1 AUTHOR

Alberto Attilio Reggiori, <areggiori at cpan dot org>

=head1 THANKS

Anatoliy Grishayev for prompt support and developments on Storable::AMF

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 by Alberto Attilio Reggiori

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
