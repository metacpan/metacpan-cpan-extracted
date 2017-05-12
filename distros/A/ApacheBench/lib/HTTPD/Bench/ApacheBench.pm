package HTTPD::Bench::ApacheBench;

use strict;
use vars qw($VERSION @ISA);

use base qw(DynaLoader HTTPD::Bench::ApacheBench::Regression);

use HTTPD::Bench::ApacheBench::Run;
use Scalar::Util qw/blessed/;

$HTTPD::Bench::ApacheBench::VERSION = '0.73';

bootstrap HTTPD::Bench::ApacheBench $VERSION;

##################################################
## the constructor                              ##
##################################################
sub new {
    my ($this, $self) = @_;
    my $class = ref($this) || $this;
    if (ref($self) ne 'HASH') { $self = {} }
    bless $self, $class;
    $self->initialize;
    return $self;
}

##################################################
## initialize defaults                          ##
##################################################
sub initialize {
    my ($self) = @_;
    $self->{runs} = [] if ref $self->{runs} ne 'ARRAY';
    $self->{concurrency} ||= 1;
    $self->{repeat} ||= 1;
    $self->{priority} ||= "equal_opportunity";
    $self->{buffersize} ||= 262144;
    $self->{request_buffersize} ||= 8192;
    $self->{timelimit} = undef if ! defined $self->{timelimit};
    $self->{keepalive} = 0 if ! defined $self->{keepalive};
    $self->{memory} = 1 if ! defined $self->{memory};
}


##################################################
## configure the global parameters              ##
##################################################
sub config {
    my ($self, $opt) = @_;
    foreach (qw(concurrency priority buffersize repeat memory)) {
	$self->{$_} = $opt->{$_} if defined $opt->{$_};
    }
}

sub concurrency {
    my ($self, $arg) = @_;
    $self->{concurrency} = $arg if $arg;
    return $self->{concurrency};
}

sub priority {
    my ($self, $arg) = @_;
    $self->{priority} = $arg if $arg;
    return $self->{priority};
}

sub memory {
    my ($self, $arg) = @_;
    $self->{memory} = $arg if defined $arg;
    return $self->{memory};
}

sub repeat {
    my ($self, $arg) = @_;
    $self->{repeat} = $arg if $arg;
    return $self->{repeat};
}

sub keepalive {
    my ($self, $arg) = @_;
    $self->{keepalive} = $arg if $arg;
    return $self->{keepalive};
}

sub timelimit {
    my ($self, $arg) = @_;
    $self->{timelimit} = $arg if $arg;
    return $self->{timelimit};
}

sub buffersize {
    my ($self, $arg) = @_;
    $self->{buffersize} = $arg if $arg;
    return $self->{buffersize};
}

sub request_buffersize {
    my ($self, $arg) = @_;
    $self->{request_buffersize} = $arg if $arg;
    return $self->{request_buffersize};
}

