package Apache::Gateway;

=head1 NAME

Apache::Gateway - A Bloated Gateway Module

=head1 SYNOPSIS

Example B<Apache> configuration:

  <Location /CPAN/>
  SetHandler perl-script
  PerlHandler Apache::Gateway
  PerlSetVar GatewayConfig /etc/apache/gateway/CPAN
  PerlSetupEnv Off
  </Location>

Example GatewayConfig file:

  GatewayRoot /CPAN/
  
  <LocationMatch ".*">
  Site    ftp://ftp.perl.org/pub/perl/CPAN/
  MuxSite ftp://ftp.cdrom.com/pub/perl/CPAN/
  MuxSite ftp://ftp.digital.com/pub/plan/perl/CPAN/
  Site 	  ftp://ftp.orst.edu/pub/packages/CPAN/
  Site 	  ftp://ftp.funet.fi/pub/languages/perl/CPAN/
  </LocationMatch>
  
  ClockBroken ftp://ftp.cdrom.com	EET	PST8PDT
  ClockBroken ftp://ftp.digital.com	EET	PST8PDT
  ClockBroken ftp://ftp.orst.edu	EET	PST8PDT
  ClockBroken ftp://ftp.perl.org	CST	CST6CDT

See the examples directory for commented examples.

=head1 DESCRIPTION

The C<Apache::Gateway> module implements a gateway with assorted
optional features.

=head1 FEATURES

=over 4

=item Standard Gateway Features

C<Apache::Gateway> services requests using C<LWP> and, hence, can
gateway to any protocol that C<LWP> understands.  It also makes
foreign URIs appear to be local URIs.

C<Apache::Gateway> does not include a cache, but it can be used in
combination with a proxy cache to cache what the gateway retrieves.
For example, B<Apache> can provide caching for the gateway by setting
up a proxy cache virtual host and a gateway virtual host and then
using the proxy to access the gateway.

=item Automatic Failover with Mirrored Instances

Multiple mirrors can provide an instance.  Requests which fail will
automatically be retried with the next mirror.  This capability is
very useful when some mirrors are busy or erratic.

=item Multiplexing

Like the CPAN multiplexer, C<Apache::Gateway> can multiplex requests
amongst several mirrors.

=item Pattern-dependent Gatewaying

The origin server to contact can vary depending upon the URL.  This
capability is particularly useful when dealing with partial mirrors.
A common situation is that some files may be available at all mirrors,
but less commonly used files will only be available at a few mirrors.

=item FTP Directory Gatewaying

(Need to think of a better name for this feature.)  Remote FTP
directory listings can be modified to refer to the gateway.  This
feature is somewhat similar to the ProxyPassReverse directive.

This feature was especially complicated and problematical.  It has now
been removed.

=item Timestamp Correction

C<Apache::Gateway> can try to correct incorrect timestamps generated
by popular mirroring software.  In particular, it can try to
compensate for the way the Perl B<mirror> program sets timestamps.

=back

=head1 CONFIGURATION

Most configuration is done in the GatewayConfig files.  The regular
B<Apache> configuration files only need to include the handler
directives and set the C<GatewayConfig> filename.  Environment
variables are not used, so C<PerlSetupEnv> can be Off.

GatewayConfig directives purposely look like Apache config directives
so that the syntax will be familiar.  However, GatewayConfig
directives are not Apache config directives.  They cannot be used in
Apache config files (and vice versa)!

=over 4

=item GatewayRoot path

Sets the root of the gatewayed area on the local server.  Generally
matches the C<Location> setting in the B<Apache> config files.
Defaults to "/".

=item GatewayTimeout timeout

Passes timeout (in seconds) to C<LWP::UserAgent>.

=item LocationMatch regexp

Begins a LocationMatch section.  Works similarly to the ApacheLocation
match directive except that the pattern is a Perl regexp.  Note: there
are no C<Location> or other style sections, only C<LocationMatch>.

LocationMatch sections are tried in order until a regexp is matched.

=item Site URI

