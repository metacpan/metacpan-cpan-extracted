package Apache2::Proxy;

use strict;
use warnings;

our $VERSION = 0.04;

=head1 NAME

Apache2::Proxy - a mod_perl based http proxy base class

=head1 SYNOPSIS

A mod_perl based HTTP proxy base class

=cut


use Apache2::Const -compile => qw( OK SERVER_ERROR NOT_FOUND DECLINED
  REDIRECT LOG_DEBUG LOG_ERR LOG_INFO CONN_KEEPALIVE HTTP_BAD_REQUEST
  HTTP_UNAUTHORIZED HTTP_SEE_OTHER HTTP_MOVED_PERMANENTLY DONE
  HTTP_NO_CONTENT HTTP_PARTIAL_CONTENT HTTP_NOT_MODIFIED );
use Apache2::Connection  ();
use Apache2::Log         ();
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::RequestIO   ();
use Apache2::Response    ();
use Apache2::ServerRec   ();
use Apache2::ServerUtil  ();
use Apache2::URI         ();
use Apache2::Filter      ();
use APR::Table           ();

use Compress::Zlib ();
use Compress::Bzip2 ();
use Encode ();

use URI;
use Net::HTTP;
use HTTP::Response;
use HTTP::Headers;
use HTTP::Headers::Util ();
use Data::Dumper;
use Net::DNS;
our $Resolver = Net::DNS::Resolver->new;

use constant DEBUG         => 1;
use constant VERBOSE_DEBUG => 0;

use constant MAX_CONTENT_LENGTH => 131072;    # 128k

# firefox default headers
our %Headers = (
    'Accept-Encoding' => 'gzip,deflate',
    'Accept-Charset'  => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
    'Accept-Lang'     => 'en-us,en;q=0.5',
    'Accept' =>
'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
    'User-Agent' =>
'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.10) Gecko/2009042315 Firefox/3.0.10',
);

our %Response = (
    200 => 'twohundred',
    204 => 'twoohfour',
    206 => 'twoohsix',
    301 => 'threeohone',
    302 => 'redirect',
    303 => 'redirect',
    304 => 'threeohfour',
    307 => 'redirect',
    400 => 'bsod',
    401 => 'bsod',
    403 => 'bsod',
    404 => 'bsod',
    410 => 'bsod',
    500 => 'bsod',
    502 => 'bsod',
    503 => 'bsod',
    504 => 'bsod',
);

# handles common proxy functions

# takes $r and returns the http headers

sub get_request_headers {
    my ( $class, $r ) = @_;

    my %headers;
    $r->headers_in->do(
        sub {
            my $k = shift;
            my $v = shift;

            if ( $k =~ m/^connection/i ) {
                $headers{$k} = 'keep-alive';
                return 1;
            }

            # pass this header onto the remote request
            $headers{$k} = $v;

            return 1;    # don't remove me or you will burn in hell baby
        }
    );

    # work around clients which don't support compression
    if ( !exists $headers{'Accept-Encoding'} ) {
        $r->log->debug(
            "$$ client DOES NOT support compression " . Dumper( \%headers ) )
          if VERBOSE_DEBUG;

        # set default outgoing compression headers
        $headers{'Accept-Encoding'} = 'gzip, deflate';
    }
    else {
        $r->log->debug(
            "$$ client supports compression " . $headers{'Accept-Encoding'} )
          if VERBOSE_DEBUG;
        $r->pnotes(
            client_supports_compression => $headers{'Accept-Encoding'} );
    }

    $r->log->debug( "$$ proxy request headers " . Dumper( \%headers ) )
      if DEBUG;

    return \%headers;
}

# Takes an HTTP::Response object, clears the response headers,
# adds cookie and auth headers, and additional headers
# Sets the Server header to sl if it is not defined.