sub total_requests {
    my ($self) = @_;
    return 0 if ref $self->{runs} ne 'ARRAY';
    my $total = 0;
    foreach my $run (@{$self->{runs}}) {
	my $repeat = $run->repeat ? $run->repeat : $self->{repeat};
	$total += ($#{$run->urls} + 1) * $repeat
	  if ref $run->urls eq 'ARRAY';
    }
    return $total;
}


##################################################
## verify configuration of runs and execute     ##
##################################################
sub execute {
    my ($self) = @_;
    # keep track of temporarily altered run object variables
    my %altered;

    # fail if they have not added any runs
    return undef if ref $self->{runs} ne 'ARRAY';

    # pre execute initialization of each run
    foreach my $run_no (0..$#{$self->{runs}}) {
	my $runobj = $self->{runs}->[$run_no];

	$runobj->ready_to_execute or $runobj->prepare_for_execute or
	  return undef;

	# default to base ApacheBench object variables if not specified in run
	if (! $runobj->repeat) {
	    $runobj->repeat($self->{repeat});
	    $altered{$run_no}->{repeat} = 1;
	}
	if (! defined $runobj->memory) {
	    $runobj->memory($self->{memory});
	    $altered{$run_no}->{memory} = 1;
	}

        $runobj->pre_execute_warnings;
    }

    # call the XS code and store regression data
    $self->{'regression'} = $self->ab;

    # post execute polishing of each run
    foreach my $run_no (0..$#{$self->{runs}}) {
	my $runobj = $self->{runs}->[$run_no];
	$runobj->{'run_no'} = $run_no;
	$runobj->{'regression'} = $self->{'regression'};
	foreach my $param (qw(repeat memory)) {
	    delete $runobj->{$param}
	      if (ref $altered{$run_no} and $altered{$run_no}->{$param});
	}
    }
    return HTTPD::Bench::ApacheBench::Regression->new
      ({ 'regression' => $self->{'regression'} });
}


##################################################
## run accessors                                ##
##################################################
sub run {
    my ($self, $run_no, $run) = @_;
    return undef if ! (ref $self->{runs} eq 'ARRAY' && blessed $self->{runs}->[$run_no]
                         && $self->{runs}->[$run_no]->isa('HTTPD::Bench::ApacheBench::Run'));
    if (blessed $run && $run->isa('HTTPD::Bench::ApacheBench::Run')) {
	my $replaced_run = $self->{runs}->[$run_no];
	$self->{runs}->[$run_no] = $run;
	return $replaced_run;
    }
    return $self->{runs}->[$run_no];
}

sub add_run {
    my ($self, $newrun) = @_;
    return undef if ! (ref $self->{runs} eq 'ARRAY' && blessed $newrun
                         && $newrun->isa('HTTPD::Bench::ApacheBench::Run'));
    push(@{$self->{runs}}, $newrun);
    return $#{$self->{runs}};
}

sub delete_run {
    my ($self, $run_no) = @_;
    return undef if ref $self->{runs} ne 'ARRAY';
    my $deleted_run = $self->{runs}->[$run_no];
    $self->{runs} = [ @{$self->{runs}}[0..$run_no-1],
		      @{$self->{runs}}[$run_no+1..$#{$self->{runs}}] ];
    return $deleted_run;
}

sub num_runs {
    my ($self) = @_;
    return scalar(@{$self->{runs} || []});
}


1;

__END__

=head1 NAME

HTTPD::Bench::ApacheBench - Perl API for Apache benchmarking and regression testing.

=head1 SYNOPSIS

  use HTTPD::Bench::ApacheBench;

  my $b = HTTPD::Bench::ApacheBench->new;

  # global configuration
  $b->concurrency(5);
  $b->priority("run_priority");

  # add HTTP request sequences (aka: runs)
  my $run1 = HTTPD::Bench::ApacheBench::Run->new
    ({ urls => ["http://localhost/one", "http://localhost/two"] });
  $b->add_run($run1);

  my $run2 = HTTPD::Bench::ApacheBench::Run->new
    ({ urls    => ["http://localhost/three", "http://localhost/four"],
       cookies => ["Login_Cookie=b3dcc9bac34b7e60;"],
       # note: manual cookies no longer necessary due to use_auto_cookies (enabled by default)
       order   => "depth_first",
       repeat  => 10,
       memory  => 2 });
  $b->add_run($run2);

  my $run3 = HTTPD::Bench::ApacheBench::Run->new
    ({ urls     => ["http://localhost/five", "http://localhost/six"],
       memory   => 3,
       postdata => [
           sub($) { sleep(int(rand(5)) + 1); return undef; },
           sub($) {
               my $prev_response = shift;
               sleep(int(rand(5)) + 1);
               my ($username) = ( $prev_response =~ m|<div id="userName">([^<>]+)</div>|i );
               return $username ? 'cgi-username='.$username : undef;
           },
       ] });
  $b->add_run($run3);

  # send HTTP request sequences to server and time responses
  my $ro = $b->execute;

  # calculate hits/sec
  print ((1000*$b->total_requests/$b->total_time)." req/sec\n");

  # show request times (in ms) for $run1, 1st repetition
  print join(', ', @{$run1->request_times}) . "\n";

  # show response times (in ms) for $run2, 7th repetition
  print join(', ', @{$run2->iteration(6)->response_times}) . "\n";

  # dump the entire regression object (WARNING, this could be a LOT OF DATA)
  use Data::Dumper;
  my $d = Data::Dumper->new([$ro]);
  print $d->Dumpxs;


=head1 GOALS

This project is meant to be the foundation of a complete benchmarking
and regression testing suite for an advanced, transaction-based mod_perl
site.  We need to be able to stress our server to its limit while also
having a way to verify the HTTP responses for correctness.  Since our site
is transaction-based (as opposed to content-based), we needed to extend
the single-URL ab model to a multiple-URL sequence model.

ApacheBench was originally based on the Apache 1.3.12 ab code
(src/support/ab.c), but has since undergone major rewrites and now barely
resembles ab.c.

Note: although this tool was designed to be used on an Apache mod_perl
site, it is generally applicable to any HTTP-compliant server.  Beware,
however, that it sends a high volume of HTTP requests in a very short period
of time, which may overwhelm some weaker HTTP server implementations
like NT/IIS.

=head1 DESCRIPTION

ApacheBench sends sequences of HTTP requests to an HTTP server and keeps
track of the time taken to receive a response, the data that was returned,
the size of the data that was returned, and various other bits of information.

Since it is implemented in C, it sends HTTP requests in a tight loop which
can stress your server to 100% capacity, especially if invoked in multiple
concurrent instances.  It gives accurate time measurements down to the
millisecond for each HTTP request-response interval.

Included is a simplified re-implementation of ab using the ApacheBench/Perl
API.  This should help get you started with ApacheBench.

=head1 CONFIGURATION METHODS

You need to tell ApacheBench what the requests will be, in what order to
send them, and how to prioritize sending them.  ApacheBench was designed
to simulate many users logged in simultaneously, each of whom may be doing
many different transactions at once.

=head2 Global configuration methods

Global configuration methods apply to all benchmarking runs associated
with this ApacheBench object.

=over 4

=item $b = HTTPD::Bench::ApacheBench->new()

Constructor.

=item $b->concurrency( $concur_level )

Number of requests to send simultaneously (default: B<1>)

=item $b->priority( $priority )

$priority can be either "B<equal_opportunity>" or "B<run_priority>".

If set to "B<equal_opportunity>", all benchmark runs that are configured
(see below) under this ApacheBench object are given equal access to
the concurrency level.  This means requests are taken from each run
and sent in parallel (the level of parallelism defined by concurrency()).

If set to "B<run_priority>", the benchmark runs that are configured first
get the highest priority.  This means all requests in $b->run(0) will
be sent before any requests in $b->run(1) are sent, provided that
$b->run(0)->order eq "B<breadth_first>" (see below).

See L<"EXAMPLES"> near the bottom of this manual for a tutorial on the
effects of "B<equal_opportunity>" vs. "B<run_priority>".

(default: "B<equal_opportunity>")

=item $b->repeat( $n )

The number of times to repeat the request sequence in each run.
This can be overridden on a per-run basis (see below).

(default: B<1>)

=item $b->keepalive( 0|1 )

Whether or not to use HTTP Keep-Alive feature for requests configured in this
object.  This can be overridden on a per-url/per-run basis (see below).

B<Warning>: If you configure runs which contain requests to more than one
hostname/port, be aware that setting $b->keepalive() may not improve
performance.  See the discussion in the $run->keepalive() section for more
details.

(default: B<0>)

=item $b->timelimit( $sec_to_max_wait )

Set the maximum number of seconds to wait for requests configured in this
object to complete (i.e. receive the full response from the server).
B<Warning>: once the specified number of seconds have elapsed, ApacheBench
will read one last chunk of data from each open socket, and exit.  This could
result in partially received responses, which will cause broken sockets for
the server.

Per-url/per-run time limits can also be specified using the $run->timelimits()
method, but it does B<not> override this global setting.  If $b->timelimit()
is set, ApacheBench will exit after $sec_to_max_wait (or slightly over, due to
final connection reads and building regression data), regardless of any other
settings.

(default: B<0>, which means wait an unlimited amount of time)

=item $b->buffersize( $bufsz )

The size of the buffer in which to store HTTP response bodies, in bytes.
If an HTTP response is received with a size larger than this limit,
the content is truncated at length $bufsz, and a warning is issued.
This method has no effect if $b->memory() < 3.
This can be overridden on a per-run basis (see below).

(default: B<262144> or 256K)

=item $b->request_buffersize( $req_bufsz )

The size of the buffer in which to store HTTP requests, in bytes.  If you
configure an HTTP request that is larger than this limit, unpredictable
things will happen. (most likely a segmentation fault)

(default: B<8192> or 8K)

=item $b->memory( $memlvl )

The memory level.  Controls how much data ApacheBench will remember and
return in the regression object.  This can be overridden on a per-run basis
(see below).

(default: B<1>)

Key:
 $memlvl => Description

  0  =>  Remember nothing. (actually still keeps global
         regression data: total_time, bytes_received,
         and warnings)

  1  =>  Remember connect/response times and minimal
         summary information about size of requests and
         responses.

  2  =>  Remember connect/response times and all
         information about size of requests and responses.
         Also keeps an array of all HTTP response
         headers returned by the server for each request.

  3  =>  Remember connect/response times, all information
         about request/response sizes, HTTP response
         headers, and also all content of every HTTP
         response returned by the server.  B<Warning>:
         this can quickly eat up all available main
         memory if used with large runs.

=item $b->add_run( $run_object )

Schedule a run for this ApacheBench object.  Returns the run number where
this object was inserted, or undef on failure.  See below for details on
$run_object.

=item $run = $b->run( $run_no, [$run_object] )

Returns the run object stored in location $run_no.  If a run object is passed
as the optional second argument, it is stored in location $run_no, displacing
whatever was there.  The displaced run object is then returned.

=item $b->delete_run( $run_no )

Delete the run object stored in location $run_no.  The deleted run object
is returned to the caller for safety sake.

=item $b->num_runs()

Returns the number of runs currently configured in $b.

=back

=head2 Run configuration methods

You need to configure one or more benchmark runs.  A run is defined as an
ordered sequence of HTTP requests which can be repeated multiple times,
and scheduled to be sent in different ways.

=over 4

=item $run = HTTPD::Bench::ApacheBench::Run->new({ urls => [ @url_list ] })

Construct a run object with the ordered sequence of HTTP requests
in @url_list.

=item $run->repeat( $n )

Number of times to repeat this request sequence.

(default: B<1>, or whatever is specified in global configuration)

=item $run->use_auto_cookies( 0|1 )

Controls whether to enable dynamic setting of cookies based on previous
response headers in this run.  If set, will parse the Set-Cookie: headers
in each response in the run, and set the corresponding Cookie: headers in
all subsequent requests in this run.  (basically a crude, but fast emulation
of a browser's cookie handling mechanism)  The cookies are cumulative for
each iteration of the run, so they will accumulate with each request/response
pair until the next iteration, when they get reset.

(default: B<1>)

=item $run->cookies( \@cookies )

Set any extra HTTP Cookie: headers for each B<repetition> of this run.
Length of @cookies should equal $n (whatever you set $run->repeat to).
If this option is omitted, only auto-set cookies will be sent in
requests for this run.

If you need to set different cookies within a single URL sequence, use
the request_headers() method.

Note: this is somewhat obsolete now that there is support for dynamic
cookies, but is kept for backwards compatibility and in case you want to
add your own "static" cookies.

Example usage:  You could simulate $n users all doing the same transaction
simultaneously by giving $n different login cookies here.  Say you have
login cookies in an array called @login of length $n.  Set $run->repeat($n),
$run->order("breadth_first"), $run->cookies([map {$login[$_]} 0..$n-1]), and
ApacheBench will perform the transaction sequence set by $run->urls $n times,
each with a separate login cookie.

=item $run->urls( \@url_list )

Set the HTTP request URLs for this run.  A @url_list B<must> be given for
each run, otherwise the run will not execute.  Typically @url_list is set
using the constructor.

=item $run->postdata( \@postdata )

Set the HTTP POST request body contents.  If an undef value is encountered
in @postdata, that request will be a GET request (or a HEAD request if you
used $run->head_requests() below).  If this option is omitted, all requests
for this run will be GET (or HEAD) requests.

Length of @postdata should equal the length of @url_list.  

The @postdata array should consist of either strings or code refs (or undef).
A string value will make this request always a POST.  An undef makes this
request always a GET.  If a code ref, it will depend on the return value of
the called code. (see below for details)

The strings should contain exactly what you want sent in the HTTP POST request
body.  For example,

  @postdata = (undef, undef, 'cgikey1=val1&cgikey2=val2');

will send two GET requests, then a POST request with the CGI parameter
'cgikey1' set to 'val1' and the CGI parameter 'cgikey2' set to 'val2'.

The code refs should be references to subroutines that take one string
argument, which will be the http response (both headers and body) returned
from the *previous* request in this run, and return CGI post data as above.
If a subroutine returns undef, then the request will be a GET rather than a
POST.  If the return value is a string (even empty string), the request sent
will be a POST with the string as the request body.

For example,

  @postdata = (undef, sub($) {
    my $prev_response = shift;
    my ($username) = ( $prev_response =~ m|<div id="userName">([^<>]+)</div>|i );
    return $username ? 'cgi-username='.$username : undef;
  });

will send one GET request, then it will scan the HTTP response body returned by
the server for that GET request, and pull out any text (non-HTML) inside the HTML div
with id = "userName".

This text is then sent in a POST request as the value of CGI parameter 'cgi-username'.
If the <div id="userName"> element is not found in the most recent http response,
then the second request will be a GET instead of a POST request.

WARNING: when using code refs in @postdata, you need to be running with $run->memory(3),
since it needs to remember the most recent http response content.  If you forget, you will
be warned at runtime (and your POST requests will likely not send the desired content).

NOTES:

 1. The time taken to call your postdata function is not included in the
    times reported in the Regression object.  This is intentional, so you can
    benchmark your server response time, not your load testing script.

 2. You can use the above property to implement a random delay between http
    requests; while this is sort of a hack of the postdata function feature,
    it is much easier to implement a random delay this way than to add it in C.

    e.g. the following postdata coderef would produce a GET request with a
         random 1-5 sec delay:

    sub($) {
        sleep(int(rand(5)) + 1);
        return undef;
    }
    

=item $run->head_requests( \@head_reqs )

Send HTTP HEAD requests for the specified requests in this run.  The
length of @head_reqs should equal the length of @url_list, and it is
interpreted as an array of booleans.  Any true value in @head_reqs will
result in a HEAD request being sent for the corresponding URL (unless the
corresponding postdata() value is defined, in which case a POST will be sent).

You can configure a run composed of any combination of the three HTTP
request types (GET, HEAD, and POST), but note that an individual URL with a
defined postdata() value will cause a POST request regardless of whether
head_requests() is set for that URL.  The following precedence table
illustrates which type of request will be sent for URL $url_no in the sequence.

  defined $run->postdata->[$url_no] && ! ref($run->postdata->[$url_no])
                                     ?  ==> POST request
  defined $run->postdata->[$url_no] && ref($run->postdata->[$url_no]) eq 'CODE'
           && defined $run->postdata->[$url_no]->( $preceding_response )
                                     ?  ==> POST request
  defined $run->postdata->[$url_no] && ref($run->postdata->[$url_no]) eq 'CODE'
           && ! defined $run->postdata->[$url_no]->( $preceding_response )
                                     ?  ==> GET request
  $run->head_requests->[$url_no]     ?  ==> HEAD request
  else                               :  ==> GET request

=item $run->content_types( \@ctypes )

Set the Content-type: header for each POST request in this run.  Default
is "application/x-www-form-urlencoded" which will be used if an undef
value is encountered in @ctypes.  Length of @ctypes should equal the
length of @postdata.  Only sends the Content-type: header for POST requests:
a defined value in @ctypes with an undef in the corresponding @postdata will
result in no Content-type: header being sent.

=item $run->request_headers( \@req_headers )

Set arbitrary HTTP request headers for each request in this run, which will
be inserted after all normal headers.  Multiple extra headers for a single
url should be separated with "\r\n".  An undef value in @req_headers results
in no extra HTTP request headers being sent for the corresponding url.
If this option is omitted, no extra HTTP request headers will be sent in
any of the requests for this run.  Length of @req_headers should equal the
length of @url_list.

The following example for a @url_list of length 4 produces two requests with
no extra headers, one with 1 extra header, and one with 2 extra headers.

  $run->request_headers([ undef, undef, "Extra-Header: bread",
                          "Extra-Header1: butter\r\nExtra-Header2: toaster" ])

=item $run->keepalive( \@keepalives )

Use HTTP Keep-Alive feature for the specified requests in this run.  The
length of @keepalives should equal the length of @url_list, and it is
interpreted as an array of booleans, with undef indicating to use the
object default set by $b->keepalive().  Any true value in @keepalives will
result in a Keep-Alive HTTP request being sent for the corresponding URL.

To achieve full performance benefits from this feature, you need to be sure
your Keep-Alive requests are consecutive.  If a non-Keep-Alive request or
a request for a different hostname or port immediately follows a Keep-Alive
request B<in the connection slot>, I<the connection will be closed> and a
new connection will be opened.

Further, keep in mind that for $b->concurrency() > 1, there are many
connection slots open and even though requests in @url_list will be sent
in order, there is no guarantee they will all use the same connection slot.
The HTTP Keep-Alive feature only yields performance benefits when consecutive
Keep-Alive requests use the same connection slot.  Otherwise ApacheBench has
to close and re-open connections, resulting in the same performance as not
using keepalive() at all.

To guarantee consecutive Keep-Alive requests with $b->concurrency() > 1,
I recommend you either declare I<all> URLs in all runs as keepalive()
(this can be done by setting $b->keepalive( 1 ) and not overriding it by
calling keepalive() for any runs), or set $run->order( "depth_first" ) and
$b->priority( "run_priority" ).  This is the only combination of configuration
options that guarantees consecutive, same-slot Keep-Alive requests
regardless of your concurrency setting.

For $b->concurrency() == 1, things are simpler.  At any given time, there
is only one connection slot open, so just make sure your keepalive URLs are
consecutive within each run (if in "run_priority" mode), or that
equal-numbered repetitions of URLs in all runs are keepalive (if in
"equal_opportunity" mode), and be sure that all requests are to the
same hostname/port.

=item $run->timelimits( \@timelimits )

Set the maximum number of seconds to wait for requests in this
run to complete (i.e. receive the full response from the server).  The
length of @timelimits should equal the length of @url_list, and it is
interpreted as an array of double precision floating point numbers
(representing the number of seconds to wait for a response).  An undef or 0
represents waiting an indefinite amount of time for that particular response.
If this option is not configured, there will be no time limit on any responses.

B<Warning>: once the specified number of seconds have elapsed on the specified
URL, ApacheBench will close the connection immediately.  This can cause strange
results in the regression data for this request.  It could also result in
partially received responses, which will cause broken sockets for the server.

=item $run->order( $order )

Either "B<depth_first>" or "B<breadth_first>"

"B<breadth_first>" mode sends $n of the first request in the
@url_list, then $n of the second request in the @urls_list,
then $n of the third... and so on.  (e.g. If $n == 3 and @url_list
contains two requests, then ApacheBench would send the first
request 3 times, and then the second request 3 times.)

"B<depth_first>" mode ensures that HTTP requests in the sequence are
sent in order, completing a full sequence before starting again for the
next repeat() iteration.  (e.g. If $n == 3 and @url_list contains two
requests, then ApacheBench would send the @url_list sequence in order,
then send it again, and then again.  A total of six requests would be sent.)

See L<"EXAMPLES"> near the bottom of this manual for a tutorial on the
effects of "B<breadth_first>" vs. "B<depth_first>".

(default: "B<breadth_first>")

B<Note:> if $run->repeat() == 1, or the length of $run->urls() is 1, then the
B<order> option has no effect

=item $run->buffersize( $bufsz )

The size of the buffer in which to store HTTP response bodies.
If an HTTP response is received with a size larger than this limit,
the content is truncated at length $bufsz, and a warning is issued.
This method has no effect if $run->memory() < 3.

(default: B<262144> or 256K, or whatever is specified in global configuration)

=item $run->memory( $memlvl )

The memory level.  Controls how much data ApacheBench will remember and
return in the regression object for this run.  See global configuration
method of same name for detailed description.

(default: B<1>, or whatever is specified in global configuration)

=back

=head1 EXECUTION METHODS

=head2 Global execution methods

=over 4

=item $b->execute

Send all scheduled runs to their respective destinations, and record
response data.

=back

=head2 Run execution methods

=over 4

=item $run->ready_to_execute

Check all run configuration parameters for sanity.  Returns 1 to
indicate a call to $b->execute() I<should> complete safely.  Returns 0 to
indicate some more parameters need setting before $b->execute() should be
called.  Some of these parameters are automatically set by
prepare_for_execute() (below).

=item $run->prepare_for_execute

Set any run configuration parameters that were unspecified to sane values
in order to prevent a segmentation fault on execute().  Returns 1 if it
could set all parameters necessary to cause ready_to_execute() to return 1.
Returns 0 otherwise.

Note: this method is automatically called from execute() before entering
any XS code.

=back

=head1 REGRESSION METHODS

All of the following methods will return B<undef> unless the underlying
ApacheBench object has been execute()'d at least once.

=head2 Global regression methods

=over 4

=item $b->total_time

Total time, in milliseconds, between the start of the first request in the
first run, and the end of the final response in the final run.

=item $b->bytes_received

Total bytes received from all responses in all runs.

=item $b->total_requests

Total number of HTTP requests which were configured in this object.

=item $b->total_requests_sent

Total number of HTTP requests which were successfully sent to the server(s).

=item $b->total_responses_received

Total number of complete, successful HTTP responses received.

=item $b->total_responses_failed

Total number of HTTP responses which were not received successfully.
Check the warning messages for possible explanations of why they failed.

=item $b->warnings

Various warning messages.

=back

=head2 Run regression methods

=over 4

=item $run->sent_requests( $url_no )

Returns the number of HTTP requests which were B<successfully> sent to the
server for the URL specified by $url_no.

If $url_no is not given, returns a reference to an array the same length as
$run->urls() which contains the number of B<successful> HTTP requests sent
for each url in this run.

=item $run->good_responses( $url_no )

Returns the number of complete, B<successful> HTTP responses received for the
URL specified by $url_no.

If $url_no is not given, returns a reference to an array the same length as
$run->urls() which contains the number of B<successful> HTTP responses
received for each HTTP request in this run.

=item $run->failed_responses( $url_no )

Returns the number of HTTP responses which failed or were otherwise
B<unsuccessful>, for the URL specified by $url_no.

If $url_no is not given, returns a reference to an array the same length as
$run->urls() which contains the number of B<unsuccessful> HTTP responses
received for each HTTP request in this run.

=item $i = $run->iteration( $iter_no )

Return a regression object specific to iteration $iter_no of this run.
If $iter_no is not given, it assumes 0, or the first iteration of the run.
The number of iterations for the run can be retrieved with $run->repeat().

=item $i->connect_times( $url_no )

Returns the connection time, in milliseconds, for the URL specified by $url_no.

If $url_no is not given, returns a reference to an array the same length as
$run->urls() which contains connection times, in milliseconds, for each HTTP
request in this iteration of the sequence.

=item $i->min_connect_time

The minimum connect time of all requests in the sequence.

=item $i->max_connect_time

The maximum connect time of all requests in the sequence.

=item $i->avg_connect_time

The average connect time of all requests in the sequence.

=item $i->sum_connect_time

The total connect time of all requests in the sequence (equal to the
summation of all elements of $i->connect_times).

=item $i->request_times( $url_no )

Returns the time taken to send a request to the server, in milliseconds,
for the URL specified by $url_no.

If $url_no is not given, returns a reference to an array the same length as
$run->urls() which contains the times taken to send a request to the server,
in milliseconds, for each HTTP request in the sequence.

=item $i->min_request_time

The minimum request time of all requests in the sequence.

=item $i->max_request_time

The maximum request time of all requests in the sequence.

=item $i->avg_request_time

The average request time of all requests in the sequence.

=item $i->sum_request_time

The total request time of all requests in the sequence (equal to the
summation of all elements of $i->request_times).

=item $i->response_times( $url_no )

Returns the time taken to receive a response from the server, in milliseconds,
for the URL specified by $url_no.

If $url_no is not given, returns a reference to an array the same length as
$run->urls() which contains the times taken to receive a response from the
server, in milliseconds, for each HTTP request in the sequence.

=item $i->min_response_time

The minimum response time of all requests in the sequence.

=item $i->max_response_time

The maximum response time of all requests in the sequence.

=item $i->avg_response_time

The average response time of all requests in the sequence.

=item $i->sum_response_time

The total response time of all requests in the sequence (equal to the
summation of all elements of $i->response_times).

=item $i->bytes_posted( $url_no )

Returns the length of the HTTP POST request body for the URL specified
by $url_no.

If $url_no is not given, returns a reference to an array the same length as
$run->urls() which contains the number of bytes posted to the server for each
HTTP request in the sequence.

(return value will be undefined if B<memory> < 2)

=item $i->sum_bytes_posted

The total number of bytes posted to the server in HTTP requests over this
iteration of the request sequence.

=item $i->bytes_read( $url_no )

Returns the length of the HTTP response body for the URL specified by $url_no.

If $url_no is not given, returns a reference to an array the same length as
$run->urls() which contains the total number of bytes read from the server in
each HTTP response in the sequence.

(return value will be undefined if B<memory> < 2)

=item $i->sum_bytes_read

The total number of bytes read from the server in HTTP responses over this
iteration of the request sequence.

=item $i->request_body( $url_no )

Returns the full HTTP request sent to the server for the URL specified
by $url_no.

If $url_no is not given, returns a reference to an array the same length as
$run->urls() which contains the full HTTP request (including HTTP request
headers) sent to the server for each URL in the sequence.

(return value will be undefined if B<memory> < 3)

=item $i->response_headers( $url_no )

Returns the HTTP response header returned by the server for the URL specified
by $url_no.

If $url_no is not given, returns a reference to an array the same length as
$run->urls() which contains the HTTP response headers returned by the server
for each URL in the sequence.

(return value will be undefined if B<memory> < 2)

=item $i->response_body( $url_no )

Returns the full HTTP response page content returned by the server
(including HTTP headers) for the URL specified by $url_no.

If $url_no is not given, returns a reference to an array the same length as
$run->urls() which contains the full HTTP responses returned by the server for
each URL in the sequence.

(return value will be undefined if B<memory> < 3)

=item $i->response_body_lengths( $url_no )

Returns the length of the document (in bytes) returned by the server,
for the URL specified by $url_no.

If $url_no is not given, returns a reference to an array the same length as
$run->urls() which contains the length of the document (in bytes) returned by
the server for each HTTP response in the sequence.  This should be equivalent
to the Content-Length: line in the response headers, if the server set them
correctly.  The following should also be true,
for 1 <= $j <= size($run->urls()):

( $i->response_body_lengths()->[$j] == $i->bytes_read()->[$j] - length($i->response_headers()->[$j]) )

(return value will be undefined if B<memory> < 2)

=back

=head1 HTTP Proxies

ApacheBench can be used to make HTTP requests via an HTTP proxy.  To do so,
one passes a "special" URI to the ApacheBench::Run constructor or urls
method.  This special URI is of the form
http://proxyserver:proxyport/http://realserver:realport/...

=head1 EXAMPLES

The following examples of ApacheBench usage are paired with the resulting
output from an Apache access_log.  This should give you a feel for how the
global $b->priority() method and the per-run $run->order() method affect how
HTTP requests are sent.

First, let's set $b->priority("B<equal_opportunity>") (its default).

  my $b = HTTPD::Bench::ApacheBench->new;
  $b->concurrency(1);
  $b->priority("equal_opportunity");

Add a single run and execute, then look at what gets sent to Apache.

  my $run = HTTPD::Bench::ApacheBench::Run->new
    ({
       repeat    => 3,
       urls      => [ "http://localhost/",
                      "http://localhost/server-status" ],
       order     => "breadth_first",
     });
  $b->add_run($run);
  $b->execute;

Apache access_log output:

  127.0.0.1 - - [20/Sep/2000:18:43:32 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:18:43:32 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:18:43:32 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:18:43:32 -0400] "GET /server-status HTTP/1.0" 200 5294
  127.0.0.1 - - [20/Sep/2000:18:43:32 -0400] "GET /server-status HTTP/1.0" 200 5294
  127.0.0.1 - - [20/Sep/2000:18:43:32 -0400] "GET /server-status HTTP/1.0" 200 5294

Let's add another run and execute, and see what Apache sees.

  my $run2 = HTTPD::Bench::ApacheBench::Run->new
    ({
       repeat       => 3,
       urls         => [ "http://localhost/perl-status",
                         "http://localhost/proxy-status" ],
       order        => "breadth_first",
     });
  $b->add_run($run2);
  $b->execute;

Notice that both the first and second runs get equal opportunity.
Apache access_log output:

  127.0.0.1 - - [20/Sep/2000:18:49:10 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:18:49:11 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:18:49:11 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:18:49:11 -0400] "GET /perl-status HTTP/1.0" 200 848
  127.0.0.1 - - [20/Sep/2000:18:49:11 -0400] "GET /perl-status HTTP/1.0" 200 848
  127.0.0.1 - - [20/Sep/2000:18:49:11 -0400] "GET /perl-status HTTP/1.0" 200 848
  127.0.0.1 - - [20/Sep/2000:18:49:11 -0400] "GET /server-status HTTP/1.0" 200 5294
  127.0.0.1 - - [20/Sep/2000:18:49:11 -0400] "GET /server-status HTTP/1.0" 200 5294
  127.0.0.1 - - [20/Sep/2000:18:49:11 -0400] "GET /server-status HTTP/1.0" 200 5294
  127.0.0.1 - - [20/Sep/2000:18:49:11 -0400] "GET /proxy-status HTTP/1.0" 200 5886
  127.0.0.1 - - [20/Sep/2000:18:49:11 -0400] "GET /proxy-status HTTP/1.0" 200 5888
  127.0.0.1 - - [20/Sep/2000:18:49:11 -0400] "GET /proxy-status HTTP/1.0" 200 5889

Now let's set $b->priority("B<run_priority>").

  $b->priority("run_priority");
  $b->execute;

Notice that now ApacheBench completes the entire first run before it starts
the second.  Here's the Apache access_log output:

  127.0.0.1 - - [20/Sep/2000:18:52:47 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:18:52:47 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:18:52:47 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:18:52:47 -0400] "GET /server-status HTTP/1.0" 200 5294
  127.0.0.1 - - [20/Sep/2000:18:52:47 -0400] "GET /server-status HTTP/1.0" 200 5294
  127.0.0.1 - - [20/Sep/2000:18:52:47 -0400] "GET /server-status HTTP/1.0" 200 5294
  127.0.0.1 - - [20/Sep/2000:18:52:47 -0400] "GET /perl-status HTTP/1.0" 200 848
  127.0.0.1 - - [20/Sep/2000:18:52:47 -0400] "GET /perl-status HTTP/1.0" 200 848
  127.0.0.1 - - [20/Sep/2000:18:52:47 -0400] "GET /perl-status HTTP/1.0" 200 848
  127.0.0.1 - - [20/Sep/2000:18:52:47 -0400] "GET /proxy-status HTTP/1.0" 200 5858
  127.0.0.1 - - [20/Sep/2000:18:52:47 -0400] "GET /proxy-status HTTP/1.0" 200 5861
  127.0.0.1 - - [20/Sep/2000:18:52:47 -0400] "GET /proxy-status HTTP/1.0" 200 5864

Let's now set our runs to $run->order("B<depth_first>") instead of
"B<breadth_first>".  With "B<depth_first>", $b->priority() has no effect,
since each run can only use a maximum of one concurrent server
(by definition of "B<depth_first>", it can only be sending one request
at a time).

  $b->run(0)->order("depth_first");
  $b->run(1)->order("depth_first");
  $b->execute;

Notice each sequence gets sent in full before it repeats.
Apache access_log output:

  127.0.0.1 - - [20/Sep/2000:19:02:01 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:19:02:01 -0400] "GET /server-status HTTP/1.0" 200 5294
  127.0.0.1 - - [20/Sep/2000:19:02:01 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:19:02:01 -0400] "GET /server-status HTTP/1.0" 200 5294
  127.0.0.1 - - [20/Sep/2000:19:02:01 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:19:02:01 -0400] "GET /server-status HTTP/1.0" 200 5294
  127.0.0.1 - - [20/Sep/2000:19:02:01 -0400] "GET /perl-status HTTP/1.0" 200 848
  127.0.0.1 - - [20/Sep/2000:19:02:01 -0400] "GET /proxy-status HTTP/1.0" 200 5858
  127.0.0.1 - - [20/Sep/2000:19:02:01 -0400] "GET /perl-status HTTP/1.0" 200 848
  127.0.0.1 - - [20/Sep/2000:19:02:01 -0400] "GET /proxy-status HTTP/1.0" 200 5860
  127.0.0.1 - - [20/Sep/2000:19:02:01 -0400] "GET /perl-status HTTP/1.0" 200 848
  127.0.0.1 - - [20/Sep/2000:19:02:01 -0400] "GET /proxy-status HTTP/1.0" 200 5860

Now let's send the same runs, but with a higher concurrency level.

  $b->concurrency(2);
  $b->execute;

Notice that ApacheBench sends requests from all runs in order to fill up
the specified level of concurrent requests.  Apache access_log output:

  127.0.0.1 - - [20/Sep/2000:19:04:38 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:19:04:38 -0400] "GET /perl-status HTTP/1.0" 200 848
  127.0.0.1 - - [20/Sep/2000:19:04:38 -0400] "GET /server-status HTTP/1.0" 200 5294
  127.0.0.1 - - [20/Sep/2000:19:04:38 -0400] "GET /proxy-status HTTP/1.0" 200 5891
  127.0.0.1 - - [20/Sep/2000:19:04:38 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:19:04:38 -0400] "GET /perl-status HTTP/1.0" 200 848
  127.0.0.1 - - [20/Sep/2000:19:04:38 -0400] "GET /server-status HTTP/1.0" 200 5294
  127.0.0.1 - - [20/Sep/2000:19:04:38 -0400] "GET /proxy-status HTTP/1.0" 200 5878
  127.0.0.1 - - [20/Sep/2000:19:04:38 -0400] "GET / HTTP/1.0" 200 5565
  127.0.0.1 - - [20/Sep/2000:19:04:38 -0400] "GET /perl-status HTTP/1.0" 200 848
  127.0.0.1 - - [20/Sep/2000:19:04:38 -0400] "GET /server-status HTTP/1.0" 200 5294
  127.0.0.1 - - [20/Sep/2000:19:04:38 -0400] "GET /proxy-status HTTP/1.0" 200 5878

Let's take a look at the regression data from that last execute() call.

  foreach my $run_no (0..1) {
    foreach my $repeat (0..2) {
      print "response times (in ms) for run $run_no, iteration ".($repeat+1).":\n  ";
      print join("\n  ", @{$b->run($run_no)->iteration($repeat)->response_times});
      print "\n";
    }
  }

Perl output:

  response times (in ms) for run 0, iteration 1:
    69
    39
  response times (in ms) for run 0, iteration 2:
    67
    39
  response times (in ms) for run 0, iteration 3:
    65
    41
  response times (in ms) for run 1, iteration 1:
    67
    40
  response times (in ms) for run 1, iteration 2:
    66
    39
  response times (in ms) for run 1, iteration 3:
    65
    39


=head1 BUGS

Error checking in configuration is good but not perfect.
If you do not configure correctly, you may experience a
segmentation fault on execute().

The body of any response which comes back larger than the B<buffersize>
applicable to it may be truncated to zero length.  If you expect to receive
responses larger than the default 256K buffersize, make sure to set your
$run->buffersize() big enough for the largest page you anticipate receiving.

If you are running in perl's taint-checking mode, and you pass tainted data
to ApacheBench (e.g. a tainted URL), it will barf.  Don't ask me why.

HTTP Proxy support needs to be expanded to allow for a username and
password.

=head1 AUTHORS

The ApacheBench Perl API is based on code from
Apache 1.3.12 ab (src/support/ab.c), by the Apache group.

The ApacheBench Perl API was originally written by Ling Wu <ling@certsite.com>

Rewritten and currently maintained by Adi Fairbank <adi@adiraj.org>

Recent efforts have been made to incorporate the newest ab code from the Apache
Group.  As of version 0.62, most features of Apache 1.3.22 ab are supported.
The main exception being SSL.

Please e-mail Adi with bug reports, or preferably patches.

=head1 LICENSE

This package is free software and is provided AS IS without express or
implied warranty.  It may be used, redistributed and/or modified under the
terms of the Perl Artistic License
(http://www.perl.com/perl/misc/Artistic.html)

=cut
