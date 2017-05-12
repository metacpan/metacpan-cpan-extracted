package AnyEvent::Curl::Multi;

use common::sense;
use base 'Object::Event';
use Carp qw(croak);
use AnyEvent;
use WWW::Curl 4.14;
use WWW::Curl::Easy;
use WWW::Curl::Multi;
use Scalar::Util qw(refaddr);
use HTTP::Response;

our $VERSION = '1.1';

# Test whether subsecond timeouts are supported.
eval { CURLOPT_TIMEOUT_MS(); }; my $MS_TIMEOUT_SUPPORTED = $@ ? 0 : 1;

=head1 NAME

AnyEvent::Curl::Multi - a fast event-driven HTTP client

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::Curl::Multi;
  
  my $client = AnyEvent::Curl::Multi->new;
  $client->max_concurrency(10);

  # Method 1: Object::Event pattern
  #
  # Schedule callbacks to be fired when a response is received,
  # or when an error occurs.
  $client->reg_cb(response => sub {
      my ($client, $request, $response, $stats) = @_;
      # $response is an HTTP::Request object
  });
  $client->reg_cb(error => sub {
      my ($client, $request, $errmsg, $stats) = @_;
      # ...
  });
  my $request = HTTP::Request->new(...);
  $client->request($request);

  # Method 2: AnyEvent::CondVar pattern
  # Do not use this pattern in an existing event loop!
  my $handle = $client->request($request);
  eval {
      my ($response, $stats) = $handle->cv->recv;
      # $response is an HTTP::Request object
      # ...
  }; 
  if ($@) {
      my $errmsg = $@;
      # ...
  }
  
=head1 DESCRIPTION

This module is an AnyEvent user; you must use and run a supported event loop.

AnyEvent::Curl::Multi is an asynchronous, event-driven HTTP client.  You can
use it to make multiple HTTP requests in parallel using a single process.  It
uses libcurl for fast performance.

=head2 Initializing the client

 my $client = AnyEvent::Curl::Multi->new;

You can specify the maximum number of concurrent requests by setting
C<max_concurrency>, e.g.:

 my $client = AnyEvent::Curl::Multi->new(max_concurrency => 10);

You can also set the maximum concurrency after the client has been created:

 $client->max_concurrency(10);

A value of 0 means no limit will be imposed.

You can also set global default behaviors for requests: 

=over

=item timeout => PERIOD

Specifies a timeout for each request.  If your WWW::Curl is linked against
libcurl 7.16.2 or later, this value can be specified in fractional seconds (ms
resolution).  Otherwise, the value must be specified in whole seconds.

=item proxy => HOST[:PORT]

Specifies a proxy host/port, separated by a colon.  (The port number is
optional.)

=item max_redirects => COUNT

Specifies the maximum number of HTTP redirects that will be followed.  Set to
0 to disable following redirects.

=item ipresolve => 4 | 6

Specifies which kind of IP address to select when resolving host names.  This
is only useful when using host names that resolve to both IPv4 and IPv6
addresses.  The allowed values are 4 (IPv4) or 6 (IPv6).  The default is to
resolve to all addresses.

=back

=head2 Issuing requests

To dispatch HTTP requests to the client, use the request() method.  request()
takes an HTTP::Request object as the first argument, and a list of
attribute-value pairs as the remaining arguments:
  
  $handle = $client->request($request, ...);

The following attributes are accepted:

=over 

=item timeout => PERIOD

Specified a timeout for the request.  If your WWW::Curl is linked against
libcurl 7.16.2 or later, this value can be specified in fractional seconds (ms
resolution).  Otherwise, the value must be specified in whole seconds.

=item proxy => HOST[:PORT]

Specifies a proxy host/port, separated by a colon.  (The port number is optional.)

=item max_redirects => COUNT

Specifies the maximum number of HTTP redirects that will be followed.  Set to
0 to disable following redirects.

=back
 
The request() method returns an object of class AnyEvent::Curl::Multi::Handle.
This object can be used later to cancel the request; see "Canceling requests",
below.  

Calling $handle->cv() will return an AnyEvent condvar that you can use as usual
(e.g., recv() or cb()) to retrieve response results, or that will croak if an
error occurs.  See L<AnyEvent> for details on condvars.

=head2 Callbacks

Instead of using condvars, you may register interest in the following events
using the client's reg_cb() method (see Object::Event for more details on
reg_cb()):

=over

=item response => $cb->($client, $request, $response, $stats);

Fired when a response is received.  (This doesn't imply that the response is
HTTP OK, so you should examine the response to determine whether there was
an HTTP error of some sort.)  

The arguments sent to your callback will be the client object, the original
request (untampered with), the response (as an HTTP::Response object), and a
hashref containing some interesting statistics.

=item error => $cb->($client, $request, $errmsg, $stats);

Fired when an error is received.  

