package AnyEvent::HTTP::LWP::UserAgent;
{
  $AnyEvent::HTTP::LWP::UserAgent::VERSION = '0.10';
}

use strict;
use warnings;

#ABSTRACT: LWP::UserAgent interface but works using AnyEvent::HTTP


use parent qw(LWP::UserAgent);

use AnyEvent 5;           # AE syntax
use AnyEvent::HTTP 2.1;   # http(s)/1.1
use HTTP::Response;
use LWP::UserAgent 5.815; # first version with handlers


sub conn_cache {
    my $self = shift;

    my $res = $self->SUPER::conn_cache(@_);
    my $cache = $self->SUPER::conn_cache;
    if ($cache) {
        my $total_capacity = $cache->total_capacity;
        $total_capacity = 100_000 unless(defined($total_capacity));
        $AnyEvent::HTTP::ACTIVE = $total_capacity;
    }

    return $res;
}


sub simple_request_async {
    my ($self, $in_req, $arg, $size) = @_;

    my ($method, $uri_ref, $args) = $self->lwp_request2anyevent_request($in_req);

    my $cv = AE::cv;
    my $out_req;
    my $content = '';
    my $fh;
    if(!ref($arg) && defined($arg) && length($arg)) {
        open $fh, '>', $arg or $cv->croak("Can't write to '$arg': $!");
        binmode $fh;
        $args->{on_body} = sub {
            my ($d, $h) = @_;
            if($out_req->code < 200 || 300 <= $out_req->code) { # not success
                $content .= $d;
            } else {
                print $fh $d or $cv->croak("Can't write to '$arg': $!");
            }
            return 1;
        };
    } elsif(ref($arg) eq 'CODE') {
        $args->{on_body} = sub {
            my ($d, $h) = @_;
            if($out_req->code < 200 || 300 <= $out_req->code) { # not success
                $content .= $d;
            } else {
                eval { $arg->($d, $out_req, undef) };
                my $err = $@;
                if($err) {
                    chomp $err;
                    $out_req->header('X-Died' => $err);
                    $out_req->header('Client-Aborted' => 'die');
                    return 0;
                }
            }
            return 1;
        };
    }
    my $header_init = sub {
        my ($d, $h) = @_;

        # special AnyEvent::HTTP's headers
        my $code = delete $h->{Status};
        my $message = delete $h->{Reason};

        # Now we don't use in any place this AnyEvent::HTTP pseudo-headers, so
        # just delete it
        for (qw/HTTPVersion OrigStatus OrigReason Redirect URL/) {
            delete $h->{$_};
        }

        # AnyEvent::HTTP join headers by comma
        # in this header exists many times in response.
        # It is some trie to split such headers, I need
        # to read RFCs more carefully.
        my $headers = HTTP::Headers->new;
        while (my ($header, $value) = each %$h) {
            # In previous versions it was a place where heavily used
            # Coro stack (if Coro used) when you had pseudo-header URL
            # and URL was really big.
            # Now it's not such a big problem, we delete URL pseudo-header
            # and haven't sudden gigantous headers (I hope).
            my @v = $value =~ /^([^ ].*?[^ ],)*([^ ].*?[^ ])$/;
            @v = grep { defined($_) } @v;
            if (scalar(@v) > 1) {
                @v = map { s/,$//; $_ } @v;
                $value = \@v;
            }
            $headers->header($header => $value);
        }

        # special AnyEvent::HTTP codes
        if ($code >= 590 && $code <= 599) {
            # make LWP-compatible error in the case of timeout
            if ($message =~ /timed/ && $code == 599) {
                $d = '500 read timeout';
                $code = 500;
            } elsif (!defined($d) || $d =~ /^\s*$/) {
                $d = $message;
            }
        }
        $out_req = HTTP::Response->new($code, $message, $headers, $d);

        $self->run_handlers(response_header => $out_req);

        return 1;
    };
    $args->{on_header} = sub {
        my ($h) = @_;
        $header_init->(undef, $h);
    };

    http_request $method => $$uri_ref, %$args, sub {
        my ($d, $h) = @_;
        $d = $content if $content ne '';
        $header_init->($d, $h) if ! defined $out_req;
        $out_req->content($d) if defined $d;
        close($fh) or $cv->croak("Can't write to '$arg': $!") if defined ($fh);

        if(defined($d) && length($d)) {
            # from LWP::Protocol
            my %skip_h;
            for my $h ($self->handlers('response_data', $out_req)) {
                next if $skip_h{$h};
                unless ($h->{callback}->($out_req, $self, $h, $d)) {
                    # XXX remove from $response->{handlers}{response_data} if present
                    $skip_h{$h}++;
                }
            }
        }

        $out_req->request($in_req);

        # cookie_jar will be set by the handler
        $self->run_handlers(response_done => $out_req);

        $cv->send($out_req);
    };

    return $cv;
}

sub simple_request {
    return shift->simple_request_async(@_)->recv;
}

sub get_async {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request_async( HTTP::Request::Common::GET( @parameters ), @suff );
}


sub post_async {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters, (ref($parameters[1]) ? 2 : 1));
    return $self->request_async( HTTP::Request::Common::POST( @parameters ), @suff );
}