sub set_response_headers {
    my ( $class, $r, $res ) = @_;

    #############################
    # clear the current headers
    $r->headers_out->clear();

    $class->translate_cookie_and_auth_headers( $r, $res );

    #########################
    # Create a hash with the remaining HTTP::Response HTTP::Headers attributes
    my %headers;
    $res->scan( sub { $headers{ $_[0] } = $_[1]; } );

    ##########################################
    # this is for any additional headers, usually site specific
    $class->translate_remaining_headers( $r, \%headers );

    # set the server header
    $headers{Server} ||= __PACKAGE__;
    $r->log->debug( "$$ server header is " . $headers{Server} )
      if VERBOSE_DEBUG;
    $r->server->add_version_component( $headers{Server} );

    return 1;
}

sub translate_remaining_headers {
    my ( $class, $r, $headers ) = @_;

    foreach my $key ( keys %{$headers} ) {

        # we set this manually
        next if lc($key) eq 'server';

        # skip HTTP::Response inserted headers
        next if substr( lc($key), 0, 6 ) eq 'client';

        # let apache set these
        next if substr( lc($key), 0, 10 ) eq 'connection';
        next if substr( lc($key), 0, 10 ) eq 'keep-alive';

        # some headers have an unecessary newline appended so chomp the value
        chomp( $headers->{$key} );
        if ( $headers->{$key} =~ m/\n/ ) {
            $headers->{$key} =~ s/\n/ /g;
        }

        $r->log->debug(
            "$$ Setting header key $key, value " . $headers->{$key} )
          if VERBOSE_DEBUG;
        $r->headers_out->set( $key => $headers->{$key} );
    }

    return 1;
}

sub translate_cookie_and_auth_headers {
    my ( $class, $r, $res ) = @_;

    ################################################
    # process the www-auth and set-cookie headers
    no strict 'refs';
    foreach my $header_type qw( set-cookie www-authenticate ) {
        next unless defined $res->header($header_type);

        my @headers = $res->header($header_type);
        foreach my $header (@headers) {
            $r->log->debug("$$ setting header $header_type value $header")
              if VERBOSE_DEBUG;
            $r->err_headers_out->add( $header_type => $header );
        }

        # and remove it from the response headers
        my $removed = $res->headers->remove_header($header_type);
        $r->log->debug("$$ translated $removed $header_type headers")
          if VERBOSE_DEBUG;
    }

    return 1;
}