Sets an upstream server to contact for this URI.  In case of failure,
requests are automatically retried with successive sites in the order
they appear.  Failures can include anything from the upstream server
being down or flaky to a file not being present because the upstream
mirror is out of synch with its primary site.

=item MuxSite URI

Sets an upstream server to contact for this URI.  Adjacent C<MuxSite>
servers are tried in round robin order.

For example, here again is the default portion of the sample
GatewayConfig file above:

  <LocationMatch ".*">
  Site    ftp://ftp.perl.org/pub/perl/CPAN/
  MuxSite ftp://ftp.cdrom.com/pub/perl/CPAN/
  MuxSite ftp://ftp.digital.com/pub/plan/perl/CPAN/
  Site 	  ftp://ftp.orst.edu/pub/packages/CPAN/
  Site 	  ftp://ftp.funet.fi/pub/languages/perl/CPAN/
  </LocationMatch>

With the C<Site> and C<MuxSite> directives here, the first request
will be forwarded to ftp.perl.org.  If it fails, the request will be
retried with cdrom, digital, orst, and funet, in that order.  The
next request for that process will be tried with ftp.perl.org first
again.  If it fails, retries then go to digital, cdrom, orst, and
finally funet.

A good general strategy for packages with multiple mirrors might be
to specify one or two nearby sites to try first.  Then specify some
multiplexed sites slightly further away in case the nearby sites
fail.  Finally, fall back to the primary site if all else fails.

=item ClockBroken server-URL upstream^2-TZ upstream-TZ

When caching is employed and requests can be gatewayed to multiple
mirrors, timestamp correctness becomes more important.  Unfortunately,
timestamps on mirrored files are usually wrong.  For example, the
popular Perl B<mirror> program is generally configured to match
timestamps using the local timezone both locally and on the server it
is mirroring.  This strategy is only guaranteed to work if both
servers are in the same timezone.

Example:
  ClockBroken ftp://ftp.cdrom.com	EET	PST8PDT

cdrom gets files from funet, which seems always to use the EET
timezone (which is two hours off from GMT) for purposes of mirroring.
cdrom, however, uses the PST8PDT timezone, so that 00:00 on funet
differs from 00:00 on cdrom by 9 or 10 hours, depending upon whether
or not Daylight Savings Time is in effect.  The example ClockBroken
line corrects for this disparity.

Note: timezones are those understood by Time::Zone.

=back

=head1 FUNCTIONS

The following internal functions are documented (mostly useful for
hackers):

=over 4

=cut

use strict;
use vars qw(@ISA);

use Exporter ();
@ISA = qw(Exporter);
$Apache::Gateway::VERSION = sprintf("%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/g);

use Apache::Constants ':server'; # for SERVER_VERSION for Via comment
use Apache::URI ();
use HTTP::Date ();
use HTTP::Request ();
use HTTP::Status ();
use IO::File ();
use LWP::UserAgent ();
use Time::Zone ();

# In an Apache::Registry script, we would need to make the following
# variables global.  However, making them global seems unnecesary in a
# handler.
my %default_port = (finger => 79,
		    ftp => 21,
		    gopher => 70,
		    http => 80,
		    https => 443,
		    nntp => 119,
		    prospero => 1525,
		    rlogin => 513,
		    snews => 563,
		    telnet => 23,
		    wais => 210,
		    webster => 765,
		    whois => 43,
		   );

my $gw;

=item $gw = Apache::Gateway->new( [$ua] )

Construct a new Apache::Gateway object describing a gateway.  If a
LWP::UserAgent is not provided, a new one will be created.  Note: the
user agent is modified for seach request; it is not constant and is
probably not shareable.

=cut

sub new($;$) {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};
    $self->{UA} = @_ ? shift : new LWP::UserAgent,
    $self->{CONFIG} = {};

    bless($self, $class);
    return $self;
}

=item $gw->user_agent( [$ua] )

Get/set the user agent.

=cut

sub user_agent($;$) {
    my $self = shift;
    if (@_) { $self->{UA} = shift }
    return $self->{UA};
}

=item $gw->request( [$r] )

Get/set the Apache request currently being gatewayed.  To send the
request, see the send_request method.

=cut