sub head_async {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request_async( HTTP::Request::Common::HEAD( @parameters ), @suff );
}


sub put_async {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters, (ref($parameters[1]) ? 2 : 1));
    return $self->request_async( HTTP::Request::Common::PUT( @parameters ), @suff );
}


sub delete_async {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request_async( HTTP::Request::Common::DELETE( @parameters ), @suff );
}

sub get {
    return shift->get_async(@_)->recv;
}

sub post {
    return shift->post_async(@_)->recv;
}

sub head {
    return shift->head_async(@_)->recv;
}

sub put {
    return shift->put_async(@_)->recv;
}

sub delete {
    return shift->delete_async(@_)->recv;
}

sub lwp_request2anyevent_request {
    my ($self, $in_req) = @_;

    my $method = $in_req->method;
    my $uri = $in_req->uri->as_string;

    if ($self->cookie_jar) {
        $self->cookie_jar->add_cookie_header($in_req);
    }

    my $in_headers = $in_req->headers;
    my $out_headers = {};
    $in_headers->scan( sub {
        my ($header, $value) = @_;
        $out_headers->{$header} = $value;
    } );

    # if we will use some code like
    #    local $AnyEvent::HTTP::USERAGENT = $useragent;
    # in simple_request, it will not work properly in redirects
    $out_headers->{'User-Agent'} = $self->agent;

    my $body;
    if(ref($in_req->content) eq 'CODE') {
        # Minimum coderef support
        # TODO: Add chunked transfer but maybe necessary to modify AnyEvent::HTTP itself
        $body = '';
        while(my $ret = $in_req->content->()) {
            $body .= $ret;
            last if $ret eq '';
        }
    } else {
        $body = $in_req->content;
    }

    my %args = (
        headers => $out_headers,
        body    => $body,
        recurse => 0, # because LWP call simple_request as much as needed
        timeout => $self->timeout,
    );
    if ($self->conn_cache) {
        $args{persistent} = 1;
        $args{keepalive} = 1;
    } else {
        # By default AnyEvent::HTTP set persistent = 1 for idempotent
        # requests. So just for compatibility with LWP::UserAgent we
        # disable this options.
        $args{persistent} = 0;
        $args{keepalive} = 0;
    }
    return ($method, \$uri, \%args);
}