sub set_twohundred_response_headers {
    my ( $class, $r, $res, $response_content_ref ) = @_;


    $r->log->debug("setting response headers " . Dumper($res->headers)) if DEBUG;

    # This loops over the response headers and adds them to headers_out.
    # Override any headers with our own here
    my %headers;
    $r->headers_out->clear();

    $class->translate_cookie_and_auth_headers( $r, $res );

    # Create a hash with the HTTP::Response HTTP::Headers attributes
    $res->scan( sub { $headers{ $_[0] } = $_[1]; } );
    $r->log->debug(
        sprintf( "$$ not cookie/auth headers: %s", Dumper( \%headers ) ) )
      if VERBOSE_DEBUG;

    ## Set the response content type from the request, preserving charset
    $r->content_type( $headers{'Content-Type'} );
    delete $headers{'Content-Type'};

    # need to encode content if utf-8
    my $charset = $class->response_charset($r, $res);
    $r->log->debug("$$ charset is $charset") if DEBUG;
    if (($charset ne 'ISO-8859-1') && ($r->content_type !~ m/image|video/)) {
        $$response_content_ref = Encode::encode($charset,
            $$response_content_ref);
    }       

    #############################
    ## Content languages
    if ( defined $headers{'content-language'} ) {
        $r->content_languages( [ $res->header('content-language') ] );
        $r->log->debug(
            "$$ content languages set to " . $res->header('content_language') )
          if DEBUG;
        delete $headers{'Content-Language'};
    }

    ##################
    # content_encoding
    # do not mess with this next section unless you like pain
    my $encoding;
    if (($r->content_type !~ m/image|video/) &&
        ((length($$response_content_ref) != 0) or
        ($headers{'Content-Length'} != 0)) &&
        ( $r->pnotes('client_supports_compression') )) {

        $r->log->debug( "$$ client supports compression: "
              . $r->pnotes('client_supports_compression') )
          if DEBUG;

        my @h =
          map { $_->[0] }
          HTTP::Headers::Util::split_header_words(
            $r->pnotes('client_supports_compression') );
        $r->log->debug( "$$ header words are " . join( ',', @h ) )
          if VERBOSE_DEBUG;

        # use the first acceptable compression, ordered by
        if ( grep { $_ eq 'x-bzip2' } @h ) {

            $response_content_ref =
              Compress::Bzip2::compress($$response_content_ref);
            $encoding = 'x-bzip2';

        }
        elsif (( grep { $_ eq 'gzip' } @h )
            || ( grep { $_ eq 'x-gzip' } @h ) )
        {    # some parts lifted from HTTP::Message

            # need a copy for memgzip, see HTTP::Message notes
            my $gzipped =
              eval { Compress::Zlib::memGzip($response_content_ref); };

            my $err = $@;
            if ($err) {
                $r->log->error("compression error: $err");
            } else {

                $r->log->debug("$$ compressed response from " . length($$response_content_ref) . " to " . length($gzipped)) if DEBUG;
                $$response_content_ref = $gzipped;
                $encoding              = 'gzip';
            }

        }
        elsif ( grep { $_ eq 'deflate' } @h ) {

            my $copy = $$response_content_ref;
            $$response_content_ref = Compress::Zlib::compress($copy);
            $encoding              = 'deflate';

        }
        else {
            $r->log->error( "$$ unknown content-encoding encountered:  "
                  . join( ',', @h ) );
        }
    }

    if ($encoding) {
        $r->log->debug("$$ setting content encoding to $encoding") if DEBUG;
        $r->content_encoding($encoding);
        delete $headers{'Transfer-Encoding'};    # don't want to be chunked here
    }
    delete $headers{'Content-Encoding'};

    ###########################
    # set the content length to the uncompressed content length
    $r->set_content_length( length($$response_content_ref) );
    delete $headers{'Content-Length'};

    ##########################################
    # this is for any additional headers, usually site specific
    $class->translate_remaining_headers( $r, \%headers );

    ###############################
    # possible through a nasty hack, set the server version
    $r->server->add_version_component( $headers{Server} || 'sl' );

    ###############################
    # maybe someday but not today, do not cache this response
    $r->no_cache(1);

    return 1;
}

# figure out what charset a response was made in, code adapted from
# HTTP::Message::decoded_content
sub response_charset {
    my ( $class, $r, $response ) = @_;

    # pull apart Content-Type header and extract charset
    my $charset;
    my @ct = HTTP::Headers::Util::split_header_words(
        $response->header("Content-Type") );
    if (@ct) {
        my ( undef, undef, %ct_param ) = @{ $ct[-1] };
        $charset = $ct_param{charset};
    }

    # if the charset wasn't in the http header look for meta-equiv
    unless ($charset) {

        # default charset for HTTP::Message - if it couldn't guess it will
        # have decoded as 8859-1, so we need to match that when
        # re-encoding
        return $charset || "ISO-8859-1";
    }
}

sub resolve {
    my ( $class, $hostname ) = @_;

    # run the dns query
    my $query = $Resolver->query($hostname);
    unless ($query) {

        die "dns resolution failed: " . $Resolver->errorstring;

    }
    else {

        foreach my $rr ( $query->answer ) {

            next unless $rr->type eq "A";

            # return the A record
            return $rr->address;
        }
    }

    die "could not resolve A record for $hostname";
}