The arguments sent to your callback will be the client object, the original
request (untampered with), the error message, and a hashref containing some
interesting statistics.  (If the error was other than a timeout, the statistics
may be invalid.)

=back
  
=cut

sub new { 
    my $class = shift;

    my $self = $class->SUPER::new(
        multi_h => WWW::Curl::Multi->new,
        state => {},
        timer_w => undef,
        io_w => {},
        queue => [],
        max_concurrency => 0,
        max_redirects => 0,
        timeout => undef,
        proxy => undef,
        debug => undef,
        ipresolve => undef,
        @_
    );

    if (! $MS_TIMEOUT_SUPPORTED 
        && $self->{timeout}
        && $self->{timeout} != int($self->{timeout})) {
        croak "Subsecond timeout resolution is not supported by your " .
              "libcurl version.  Upgrade to 7.16.2 or later.";
    }

    return bless $self, $class;
}

sub request {
    my $self = shift;
    my ($req, %opts) = @_;

    my $easy_h; 

    if ($req->isa("HTTP::Request")) {
        # Convert to WWW::Curl::Easy
        $easy_h = $self->_gen_easy_h($req, %opts);
    } else {
        croak "Unsupported request type";
    }

    # Initialize easy curl handle
    my $id = refaddr $easy_h;
    my ($response, $header);
    $easy_h->setopt(CURLOPT_WRITEDATA, \$response);
    $easy_h->setopt(CURLOPT_WRITEHEADER, \$header);
    $easy_h->setopt(CURLOPT_PRIVATE, $id);

    my $obj = {
        easy_h => $easy_h,
        req => $req,
        response => \$response,
        header => \$header,
        cv => AE::cv,
    };

    push @{$self->{queue}}, $obj;

    $self->_dequeue;

    return bless $obj, 'AnyEvent::Curl::Multi::Handle';
}

sub _dequeue {
    my $self = shift;

    while ($self->{max_concurrency} == 0 || 
           scalar keys %{$self->{state}} < $self->{max_concurrency}) {
        if (my $dequeued = shift @{$self->{queue}}) {
            $self->{state}->{refaddr($dequeued->{easy_h})} = $dequeued;
            # Add it to our multi handle
            $self->{multi_h}->add_handle($dequeued->{easy_h});
        } else {
            last;
        }
    }
    
    # Start our timer
    $self->{timer_w} = AE::timer(0, 0.5, sub { $self->_perform });
}

sub _perform {
    my $self = shift;

    $self->{multi_h}->perform;

    while (my ($id, $rv) = $self->{multi_h}->info_read) {
        if ($id) {
            my $state = $self->{state}->{$id};
            my $req = $state->{req};
            my $easy_h = $state->{easy_h};
            my $stats = {
                total_time => $easy_h->getinfo(CURLINFO_TOTAL_TIME),
                dns_time => $easy_h->getinfo(CURLINFO_NAMELOOKUP_TIME),
                connect_time => $easy_h->getinfo(CURLINFO_CONNECT_TIME),
                start_transfer_time => 
                    $easy_h->getinfo(CURLINFO_STARTTRANSFER_TIME),
                download_bytes => 
                    $easy_h->getinfo(CURLINFO_SIZE_DOWNLOAD),
                upload_bytes => $easy_h->getinfo(CURLINFO_SIZE_UPLOAD),
            };
            if ($rv) {
                # Error
                $state->{cv}->croak($easy_h->errbuf);
                $req->event('error', $easy_h->errbuf, $stats) 
                    if $req->can('event');
                $self->event('error', $req, $easy_h->errbuf, $stats);
            } else {
                # libcurl appends subsequent response headers to the buffer
                # when following redirects.  We need to remove all but the
                # most recent header before we parse the response.
                my $last_header = (split(/\r?\n\r?\n/, 
                                   ${$state->{header}}))[-1];
                my $response = HTTP::Response->parse($last_header . 
                                                     "\n\n" . 
                                                     ${$state->{response}});
                $req->uri($easy_h->getinfo(CURLINFO_EFFECTIVE_URL));
                $response->request($req);
                $state->{cv}->send($response, $stats);
                $req->event('response', $response, $stats) 
                    if $req->can('event');
                $self->event('response', $req, $response, $stats);
            }
            delete $self->{state}->{$id};
            $self->_dequeue;
        }
    }

    # We must recalculate the number of active handles here, because
    # a user-provided callback may have added a new one.
    my $active_handles = scalar keys %{$self->{state}};
    if (! $active_handles) {
        # Nothing left to do - no point keeping the watchers around anymore.
        delete $self->{timer_w};
        delete $self->{io_w};
        return;
    }

    # Re-establish all I/O watchers
    foreach my $fd (keys %{$self->{io_w}}) {
        delete $self->{io_w}->{$fd};
    }

    my ($readfds, $writefds, $errfds) = $self->{multi_h}->fdset;

    foreach my $fd (@$writefds) {
        $self->{io_w}->{$fd} ||= AE::io($fd, 1, sub { $self->_perform }); 
    }
    foreach my $fd (@$readfds) {
        $self->{io_w}->{$fd} ||= AE::io($fd, 0, sub { $self->_perform }); 
    }
}