sub request_async
{
    my($self, $request, $arg, $size, $previous) = @_;

    my $cv = AE::cv;
    $self->simple_request_async($request, $arg, $size)->cb(sub {
    my $response = shift->recv;
    $response->previous($previous) if $previous;

    if ($response->redirects >= $self->{max_redirect}) {
        $response->header("Client-Warning" =>
                          "Redirect loop detected (max_redirect = $self->{max_redirect})");
        $cv->send($response); return;
    }

    if (my $req = $self->run_handlers("response_redirect", $response)) {
        $self->request_async($req, $arg, $size, $response)->cb(sub { $cv->send(shift->recv) }); return;
    }

    my $code = $response->code;

    if ($code == &HTTP::Status::RC_MOVED_PERMANENTLY or
	$code == &HTTP::Status::RC_FOUND or
	$code == &HTTP::Status::RC_SEE_OTHER or
	$code == &HTTP::Status::RC_TEMPORARY_REDIRECT)
    {
	my $referral = $request->clone;

	# These headers should never be forwarded
	$referral->remove_header('Host', 'Cookie');

	if ($referral->header('Referer') &&
	    $request->uri->scheme eq 'https' &&
	    $referral->uri->scheme eq 'http')
	{
	    # RFC 2616, section 15.1.3.
	    # https -> http redirect, suppressing Referer
	    $referral->remove_header('Referer');
	}

	if ($code == &HTTP::Status::RC_SEE_OTHER ||
	    $code == &HTTP::Status::RC_FOUND)
        {
	    my $method = uc($referral->method);
	    unless ($method eq "GET" || $method eq "HEAD") {
		$referral->method("GET");
		$referral->content("");
		$referral->remove_content_headers;
	    }
	}

	# And then we update the URL based on the Location:-header.
	my $referral_uri = $response->header('Location');
	{
	    # Some servers erroneously return a relative URL for redirects,
	    # so make it absolute if it not already is.
	    local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;
	    my $base = $response->base;
	    $referral_uri = "" unless defined $referral_uri;
	    $referral_uri = $HTTP::URI_CLASS->new($referral_uri, $base)
		            ->abs($base);
	}
	$referral->uri($referral_uri);

	if($self->redirect_ok($referral, $response)) {
	    $self->request_async($referral, $arg, $size, $response)->cb(sub{ $cv->send(shift->recv) }); return;
	} else {
	    $cv->send($response); return;
	}

    }
    elsif ($code == &HTTP::Status::RC_UNAUTHORIZED ||
	     $code == &HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED
	    )
    {
	my $proxy = ($code == &HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED);
	my $ch_header = $proxy ?  "Proxy-Authenticate" : "WWW-Authenticate";
	my @challenge = $response->header($ch_header);
	unless (@challenge) {
	    $response->header("Client-Warning" =>
			      "Missing Authenticate header");
	    $cv->send($response); return;
	}

	require HTTP::Headers::Util;
	CHALLENGE: for my $challenge (@challenge) {
	    $challenge =~ tr/,/;/;  # "," is used to separate auth-params!!
	    ($challenge) = HTTP::Headers::Util::split_header_words($challenge);
	    my $scheme = shift(@$challenge);
	    shift(@$challenge); # no value
	    $challenge = { @$challenge };  # make rest into a hash

	    unless ($scheme =~ /^([a-z]+(?:-[a-z]+)*)$/) {
		$response->header("Client-Warning" =>
				  "Bad authentication scheme '$scheme'");
		$cv->send($response); return;
	    }
	    $scheme = $1;  # untainted now
	    my $class = "LWP::Authen::\u$scheme";
	    $class =~ s/-/_/g;

	    no strict 'refs';
	    unless (%{"$class\::"}) {
		# try to load it
		eval "require $class";
		if ($@) {
		    if ($@ =~ /^Can\'t locate/) {
			$response->header("Client-Warning" =>
					  "Unsupported authentication scheme '$scheme'");
		    }
		    else {
			$response->header("Client-Warning" => $@);
		    }
		    next CHALLENGE;
		}
	    }
	    unless ($class->can("authenticate")) {
		$response->header("Client-Warning" =>
				  "Unsupported authentication scheme '$scheme'");
		next CHALLENGE;
	    }
# TODO: Maybe able to be more asynchronous
	    $cv->send($class->authenticate($self, $proxy, $challenge, $response,
					$request, $arg, $size)); return;
	}
	$cv->send($response); return
    }
    $cv->send($response); return;
    });
    return $cv;
}

sub request
{
    return shift->request_async(@_)->recv;
}

1;

__END__

=pod

=head1 NAME