sub request($;$) {
    my $self = shift;
    if (@_) { $self->{REQUEST} = shift }
    return $self->{REQUEST};
}

# $gw->_config( [$config] )

# Get/set the cached configuration information and current run state.
# This very low-level method is for hackers only.  This API might
# change.

sub _config($;$) {
    my $self = shift;
    if (@_) { $self->{CONFIG} = shift }
    return $self->{CONFIG};
}

=item $gw->location_config( [$config] )

Get/set the configuration information for this gateway location.  Can
be overridden to provide dynamic per location information

=cut

sub location_config($;$) {
    my $self = shift;
    my $config_file = $self->{REQUEST}->dir_config('GatewayConfig');
    if (@_) { $self->{CONFIG}{$config_file} = shift }
    return $self->{CONFIG}{$config_file};
}

# $gw->_init_config_file
#
# If necessary, parse and cache a configuration file specified by the
# GatewayConfig variable.  On error, sets
# $r->status(HTTP::Status::RC_INTERNAL_SERVER_ERROR) and returns.

# Parsed info and state is stored in $gw->_config, which has the
# following structure

#  $gw->_config->{$config_filename}
#      = { LOCATION => [ { PATTERN => Regexp,
#			   SITE => [ site or mux sites list, ... ] },
#			 ... ],
#	   BROKEN_CLOCK => { $server0 => [upstream^2 TZ, upstream TZ],
#			     $server1 => [upstream^2 TZ, upstream TZ],
#			     ... }
#	   ROOT => location of root of gateway,
#	   TIMEOUT => timeout in seconds for contacting upstream server
#	}
#  site = a site URL, e.g., http://www.perl.com/CPAN/
#  mux sites list = { START_INDEX => start index of round robin,
#		      SITE => [ site, site, ... ] }