sub handler {
    my ( $class, $r ) = @_;

    unless ($r->hostname) {
        $r->log->error("$$ no hostname for req " . $r->as_string);
        return Apache2::Const::HTTP_BAD_REQUEST;
    }

    # Build the request headers
    my $headers = $class->get_request_headers($r);

    my $url = $r->construct_url($r->unparsed_uri);
    $r->pnotes('url' => $url);

    my %get = (
        headers      => $headers,
        url          => $url,
    );

    my $ip;
    if ($r->hostname !~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {

        $r->log->debug( "$$ resolving host " . $r->hostname ) if DEBUG;
        $ip = eval { $class->resolve( $r->hostname ) };
        if ($@) {

            # dns error
            $r->log->error( "$$ unable to resolve host " . $r->hostname );
            return &crazypage($r);    # haha this page is kwazy!

        }
    } else {
        $ip = $r->hostname
    }

    $get{host} = $ip;
    $r->log->debug( "$$ making proxy request " . Dumper( \%get ) ) if DEBUG;

    # Make the request to the remote server
    my $response = eval { $class->get( \%get ); };

    # socket timeout, give em the crazy page
    if ($@) {
        $r->log->error("$$ error fetching $url : $@") if DEBUG;
        return &crazypage($r);    # haha this page is kwazy!
    }

    $r->log->debug("$$ request to $url complete") if DEBUG;

    # no response means html too big
    # send it to perlbal to reproxy
    unless ($response) {

        $r->log->error("$$ no response") if DEBUG;
        return Apache2::Const::NOT_FOUND;
    }

    $r->log->debug( "$$ Response headers from url $url proxy request code\n" 
          . "code: "
          . $response->code . "\n"
          . Dumper( $response->headers ) )
      if VERBOSE_DEBUG;

    # Dispatch the response
    my $sub = $Response{ $response->code };
    unless ( defined $sub ) {
        $r->log->error(
            sprintf(
                "No handler for response code %d, url %s, ua %s",
                $response->code, $url, $r->pnotes('ua')
            )
        );
        $sub = $Response{'404'};
    }

    $r->log->debug(
        sprintf(
            "$$ Request returned %d response: %s",
            $response->code, Dumper( $response->decoded_content ),
        )
    ) if VERBOSE_DEBUG;

    no strict 'refs';
    return $class->$sub( $r, $response );
}

# this page handles invalid urls, we run ads there

sub crazypage {
    my $r = shift;

    $r->content_type('text/html');
    $r->print( "<html><body><h2>Sorry the url "
          . $r->construct_url($r->unparsed_uri)
          . ' is not a valid hostname, please try again.</h2></body></html>' );
    return Apache2::Const::OK;
}

sub twoohfour {
    my ( $class, $r, $res ) = @_;

    # status line 204 response
    $r->status( $res->code );

    # translate the headers from the remote response to the proxy response
    my $translated = $class->set_response_headers( $r, $res );

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    # no content sent for a 204
    return Apache2::Const::OK;
}

sub twoohsix {
    my ( $class, $r, $res ) = @_;

    # set the status line here and I will beat you with a stick

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    # translate the headers from the remote response to the proxy response
    my $translated = $class->set_response_headers( $r, $res );

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    $r->print( $res->content );

    # we send a 200 here so don't change this or mess with the status line!
    return Apache2::Const::OK;
}

sub bsod {
    my ( $class, $r, $res ) = @_;

    # setup response
    $r->status( $res->code );

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    # translate the headers from the remote response to the proxy response
    my $translated = $class->set_response_headers( $r, $res );

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    $r->print( $res->content );

    return Apache2::Const::OK;
}

sub threeohone {
    my ( $class, $r, $res ) = @_;

    my $content_type = $res->content_type;
    $r->content_type($content_type) if $content_type;

    # translate the headers from the remote response to the proxy response
    my $translated = $class->set_response_headers( $r, $res );

    # do not change this line
    return Apache2::Const::HTTP_MOVED_PERMANENTLY;
}

# 302, 303, 307
sub redirect {
    my ( $class, $r, $res ) = @_;

    # translate the headers from the remote response to the proxy response
    my $translated = $class->set_response_headers( $r, $res );

    # do not change this line
    return Apache2::Const::REDIRECT;
}

sub threeohfour {
    my ( $class, $r, $res ) = @_;

    # set the status line
    $r->status( $res->code );

    # translate the headers from the remote response to the proxy response
    my $translated = $class->set_response_headers( $r, $res );

    # do not change this line
    return Apache2::Const::OK;
}

# the big dog
sub twohundred {
    my ( $class, $r, $response, $subref ) = @_;

    my $url = $r->pnotes('url');

    if ( $response->is_html ) {

        #$Cache->add_known_html( $url => $response->content_type );

    }
    else {

        #$Cache->add_known_not_html( $url => $response->content_type );
    }

    $r->log->debug( "$$ 200 for $url, length "
          . length( $response->decoded_content )
          . " bytes" )
      if DEBUG;

    my $response_content_ref = \$response->decoded_content;

    # set the status line
    $r->status_line( $response->status_line );
    $r->log->debug( "$$ status line is " . $response->status_line )
      if DEBUG;

    # set the response headers
    my $set_ok =
      $class->set_twohundred_response_headers( $r, $response,
        $response_content_ref );

    if (VERBOSE_DEBUG) {
        $r->log->debug( "$$ Response content: " . $$response_content_ref );
    }

    # rflush() flushes the headers to the client
    # thanks to gozer's mod_perl for speed presentation
    $r->rflush();

    my $bytes_sent = $r->print($$response_content_ref);
    $r->log->debug("$$ bytes sent: $bytes_sent") if DEBUG;

    return Apache2::Const::DONE;
}

sub get {
    my ( $class, $args_ref ) = @_;
    unless ( $args_ref->{url} ) {
        warn("$$ no url passed, returning");
        return;
    }
    my $url  = $args_ref->{url};
    my $host = $args_ref->{host} || $args_ref->{headers}->{Host} || 'localhost';
    my $port = $args_ref->{port} || 80;

    $url = URI->new($url) or die("Unable to parse url '$url'.");

    my $headers = $args_ref->{headers} || \%Headers;

    # convert headers to array-ref if a hash-ref is passed
    $headers = [%$headers] if ( ref $headers eq 'HASH' );

    my $http = Net::HTTP->new(
        Host     => $url->host,
        PeerAddr => $host,
        PeerPort => $port
    ) || die $@;

    # set keep alive
    $http->keep_alive(1);

    # reinforce the point (Net::HTTP adds PeerPort to host during
    # new())
    $http->host( $url->host );

    # make the request
    my $req = $url->path_query || "/";
    my $ok = $http->write_request( GET => $req, @$headers );

    # get the result code, message and response headers
    my ( $code, $mess, @headers_out ) = $http->read_response_headers;

    # read response body
    my $body = "";
    my $response = _build_response( $code, $mess, \@headers_out, \$body );

    # is this response too big?
    my $content_length = $response->headers->header('Content-Length') || 0;
    return if ( $content_length > MAX_CONTENT_LENGTH );

    while (1) {

        my $buf;
        my $n = $http->read_entity_body( $buf, 10240 );
        die "read failed: $!" unless defined $n;
        last unless $n;
        $body .= $buf;

        return if ( length($body) > MAX_CONTENT_LENGTH );
    }

    $response->content_ref( \$body );
    return $response;
}

# turns data returned by Net::HTTP into a HTTP::Response object
sub _build_response {
    my ( $code, $mess, $header_list, $body_ref ) = @_;

    my $header = HTTP::Headers->new(@$header_list);

    my $response = HTTP::Response->new( $code, $mess, $header, $$body_ref );
    return $response;
}

# adds a convenient extra method for inspection
{
    no warnings;
    *HTTP::Response::is_html = sub {
        return 1 if ( shift->content_type =~ m/text\/html/ );
        return;
    };

    *HTTP::Response::should_compress = sub {
        $" = '|';
        my @compressibles
          ;    # = qw( text/html text/xml text/plain application/pdf );
        return 1 if ( shift->content_type =~ m/(?:@compressibles)/ );
        return;
    };
}

=head1 COPYRIGHT

Copyright 2012 Red Hot Penguin Consulting LLC

=head1 LICENSE

This software is licensed under the same terms as Perl itself.

=head1 SEE ALSO

mod_perl

=cut


1;