AnyEvent::HTTP::LWP::UserAgent - LWP::UserAgent interface but works using AnyEvent::HTTP

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  use AnyEvent::HTTP::LWP::UserAgent;
  use Coro;

  my $ua = AnyEvent::HTTP::LWP::UserAgent->new;
  my @urls = (...);
  my @coro = map {
      my $url = $_;
      async {
          my $r = $ua->get($url);
          print "url $url, content " . $r->content . "\n";
      }
  } @urls;
  $_->join for @coro;

  # Or without Coro
  use AnyEvent::HTTP::LWP::UserAgent;
  use AnyEvent;

  my $ua = AnyEvent::HTTP::LWP::UserAgent->new;
  my @urls = (...);
  my $cv = AE::cv;
  $cv->begin;
  foreach my $url (@urls) {
      $cv->begin;
      $ua->get_async($url)->cb(sub {
          my $r = shift->recv;
          print "url $url, content " . $r->content . "\n";
          $cv->end;
      });
  }
  $cv->end;
  $cv->recv;

=head1 DESCRIPTION

When you use Coro you have a choice: you can use L<Coro::LWP> or L<AnyEvent::HTTP>
(if you want to make asynchronous HTTP requests).
If you use Coro::LWP, some modules may work incorrectly (for example Cache::Memcached)
because of global change of IO::Socket behavior.
AnyEvent::HTTP uses different programming interface, so you must change more of your
old code with LWP::UserAgent (and HTTP::Request and so on), if you want to make
asynchronous code.

AnyEvent::HTTP::LWP::UserAgent uses AnyEvent::HTTP inside but have an interface of
LWP::UserAgent.
You can safely use this module in Coro environment (and possibly in AnyEvent too).

In plain AnyEvent, you may use _async methods.
They don't make blocking wait but return condition variable.
So, you can avoid recursive blocking wait error.

=head1 SOME METHODS

=over

=item $ua->conn_cache

=item $ua->conn_cache($cache_obj)

New versions of C<AnyEvent::HTTP> supports HTTP(S)/1.1 persistent connection, so
you can control it in C<AnyEvent::HTTP::LWP::UserAgent> using C<conn_cache> method.

If you set C<conn_cache> (as C<LWP::ConnCache> object) then
C<Anyevent::HTTP::LWP::UserAgent> makes two things. In first it sets global variable
C<$AnyEvent::HTTP::ACTIVE> as you setted C<total_capacity> for C<conn_cache> (be careful:
this have a global consequences, not local). And in the second C<AnyEvent::HTTP::LWP::UserAgent>
will create persistent connections if your C<$ua> have C<conn_cache> (local propery of C<$ua>).

But you can't use remainder methods of your C<conn_cache>, all connections will
contains in C<AnyEvent::HTTP>. C<$AnyEvent::HTTP::ACTIVE> sets only when you set
C<conn_cache> for C<$ua>. If you just change C<total_capacity> of old C<conn_cache>
it will not change anything.

=back

=head1 ASYNC METHODS

The following methods are async version of corresponding methods w/o _async suffix.
Parameters are identical as originals.
However, return value becomes condition variable.
You can use it in a synchronous way by blocking wait

  $ua->simple_request_async(@args)->recv

or in an asynchronous way, also.

  $ua->simple_request_async(@args)->cb(sub { ... });

=over 4

=item simple_request_async

=item request_async

=item get_async

=item post_async

=item head_async

=item put_async

=item delete_async

=back

=head1 LIMITATIONS AND DETAILS

Some features of LWP::UserAgent can be broken (C<protocols_forbidden> or something else).
Precise documentation and realization of these features will come in the future.

You can use some AnyEvent::HTTP global function and variables.
But use C<agent> of UA instead of C<$AnyEvent::HTTP::USERAGENT> and C<max_redirect>
instead of C<$AnyEvent::HTTP::MAX_RECURSE>.

Content in request can be specified by code reference.
This is the same as L<LWP::UserAgent> but there are some limitations.
L<LWP::UserAgent> uses chunked encoding if Content-Length is not specified,
while this module does NOT use chunked encoding even if Content-Length is not specified.

Content in response can be specified as filename or code reference.
This is the same as L<LWP::UserAgent>.

=head1 SEE ALSO

L<http://github.com/tadam/AnyEvent-HTTP-LWP-UserAgent>
L<Coro::LWP>
L<AnyEvent::HTTP>
L<LWP::Protocol::AnyEvent::http>
L<LWP::Protocol::Coro::http>

=head1 ACKNOWLEDGEMENTS

Yasutaka Atarashi

=head1 AUTHOR

Yury Zavarin <yury.zavarin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yury Zavarin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