# This structure is subject to change.  Because it contains state
# information, it is per object and cannot be shared.
sub _init_config_file($) {
    my $self = shift;
    my $r = $self->{REQUEST};
    my $config = $self->{CONFIG};
    my $config_file = $r->dir_config('GatewayConfig');
    unless ($config_file) {
	$r->log_error('no GatewayConfig');
	$r->status(HTTP::Status::RC_INTERNAL_SERVER_ERROR);
	return;
    }

    # Return if file has already been parsed.
    return 1 if exists $config->{$config_file};

    # Open file.
    my $f = IO::File->new($config_file, 'r');
    unless ($f) {
	$r->log_error('open ' . $config_file . ': ' . $!);
	$r->status(HTTP::Status::RC_INTERNAL_SERVER_ERROR);
	return;
    }

    my $gw_root = '/';
    my($timeout, @entry, %clock_broken);

    # Read lines.
    while(<$f>) {
	s/\s+$//;		# Remove trailing whitespace.
	next if /^$/ || /\#/;	# Ignore blank and comment lines.

	# E.g., <LocationMatch "\.gz$">
	if(/^<LocationMatch \s*\"(.*)\">$/) {
	    # Begin a new entry.
	    my $cur_entry = { PATTERN => $1,
			      SITE => [] };

	    while(<$f>) {
		s/\s+$//;	# Remove trailing whitespace.
		next if /^$/ || /\#/;  # Ignore blank and comment lines.
	
		if(/Site/) {
		    my $site = $cur_entry->{SITE};
		    # E.g., Site http://www.perl.com/CPAN/
		    if(/^Site\s*(.*)/) {
			# Add one or more sites to this entry.
			push @$site, split(' ', $1);
		    }
		    elsif(/^MuxSite\s*(.*)/) {
			# Add one or more muliplexed sites to this entry.
			# E.g., MuxSite http://www.perl.com/CPAN/
			my $last_site_added = $site->[$#$site];
			if(ref($last_site_added)) {
			    push @{$last_site_added->{SITE}}, split(' ', $1);
			}
			else {
			    # start_index = start index of round robin
			    push @$site, { START_INDEX => 0,
					   SITE => [ split(' ', $1) ] };
			}
		    }
		}
		elsif(/^<\/LocationMatch>$/) {
		    push @entry, $cur_entry;
		    last;
		}
		else {
		    $r->log_error('Unrecognized command: ' . $_);
		    $r->status(HTTP::Status::RC_INTERNAL_SERVER_ERROR);
		    return;
		}
	    }

	}
	elsif(/^ClockBroken\s*(.*)/) {
	    # E.g., ClockBroken ftp://ftp.fuller.edu EST5EDT PST8PDT Yes
	    my($server, @arg) = split(' ', $1);

	    $arg[1] = 'GMT' unless defined $arg[1];
	    $clock_broken{$server} = [ @arg ];
	}
	elsif(/^GatewayRoot\s*(.*)/) {
	    $gw_root = $1;
	}
	elsif(/^GatewayTimeout\s*(.*)/) {
	    $timeout = $1;
	}
	else {
	    $r->log_error('Unrecognized command: ' . $_);
	    $r->status(HTTP::Status::RC_INTERNAL_SERVER_ERROR);
	    return;
	}
    }

    # Store parsed results.
    $config->{$config_file} = { LOCATION => \@entry,
				ROOT => $gw_root,
				BROKEN_CLOCK => \%clock_broken };
    $config->{$config_file}{TIMEOUT} = $timeout;

    return 1;
}

=item clear_headers_for_redirect($r)

Clear request headers in $r in preparation for a redirect.

=cut

sub clear_headers_for_redirect($) {
    my $r = shift;
    # Some of this should be done with Apache::Tie when it is working.
    $r->header_out('Content-Length' => undef); # should use tie
    $r->status(HTTP::Status::RC_OK);

    my %err = $r->err_headers_out; # should use tie
    foreach (keys %err) {
	$r->err_header_out($_ => undef);
    }
}

=item canonicalized_server_URL($scheme, $hostname, $port)

Return semicanonicalized server URL (without trailing slash).

=cut

sub canonicalized_server_URL($$$) {
    my($scheme, $host, $port) = @_;
    my $server = lc($scheme . '://' . $host);
    if(defined $port and exists $default_port{$scheme}
       and $port != $default_port{$scheme}) {
	$server .= ':' . $port;
    }
    return $server;
}

=item server_name_from_URL($r, $url)

Return the (somewhat canonicalized) "server name" portion of the URL.
The "server name" is defined as the leading scheme://authority portion
of the URL.

=cut

sub server_name_from_URL($$) {
    my ($r, $url) = @_;
    $url = Apache::URI->parse($r, $url) unless ref $url;
    return canonicalized_server_URL($url->scheme, $url->hostname, $url->port);
}

=item server_name($r)

Return the (somewhat canonicalized) "server name" portion of the
URL of this server.  The "server name" is defined as the leading
scheme://authority portion of the URL.  Currently assumes server
access is via HTTP.

=cut

sub server_name($) {
    my $r = shift;
    return canonicalized_server_URL('http', $r->server->server_hostname,
				    $r->server->port);
}

=item diff_TZ($origin_TZ, $mirror_TZ)

Get the usual time difference (in seconds) between the two time zones.
Will yield the wrong results in the midst of a change to/from daylight
savings time.  Specifically, as used in this module, this function
will return the wrong results when applied to files retrieved by the
mirror during the two hours of the year when one server is in Daylight
Savings Time and the other is not.

=cut

sub diff_TZ($$) {
    my($mirror_TZ, $origin_TZ) = @_;

    return 0 if $origin_TZ eq $mirror_TZ; # no need to do anything

    # Use Thu Jan 01 00:00:00 GMT 1998 as a reference time.  No
    # changes to/from Daylight Savings Time occurred near this time.
    my $reference_time = 883612800;

    return Time::Zone::tz_offset(Time::Zone::tz2zone($mirror_TZ),
				 $reference_time)
      - Time::Zone::tz_offset(Time::Zone::tz2zone($origin_TZ),
			      $reference_time);
}

=item $gw->update_via_header_field($response)

Update Via header in HTTP::Response with information about this hop.
Hop information combines protocol information from the message with
server information from the B<Apache> server.  The server name
returned is hardcoded as 'C<apache>'.

Eventually, options should be provided to control hostname suppression
and comment customization.

=cut

sub update_via_header_field($$) {
    my($self, $response) = @_;
    my $r = $self->{REQUEST};

    # Set protocol.
    my $hop = $response->protocol;

    # Oops.  No protocol.  Try to guess from request.
    unless(defined $hop) {
	$hop = (uc(Apache::URI->parse($r, $response->request->url)->scheme)
		. '/unknown');
    }

    # HTTP protocol-name can be dropped.  Remember if the server is
    # being accessed via HTTP.
    my $server_accessed_via_HTTP = ($hop =~ s{^HTTP/}{});

    # Set server name.
    $hop .= ' apache';		# For now, use a pseudonym.
    $hop .= ':' . $r->server->port
      unless $server_accessed_via_HTTP && $r->server->port == 80;

    # Set comment.  Comment text may not contain embedded parentheses.
    my $comment = SERVER_VERSION;
    $comment =~ tr/()/[]/;	# Replace parentheses with brackets.
    $hop .= ' (' . $comment . ')'; # Append comment.

    # Update header.
    my $via = $response->header('Via');
    $response->header(Via => defined $via ? $via . ', ' . $hop : $hop);
}

=item copy_header_to_Apache_request($r, $headers)

Copy the headers from an C<HTTP::Headers> object to an
C<Apache::Request>.  Hope that the B<Apache> request object will later
print out the headers in "Good Practice" order (there appears to be no
way of controlling this).

The only tricky item is the Content-Type header, which needs special
handling.

=cut

sub copy_header_to_Apache_request($$) {
    my($r, $header) = @_;

    # Apache might already know the proper content type, e.g., by use
    # of a ForceType directive.  If so, try not to override it.  Else,
    # the type needs to be set explicitly with the Apache request's
    # content_type method: simply setting the header value isn't
    # enough.
    if(defined $r->content_type) {
	$header->content_type(undef);
    }
    else {
	$r->content_type($header->content_type);
    }

    # Copy headers to Apache request (in "Good Practice" order).
    $header->scan(sub {$r->header_out(@_);});
}

sub print_headers($$$) {
    my ($self, $response, $allow_abort) = @_;
    my $r = $self->{REQUEST};
    my $site = $self->{SITE};
    my $path = $self->{GW_PATH};

    # Copy status code and reason phrase from response to Apache
    # request.
    $r->status($1) if $response->status_line =~ /^(\d+)/;
    $r->status_line($response->status_line);

    # Attempt to abort on failure.
    return if $allow_abort && $response->is_error;

    # $r->log_error('Gateway: ' . $response->request->url
    #               . ' ' . $response->status_line);

    # configuration info for this directory
    my $loc_conf = $self->location_config;

    # Try to modify Content-Base to refer to our multiplexer.
    if(my $base = $response->header('Content-Base')) {
	# where site appears on gateway, e.g., <http://www.perl.com/CPAN/>.
	my $gw_site = server_name($r) . $loc_conf->{ROOT};
	$response->header(Content_Base => $base)
	  if $base =~ s/^$site/$gw_site/;
    }

    # If necessary, try to compensate for servers with broken clocks.
    if(my $lm = $response->last_modified) {
	my $upstream_server = server_name_from_URL($r,
		$response->request->url->as_string);
	if(exists $loc_conf->{BROKEN_CLOCK}{$upstream_server}) {
	    my $TZ = $loc_conf->{BROKEN_CLOCK}{$upstream_server};
	    $response->last_modified($lm + diff_TZ($$TZ[1], $$TZ[0]));
	}
    }

    $self->update_via_header_field($response);
    copy_header_to_Apache_request($r, $response);
    $r->send_http_header;
}

=item redirect($allow_abort);

Try a redirect.  We do this via C<LWP::UserAgent> because
C<internal_redirect_handler> does not provide hooks for detecting and
recovering from errors.

=cut

sub redirect($$) {
    my ($self, $allow_abort) = @_;

    my $r = $self->{REQUEST};
    my $ua = $self->{UA};
    my $site = $self->{SITE};
    my $path = $self->{GW_PATH};

    my $url = Apache::URI->parse($r, $site . $path);

    # If this is an anon-FTP request, fill in the password with the
    # UA's from field.
    if($url->scheme eq 'ftp' && $url->user eq 'anonymous') {
	$url->password($ua->from) # anon-FTP passwd
    }

    my $request = HTTP::Request->new($r->method, $url->unparse);

    # If upstream server has a broken clock, calculate how much we
    # need to adjust condition GET time fields.  Note: this code won't
    # work correctly if we get redirected to another server with a
    # different clock.  Oh, well.
    my $loc_conf = $self->location_config;
    my $upstream_server = server_name_from_URL($r, $url);
    my $broken_clock = 0;
    if(exists $loc_conf->{BROKEN_CLOCK}{$upstream_server}) {
	my $TZ = $loc_conf->{BROKEN_CLOCK}{$upstream_server};
	$broken_clock = diff_TZ($$TZ[1], $$TZ[0]);
    }

    if(my $IMS = $r->header_in('If-Modified-Since')) {
	$request->if_modified_since(HTTP::Date::str2time($IMS)
				    - $broken_clock);
    }
    if(my $IUmS = $r->header_in('If-Unmodified-Since')) {
	$request->if_unmodified_since(HTTP::Date::str2time($IUmS)
				      - $broken_clock);
    }

    $request->header(Accept => $r->header_in('Accept'));

    # Pragma directives must be passed through.
    if(my $pragma = $r->header_in('Pragma')) {
	$request->header($pragma);
	$request->header('Cache-Control' => 'no-cache')	# HTTP/1.1
	  if $pragma =~ /^no-cache$/i;
    }

    # Cache directives must be passed through.
    if(my $cache = $r->header_in('Cache-Control')) {
	$request->header('Cache-Control' => $cache);
    }

    # We would like the first callback to occur as soon as reasonably
    # possible after the headers have been retrieved.  Thus, we need a
    # small size argument because the first callback may not occur
    # until all the headers plus size bytes of the content have been
    # retrieved.

    my $headers_printed;
    my $response = $ua->request($request,
		sub {
		    my($data, $response) = @_;
		    $self->print_headers($response, $allow_abort)
		      unless $headers_printed;
		    $headers_printed = 1;
		    return if($allow_abort && $response->is_error
			      || $r->connection->aborted);
		    $r->print($data);
		},
				1024);

    # Be sure we've printed the headers.  We need this check here
    # because callback will never get called for responses with no
    # content.
    $self->print_headers($response, $allow_abort)
      unless $headers_printed || $r->connection->aborted;
}

=item $gw->site( [$site] )

Get/set the site tried.  Can be used to determine which upstream
server actually fields a request.

=cut

sub site($;$) {
    my $self = shift;
    if (@_) { $self->{SITE} = shift }
    return $self->{SITE};
}

=item $gw->try_URI($allow_abort)

Try the site $gw->site.  Ideally, we could use
C<Apache::internal_redirect_handler> to try the redirects.  However,
it provides no hook for detecting an error and aborting output.
That's not B<mod_perl>'s fault--B<Apache> source would need to be
modified to support such a hook.

=cut

sub try_URI($$) {
    my ($self, $allow_abort) = @_;
    clear_headers_for_redirect($self->{REQUEST});
    $self->redirect($allow_abort);
}

=item try_sites($allow_last_site_abort, @site)

Try sites in order until one succeeds.  $allow_last_site_abort
indicates if the last site can/should be aborted after examing the
head for its error code.  All other sites always allow premature
abortion.

Abortion is needed because only one request can be allowed to run to
completion and produce a message body.

=cut

sub try_sites($$@) {
    my ($self, $allow_last_site_abort, @site) = @_;

    my $r = $self->{REQUEST};

    # Try all but last site, aborting each attempt on error.
    for(my $i = 0; $i <= $#site; ++$i) {
	if(ref $site[$i]) {
	    # Try this group of sites, starting at index $idx.
	    my $mux_site = $site[$i];
	    my $idx = $mux_site->{START_INDEX};
	    my $list = $mux_site->{SITE};
	    my $last = $#$list;
	    $self->try_sites($i < $#site || $allow_last_site_abort,
			     @$list[$idx .. $last], @$list[0 .. ($idx - 1)]);

	    # Increment index for next time round.
	    $mux_site->{START_INDEX} = $idx < $last ? ++$idx : 0;
	}
	else {
	    $self->{SITE} = $site[$i];
	    $self->try_URI($i < $#site || $allow_last_site_abort);
	}

	# We can exit if the last attempt succeeded or if the client
	# is no longer talking to us.
	return if(!HTTP::Status::is_error($r->status)
		  || $r->connection->aborted);
    }
}

# Set up the user agent for this particular request.
sub _init_ua($) {
    my $self = shift;
    my $r = $self->{REQUEST};
    my $ua = $self->{UA};
    $ua->from($r->server->server_admin);
    $ua->agent($r->header_in('User-Agent'));
    $ua->timeout($self->location_config->{TIMEOUT});
    return 1;			# succeeded
}

# Set $self->{GW_PATH} to the portion of the path relative to
# GatewayRoot.  This is also the path which is appended to the URIs of
# the upstream servers.
sub _init_path($) {
    my $self = shift;
    my $r = $self->{REQUEST};

    # epath = $gw_root . $gw_path
    my $gw_root = $self->location_config->{ROOT};
    my ($gw_path) = $r->parsed_uri->path =~ /^\Q$gw_root\E(.*)/;

    unless(defined $gw_path) {	# error
	$r->log_error($r->uri . ' does not begin with ' . $gw_root);
	$r->status(HTTP::Status::RC_INTERNAL_SERVER_ERROR);
	return;
    }

    $self->{GW_PATH} = $gw_path; # succeeded
    return 1;
}

sub _init_request($) {
    my $self = shift;
    $self->_init_config_file	or return;
    $self->_init_ua		or return;
    $self->_init_path		or return;
    return 1;			# succeeded
}

=item $gw->site_list

Get the list of sites to try for this request.  Can be overridden to
customize the list of sites to try.

By default, this method looks through the LocationMatch sections in
the GatewayConfig file in order and returns the sites in the first
section matched.

=cut

sub site_list($) {
    my $self = shift;
    my $location_conf = $self->location_config;
    my $gw_path = $self->{GW_PATH};
    foreach my $entry (@{$location_conf->{LOCATION}}) {
	if($gw_path =~ /$entry->{PATTERN}/) {
	    return @{$entry->{SITE}};
	}
    }
    return;
}

=item $gw->send_request( [$r] )

Send the Apache request to the upstream server.  Optionally sets it
first.

=cut

sub send_request($;$) {
    my $self = shift;
    if (@_) { $self->{REQUEST} = shift }
    $self->_init_request or return;
    $self->try_sites(0, $self->site_list);
    return 1;			# succeeded
}

sub handler {
    if(! defined $gw) {
	$gw = new Apache::Gateway;
    }

    $gw->send_request(shift);

    return 0;
}

1;

__END__

=back

=head1 CAVEATS

C<Apache::Gateway> is a big, complicated module that loads many other
modules.  As such, it pushes C<mod_perl> to its limits, especially
when used with DSO/APXS.

The current version of C<LWP> (5.35) only supports If-Modified-Since
for file and ftp URLs.  Thus, gatewaying to ftp servers will actually
be better than gatewaying to http servers for cached responses.

=head1 BUGS

A ProxyRemote-like capability is needed for origin servers which must
be accessed through a proxy.

A ProxyPassReverse analogue might be useful, too.

C<Apache::Gateway> assumes it is being accessed using HTTP.  Ought to
handle cases where this gateway is accessed using https (SSL).

There is no way to tell LWP to use a proxy.

The C<Server> response header field should contain information about
the origin server, not this server.  Unfortunately, Apache overrides
any existing origin server information in this field.

=head1 AUTHOR

Charles C. Fu, perl@web-i18n.net

=head1 SEE ALSO

perl(1), Apache(3pm), LWP(3pm).

=cut
