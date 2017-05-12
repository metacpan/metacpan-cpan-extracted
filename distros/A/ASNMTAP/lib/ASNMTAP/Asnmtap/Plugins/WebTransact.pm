# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, package ASNMTAP::Asnmtap::Plugins::WebTransact
# ----------------------------------------------------------------------------------------------------------

package ASNMTAP::Asnmtap::Plugins::WebTransact;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI::Carp qw(fatalsToBrowser set_message cluck);

use HTTP::Request::Common qw(GET POST HEAD);
use HTTP::Cookies;

use LWP::Debug;
use LWP::UserAgent;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap qw(%ERRORS %TYPE &_dumpValue);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { $ASNMTAP::Asnmtap::Plugins::WebTransact::VERSION = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use constant FALSE => 0;
use constant TRUE  => ! FALSE;

use constant Field_Refs	=> {
                             Method	        => { is_ref => FALSE, type => ''      },
                             Url            => { is_ref => FALSE, type => ''      },
                             Qs_var	        => { is_ref => TRUE,  type => 'ARRAY' },
                             Qs_fixed	      => { is_ref => TRUE,  type => 'ARRAY' },
                             Exp            => { is_ref => FALSE, type => 'ARRAY' },
                             Exp_Fault	    => { is_ref => FALSE, type => ''      },
                             Exp_Return     => { is_ref => TRUE,  type => 'HASH'  },
                             Msg            => { is_ref => FALSE, type => ''      },
                             Msg_Fault	    => { is_ref => FALSE, type => ''      },
                             Timeout        => { is_ref => FALSE, type => undef   },
                             Perfdata_Label => { is_ref => FALSE, type => undef   }
                           };

my (%returns, %downloaded, $ua);
keys %downloaded = 128;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _handleHttpdErrors { print "<hr><h1>ASNMTAP::Asnmtap::Plugins::WebTransact It's not a bug, it's a feature!</h1><p>Error: $_[0]</p><hr>"; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

set_message ( \&_handleHttpdErrors );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _error_message { $_[0] =~ s/\n/ /g; $_[0]; }

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub new {
  my ($object, $asnmtapInherited, $urls_ar) = @_;

  # $urls_ar is a ref to a list of hashes (representing a request record) in a partic format.

  # If a hash is __not__ in that format it's much better to cluck since it is
  # hard to interpret 'not an array ref' messages (from check::_make_request) caused
  # by mis spelled or mistaken field names.

  &_dumpValue ( $asnmtapInherited, $object .': attribute asnmtapInherited is missing.' ) unless ( defined $asnmtapInherited );

  &_dumpValue ( $urls_ar, $object .': URL list is not an array reference.' ) if ( ref $urls_ar ne 'ARRAY' );
  my @urls = @$urls_ar;

  foreach my $url ( @urls ) {
    &_dumpValue ( $url, $object .': Request record is not a hash.' ) if ( ref $url ne 'HASH' );
    my @keys = keys %$url;

    foreach my $key ( @keys ) {
      unless ( exists Field_Refs->{$key} ) {
        warn "Expected keys: ", join " ", keys %{ (Field_Refs) };
        &_dumpValue ( $url, $object .": Unexpected key \"$key\" in record." );
      }

      my $ref_type = '';

      if ( ($ref_type = ref $url->{$key}) && ( $ref_type ne Field_Refs->{$key}{type} ) ) {
        warn "Expected key \"$key\" to be ", Field_Refs->{$key}{type} ? Field_Refs->{$key}{type} .' ref' : 'non ref', "\n";
        &_dumpValue ( $url, $object .": Field \"$key\" has wrong reference type" );
      }

      if ( ! ref $url->{$key} and Field_Refs->{$key}{is_ref} ) {
        warn "Expected key \"$key\" to be ", Field_Refs->{$key}{type} ? Field_Refs->{$key}{type} .' ref' : 'non ref', "\n";
        &_dumpValue ( $url, $object .": Key \"$key\" not a  reference" );
      }

      if ( $url->{$key} eq '' ) {
        warn "Expected key \"$key\" is empty\n";
        &_dumpValue ( $url, $object .": Key \"$key\" is empty" );
      }
    }
  }

  my $classname = ref ($object) || $object;
  my $accessor_stash_slot = $classname .'::'. 'get_urls';
  no strict 'refs';

  unless ( ref *$accessor_stash_slot{CODE} eq 'CODE' ) {
    foreach my $accessor ( qw(urls matches returns ua) ) {
      my $full_name = $classname .'::'. $accessor;

      *{$full_name} = sub { my $self = shift @_;
                            $self->{$accessor} = shift @_ if @_;
                            $self->{$accessor};
                          };

      foreach my $acc_pre (qw(get set)) {
        $full_name = $classname .'::'. $acc_pre .'_'. $accessor;
        *{$full_name} = $acc_pre eq 'get' ? sub { my $self = shift @_; $self->{$accessor} } : sub { my $self = shift @_; $self->{$accessor} = shift @_ };
      }
    }
  }

  bless { asnmtapInherited => $asnmtapInherited, urls => $urls_ar, matches => [], returns => {}, ua => undef, newAgent => 1, number_of_images_downloaded => 0, _unknownErrors => 0, _KnownError => undef, _timing_tries => 0 }, $classname;
  # The field urls contains a ref to a list of (hashes) records representing the web transaction.

  # self->_my_match() will update $self->{matches};
  # with the set of matches it finds by matching patterns with memory (ie patterns in paren) from
  # the Exp field against the request response.
  # An array ref to the array containing the matches is stored in the field 'matches'.

  # Qs_var = [ form_name_1 => 0, form_name_2 => 1 ..] will lead to a query_string like
  # form_name_1 = $matches[0] form_name_2 = $matches[1] .. in $self->_make_request() by
  # @matches = $self->matches(); and using 0, 1 etc as indices of @matches.
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub check {
  my ($self, $cgi_parm_vals_hr) = @_;

  my %defaults = ( custom           => undef,
                   perfdataLabel    => undef,
                   newAgent         => undef,
                   timeout          => undef,
                   triesTiming      => '1,3,15',
                   triesCodes       => '408,500,502,503,504',
                   openAppend       => TRUE,
                   cookies          => TRUE,
                   protocol         => TRUE,
                   keepAlive        => TRUE,
                   download_images  => FALSE,
                   fail_if_1        => TRUE );

  my %parms = (%defaults, @_);

  my $debug         = ${$self->{asnmtapInherited}}->getOptionsValue ( 'debug' );
  my $onDemand      = ${$self->{asnmtapInherited}}->getOptionsValue ( 'onDemand' );
  my $debugfile     = ${$self->{asnmtapInherited}}->getOptionsArgv ( 'debugfile' );
  my $openAppend    = $parms{openAppend};
  my $triesTiming   = $parms{triesTiming};
  my %triesCodesToDeterminate = map { $_ => 1 } ( $parms{triesCodes} =~ m<(\d+(?:\.\d+)*)>g );

  my $proxyServer   = ${$self->{asnmtapInherited}}->proxy ( 'server' );
  my $proxyUsername = ${$self->{asnmtapInherited}}->proxy ( 'username' );
  my $proxyPassword = ${$self->{asnmtapInherited}}->proxy ( 'password' );

  $self->{newAgent} = $parms{newAgent} if ( defined $parms{newAgent} and defined $ua );

  if ( $self->{newAgent} or ! defined $ua ) {
    $self->{newAgent} = 0;
    LWP::Debug::level('+') if ( $debug );

    if ( $parms{keepAlive} ) {
      $ua = LWP::UserAgent->new ( keep_alive => 1 );
    } else {
      $ua = LWP::UserAgent->new ( keep_alive => 0 );
    }

    $self->{ua} = $ua;
    $ua->agent ( ${$self->{asnmtapInherited}}->browseragent () );
    $ua->timeout ( ${$self->{asnmtapInherited}}->timeout () );

    $ua->default_headers->push_header ( 'Accept-Language' => 'no, en' );
    $ua->default_headers->push_header ( 'Accept-Charset'  => 'iso-8859-1,*,utf-8' );
    $ua->default_headers->push_header ( 'Accept-Encoding' => 'gzip, deflate' );

    $ua->default_headers->push_header ( 'Keep-Alive' => ${$self->{asnmtapInherited}}->timeout () ) if ( $parms{keepAlive} );
    $ua->default_headers->push_header ( 'Connection' => 'Keep-Alive' );

    if ( defined $proxyServer ) {
      $ua->default_headers->push_header ( 'Proxy-Connection' => 'Keep-Alive' );

      # don't use $ua->proxy ( ['http', 'https', 'ftp'] => $proxyServer ); or $ua->proxy ( 'https' => undef ) ;
      $ua->proxy ( ['http', 'ftp'] => $proxyServer );

      # do not proxy requests to the given domains. Calling no_proxy without any domains clears the list of domains.
      ( defined ${$self->{asnmtapInherited}}->proxy ( 'no' ) and ${$self->{asnmtapInherited}}->proxy ( 'no' ) ne '' ? $ua->no_proxy( @{ ${$self->{asnmtapInherited}}->proxy ( 'no' ) } ) : $ua->no_proxy( ) ) ;
    }

    $ua->cookie_jar ( HTTP::Cookies->new ) if ( $parms{cookies} );
  }

  if ( defined $parms{timeout} ) {
    $ua->timeout ( $parms{timeout} );
    $ua->default_headers->push_header ( 'Keep-Alive' => $parms{timeout} ) if ( $parms{keepAlive} );
  }

  my $returnCode = $parms{fail_if_1} ? $ERRORS{OK} : $ERRORS{CRITICAL};
  my ($response_as_content, $response, $found);

  my $startTime;

  if ( defined $parms{perfdataLabel} and $parms{perfdataLabel} ) {
    ${$self->{asnmtapInherited}}->setEndTime_and_getResponsTime ( ${$self->{asnmtapInherited}}->pluginValue ('endTime') );
    $startTime = ${$self->{asnmtapInherited}}->pluginValue ('endTime');
  }

  my $statusTimeout;

  foreach my $url_r ( @{ $self->{urls} } ) {
    if ( defined $url_r->{Timeout} ) {
      $statusTimeout = 1;
      $ua->timeout ( $url_r->{Timeout} );
      $ua->default_headers->push_header ( 'Keep-Alive' => $url_r->{Timeout} ) if ( $parms{keepAlive} );
    } elsif ( defined $statusTimeout ) {
      $statusTimeout = undef;

      if ( defined $parms{timeout} ) {
        $ua->timeout ( $parms{timeout} );
        $ua->default_headers->push_header ( 'Keep-Alive' => $parms{timeout} ) if ( $parms{keepAlive} );
      } else {
        $ua->timeout ( ${$self->{asnmtapInherited}}->timeout () );
        $ua->default_headers->push_header ( 'Keep-Alive' => ${$self->{asnmtapInherited}}->timeout () ) if ( $parms{keepAlive} );
      }
    }

    $self->{_KnownError} = undef;
    ${$self->{asnmtapInherited}}->setEndTime_and_getResponsTime ( ${$self->{asnmtapInherited}}->pluginValue ('endTime') );

    my $url = $url_r->{Url} ? $url_r->{Url} : &_next_url ($response, $response_as_content);
    my $request = $self->_make_request ( $url_r->{Method}, $url, $url_r->{Qs_var}, $url_r->{Qs_fixed}, $cgi_parm_vals_hr );
    $request->protocol ('HTTP/1.1') if ( $parms{protocol} );
    $request->proxy_authorization_basic ( $proxyUsername, $proxyPassword ) if ( defined $proxyServer && defined $proxyUsername && defined $proxyPassword );

    my $request_as_string = $request->as_string;
    print "\n", ref ($self), '::send_request: ', $request_as_string, "\n" if ( $debug );

    if ( defined $triesTiming and $triesTiming ) {
      my (@timing_tries) = ( $triesTiming =~ m<(\d+(?:\.\d+)*)>g );
      LWP::Debug::debug ('My retrial code policy is ['. join(' ', sort keys %triesCodesToDeterminate) .'].');
      LWP::Debug::debug ('My retrial timing policy is ['. $triesTiming .'].');
      my $timing_tries = 0;

      foreach my $pause_if_unsuccessful ( @timing_tries, undef ) {
        $response = $ua->request ($request);
        my $code = $response->code;
        my $message = $response->message;
        $message =~ s/\s+$//s;
        $timing_tries++;

        unless( $triesCodesToDeterminate{$code} ) { # normal case: all is well (or 404, etc)
          LWP::Debug::debug ("It returned a code ($code $message) blocking a retry");
          last;
        }

        if ( defined $pause_if_unsuccessful ) {
          LWP::Debug::debug ("It returned a code ($code $message) that'll make me retry, after $pause_if_unsuccessful seconds.");
          sleep $pause_if_unsuccessful if ( $pause_if_unsuccessful );
          $self->{_timing_tries}++;
        } else {
          LWP::Debug::debug ("I give up.  I'm returning this '$code $message' response.");
        }
      }

      print ref ($self), '::timing_tries: ', $timing_tries, " - $url\n" if ( $onDemand );
    } else {
      $response = $ua->request ($request);
    }

    if ( defined $response->content_encoding and $response->content_encoding =~ /^gzip$/i ) {
      use Compress::Zlib;
      $response_as_content = Compress::Zlib::memGunzip ( $response->content );
    } else {
      $response_as_content = $response->content;
    }

    if ( $debug >= 3 ) {
      print "\n", ref ($self), '::request: ()', "\n", $response->as_string, "\n\n";
    } elsif ( $debug >= 2 ) {
      print "\n", ref ($self), '::content: ()', "\n", $response_as_content, "\n\n";
    }

    my $responseTime = ${$self->{asnmtapInherited}}->setEndTime_and_getResponsTime ( ${$self->{asnmtapInherited}}->pluginValue ('endTime') );
    print ref ($self), '::response_time: ', $responseTime, " - $url\n" if ( $onDemand );
    ${$self->{asnmtapInherited}}->appendPerformanceData ( "'". $url_r->{Perfdata_Label} ."'=". $responseTime .'ms;;;;' ) if ( defined $url_r->{Perfdata_Label} );

    $self->_write_debugfile ( $request_as_string, $response_as_content, $debugfile, $openAppend ) if ( defined $debugfile );

    if ( $parms{fail_if_1} ) {
      unless ( $response->is_success or $response->is_redirect ) {
        my $response_as_request = $response->as_string;

        # Deal with __Can't__ from LWP.
        # Otherwise notification fails because /bin/sh is called to
        # printf '$OUTPUT' and sh cannot deal with nested quotes (eg Can't echo ''')
        $response_as_request =~ s#'#_#g;

        $returnCode = $ERRORS{CRITICAL};
        my $knownError = 0;
        my $errorMessage = "other than HTTP 200";

        for ( $response_as_request ) {
          # ***************************************************************************
          # The 500 series of Web error codes indicate an error with the Web server   *
          # ***************************************************************************

          # The server had some sort of internal error trying to fulfil the request. The client may see a partial page or error message.
          # It's a fault in the server and happens all too frequently.
          /500 Can_t connect to/       && do { $knownError = 1; $errorMessage = "500 Can't connect to ..."; $returnCode = $ERRORS{UNKNOWN}; last; };
          /500 Connect failed/         && do { $knownError = 1; $errorMessage = "500 Connect failed"; $returnCode = $ERRORS{UNKNOWN}; last; };
          /500 proxy connect failed/   && do { $knownError = 1; $errorMessage = "500 Proxy connect failed"; $returnCode = $ERRORS{UNKNOWN}; last; };
          /500 Server Error/           && do { $knownError = 1; $errorMessage = "500 Server Error"; $returnCode = $ERRORS{UNKNOWN}; last; };
          /500 SSL negotiation failed/ && do { $knownError = 1; $errorMessage = "500 SSL negotiation failed"; $returnCode = $ERRORS{UNKNOWN}; last; };
          /500 SSL read timeout/       && do { $knownError = 1; $errorMessage = "500 SSL read timeout"; $returnCode = $ERRORS{UNKNOWN}; last; };

          /Internal Server Error/      && do { $knownError = 0; $errorMessage = "500 Internal Server Error"; $returnCode = $ERRORS{UNKNOWN}; last; };

          # Function not implemented in Web server software. The request needs functionality not available on the server
          /501 (?:No Server|Not Implemented)/ && do { $errorMessage = "501 Not Implemented"; last; };

          # Bad Gateway: a server being used by this Web server has sent an invalid response.
          # The response by an intermediary server was invalid. This may happen if there is a problem with the DNS routing tables.
          /502 (?:Bad Gateway|Server Overload)/ && do { $knownError = 1; $errorMessage = "502 Bad Gateway"; last; };

          # Service temporarily unavailable because of currently/temporary overload or maintenance.
          /503 (?:Out of Resources|Service Unavailable)/ && do { $knownError = 1; $errorMessage = "503 Service Unavailable"; last; };

          # The server did not respond back to the gateway within acceptable time period
          /504 Gateway Time-?Out/ && do { $knownError = 1; $errorMessage = "504 Gateway Timeout"; last; };

          # The server does not support the HTTP protocol version that was used in the request message.
          /505 HTTP Version [nN]ot supported/ && do { $knownError = 1; $errorMessage = "505 HTTP Version Not Supported"; last; };

          # ***************************************************************************
          # The 400 series of Web error codes indicate an error with your Web browser *
          # ***************************************************************************

          # The request could not be understood by the server due to incorrect syntax.
          /400 Bad Request/ && do { $knownError = 1; $errorMessage = "400 Bad Request"; last; };

          # The client does not have access to this resource, authorization is needed
          /401 (?:Unauthorized|Authorization Required)/ && do { $knownError = 1; $errorMessage = "401 Unauthorized User"; last; };

          # Payment is required. Reserved for future use
          /402 Payment Required/ && do { $knownError = 1; $errorMessage = "402 Payment Required"; last; };

          # The server understood the request, but is refusing to fulfill it. Access to a resource is not allowed.
          # The most frequent case of this occurs when directory listing access is not allowed.
          /403 Forbidden/ && do { $knownError = 1; $errorMessage = "403 Forbidden Connection"; last; };

          # The resource request was not found. This is the code returned for missing pages or graphics.
          # Viruses will often attempt to access resources that do not exist, so the error does not necessarily represent a problem.
          /404 (?:Page )?Not Found/ && do { $knownError = 1; $errorMessage = "404 Page Not Found"; last; };

          # The access method (GET, POST, HEAD) is not allowed on this resource
          /405 Method Not Allowed/ && do { $knownError = 1; $errorMessage = "405 Method Not Allowed"; last; };

          # None of the acceptable file types (as requested by client) are available for this resource
          /406 Not Acceptable/ && do { $errorMessage = "406 Not Acceptable"; last; };

          # The client does not have access to this resource, proxy authorization is needed
          /407 Proxy Authentication Required/ && do { $knownError = 1; $errorMessage = "407 Proxy Authentication Required"; last; };

          # The client did not send a request within the required time period
          /408 Request Time(?:[- ])?[oO]ut/ && do { $knownError = 1; $errorMessage = "408 Request Timeout"; last; };

          # The request could not be completed due to a conflict with the current state of the resource.
          /409 Conflict/ && do { $knownError = 1; $errorMessage = "409 Conflict"; last; };

          # The requested resource is no longer available at the server and no forwarding address is known.
          # This condition is similar to 404, except that the 410 error condition is expected to be permanent.
          # Any robot seeing this response should delete the reference from its information store.
          /410 Gone/ && do { $knownError = 1; $errorMessage = "410 Gone"; last; };

          # The request requires the Content-Length HTTP request field to be specified
          /411 (?:Content )?Length Required/ && do { $knownError = 1; $errorMessage = "411 Length Required"; last; };

          # The precondition given in one or more of the request-header fields evaluated to false when it was tested on the server.
          /412 Precondition Failed/ && do { $knownError = 1; $errorMessage = "412 Precondition Failed"; last; };

          # The server is refusing to process a request because the request entity is larger than the server is willing or able to process.
          /413 Request Entity Too Large/ && do { $knownError = 1; $errorMessage = "413 Request Entity Too Large"; last; };

          # The server is refusing to service the request because the Request-URI is longer than the server is willing to interpret.
          # The URL is too long (possibly too many query keyword/value pairs)
          /414 Request[- ]URL Too Large/ && do { $knownError = 1; $errorMessage = "414 Request URL Too Large"; last; };

          # The server is refusing to service the request because the entity of the request is in a format not supported by the requested resource for the requested method.
          /415 Unsupported Media Type/  && do { $knownError = 1; $errorMessage = "415 Unsupported Media Type"; last; };

          # The portion of the resource requested is not available or out of range
          /416 Requested Range (?:Invalid|Not Satisfiable)/ && do { $knownError = 1; $errorMessage = "416 Requested Range Invalid"; last; };

          # The Expect specifier in the HTTP request header can not be met
          /417 Expectation Failed/ && do { $knownError = 1; $errorMessage = "417 Expectation Failed"; last; };
        }

        ${$self->{asnmtapInherited}}->pluginValues ( { stateValue => $returnCode, alert => "'". $errorMessage ."' - ". $url_r->{Msg}, error => &_error_message( $request->method .' '. $request->uri ), result => $response_as_content }, $TYPE{REPLACE} );
        $self->{_KnownError} = $debugfile if ( defined $debugfile and $knownError );
        $self->{_unknownErrors}++ unless ( $knownError );
        return ( $returnCode );
      }
    } else {
      $returnCode = $ERRORS{OK} if $response->is_success;
    }

    if ( $parms{custom} ) {
	  my ($returnCode, $knownError, $errorMessage) = $parms{custom}->( $response_as_content );

	  if ( $returnCode != $ERRORS{OK} and defined $errorMessage ) {
        ${$self->{asnmtapInherited}}->pluginValues ( { stateValue => $returnCode, alert => $errorMessage .' - '. $url_r->{Msg}, error => &_error_message ( $request->method .' '. $request->uri ), result => $response_as_content }, $TYPE{REPLACE} );
        $self->{_KnownError} = $debugfile if ( defined $debugfile and $knownError );
        $self->{_unknownErrors}++ unless ( $knownError );
        return ( $returnCode );
	  }
	}

    $self->_my_return ( $url_r->{Exp_Return}, $response_as_content );

    if ( $self->_my_match ( $url_r->{Exp_Fault}, $response_as_content, 0 ) ) {
      my $fault_ind = $url_r->{Exp_Fault};
      my ($bad_stuff) = $response_as_content =~ /($fault_ind.*\n.*\n)/;
      ${$self->{asnmtapInherited}}->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => $url_r->{Msg_Fault}, error => &_error_message ( $request->method .' '. $request->uri ), result => $bad_stuff }, $TYPE{REPLACE} );
      $self->{_unknownErrors}++;
      return ( $ERRORS{CRITICAL} );
    } elsif ( ! ($found = $self->_my_match ( $url_r->{Exp}, $response_as_content, 1 )) ) {
      my $exp_type = ref $url_r->{Exp};
      my $exp_str = $exp_type eq 'ARRAY' ? "@{$url_r->{Exp}}" : $url_r->{Exp};
      ${$self->{asnmtapInherited}}->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => "'". $url_r->{Msg} ."' - '". $exp_str ."' not in response", error => &_error_message ( $request->method .' '. $request->uri ), result => $response_as_content }, $TYPE{REPLACE} );
      $self->{_unknownErrors}++;
      return ( $ERRORS{CRITICAL} );
    } elsif (ref $url_r->{Exp} eq 'ARRAY') {
      my $exp_array = @{$url_r->{Exp}};

      if ( $exp_array != $found ) {
        ${$self->{asnmtapInherited}}->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => "'". $url_r->{Msg} ."' - '". ( $exp_array - $found ) ."' element(s) not in response", error => &_error_message ( $request->method .' '. $request->uri ), result => $response_as_content }, $TYPE{REPLACE} );
        $self->{_unknownErrors}++;
        return ( $ERRORS{CRITICAL} );
      }
    }

    if ( $parms{download_images} ) {
      my ($image_dl_nok, $image_dl_msg, $number_imgs_dl) = $self->_download_images ($response, \%parms, \%downloaded);

      if ( $image_dl_nok ) {
        ${$self->{asnmtapInherited}}->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => $image_dl_msg }, $TYPE{REPLACE} );
        $self->{_unknownErrors}++;
        return ( $ERRORS{CRITICAL} );
      }

      $self->{number_of_images_downloaded} += $number_imgs_dl;
    }
  }

  if ( defined $parms{perfdataLabel} and defined $startTime ) {
    my $responseTime = ${$self->{asnmtapInherited}}->setEndTime_and_getResponsTime ( $startTime );
    ${$self->{asnmtapInherited}}->appendPerformanceData ( "'". $parms{perfdataLabel} ."'=". $responseTime .'ms;;;;' );
  }

  ${$self->{asnmtapInherited}}->pluginValues ( { stateValue => $returnCode, alert => ( ( $parms{download_images} and ! $returnCode ) ? "downloaded $self->{number_of_images_downloaded} images" : undef ), error => ( $returnCode ? '?' : undef ), result => $response_as_content }, $TYPE{REPLACE} );
  return ( $returnCode );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _download_images {
  my ($self, $response, $parms_hr, $downloaded_hr) = @_;

  require HTML::LinkExtor;
  require URI::URL;
  URI::URL->import(qw(url));

  my @imgs = ();

  my $cb = sub {
    my ($tag, %attr) = @_;
    return if $tag ne 'img';           # we only look closer at <img ...>
    push (@imgs, $attr{src});
  };

  my $p = HTML::LinkExtor->new($cb);
  $p->parse($response->as_string);
  my $base = $response->base;
  my @imgs_abs = grep ! $downloaded_hr->{$_}++, map { my $x = url($_, $base)->abs; } @imgs;
  my @img_urls = map { Method => 'GET', Url => $_->as_string, Qs_var => [], Qs_fixed => [], Exp => '.', Exp_Fault => 'NeverInAnImage', Msg => '.', Msg_Fault => 'NeverInAnImage', Perfdata_Label => $_->as_string }, @imgs_abs;

  # url() returns an array ref containing the abs url and the base.
  if ( my $number_of_images_not_already_downloaded = scalar @img_urls ) {
    my $img_trx = __PACKAGE__->new( $self->{asnmtapInherited}, \@img_urls );
    my %image_dl_parms = (%$parms_hr, fail_if_1 => FALSE, download_images => FALSE);
    return ( $img_trx->check( {}, %image_dl_parms), 'Downloaded not all '. $number_of_images_not_already_downloaded .' images found in '. $response->base, $number_of_images_not_already_downloaded );
  } else {
    return ( $ERRORS{OK}, 'Downloaded all __zero__ images found in '. $response->base, 0 );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _make_request {
  my ($self, $method, $url, $qs_var_ar, $qs_fixed_ar, $name_vals_hr) = @_;

  # $qs_var_ar is an array reference containing the name value pairs of any parameters whose
  # value is known only at run time

  # the format of $qs_var_ar is [cgi_parm_name => val, cg_parm_name => val ..]
  # where cgi_parm_name is the name of a fill out form parameter and val is a string used as a
  # key in %$name_vals_hr to get the value of the cgi_parameter.

  # eg [p_tm_number, tmno] has the parameter name 'p_tm_number' and val 'tmno'.

  # If $name_vals_hr = { tmno = > 1 }, the query_sring becomes p_tm_number=1

  # when the val is a digit, that digit is interpreted as a relative match in the last
  # set of matches found by ->_my_match eg

  # [p_tm_number => 1] means get the second match (from the last set of matches)
  # and use it as the value of p_tm_number.

  # If the value is a array ref eg [p_tm_number, [0, sub { $_[0] .'Blah' }]
  # then the query_string becomes p_tm_number => $ar->[1]( $name_vals{$ar->[0]} )

  # qs_fixed is an array_ref containing name value pairs

  my ($request, $content_type, @query_string, $query_string, @qs_var, @qs_fixed, %name_vals, @nvp);
  my @matches = @{ $self->matches() };
  @qs_var = @$qs_var_ar;
  @qs_fixed = @$qs_fixed_ar;
  %name_vals = %$name_vals_hr;

  # add the matches as (over the top if some of the name_val keys are eq '0', '1' ..) keys to  %name_vals
  @name_vals {0 .. $#matches} = @matches;
  @query_string = ();
  @nvp = ();
  $query_string = '';
  $content_type = 0; # 'application/x-www-form-urlencoded'

  while ( my ($name, $val) = splice(@qs_fixed, 0, 2) ) {
	  splice(@query_string, scalar @query_string, 0, ($name, $val));
    $content_type = 1 if ( ref $val eq 'ARRAY' );
  }

  # a cgi var name must be in qs_var for it's value to be changed (otherwise it doesn't get in the form query string)

  while ( my ($name, $val) = splice(@qs_var, 0, 2) ) {
    @nvp = ref $val eq 'ARRAY' ? ( $name, &{ $val->[1] }($name_vals{$val->[0]}) ) : ( $name, $name_vals{$val} );
    splice ( @query_string, scalar @query_string, 0, @nvp );
  }

  if ( $method eq 'GET' ) {
    while ( my ($name, $val) = splice(@query_string, 0, 2) ) { $query_string .= "$name=$val&"; }

    if ($query_string) {
      chop($query_string);
      $request = GET $url .'?'. $query_string;
    } else {
      $request = GET $url;
    }
  } elsif ( $method eq 'POST' ) {
    if ( $content_type == 1 ) { # 'multipart/form-data'
      $request = POST $url, Content_Type => 'multipart/form-data', Content => [ @query_string ];
  	} else {
      $request = POST $url, [ @query_string ];
    }
  } elsif ( $method eq 'HEAD' ) {
    $request = HEAD $url;
  } else { # do something to indicate no such method
    &_dumpValue ( $self, ref $self .": Unexpected method \"$method\" for url \"$url\"" );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _my_match {
  my ($self, $pat, $str, $boolean) = @_;

  return $boolean if ( $str eq '' and ref $pat ne 'ARRAY' and $pat eq '...' );
  my $found = 0;
  my @matches = ();

  if ( ref $pat eq 'ARRAY' ) {
    my $debug = ${$self->{asnmtapInherited}}->getOptionsValue ( 'debug' );

    foreach my $p (@$pat) {
      print ref ($self) ."::_my_match: ? $p\n" if ( $debug >= 3 );

      if ( my @match = ($str =~ m#$p#) ) {
        print ref ($self) ."::_my_match: = @match\n" if ( $debug >= 3 );
        push (@matches, @match) if (scalar (@match));
        $found++;
      }
    }

    $self->matches ( \@matches );
  } else {
    $found = ($str =~ m#$pat#);
  }

  return $found;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _my_return {
  my ($self, $pat, $str) = @_;

  if ( ref $pat eq 'HASH') {
    my $debug = ${$self->{asnmtapInherited}}->getOptionsValue ( 'debug' );

    while ( my ($key, $value) = each ( %{$pat} ) ) {
      print ref ($self) ."::_my_return: ? $key => $value\n" if ( $debug >= 3 );

      if ( my @match = ($str =~ m#$value#g) ) {
        print ref ($self) ."::_my_return: = @match\n" if ( $debug >= 3 );
        $returns {$key} = (scalar (@match) == 1) ? $match[0] : [ @match ];
      } else {
        $returns {$key} = undef;
      }

      $self->returns ( \%returns );
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _write_debugfile {
  my ($self, $request_as_string, $response_as_content, $debugfile, $openAppend) = @_;

  my $rvOpen = open ( HTTPDUMP, ($openAppend ? '>>' : '>') .$debugfile );

  if ($rvOpen) {
    print HTTPDUMP '<HR>', $request_as_string, "\n";

    if ( defined $response_as_content ) {
      $response_as_content =~ s/(window.location.href)/\/\/$1/gi;

      # RFC 1738 -> [ $\/:;=?@.\-!*'()\w&+,]+
      $response_as_content =~ s/(<META\s+HTTP-EQUIV\s*=\s*\"Refresh\"\s+CONTENT\s*=\s*\"\d+;\s*URL\s*=[^"]+\"(?:\s+\/?)?>)/<!--$1-->/img;

      # remove password from Basic Authentication URL before putting into database!
      $response_as_content =~ s/(http[s]?)\:\/\/(\w+)\:(\w+)\@/$1\:\/\/$2\:********\@/img;

      # comment <SCRIPT></SCRIPT>
      $response_as_content =~ s/<SCRIPT/<!--<SCRIPT/gi;
      $response_as_content =~ s/<\/SCRIPT>/<\/SCRIPT>-->/gi;

      # replace <BODY onload="..."> with <BODY>
      $response_as_content =~ s/<BODY\s*onload\s*=\s*.*\s*>/<BODY>/gi;

      print HTTPDUMP '<HR>', $response_as_content, "\n";
    } else {
      print HTTPDUMP "<HR><B>Empty response</B>\n";
    }

    close(HTTPDUMP);
  } else {
    print ref ($self) .": Cannot open $debugfile to print debug information\n";
  }
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

sub _next_url {
  my ($response, $response_as_content) = @_;

  # FIXME. Some applications (eg IIS module for SAP R3) have an action field relative to hostname.
  # Others (eg ADDS v2) have use a refresh header with relative to hostname/path ..

  if ( $response_as_content =~ m#META\s+http-equiv="refresh"\s+content="\d+;\s+url=([^"]+)"# ) {
    my $rel_url = $1;
    my $base = $response->base;
    $base =~ m#(http://.+/).+?$#;
    my $url =  $1 . $rel_url;
    return $url;
  } elsif ( $response_as_content =~ m#form name="[^"]+"\s+method="post"\s+action="([^"]+)"#i or $response_as_content =~ m#form\s+method="post"\s+action="([^"]+)"#i ) {
    # Attachmate eVWP product doesn't have a form name.
    my $rel_url = $1;
    my $base = $response->base;
    $base =~ m#(http://.+?)/#;	 		            # only want hostname
    my $url =  $1 . $rel_url;
    return $url;
  } else {
    return '';
  }
}

# Destructor  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub DESTROY { 
  print (ref ($_[0]), "::DESTROY: ()\n") if ( ${$_[0]->{asnmtapInherited}}->getOptionsValue ( 'debug' ) );
  rename ( $_[0]->{_KnownError}, $_[0]->{_KnownError} .'-KnownError' ) if ( defined $_[0]->{_KnownError} and ! $_[0]->{_unknownErrors} );
  ${$_[0]->{asnmtapInherited}}->appendPerformanceData ( "'url timing retries'=". $_[0]->{_timing_tries} .';;;;' );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__END__

=head1 NAME

ASNMTAP::Asnmtap::Plugins::WebTransact is a Perl module that provides WebTransact functions used by ASNMTAP-based plugins.

=head1 DESCRIPTION

This module implements a check of a Web Transaction.

A Web transaction is a sequence of web pages, often fill out forms,
that accomplishes an enquiry or an update. Common examples are database
searches and registration activities.

=head1 AUTHOR

Stanley Hopcroft [Stanley.Hopcroft@IPAustralia.Gov.AU]
Alex Peeters [alex.peeters@citap.be]

=head1 COPYRIGHT NOTICE

(c) Copyright 2003-2004 Stanley.Hopcroft@IPAustralia.Gov.AU

ASNMTAP::Asnmtap::Plugins::WebTransact is based on 'Nagios::WebTransact' v0.14.1 & v0.16 from Stanley Hopcroft [Stanley.Hopcroft@IPAustralia.Gov.AU]

=head1 SEE ALSO

ASNMTAP::Asnmtap::Plugins::WebTransact.pod