sub _gen_easy_h {
    my $self = shift;
    my $req = shift;
    my %opts = @_;

    my $easy_h = WWW::Curl::Easy->new;
    $easy_h->setopt(CURLOPT_URL, $req->uri);

    $easy_h->setopt(CURLOPT_SSL_VERIFYPEER, 0);
    $easy_h->setopt(CURLOPT_DNS_CACHE_TIMEOUT, 0);

    if (defined $self->{ipresolve}) {
        if (int($self->{ipresolve}) == 4) {
            $easy_h->setopt(CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
        } elsif (int($self->{ipresolve}) == 6) {
            $easy_h->setopt(CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V6);
        } else {
            die "Invalid ipresolve setting '$self->{ipresolve}' (must be 4 or 6)";
        }
    }

    $easy_h->setopt(CURLOPT_CUSTOMREQUEST, $req->method);
    $easy_h->setopt(CURLOPT_HTTPHEADER, 
        [ split "\n", $req->headers->as_string ]);
    if (length $req->content) {
        $easy_h->setopt(CURLOPT_POSTFIELDS, $req->content);
        $easy_h->setopt(CURLOPT_POSTFIELDSIZE, length $req->content);
    }

    # Accept gzip or deflate-compressed responses
    $easy_h->setopt(CURLOPT_ENCODING, "");

    $easy_h->setopt(CURLOPT_VERBOSE, 1) if $self->{debug} || $opts{debug};

    my $proxy = $self->{proxy} || $opts{proxy};
    $easy_h->setopt(CURLOPT_PROXY, $proxy) if $proxy;

    my $timeout = $self->{timeout} || $opts{timeout};

    if ($timeout) {
        if ($timeout == int($timeout)) {
            $easy_h->setopt(CURLOPT_TIMEOUT, $timeout);
        } else {
            croak "Subsecond timeout resolution is not supported by your " .
                  "libcurl version.  Upgrade to 7.16.2 or later."
                unless $MS_TIMEOUT_SUPPORTED;
            $easy_h->setopt(CURLOPT_TIMEOUT_MS(), $timeout * 1000);
        }
    }

    my $max_redirects = defined $opts{max_redirects} ? $opts{max_redirects}
                                                     : $self->{max_redirects};

    if ($max_redirects > 0) {
        $easy_h->setopt(CURLOPT_FOLLOWLOCATION, 1);
        $easy_h->setopt(CURLOPT_MAXREDIRS, $max_redirects);
    }

    return $easy_h;
}

=head2 Canceling requests

To cancel a request, use the cancel() method:

  my $handle = $client->request(...);

  # Later...
  $client->cancel($handle);

=cut

sub cancel {
    my $self = shift;
    my $obj = shift;

    croak "Missing object" unless $obj;

    $self->{multi_h}->remove_handle($obj->{easy_h});
    delete $self->{state}->{refaddr($obj->{easy_h})};
    undef $obj;
    $self->_dequeue;
}

sub max_concurrency {
    my $self = shift;
    if (defined(my $conc = shift)) {
        $self->{max_concurrency} = $conc;
    }
    return $self->{max_concurrency};
}

package AnyEvent::Curl::Multi::Handle;

sub cv { shift->{cv} }

1;

=head1 NOTES

B<libcurl 7.21 or higher is recommended.>  There are some bugs in prior
versions pertaining to host resolution and accurate timeouts.  In addition,
subsecond timeouts were not available prior to version 7.16.2.

B<libcurl should be compiled with c-ares support.>  Otherwise, the DNS
resolution phase that occurs at the beginning of each request will block your
program, which could significantly compromise its concurrency.  (You can verify
whether your libcurl has been built with c-ares support by running C<curl -V>
and looking for "AsynchDNS" in the features list.)

libcurl's internal hostname resolution cache is disabled by this module (among
other problems, it does not honor DNS TTL values).  If you need fast hostname
resolution, consider installing and configuring a local DNS cache such as BIND
or dnscache (part of djbdns).

SSL peer verification is disabled.  If you consider this a serious problem,
please contact the author.

=head1 SEE ALSO

L<AnyEvent>, L<AnyEvent::Handle>, L<Object::Event>, L<HTTP::Request>,
L<HTTP::Response>

=head1 AUTHORS AND CONTRIBUTORS

Michael S. Fischer (L<michael+cpan@dynamine.net>) released the original version
and is the current maintainer.

=head1 COPYRIGHT AND LICENSE

(C) 2010-2011 Michael S. Fischer.
(C) 2010-2011 Yahoo! Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__END__

# vim:syn=perl:ts=4:sw=4:et:ai
