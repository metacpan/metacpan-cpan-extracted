package CGI::Buffer;

# CGI::Buffer captures everything that a CGI script prints, and when the
# script ends (in the END block) verifies, optimises, compresses and caches
# it before sending it to the web server.

use 5.26.0;	# CGI::Info's dependencies, e.g. Params::Validate::Strict, need it
use strict;
use warnings;

use Carp;
use Digest::MD5;
use IO::String;
use Readonly;
use Scalar::Util;

# CGI::Info, HTTP::Date, HTTP::Status and Storable are only loaded when they're
# needed.  A CGI program is compiled afresh for every request, and CGI::Info
# alone takes over 100ms to compile, which is far more than the rest of this
# module

Readonly my $DEFAULT_GENERATE_304 => 1;
Readonly my $DEFAULT_GENERATE_LAST_MODIFIED => 1;
Readonly my $DEFAULT_COMPRESS_CONTENT => 1;
Readonly my $DEFAULT_OPTIMISE_CONTENT => 0;
Readonly my $DEFAULT_LINT_CONTENT => 0;
Readonly my $DEFAULT_CACHE_DURATION => '10 minutes';
Readonly my $DEFAULT_PROTOCOL => 'http';

# Smaller bodies than this aren't worth compressing
Readonly my $MIN_GZIP_LEN => 32;

# optimise_content at this level, or higher, repeats until the body stops
# shrinking and also optimises JavaScript
Readonly my $AGGRESSIVE_OPTIMISATION => 2;

# The HTTP statuses that this module works with
Readonly my $HTTP_OK => 200;
Readonly my $HTTP_PARTIAL_CONTENT => 206;
Readonly my $HTTP_NOT_MODIFIED => 304;
Readonly my $HTTP_NOT_ACCEPTABLE => 406;
Readonly my $HTTP_PRECONDITION_FAILED => 412;
Readonly my $HTTP_RANGE_NOT_SATISFIABLE => 416;
Readonly my $HTTP_INTERNAL_SERVER_ERROR => 500;

# The longest a client's Cache-Control: max-age may keep a page in the
# server-side cache, since one client's request affects all others
Readonly my $MAX_CLIENT_CACHE_SECONDS => 600;

# The cookie that holds the token protecting forms, different for each client
# but it doesn't change the output
Readonly my $FORM_TOKEN_COOKIE => 'csrf_token';

# Cache-Control directives which, in a request or a response, stop the cache
Readonly my %NO_CACHE_DIRECTIVES => map { $_ => 1 } qw(no-store no-cache private);

# Request methods whose responses may be cached, or answered with a 304
Readonly my %SAFE_METHODS => map { $_ => 1 } qw(GET HEAD);

# The protocols that understand ETag, If-None-Match and If-Modified-Since
Readonly my $CONDITIONAL_PROTOCOL => qr/^HTTP\/(?:1\.1|[23](?:\.0)?)$/;

# The methods that CGI::Buffer calls on the logger
Readonly my @LOGGER_METHODS => qw(trace debug info warn error);

# An ETag sent with compressed content ends in the name of the encoding
Readonly my $ENCODED_ETAG_SUFFIX => qr/-(?:gzip|br|zstd)"$/;

# Content encodings that we can produce, and the module needed for each
Readonly my %ENCODING_MODULE => (
	'gzip' => 'Compress::Zlib',
	'x-gzip' => 'Compress::Zlib',
	'br' => 'IO::Compress::Brotli',
	'zstd' => 'Compress::Zstd',
);

# A sprintf conversion, as used in the %{name}s placeholders of messages
Readonly my $SPRINTF_CONVERSION => qr/[-+ 0#]*\d*(?:\.\d+)?[sdfux]/;

# Everything that CGI::Buffer says, keyed by message.  A message is either a
# string, or a hash of plural forms chosen by the "count" argument.
# Placeholders are %{name} followed by a sprintf conversion.  Each can be
# replaced, e.g. translated, with init(messages => { key => '...' })
Readonly my %DEFAULT_MESSAGES => (
	too_late => {
		one => 'Too late to call init, %{count}d character has been printed',
		other => 'Too late to call init, %{count}d characters have been printed',
	},
	unknown_option => 'init: unknown option %{option}s ignored',
	bad_option => 'init: %{option}s %{reason}s, ignored',
	failed => '%{what}s failed: %{error}s',
	no_cache_data => 'error retrieving data for key %{key}s',
	no_cache_body => "Can't retrieve body for key %{key}s, the entry holds: %{fields}s",
	logger_method => "The logger doesn't understand %{method}s()",
	no_script_path => 'Failed to retrieve script path',
	no_script_age => "Can't determine the age of %{path}s: %{error}s",
	no_info => 'Failed to create CGI::Info object',
	send_failed => 'Sending the output failed: %{error}s',
	lint => '%{where}s: %{text}s',
);

# What each option to init() must be: a "scalar", a non-negative "count",
# a "hash" reference, or an "object" which understands the methods listed
Readonly my %INIT_OPTIONS => (
	generate_etag => ['scalar'],
	generate_last_modified => ['scalar'],
	generate_304 => ['scalar'],
	compress_content => ['scalar'],
	lint_content => ['scalar'],
	optimise_content => ['count'],
	cache => ['object', 'get_object', 'set'],
	cache_key => ['scalar'],
	cache_duration => ['scalar'],
	cache_age => ['scalar'],	# Legacy name for cache_duration
	logger => ['object'],	# _check_logger() looks at its methods
	lingua => ['object', 'language'],
	info => ['object', 'status', 'host_name'],
	messages => ['hash'],
);

=encoding utf8

=head1 NAME

CGI::Buffer - Verify, Cache and Optimise CGI Output

=head1 VERSION

Version 0.89

=cut

our $VERSION = '0.89';

=head1 SYNOPSIS

CGI::Buffer verifies the HTML that you produce by passing it through
C<HTML::Lint>.

CGI::Buffer optimises CGI programs by reducing, filtering and compressing
output to speed up the transmission and by nearly seamlessly making use of
client and server caches.

To make use of client caches, that is to say to reduce needless calls
to your server asking for the same data, all you need to do is to
include the package, and it does the rest.

    use CGI::Buffer;
    # ...

To also make use of server caches, that is to say to save regenerating
output when different clients ask you for the same data, you will need
to create a cache.
But that's simple:

    use CHI;
    use CGI::Buffer;

    # Put this at the top before you output anything
    if(CGI::Buffer::init(cache => CHI->new(driver => 'File'))->is_cached()) {
	# Nothing has changed - use the version in the cache
	exit;
    }

    # ...

To temporarily prevent the use of server-side caches, for example whilst
debugging before publishing a code change, set the NO_CACHE environment variable
to any non-zero value.
If you get errors about Wide characters in print it means that you've
forgotten to emit pure HTML on non-ASCII characters.
See L<HTML::Entities>.
As a hack work around you could also remove accents and the like by using
L<Text::Unidecode>,
which works well but isn't really what you want.

=head2 HOW THE OUTPUT IS SENT

When the script ends, CGI::Buffer:

=over 4

=item * optimises (C<optimise_content>) and checks (C<lint_content>) HTML;

=item * answers conditional requests (If-None-Match, If-Modified-Since) with
304, or 412 for methods other than GET and HEAD;

=item * answers a single byte Range with 206, or 416 if it can't be met, when
there's no server-side cache;

=item * compresses with the first encoding in Accept-Encoding that it can
produce (gzip, br or zstd);

=item * stores the output in, or sends it from, the server-side cache;

=item * sends one Status header, and a Content-Length worked out from what is
actually sent.

=back

If any of that fails, a warning is given and the output is sent as the script
printed it.

=head1 SUBROUTINES/METHODS

=cut

# Options.  $generate_etag is undef until it's given, in which case it's decided
# from the protocol when the output is sent
our $generate_etag;
our $generate_304 = $DEFAULT_GENERATE_304;
our $generate_last_modified = $DEFAULT_GENERATE_LAST_MODIFIED;
our $compress_content = $DEFAULT_COMPRESS_CONTENT;
our $optimise_content = $DEFAULT_OPTIMISE_CONTENT;
our $lint_content = $DEFAULT_LINT_CONTENT;
our($cache, $cache_duration, $cache_key, $info, $logger, $lingua);

# Messages given to init() to replace those in %DEFAULT_MESSAGES
our %messages;

# The state of this request.  $cacheable is the remembered answer of
# can_cache().  @o is the list of headers that CGI::Buffer adds to the script's
# own, which are in $headers
our($status, $script_mtime, $cobject, $cacheable, $headers, $body, @content_type,
	$etag, $send_body, @o);

# $raw is what the script printed, which is sent if processing it fails.
# $sent is set once output has started.  $script_encoded is set if the script
# gave its own Content-Encoding.  $content_encoding is the encoding that we've
# applied.  $matched_etag is the client's ETag that If-None-Match matched
our($raw, $sent, $script_encoded, $content_encoding, $matched_etag);

# $capture holds everything that the script prints, $old_buf is where it
# would otherwise have gone
our($capture, $old_buf);

BEGIN {
	# Capture the output from now on, so that it can all be looked at
	# before any of it is sent
	$capture = IO::String->new();
	$old_buf = select($capture);
}

END {
	# Nothing can be sent while Perl is destroying everything
	return if(${^GLOBAL_PHASE} eq 'DESTRUCT');

	# Premise 1: anything from here on can fail, e.g. a logger or a cache
	# Premise 2: until this is done, all that the process prints goes into
	#	the buffer, which is never sent
	# Conclusion: this must be the first thing that is done
	select($old_buf);

	# This can run while an eval is unwinding, and $? is the exit status
	local($@, $!, $?);

	# Premise 1: Perl only gives a warning for an exception in an END block
	# Premise 2: the client would be given an empty response
	# Conclusion: catch it, and send the output as the script printed it
	unless(eval { _send_output(); 1 }) {
		_problem('send_failed', { error => $@ });
		_send_raw() unless($sent);
	}

	# This will cause everything to get flushed and prevent
	# outputs to the logger.  We need to do that now since
	# if we leave it to Perl to delete later we may get
	# a message that Log4perl::init() hasn't been called
	$logger = undef;
}

# Purpose: send what the script printed, untouched, after processing it failed
# Entry criteria: $raw holds the script's output, or is undef if it wasn't read
# Exit status: none
# Side effects: prints to the original output, sets $sent
sub _send_raw {
	$sent = 1;
	if(defined($raw) && length($raw)) {
		print _to_bytes($raw);
	} else {
		# The script relied upon a cache that has now failed
		print _status_line($HTTP_INTERNAL_SERVER_ERROR), "\r\n\r\n";
	}
}

# Purpose: process everything that the script printed, and send it
# Entry criteria: the script has finished, and its output is in $capture
# Exit status: none, it dies if something unexpected fails, which END catches
# Side effects: prints the response, changes most of the request state
sub _send_output {
	_read_output();

	# Premise 1: an ETag is only useful if the protocol supports If-None-Match
	# Premise 2: an explicit generate_etag argument is the caller's decision
	# Conclusion: default it from the protocol, but only when it isn't given
	$generate_etag = _is_conditional_protocol() ? 1 : 0 unless(defined($generate_etag));
	_log_request();

	# No headers and nothing in the cache: there's nothing to send but a status
	unless($headers || is_cached()) {
		_send_status_only();
		return;
	}
	$send_body = (defined($ENV{'REQUEST_METHOD'}) && ($ENV{'REQUEST_METHOD'} eq 'HEAD')) ? 0 : 1;
	_set_content_type($headers) if($headers);

	if(defined($body) && ($body eq '')) {
		# E.g. if header of Location is given with no body, for
		#	redirection
		$body = undef;
	} elsif(_is_html() && defined($body) && !$script_encoded) {
		_optimise_html() if($optimise_content);
		_lint_html() if($lint_content);
	}
	_initial_status();

	# Range, Content-Length, compression and the ETag all work in bytes.
	# A script which printed bytes is left alone: encoding those would
	# encode any UTF-8 in them a second time
	$body = _to_bytes($body);

	my $unzipped_body = _prepare_body();

	if($cache) {
		_use_cache($unzipped_body);
	} else {
		push @o, @{_x_cache_headers('MISS', 'MISS')};
		if($info && $generate_last_modified && (my $age = _my_age())) {
			push @o, 'Last-Modified: ' . _http_date($age);
		}
	}

	_add_vary($headers);
	_add_etag_header();
	_emit();
}

# Purpose: read what the script printed, and split it into headers and body
# Entry criteria: the script has finished printing
# Exit status: none
# Side effects: sets $raw, $headers and $body
sub _read_output {
	my $pos = $capture->getpos();
	$capture->setpos(0);
	read($capture, my $output, $pos);

	# Keep this before anything else that can fail, it's what will be sent
	# if something does
	$raw = $output;
	($headers, $body) = split /\r?\n\r?\n/, $output, 2;
}

# Purpose: log what was asked of us, to help with debugging
# Entry criteria: $generate_etag has been decided
# Exit status: none
# Side effects: writes to the logger, if there is one
sub _log_request {
	foreach my $header('HTTP_IF_NONE_MATCH', 'HTTP_IF_MODIFIED_SINCE') {
		_log('debug', "$header: $ENV{$header}") if($ENV{$header});
	}
	_log('debug', "Generate_etag = $generate_etag, ",
		"Generate_304 = $generate_304, ",
		"Generate_last_modified = $generate_last_modified");
}

# Purpose: answer a request for which the script printed nothing
# Entry criteria: $headers is empty and the page isn't in the cache
# Exit status: none
# Side effects: prints a Status header if the script printed nothing at all
sub _send_status_only {
	_log('debug', 'There was no output');

	# Headers that are defined but empty, i.e. the script only printed
	# blank lines, are left as they are
	return if(defined($headers));

	$status = $info ? $info->status() : $HTTP_OK unless(defined($status));
	$sent = 1;
	print _status_line($status), "\n\n";
}

# Purpose: work out the status that the script wants to send
# Entry criteria: $headers is the script's headers, if any
# Exit status: none
# Side effects: sets $status
sub _initial_status {
	if(defined($headers) && ($headers =~ /^Status:\s*(\d+)/mi)) {
		$status = $1;
	} else {
		$status = $info ? $info->status() : $HTTP_OK;
	}
	_log('debug', "Initial status = $status");
}

# Purpose: answer conditional and Range requests for output that the script has
#	just generated, then compress it
# Entry criteria: $body is bytes or undef, $status is set
# Exit status: the uncompressed body, which is what the cache stores, or undef
# Side effects: may change $status, $send_body, $body, $etag and @o
sub _prepare_body {
	my $encoding = _choose_encoding();
	my $unzipped_body = $body;

	# Generate the eTag before compressing, since the compressed data
	# includes the mtime field which changes thus causing a different
	# Etag to be generated
	if($generate_etag && defined($body) && _is_conditional_protocol()) {
		_generate_etag();
		_check_if_none_match() if($ENV{'HTTP_IF_NONE_MATCH'} && $generate_304 && ($status == $HTTP_OK));
	}

	if(defined($unzipped_body)) {
		# Conditions are looked at before Range, and If-Modified-Since
		# isn't looked at if If-None-Match was checked and failed.
		# With a cache, _use_cache() looks at it instead
		if((!$cache) && $info && $ENV{'HTTP_IF_MODIFIED_SINCE'} && ($status == $HTTP_OK) &&
		   !($ENV{'HTTP_IF_NONE_MATCH'} && defined($etag))) {
			_check_modified_since(_my_age());
		}

		# Only a successful GET can be cut up, and only if the client's
		# copy, if it has given one, is still the current one
		my $range = $ENV{'HTTP_RANGE'};
		if($range && !$cache && ($status == $HTTP_OK) && _is_get() && _if_range_matches() &&
		   defined(my $partial = _apply_range($body, $range))) {
			# Premise 1: Content-Range counts the bytes of what is sent
			# Premise 2: the offsets the client gave are in the page,
			#	not in a compressed copy
			# Conclusion: a part of a page is never compressed
			$encoding = '';
			_set_status($partial->{status});
			push @o, "Content-Range: $partial->{content_range}";
			if($partial->{status} == $HTTP_RANGE_NOT_SATISFIABLE) {
				# Range Not Satisfiable has no body
				$body = $unzipped_body = undef;
				$send_body = 0;
			} else {
				$body = $unzipped_body = $partial->{body};
			}
		}
		# A 304 or 412 has no body to compress, and mustn't say that it has
		_compress($encoding) if($send_body || ($status == $HTTP_OK));
	}
	return $unzipped_body;
}

# Purpose: use the server-side cache for this request
# Entry criteria: $cache is set, $unzipped_body is from _prepare_body()
# Exit status: none
# Side effects: stores the page, or loads it from the cache.  Releases $cache
sub _use_cache {
	my $unzipped_body = shift;

	require Storable;
	my $key = _generate_key();

	if(defined($body)) {
		# The script generated the page
		_store_in_cache($key, $unzipped_body);
	} elsif((!defined($headers)) || !length($headers)) {
		# The script printed nothing because is_cached() said the page
		# is in the cache
		_serve_from_cache($key);
	} else {
		# Headers with no body, e.g. a redirection.  There's nothing to
		# store, and the cache mustn't replace them
		push @o, @{_x_cache_headers('MISS', 'MISS')}, _buffer_header('Miss');
	}

	# We don't need it any more, so give Perl a chance to
	# tidy it up seeing as we're in the destructor
	$cache = undef;
}

# Purpose: send the copy of the page that is in the server-side cache
# Entry criteria: the script printed nothing, $key is the cache key
# Exit status: none
# Side effects: sets $headers, $body, $status, $send_body, $etag and @o
sub _serve_from_cache {
	my $key = shift;

	# is_cached() has already looked, and it mustn't have expired since then
	$cobject ||= _cache_lookup($key);
	my $cache_hash;
	if(defined($cobject)) {
		$cache_hash = Storable::thaw($cobject->value());
		$headers = $cache_hash->{'headers'};
		_set_content_type($headers) if(defined($headers));
		@o = (_buffer_header('Hit'), @{_x_cache_headers('HIT', 'HIT')});
	} elsif($send_body) {
		_problem('no_cache_data', { key => $key });
	}

	if($send_body && ($status == $HTTP_OK) && defined($cache_hash)) {
		$body = _to_bytes($cache_hash->{'body'});
		unless(defined($body)) {
			# The entry is damaged, remove it so that the next request
			# makes a new one
			_problem('no_cache_body', { key => $key, fields => join(', ', sort keys %{$cache_hash}) });
			_try('removing a bad entry', sub { $cache->remove($key) });
			$headers = _status_line($HTTP_INTERNAL_SERVER_ERROR);
			@o = ('Content-type: text/plain');
			$send_body = 0;
			_set_status($HTTP_INTERNAL_SERVER_ERROR);
		}
	}
	if($send_body && ($status == $HTTP_OK) && $generate_etag && ((!defined($headers)) || ($headers !~ /^ETag:/mi))) {
		_generate_etag();
	}
	unless($etag) {
		# Keep the quotes, they're part of the ETag and If-None-Match
		# includes them
		if(defined($headers) && ($headers =~ /^ETag:\s*("[^"]*")/mi)) {
			$etag = $1;
		} elsif($cache_hash) {
			$etag = $cache_hash->{'etag'};
		}
	}

	# Nothing has been output yet, so we can check if it's OK to send 304.
	# RFC 9110 13.1.3 says not to look at the date if there's an
	# If-None-Match
	if($status == $HTTP_OK) {
		if($ENV{'HTTP_IF_NONE_MATCH'} && defined($etag)) {
			_check_if_none_match() if($generate_304);
		} elsif($ENV{'HTTP_IF_MODIFIED_SINCE'} && $cobject) {
			_check_modified_since($cobject->created_at());
		}
	}

	# A 304 has no body to compress, and mustn't say that it has
	_compress(_choose_encoding()) if(($status == $HTTP_OK) && $send_body);

	if($cobject && ($status == $HTTP_OK) && $generate_last_modified) {
		_log('debug', 'Set Last-Modified to ', _http_date($cobject->created_at()));
		push @o, 'Last-Modified: ' . _http_date($cobject->created_at());
	}
}

# Purpose: store the page that the script generated in the server-side cache
# Entry criteria: $key is the cache key, $unzipped_body the page to store
# Exit status: none
# Side effects: writes to the cache, adds Last-Modified and X-Cache headers to @o
sub _store_in_cache {
	my ($key, $unzipped_body) = @_;

	if($status == $HTTP_OK) {
		# It would be great if CHI::set() allowed the time to be 'lru'
		# for least recently used.
		$cache_duration ||= $DEFAULT_CACHE_DURATION;

		my $storable = _is_storable($headers, $unzipped_body);
		if($storable) {
			my $cache_hash = { body => $unzipped_body };

			# Remember, we're storing the UNzipped version in the
			# cache, so leave out what's about this response's
			# encoding and length.  Blank lines would end the headers
			my @stored = grep {
				length && !/^(?:Content-Encoding|Content-Length|Content-Range):/i &&
				!/^Vary:\s*Accept-Encoding\s*$/i
			} ((defined($headers) ? split(/\r?\n/, $headers) : ()), @o);
			$cache_hash->{'headers'} = join("\r\n", @stored) if(scalar(@stored));

			if($generate_etag) {
				_generate_etag();
				$cache_hash->{'etag'} = $etag;
			}
			_log('debug', "Store $key in the cache, age = $cache_duration ", length($cache_hash->{'body'}), ' bytes');
			_try('storing in the cache', sub {
				$cache->set($key, Storable::freeze($cache_hash), $cache_duration);
			});
		}
		if($generate_last_modified) {
			# The time it was stored, or now if it wasn't
			$cobject = $storable ? _cache_lookup($key) : undef;
			push @o, 'Last-Modified: ' . _http_date(defined($cobject) ? $cobject->created_at() : time);
		}
	}
	push @o, @{_x_cache_headers('MISS', 'MISS')}, _buffer_header('Miss');
}

# Purpose: add the ETag header, if there is one to send
# Entry criteria: $etag is the ETag of the uncompressed body, if one was made
# Exit status: none
# Side effects: adds to @o
sub _add_etag_header {
	if($generate_etag && defined($etag) && ((!defined($headers)) || ($headers !~ /^ETag:/mi))) {
		# The compressed and the uncompressed versions aren't the same
		# bytes, so can't have the same strong ETag.
		# _check_if_none_match() removes the suffix again, and a 304 is
		# about the copy that the client has so gives back its ETag
		my $e = defined($matched_etag) ? $matched_etag : $etag;
		$e =~ s/"$/-$content_encoding"/ if($content_encoding && !defined($matched_etag));
		push @o, "ETag: $e";
		_log('debug', "Set ETag to $e");
	}
}

# Purpose: print the response
# Entry criteria: $headers, @o, $body and $send_body are final
# Exit status: none
# Side effects: prints to the original output, sets $sent
sub _emit {
	my $body_length = 0;
	if(defined($body)) {
		$body = _to_bytes($body);
		$body_length = length($body);
	}
	my $with_body = $body_length && $send_body;

	if(defined($headers) && length($headers)) {
		# Put the original headers first, then those generated within
		# CGI::Buffer.  The script is free to end its lines with \n
		unshift @o, grep { length } split(/\r?\n/, $headers);

		# The body may well have changed since the script worked out its
		# length
		@o = grep { !/^Content-Length:/i } @o if(defined($body));
		push @o, "Content-Length: $body_length" if($with_body);
		_set_status_header();
	} else {
		push @o, _buffer_header('No headers');
	}

	$sent = 1;
	print join("\r\n", @o, ($with_body ? ('', $body) : ()));

	# Without a body, a blank line must still end the headers
	print "\r\n\r\n" unless($with_body);
}

# Purpose: answer If-Modified-Since
# Entry criteria: $modified is when the page was last changed, the request has
#	an If-Modified-Since header
# Exit status: none
# Side effects: may set a 304 status, see _answer_without_body()
sub _check_modified_since {
	my $modified = shift;

	_log('trace', 'In _check_modified_since');

	# RFC 9110 13.1.3: If-Modified-Since is ignored for other methods
	return unless($generate_304 && _is_safe_method() && defined($modified));

	# An invalid date is ignored
	my $since = _parse_http_date($ENV{'HTTP_IF_MODIFIED_SINCE'});
	return unless(defined($since));

	# If the script has been updated since, it may produce different output
	my $age = _my_age();
	if(defined($age) && ($age <= $since) && ($modified <= $since)) {
		_answer_without_body($HTTP_NOT_MODIFIED);
	}
}

# Purpose: answer If-None-Match
# Entry criteria: $etag is the ETag of the page
# Exit status: true if a 304 or 412 is to be sent
# Side effects: may set a status, see _answer_without_body().  Sets $matched_etag
sub _check_if_none_match {
	my $matched = 0;

	if($ENV{'HTTP_IF_NONE_MATCH'} && defined($etag)) {
		_log('debug', "Compare $ENV{HTTP_IF_NONE_MATCH} with $etag");

		# The header is "*" or a list of entity tags, any of which may be
		# weak.  If-None-Match uses the weak comparison (RFC 9110 8.8.3.2),
		# under which the compressed version of a page matches
		foreach my $tag(split(/\s*,\s*/, $ENV{'HTTP_IF_NONE_MATCH'})) {
			(my $client_etag = $tag) =~ s/^W\///;
			(my $e = $client_etag) =~ s/$ENCODED_ETAG_SUFFIX/"/;
			if($e eq $etag) {
				$matched_etag = $client_etag;
				$matched = 1;
				last;
			}
			$matched = 1 if($e eq '*');
		}
		# RFC 9110 13.1.2: 304 is only for GET and HEAD
		_answer_without_body(_is_safe_method() ? $HTTP_NOT_MODIFIED : $HTTP_PRECONDITION_FAILED) if($matched);
	}
	_log_diffs() unless($matched);
	return $matched;
}

# Purpose: when debugging, log how a page differs from its copy in the cache
# Entry criteria: none, it only does something if the logger is debugging
# Exit status: none
# Side effects: reads the cache, writes to the logger
sub _log_diffs {
	return unless($cache && $logger && $logger->can('is_debug') && $logger->is_debug() && _can_load('Text::Diff'));

	_try('comparing with the cache', sub {
		my $cached_copy = $cache->get(_generate_key());

		if($cached_copy && $body) {
			require Storable;

			$cached_copy = Storable::thaw($cached_copy)->{body};
			$logger->debug('diffs: ', Text::Diff::diff(\$body, \$cached_copy));
		} else {
			$logger->debug('Nothing to compare');
		}
	});
}

# Purpose: send a status that has no body, e.g. 304
# Entry criteria: $code is the HTTP status
# Exit status: none
# Side effects: adds a Status header to @o, sets $status and $send_body
sub _answer_without_body {
	my $code = shift;

	push @o, _status_line($code);
	_set_status($code);
	$send_body = 0;
	_log('debug', "Set status to $code");
}

# Purpose: optimise HTML, i.e. make it smaller without changing what it shows
# Entry criteria: $body is HTML, $optimise_content is set
# Exit status: none
# Side effects: changes $body, loads HTML::Packer and maybe CGI::Info
sub _optimise_html {
	require HTML::Packer;	# Overkill using HTML::Clean and HTML::Packer...

	_log('trace', 'Packer');

	# Whitespace is significant in these, in a <textarea> it's the user's data
	my $preformatted = _protect_preformatted();

	# Level 1 is one pass, higher levels repeat until the body stops
	# shrinking
	my $oldlength = length($body);
	_optimise_content();
	if($optimise_content >= $AGGRESSIVE_OPTIMISATION) {
		while(length($body) < $oldlength) {
			$oldlength = length($body);
			_optimise_content();
		}
	}
	_shorten_links();

	# Don't use HTML::Clean because of RT402.
	# Don't always do javascript 'best' since it's confused by the common
	# <!-- HIDE technique.
	# See https://github.com/nevesenin/javascript-packer-perl/issues/1#issuecomment-4356790
	my $options = {
		remove_comments => 1,
		remove_newlines => 0,
		do_stylesheet => 'minify'
	};
	if($optimise_content >= $AGGRESSIVE_OPTIMISATION) {
		$options->{do_javascript} = 'best';
		# [^>] stops the tag running on into the rest of the page
		$body =~ s/(<script[^>]*+>)\s*+<!--/$1/gi;
		$body =~ s/\/\/-->\s*+<\/script>/<\/script>/gi;
		$body =~ s/(<script[^>]*+>)\s++/$1/gi;
	}
	$body = HTML::Packer->init()->minify(\$body, $options);
	_merge_document_writes() if($optimise_content >= $AGGRESSIVE_OPTIMISATION);

	_restore_preformatted($preformatted);
}

# Purpose: make links to this site local, e.g. on http://www.example.com change
#	http://www.example.com/foo/bar.htm to /foo/bar.htm
# Entry criteria: $body is HTML
# Exit status: none
# Side effects: changes $body, may create $info
sub _shorten_links {
	my $site_info = _info();
	my $host = $site_info->host_name();
	my $protocol = $site_info->protocol() || $DEFAULT_PROTOCOL;

	# The attribute can be anywhere in the tag, e.g. <img border=0 src=...>.
	# [^<>] keeps each match inside one tag, so hostile input can't make it
	# search the rest of the page for each tag
	my $attribute = qr/(<(?:a|img)\b[^<>]*?\s(?:href|src)\s*=\s*")/i;

	# The host name must be followed by the end of the link, or the start of
	# its path, query or fragment, otherwise www.example.com.evil.org would
	# become local
	$body =~ s/$attribute\Q$protocol\E:\/\/\Q$host\E"/$1\/"/gi;
	$body =~ s/$attribute\Q$protocol\E:\/\/\Q$host\E(?=[\/?#])/$1/gi;
}

# Purpose: change document.write("a"); document.write("b") into
#	document.write("a"+"b");
# Entry criteria: $body is HTML that HTML::Packer has minified
# Exit status: none
# Side effects: changes $body
sub _merge_document_writes {
	# Every substitution shortens the body, so this always terminates.
	# Nothing may cross a </script>, otherwise writes in different scripts
	# get merged
	1 while($body =~ s{
		(<script\s+type\s*=\s*"text/javascript"\s*>)		# $1: opening tag, kept as written
		((?:(?!</script>).)*?)					# $2: code before the writes, within this script
		document\.write\(((?:(?!</script>)[^;])*?)\);\s*+	# $3: first argument
		document\.write\(((?:(?!</script>)[^;])*?)\)		# $4: second argument
	}{$1${2}document.write($3+$4)}gisx);
}

# Purpose: check HTML with HTML::Lint, and send the errors instead of the page
# Entry criteria: $body is HTML, $lint_content is set
# Exit status: none
# Side effects: on errors, replaces $headers, @o and $body with a 500 and the
#	list of errors, and gives a warning for each
sub _lint_html {
	require HTML::Lint;
	HTML::Lint->import;

	_log('trace', 'Lint');
	my $lint = HTML::Lint->new();
	$lint->parse($body);
	$lint->eof();

	if($lint->errors) {
		$headers = _status_line($HTTP_INTERNAL_SERVER_ERROR);
		@o = ('Content-type: text/plain');
		$body = '';
		foreach my $error ($lint->errors) {
			my $args = { where => $error->where(), text => $error->errtext() };
			_problem('lint', $args);
			$body .= "$args->{where}: $args->{text}\n";
		}
	}
}

# Purpose: reduce output, e.g. remove superfluous white-space
# Entry criteria: $body is HTML, with <pre> and <textarea> protected
# Exit status: none
# Side effects: changes $body
sub _optimise_content {
	# Remove whitespace around newlines.  Possessive quantifiers and only
	# starting at the beginning of a run of whitespace keep it linear.
	# A "+" at the start of a line is JavaScript, so is left alone
	$body =~ s{
		(?<![^\S\n])	# start only at the beginning of a whitespace run
		[^\S\n]*+	# trailing spaces, tabs and \r before the newline
		\n
		\s*+		# blank lines and indentation after it
	}{\n}gx;
	$body =~ s/\<\/div\>\s+\<div/\<\/div\>\<div/gis;

	# In these, (?<!\s) and possessive quantifiers stop each alternation
	# being retried at every position inside a long run of whitespace
	$body =~ s/(?:<div>\s++|(?<!\s)\s++<div>)/<div>/gi;
	$body =~ s/\s+<\/div\>/\<\/div\>/gis;	# Remove spaces before </div>

	# Whitespace around a paragraph, which may have attributes, isn't
	# shown.  \b stops <pre> and <param> matching, [^<>] stops the tag
	# running on into the rest of the page
	$body =~ s/(?<!\s)\s++(<p\b[^<>]*+>)/$1/gi;
	$body =~ s/(<p\b[^<>]*+>)\s++/$1/gi;
	$body =~ s/(?:(?<!\s)\s++<\/p>|<\/p>\s++)/<\/p>/gi;

	# The structure of the page
	$body =~ s/<html>\s+<head>/<html><head>/is;
	$body =~ s/(?<!\s)\s*+<\/head>\s++<body>\s*+/<\/head><body>/i;
	$body =~ s/<html>\s+<body>/<html><body>/is;
	$body =~ s/<body>\s+/<body>/is;
	$body =~ s/\s+\<\/html/\<\/html/is;
	$body =~ s/\s+\<\/body/\<\/body/is;

	# Spaces between tags can be visible, e.g. "Hello <b>a</b> <i>b</i>",
	# so they're only removed around the block elements below
	$body =~ s/\<\/tr\>\s\<tr\>/\<\/tr\>\<tr\>/gi;
	$body =~ s/\<\/td\>\s\<\/tr\>/\<\/td\>\<\/tr\>/gi;
	$body =~ s/\<\/td\>\s*\<td\>/\<\/td\>\<td\>/gis;
	$body =~ s/\<\/tr\>\s\<\/table\>/\<\/tr\>\<\/table\>/gi;
	$body =~ s/\<td\>\s/\<td\>/gi;
	$body =~ s/\<br\s?\/?\>\s?\<p\>/\<p\>/gi;
	$body =~ s/\<br\>\s+/\<br\>/gi;
	$body =~ s/\s+\<br/\<br/gi;
	$body =~ s/\<br\s?\/\>\s/\<br \/\>/gi;
	$body =~ s/[ \t]+/ /gs;	# Remove duplicate space, don't use \s+ it breaks JavaScript
	$body =~ s/\s\<script/\<script/gi;
	$body =~ s/(<script>\s|\s<script>)/<script>/gis;
	$body =~ s/(<\/script>\s|\s<\/script>)/<\/script>/gis;

	# A link can't leave its quotes, so these can't span tags or backtrack
	# across the rest of the page
	$body =~ s{
		(?<!\s)\s++		# a whole run of whitespace, starting at its first character
		<a\shref="([^"]*+)">	# $1: the link
		\s?
	}{ <a href="$1">}gix;
	$body =~ s{
		\s?
		<a\shref=\s"([^"]*+)">	# $1: the link
	}{ <a href="$1">}gix;
	$body =~ s/\s+<\/a\>\s+/<\/a> /gis;
	$body =~ s/(?:\s?<hr>\s++|(?<!\s)\s++<hr>\s?)/<hr>/gi;

	# Lists
	$body =~ s/<\/li>\s+<li>/<\/li><li>/gis;
	$body =~ s/<\/li>\s+<\/ul>/<\/li><\/ul>/gis;
	$body =~ s/<ul>\s+<li>/<ul><li>/gis;
	$body =~ s/\s+<\/li>/<\/li>/gis;
	$body =~ s/\<\/option\>\s+\<option/\<\/option\>\<option/gis;

	# A title can't contain a tag.  [^<] and the possessive quantifiers stop
	# each unterminated <title> from being searched to the end of the page
	$body =~ s{<title>\s*+([^<]*+)</title>}{
		my $title = $1;
		$title =~ s/(?<!\s)\s++\z//;
		"<title>$title</title>"
	}eix;
	$body =~ s/<\/center>\s+<center>/ /gis;
}

# Purpose: create a key for the cache, unless the caller gave one
# Entry criteria: none
# Exit status: the key
# Side effects: sets $cache_key, may create $info
sub _generate_key {
	unless($cache_key) {
		my $i = _info();
		my $key = join('::', __PACKAGE__, $i->browser_type(), $i->domain_name(), $i->script_name(), $i->as_string());

		# /cgi-bin/foo.cgi/bar and /cgi-bin/foo.cgi/baz are different pages
		$key .= "::PATH_INFO=$ENV{PATH_INFO}" if(defined($ENV{'PATH_INFO'}) && length($ENV{'PATH_INFO'}));
		$key .= '::' . $lingua->language() if($lingua);

		# Different states of the client are stored in different caches
		$key .= "::$_" foreach(@{_client_cookies()});

		# The key is needed before the script has given its headers, so a
		# Vary header can't be part of it.  _is_storable() doesn't store
		# those pages
		$key =~ s/\//::/g;
		$key =~ s/(?:::){2,}/::/g;
		$key =~ s/::$//;
		_log('trace', "Returning $key");
		$cache_key = $key;
	}
	return $cache_key;
}

=head2 init

Set various options and override default values.

=head3 Purpose

Configures CGI::Buffer.  Options which affect the server-side cache must be given
before anything is printed; the others can be given at any time before the
script ends.

=head3 Arguments

A hash or a hash reference of options, any of which may be left out:

=over 4

=item * C<generate_etag> - send an ETag, and answer If-None-Match with 304.
By default, on if the protocol is HTTP/1.1 or later.

=item * C<generate_last_modified> - send a Last-Modified header, default on.
It needs a cache or an C<info> object.

=item * C<generate_304> - answer conditional requests with 304, default on.

=item * C<compress_content> - compress the output if the client accepts it,
default on.

=item * C<optimise_content> - 0 (default) leaves HTML alone, 1 optimises the
HTML and CSS, 2 also does aggressive JavaScript optimisations which may fail.

=item * C<lint_content> - check the HTML with L<HTML::Lint>, default off.
Errors are sent to the client as a 500, so only use this when developing.

=item * C<cache> - a server-side cache: an object that understands get_object(),
set(), get() and remove(), whose objects understand value() and created_at(),
such as a L<CHI> object.  Undef turns the cache off.

=item * C<cache_key> - the key for this page in the cache.  If not given, one
is generated which may not be unique.  It should be a unique value dependent
upon the values set by the browser.

=item * C<cache_duration> - how long to keep pages in the cache, default
'10 minutes'.  C<cache_age> is an old name for this.

=item * C<logger> - an object that understands trace(), debug(), info(),
warn() and error(), such as a L<Log::Log4perl> logger.

=item * C<lingua> - a L<CGI::Lingua> object; the language becomes part of the
generated cache key.

=item * C<info> - a L<CGI::Info> object.  One is created when needed if it isn't
given.  It's only taken from the first call.

=item * C<messages> - a hash of message keys to replacement text, e.g. to
translate the messages, see L</MESSAGES>.

=back

Items stay in the server-side cache by default for 10 minutes.
This can be overridden by the max-age directive of the Cache-Control HTTP header
in the request, if it's a number no larger than 600 seconds, and
the default can be changed by the cache_duration argument to init().

Responses aren't stored in the server-side cache if their headers include
Set-Cookie,
a Cache-Control of no-store, no-cache or private,
or a Vary on anything other than Accept-Encoding
(or Accept-Language when lingua is given),
since they would be given to clients that they weren't meant for.
Neither are HTML pages with no </html>,
which suggests that the script died.
A page that includes the value of the client's C<csrf_token> cookie is never
stored.
The C<csrf_token> and Google Analytics cookies aren't part of the generated
cache key, other cookies and PATH_INFO are.

=head3 Returns

The string 'CGI::Buffer', so that calls can be chained, e.g.
C<< CGI::Buffer::init(...)->is_cached() >>.

=head3 Side Effects

Sets the options for the rest of the request.
Gives a warning for each unknown or invalid option, which is ignored,
and if the cache is given after output has started.

=head3 EXAMPLE

    # Put this toward the top of your program before you do anything
    use CHI;
    use CGI::Lingua;
    use CGI::Buffer;

    CGI::Buffer::init(
	generate_etag => 1,	# make good use of client's cache
	generate_last_modified => 1,	# more use of client's cache
	compress_content => 1,	# gzip the output
	optimise_content => 0,	# optimise your program's HTML, CSS and JavaScript
	cache => CHI->new(driver => 'File'),	# cache requests
	cache_key => 'string',	# key for the cache
	cache_duration => '10 minutes',	# how long to store responses in the cache
	logger => $logger,
	lint_content => 0,	# Pass through HTML::Lint
	generate_304 => 1,	# Generate 304: Not modified
	lingua => CGI::Lingua->new(supported => ['en']),
    );

Init allows a reference of the options to be passed. So both of these work:

    CGI::Buffer::init(generate_etag => 1);
    CGI::Buffer::init({ generate_etag => 1, info => CGI::Info->new() });

Generally speaking, passing by reference is better since it copies less on to
the stack.

Alternatively you can give the options when loading the package:

    use CGI::Buffer { optimise_content => 1 };

=head3 API SPECIFICATION

=head4 INPUT

	{
		generate_etag => { type => 'boolean', optional => 1 },
		generate_last_modified => { type => 'boolean', optional => 1 },
		generate_304 => { type => 'boolean', optional => 1 },
		compress_content => { type => 'boolean', optional => 1 },
		lint_content => { type => 'boolean', optional => 1 },
		optimise_content => { type => 'integer', min => 0, optional => 1 },
		cache => { type => 'object', can => ['get_object', 'set'], optional => 1 },
		cache_key => { type => 'string', optional => 1 },
		cache_duration => { type => 'string', optional => 1 },
		cache_age => { type => 'string', optional => 1 },
		logger => { type => 'object', can => ['trace', 'debug', 'info', 'warn', 'error'], optional => 1 },
		lingua => { type => 'object', can => 'language', optional => 1 },
		info => { type => 'object', can => ['status', 'host_name'], optional => 1 },
		messages => { type => 'hashref', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'string', value => 'CGI::Buffer' }

=head3 MESSAGES

    Key             Meaning                                   Resolution
    --------------  ----------------------------------------  ---------------------------------
    unknown_option  An option that init() doesn't know about  Check the spelling, see above
    bad_option      An option of the wrong type               Pass the type listed above
    logger_method   The logger lacks a method, so is ignored  Use a logger with all five methods
    too_late        The cache was set up after printing       Call init() before printing

=head3 FORMAL SPECIFICATION

    ┌─ Init ──────────────────────────────────────────────┐
    │ ΔOptions                                            │
    │ params? : OPTION ⇸ VALUE                            │
    │ printed : ℕ                                         │
    │ result! : STRING                                    │
    ├─────────────────────────────────────────────────────┤
    │ valid == { o : dom params? | o ∈ dom INIT_OPTIONS ∧ │
    │            params?(o) ∈ INIT_OPTIONS(o) }           │
    │ ∀ o : valid \ {cache} • options'(o) = params?(o)    │
    │ cache ∈ valid ∧ params?(cache) = ⊥ ⇒                │
    │     options'(cache) = ⊥                             │
    │ cache ∈ valid ∧ params?(cache) ≠ ⊥ ∧ can_cache ⇒    │
    │     options'(cache) = params?(cache)                │
    │ result! = "CGI::Buffer"                             │
    └─────────────────────────────────────────────────────┘

=head3 PSEUDOCODE

    get the options from a hash or a hash reference
    for each option
        warn about, and drop, those that are unknown or of the wrong type
    replace any messages first, so that the warnings below use them
    set each option that can be changed at any time
    if anything has been printed, warn that it's too late
    if the cache option was given
        if it's undef, turn the cache off
        else if this request may use the cache
            work out how long to keep pages for
            remember the cache and its key
    return 'CGI::Buffer'

=cut

# The options that can be changed at any time, and where they're kept.  This
# isn't Readonly, since that would also make the variables read only
my %SAFE_OPTIONS = (
	generate_etag => \$generate_etag,
	generate_last_modified => \$generate_last_modified,
	generate_304 => \$generate_304,
	compress_content => \$compress_content,
	optimise_content => \$optimise_content,
	lint_content => \$lint_content,
	lingua => \$lingua,
);

sub init {
	my %params = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	# Messages go first, since they're used for the warnings that follow
	if(ref($params{messages}) eq 'HASH') {
		%messages = (%messages, %{$params{messages}});
	}
	_check_options(\%params);

	# Safe options - can be given at any time
	foreach my $option(keys %SAFE_OPTIONS) {
		${$SAFE_OPTIONS{$option}} = $params{$option} if(defined($params{$option}));
	}
	if(defined($params{logger})) {
		$logger = $params{logger};
		_check_logger();
	}
	$info = $params{info} if(defined($params{info}) && !defined($info));

	# Unsafe options - must be given before output has been started
	my $pos = $capture->getpos();
	_problem('too_late', { count => $pos }) if($pos > 0);

	if(exists($params{cache})) {
		if(!defined($params{cache})) {
			_log('debug', 'disabling cache', ($cache_key ? " $cache_key" : ''));
			$cache = undef;
		} elsif(can_cache()) {
			# There is an argument not to do this since one client will
			# affect others, so it's limited
			my $max_age = _client_max_age();
			if(defined($max_age) && ($max_age <= $MAX_CLIENT_CACHE_SECONDS)) {
				$cache_duration = "$max_age seconds";
				_log('debug', "cache_duration = $cache_duration");
			}
			$cache_duration ||= $params{'cache_duration'} || $params{'cache_age'};
			$cache = $params{cache};
			$cache_key = $params{cache_key} if(defined($params{cache_key}));
		}
	}
	return __PACKAGE__;
}

# Purpose: check the options given to init()
# Entry criteria: $params is a hashref of the options
# Exit status: none
# Side effects: gives a warning for, and deletes, each option that is unknown
#	or invalid
sub _check_options {
	my $params = shift;

	foreach my $option(sort keys %{$params}) {
		my $rule = $INIT_OPTIONS{$option};
		if(!defined($rule)) {
			_problem('unknown_option', { option => $option });
			delete $params->{$option};
		} elsif(defined(my $reason = _option_problem($params->{$option}, @{$rule}))) {
			_problem('bad_option', { option => $option, reason => $reason });
			delete $params->{$option};
		}
	}
}

# Purpose: check one value against a rule from %INIT_OPTIONS
# Entry criteria: $value is the value, $type and @methods the rule.  Undef is
#	always allowed, it means "leave this as it is", or no cache
# Exit status: why the value isn't allowed, or undef if it is
# Side effects: none
sub _option_problem {
	my ($value, $type, @methods) = @_;

	my $reason;
	if(!defined($value)) {
		# Allowed
	} elsif($type eq 'hash') {
		$reason = 'must be a hash reference' unless(ref($value) eq 'HASH');
	} elsif($type eq 'object') {
		if(!Scalar::Util::blessed($value)) {
			$reason = 'must be an object';
		} elsif(my @missing = grep { !$value->can($_) } @methods) {
			$reason = 'must understand ' . join(', ', @missing);
		}
	} elsif(ref($value)) {
		$reason = 'must be a scalar';
	} elsif(($type eq 'count') && ($value !~ /^\d+$/)) {
		$reason = 'must be a number, 0 or more';
	}
	return $reason;
}

sub import {
	# The class name, "CGI::Buffer"
	shift;

	# use CGI::Buffer { optimise_content => 1 } gives the options to init()
	init(@_) if(@_);
}

=head2 set_options

Synonym for init, kept for historical reasons.

=head3 Purpose, Arguments, Returns and Side Effects

As for L</init>.

=head3 EXAMPLE

    CGI::Buffer::set_options(optimise_content => 1);

=head3 API SPECIFICATION

=head4 INPUT

As for L</init>.

=head4 OUTPUT

	{ type => 'string', value => 'CGI::Buffer' }

=head3 MESSAGES

As for L</init>.

=head3 FORMAL SPECIFICATION

    SetOptions ≙ Init

=cut

sub set_options {
	return init(@_);
}

=head2 can_cache

Returns true if the server is allowed to store the results locally.

=head3 Purpose

Says whether this request may use the server-side cache.
The cache isn't used if the NO_CACHE or NO_STORE environment variables are set,
if the request method isn't GET or HEAD,
if the client has logged in (the Authorization header or REMOTE_USER is set),
or if the client's Cache-Control header includes any of no-store, no-cache,
private or max-age=0.

=head3 Arguments

None.

=head3 Returns

1 if the cache may be used, otherwise 0.

=head3 Side Effects

The answer is decided on the first call, and doesn't change for the rest of the
request.

=head3 EXAMPLE

    if(CGI::Buffer::can_cache()) {
	CGI::Buffer::init(cache => CHI->new(driver => 'File'));
    }

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

	{ type => 'boolean' }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

    ┌─ CanCache ──────────────────────────────────────────┐
    │ ΞEnvironment                                        │
    │ result! : 𝔹                                         │
    ├─────────────────────────────────────────────────────┤
    │ result! = true ⇔                                    │
    │   {NO_CACHE, NO_STORE, HTTP_AUTHORIZATION,          │
    │    REMOTE_USER} ∩ dom env = ∅ ∧                     │
    │   (REQUEST_METHOD ∉ dom env ∨                       │
    │    env(REQUEST_METHOD) ∈ {GET, HEAD}) ∧             │
    │   directives(env(HTTP_CACHE_CONTROL)) ∩             │
    │    {no-store, no-cache, private, max-age=0} = ∅     │
    └─────────────────────────────────────────────────────┘

=cut

sub can_cache {
	unless(defined($cacheable)) {
		_log('debug', "cache_control = $ENV{HTTP_CACHE_CONTROL}") if(defined($ENV{'HTTP_CACHE_CONTROL'}));

		# A request may give several directives, e.g. "no-cache, max-age=0",
		# and any one of them forbids the cache
		my $max_age = _client_max_age();
		my $forbidden = defined($ENV{'NO_CACHE'}) || defined($ENV{'NO_STORE'}) ||
			(!_is_safe_method()) || _is_logged_in() ||
			(grep { $NO_CACHE_DIRECTIVES{$_} } keys %{_cache_control()}) ||
			(defined($max_age) && ($max_age == 0));
		$cacheable = $forbidden ? 0 : 1;
	}
	return $cacheable;
}

=head2 is_cached

Returns true if the output is cached. If it is then it means that all of the
expensive routines in the CGI script can be by-passed because we already have
the result stored in the cache.

=head3 Purpose

Says whether the page is in the server-side cache, in which case the script can
exit without printing anything, and the cached copy is sent.

=head3 Arguments

None.  Any that are given, e.g. the class name when chained after init(), are
ignored.

=head3 Returns

1 if the page is in the cache, otherwise 0.

An entry that has expired isn't cached,
and neither is any entry if the script's file has changed since,
or if the age of the script can't be determined.
If the cache fails, a warning is given and the output isn't cached.

=head3 Side Effects

Remembers the cache entry for when the output is sent.
An entry made before the script was last changed is removed from the cache.

=head3 EXAMPLE

    # Put this toward the top of your program before you do anything

    # Example key generation - use whatever you want as something
    # unique for this call, so that subsequent calls with the same
    # values match something in the cache
    use CGI::Info;
    use CGI::Lingua;
    use CGI::Buffer;

    my $i = CGI::Info->new();
    my $l = CGI::Lingua->new(supported => ['en']);

    # To use server side caching you must give the cache argument, however
    # the cache_key argument is optional - if you don't give one then one will
    # be generated for you
    if(CGI::Buffer::can_cache()) {
        CGI::Buffer::init(
	    cache => CHI->new(driver => 'File'),
	    cache_key => $i->domain_name() . '/' . $i->script_name() . '/' . $i->as_string() . '/' . $l->language()
        );
        if(CGI::Buffer::is_cached()) {
	    # Output will be retrieved from the cache and sent automatically
	    exit;
        }
    }
    # Not in the cache, so now do our expensive computing to generate the
    # results
    print "Content-type: text/html\n";
    # ...

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

	{ type => 'boolean' }

=head3 MESSAGES

    Key             Meaning                                   Resolution
    --------------  ----------------------------------------  ---------------------------------
    failed          The cache couldn't be read                Check the cache's configuration
    no_script_path  CGI::Info can't find the script (fatal)   Check SCRIPT_FILENAME/SCRIPT_NAME
    no_script_age   The script's file can't be read (logged)  Check the script's permissions

=head3 FORMAL SPECIFICATION

    ┌─ IsCached ──────────────────────────────────────────┐
    │ ΞCache                                              │
    │ key : KEY                                           │
    │ script_mtime : TIME                                 │
    │ now : TIME                                          │
    │ result! : 𝔹                                         │
    ├─────────────────────────────────────────────────────┤
    │ result! = true ⇔                                    │
    │   key ∈ dom cache ∧                                 │
    │   cache(key).value ≠ ⊥ ∧                            │
    │   cache(key).expires_at > now ∧                     │
    │   script_mtime ≤ cache(key).created_at              │
    └─────────────────────────────────────────────────────┘

=head3 PSEUDOCODE

    if there's no cache, the page isn't cached
    look up the key, ignoring expired entries and a failing cache
    if there's no entry, or it has no data, the page isn't cached
    if the script's age can't be found, the page isn't cached
    if the script has changed since the entry was made
        remove the entry, the page isn't cached
    otherwise the page is cached

=cut

sub is_cached {
	my $found = 0;

	if(!$cache) {
		_log('debug', "is_cached: cache hasn't been enabled");
	} else {
		my $key = _generate_key();
		_log('debug', "is_cached: looking for key = $key");

		$cobject = _cache_lookup($key);
		if((!$cobject) || !defined($cobject->value())) {
			_log('debug', 'not found in cache');
			$cobject = undef;
		} else {
			# If the script has changed, don't use the cache since we
			# may produce different output
			my $age = _my_age();
			if(!defined($age)) {
				# Can't determine the age.  Play it safe and assume
				# we're not cached
				_log('debug', "Can't determine script's age");
				$cobject = undef;
			} elsif($age > $cobject->created_at()) {
				# Remove only this entry.  Clearing the whole cache
				# would also lose other scripts' pages (RT104471)
				_log('debug', 'Script has been updated');
				_try('removing an old entry', sub { $cache->remove($key) });
				$cobject = undef;
			} else {
				_log('debug', 'Script is in the cache');
				$found = 1;
			}
		}
	}
	return $found;
}

# Purpose: find when the script was last changed
# Entry criteria: none
# Exit status: the script's modification time, or undef if it can't be read
# Side effects: remembers the answer, may create $info.  Croaks if CGI::Info
#	can't find the script
sub _my_age {
	unless(defined($script_mtime)) {
		my $path = _info()->script_path();
		croak(_i18n('no_script_path')) unless(defined($path));

		if(my @statb = stat($path)) {
			$script_mtime = $statb[9];
		} else {
			_log('debug', _i18n('no_script_age', { path => $path, error => "$!" }));
		}
	}
	return $script_mtime;
}

# Purpose: choose the content encoding to use
# Entry criteria: @content_type and $script_encoded are set from the headers
# Exit status: the encoding, or '' for none
# Side effects: may load a compression module
#
# Premise 1: _compress() fails the request with a 406 if it can't load the
#	module for the encoding
# Premise 2: the client is happy with any of the encodings it lists
# Conclusion: choose the first listed encoding that can be loaded, then the 406
#	can't happen
sub _choose_encoding {
	my $accept = $ENV{'HTTP_ACCEPT_ENCODING'} || $ENV{'HTTP_TE'};
	my $chosen = '';

	# Only text is compressed, and not if the script already has (twice is
	# pointless)
	if($compress_content && $accept && !$script_encoded &&
	   !(defined($content_type[0]) && (lc($content_type[0]) ne 'text'))) {
		foreach my $method(split(/\s*,\s*/, lc($accept))) {
			# e.g. "gzip;q=0.8", where q=0 means "not acceptable"
			my ($name, @params) = split(/\s*;\s*/, $method);
			next unless(defined($name) && $ENCODING_MODULE{$name});
			next if(grep { /^q=0(?:\.0*)?$/ } @params);
			if(_can_load($ENCODING_MODULE{$name})) {
				$chosen = $name;
				last;
			}
		}
	}
	return $chosen;
}

# Purpose: say whether a module can be loaded
# Entry criteria: $module is a module name, from a fixed list
# Exit status: true if it can be
# Side effects: loads the module, and remembers the answer
{
	my %loadable;

	sub _can_load
	{
		my $module = shift;

		$loadable{$module} = (eval "require $module; 1") ? 1 : 0 unless(exists($loadable{$module}));
		return $loadable{$module};
	}
}

# Purpose: find the content type and content encoding in a block of headers
# Entry criteria: $headers is the block of headers
# Exit status: none
# Side effects: sets @content_type, and $script_encoded if there's an encoding
sub _set_content_type
{
	my $headers = shift;

	foreach my $header (split(/\r?\n/, $headers)) {
		my ($header_name, $header_value) = split /\:\s*/, $header, 2;
		next unless(defined($header_name) && defined($header_value));
		if(lc($header_name) eq 'content-type') {
			@content_type = split /\//, $header_value, 2;
		} elsif((lc($header_name) eq 'content-encoding') && (lc($header_value) !~ /^\s*identity\s*$/)) {
			$script_encoded = 1;
		}
	}
}

# Purpose: compress the body
# Entry criteria: $encoding is from _choose_encoding(), or '' for none
# Exit status: none
# Side effects: may change $body, $content_encoding and @o.  Sets a 406 status
#	if the encoding can't be produced
sub _compress {
	my $encoding = shift;

	# This can be called again, by which time the body is no longer compressed
	$content_encoding = undef;
	@o = grep { !/^Content-Encoding:/ } @o;

	return unless(defined($body) && defined($encoding) && length($encoding));
	return if(length($body) < $MIN_GZIP_LEN);

	# Premise: _choose_encoding() only returns encodings whose module loads
	# Conclusion: if one can't be loaded here, the request can't be met
	my $module = $ENCODING_MODULE{$encoding};
	if((!defined($module)) || !_can_load($module)) {
		_set_status($HTTP_NOT_ACCEPTABLE);
		return;
	}

	# Avoid 'Wide character in memGzip'
	my $bytes = _to_bytes($body);
	my $compressed;
	if($module eq 'Compress::Zlib') {
		$compressed = Compress::Zlib::memGzip(\$bytes);
	} elsif($module eq 'Compress::Zstd') {
		# Facebook
		$compressed = Compress::Zstd::compress(\$bytes);
	} else {
		$compressed = IO::Compress::Brotli::bro($bytes);
	}

	# Don't send it compressed if that makes it larger
	return unless(defined($compressed) && (length($compressed) < length($bytes)));

	$body = $compressed;
	$encoding = 'gzip' if($encoding eq 'x-gzip');
	$content_encoding = $encoding;
	foreach my $header("Content-Encoding: $encoding", 'Vary: Accept-Encoding') {
		push @o, $header unless(grep { $_ eq $header } @o);
	}
}

# Purpose: work out the ETag of the body
# Entry criteria: $body is the uncompressed body, or undef
# Exit status: none
# Side effects: sets $etag, unless it's already set
sub _generate_etag {
	if((!defined($etag)) && defined($body)) {
		# bytes to avoid "Wide character in subroutine entry"
		$etag = '"' . Digest::MD5::md5_hex(_to_bytes($body)) . '"';
		_log('debug', "Etag = $etag");
	}
}

# Purpose: run some code which isn't essential to sending the page, e.g.
#	something using the cache
# Entry criteria: $what describes the code, for the warning
# Exit status: what the code returns, or undef if it fails
# Side effects: those of the code, and a warning if it fails
sub _try {
	my ($what, $code) = @_;

	my $rc;
	unless(eval { $rc = $code->(); 1 }) {
		_problem('failed', { what => $what, error => $@ });
		$rc = undef;
	}
	return $rc;
}

# Purpose: report something which has gone wrong.  This can be called from
#	anywhere, so the logger itself may be the thing that's failing
# Entry criteria: $key and $args are a message, see _i18n()
# Exit status: none
# Side effects: writes to the logger, or gives a warning
sub _problem {
	my $message = _i18n(@_);

	# Carp::shortmess says where the caller of CGI::Buffer is.  Must be
	# Carp::carp instead of carp for Test::Carp
	unless($logger && eval { $logger->warn(Carp::shortmess($message)); 1 }) {
		Carp::carp($message);
	}
}

# Purpose: write to the logger, if there is one
# Entry criteria: $level is one of @LOGGER_METHODS, @message is the message
# Exit status: none
# Side effects: writes to the logger
sub _log {
	my ($level, @message) = @_;

	$logger->$level(@message) if($logger);
}

# Purpose: find the text of a message
# Entry criteria: $key is a key of %DEFAULT_MESSAGES, $args a hashref of the
#	values for its placeholders.  A count argument chooses the plural form
# Exit status: the text, starting with the package name
# Side effects: none
sub _i18n {
	my ($key, $args) = @_;

	$args ||= {};
	my $format = exists($messages{$key}) ? $messages{$key} : $DEFAULT_MESSAGES{$key};

	# An unknown key is shown as itself rather than being lost
	$format = $key unless(defined($format));
	if(ref($format) eq 'HASH') {
		# Plural forms: "one" for a count of 1, "other" for the rest
		my $form = (defined($args->{count}) && ($args->{count} == 1) && defined($format->{one})) ? 'one' : 'other';
		$format = $format->{$form};
		$format = $key unless(defined($format));
	}

	# A missing value is shown as empty, rather than as a warning
	no warnings 'numeric';
	$format =~ s/%\{(\w+)\}($SPRINTF_CONVERSION)/sprintf("%$2", defined($args->{$1}) ? $args->{$1} : '')/ge;
	return __PACKAGE__ . ": $format";
}

# Purpose: check that the logger can do what will be asked of it, otherwise
#	forget it.  AUTOLOAD is taken on trust
# Entry criteria: $logger is set
# Exit status: none
# Side effects: may set $logger to undef, and give a warning
sub _check_logger {
	my ($missing) = grep {
		!(Scalar::Util::blessed($logger) && ($logger->can($_) || $logger->can('AUTOLOAD')))
	} @LOGGER_METHODS;

	if(defined($missing)) {
		$logger = undef;
		_problem('logger_method', { method => $missing });
	}
}

# Purpose: look for an entry in the cache that can still be used.  A failing
#	cache is the same as an empty one.  CHI's get_object() returns an object
#	even if it has expired
# Entry criteria: $key is the cache key, $cache is set
# Exit status: the cache object, or undef
# Side effects: none
sub _cache_lookup {
	my $key = shift;

	my $object = _try('reading the cache', sub { return $cache->get_object($key) });
	if($object && $object->can('is_expired') && $object->is_expired()) {
		_log('debug', "$key has expired");
		$object = undef;
	}
	return $object;
}

# Purpose: a string as bytes: a string of characters is encoded, bytes are left
#	alone
# Entry criteria: $string is a string, or undef
# Exit status: the bytes, or undef
# Side effects: none
sub _to_bytes {
	my $string = shift;

	utf8::encode($string) if(defined($string) && utf8::is_utf8($string));
	return $string;
}

# Purpose: say whether the output is an HTML page
# Entry criteria: @content_type is set from the headers
# Exit status: 1 if it is, otherwise 0
# Side effects: none
sub _is_html {
	return (defined($content_type[0]) && defined($content_type[1]) &&
		(lc($content_type[0]) eq 'text') && (lc($content_type[1]) =~ /^html/)) ? 1 : 0;
}

# Purpose: stop the regular expressions from changing the contents of <pre>
#	and <textarea> by swapping them for a marker.  The end of a tag is only
#	looked for once if it isn't there, so that hostile input can't make this
#	quadratic
# Entry criteria: $body is HTML
# Exit status: a hashref of what's needed to put them back
# Side effects: changes $body
sub _protect_preformatted {
	my $marker = 'CGIBUFFERPRESERVED' . int(rand(1_000_000_000)) . 'N';
	my (@saved, %no_end);
	my $out = '';
	my $last = 0;

	while($body =~ /<(pre|textarea)\b/gi) {
		my $tag = lc($1);
		my $start = $-[0];
		my $after = pos($body);

		next if($no_end{$tag});
		unless($body =~ /<\/$tag\s*+>/gi) {
			# Unterminated, so there's no point looking again
			$no_end{$tag} = 1;
			pos($body) = $after;
			next;
		}
		my $end = $+[0];
		push @saved, substr($body, $start, $end - $start);
		$out .= substr($body, $last, $start - $last) . $marker . $#saved . 'X';
		$last = $end;
		pos($body) = $end;
	}
	$body = $out . substr($body, $last);
	return { marker => $marker, saved => \@saved };
}

# Purpose: put back what _protect_preformatted() took out
# Entry criteria: $preformatted is what _protect_preformatted() returned
# Exit status: none
# Side effects: changes $body
sub _restore_preformatted {
	my $preformatted = shift;

	my $saved = $preformatted->{'saved'};
	$body =~ s/\Q$preformatted->{marker}\E(\d+)X/$saved->[$1]/g if(scalar(@{$saved}));
}

# Purpose: tell caches that what's sent depends on what the client accepts.
#	This is also needed when the output isn't compressed, or that's what a
#	cache would then give to clients that can take it compressed
# Entry criteria: $headers is the script's headers
# Exit status: none
# Side effects: may add to @o
sub _add_vary {
	my $headers = shift;

	return unless(defined($headers) && length($headers));
	return unless($compress_content && defined($body) && !$script_encoded);
	return if(defined($content_type[0]) && (lc($content_type[0]) ne 'text'));
	return if($headers =~ /^Vary:.*\baccept-encoding\b/mi);
	return if(grep { /^Vary:.*\baccept-encoding\b/i } @o);
	push @o, 'Vary: Accept-Encoding';
}

# Purpose: send one Status header, that of the status we've ended up with,
#	keeping the script's one if it's the same since it may have its own
#	wording
# Entry criteria: @o holds all of the headers, $status is final
# Exit status: none
# Side effects: changes @o
sub _set_status_header {
	my $found = 0;
	@o = grep {
		my $keep = 1;
		if(/^Status:\s*(\d+)/i) {
			$keep = (!$found) && ($1 == $status);
			$found ||= $keep;
		}
		$keep
	} @o;

	unless($found) {
		push @o, _status_line($status);
		_set_status($status);
	}
}

# Purpose: the Status header for a status
# Entry criteria: $code is an HTTP status
# Exit status: the header, e.g. "Status: 304 Not Modified"
# Side effects: loads HTTP::Status
sub _status_line {
	my $code = shift;

	require HTTP::Status;
	return "Status: $code " . HTTP::Status::status_message($code);
}

# Purpose: the header that says what CGI::Buffer did
# Entry criteria: $what is e.g. "Hit"
# Exit status: the header
# Side effects: none
sub _buffer_header {
	my $what = shift;

	return "X-CGI-Buffer-$VERSION: $what";
}

# Purpose: say whether If-Range asks for a part, which it does only if the
#	client's copy is the current one (RFC 9110 14.5), which needs an exact
#	match of a strong validator
# Entry criteria: $body is the uncompressed body
# Exit status: 1 if a part may be sent, otherwise 0
# Side effects: may set $etag
sub _if_range_matches {
	my $if_range = $ENV{'HTTP_IF_RANGE'};
	my $matches = 1;

	if(defined($if_range) && length($if_range)) {
		if($if_range =~ /^(?:W\/)?"/) {
			_generate_etag();
			$matches = (defined($etag) && ($if_range eq $etag)) ? 1 : 0;
		} else {
			my $since = _parse_http_date($if_range);
			my $age = (defined($since) && $info) ? _my_age() : undef;
			$matches = (defined($age) && ($age == $since)) ? 1 : 0;
		}
	}
	return $matches;
}

# Purpose: the CGI::Info object, which is created if it wasn't given
# Entry criteria: none
# Exit status: the object
# Side effects: may load CGI::Info and set $info.  Croaks if it can't
sub _info {
	unless(defined($info)) {
		require CGI::Info;
		$info = CGI::Info->new($cache ? { cache => $cache } : ())
			or croak(_i18n('no_info'));
	}
	return $info;
}

# Purpose: set the HTTP status, and tell CGI::Info if we have one
# Entry criteria: $code is an HTTP status
# Exit status: none
# Side effects: sets $status
sub _set_status {
	$status = shift;
	$info->status($status) if($info);
}

# Purpose: format a time for an HTTP header
# Entry criteria: $time is seconds since the epoch
# Exit status: the date, e.g. "Mon, 02 Nov 2026 12:00:00 GMT"
# Side effects: loads HTTP::Date
sub _http_date {
	require HTTP::Date;
	return HTTP::Date::time2str(shift);
}

# Purpose: read a date from an HTTP header
# Entry criteria: $date is the header's value
# Exit status: seconds since the epoch, or undef if it isn't a valid date
# Side effects: loads HTTP::Date
sub _parse_http_date {
	require HTTP::Date;
	return HTTP::Date::str2time(shift);
}

# Purpose: say whether the protocol supports conditional requests (ETag etc.)
# Entry criteria: none
# Exit status: true if it does
# Side effects: none
sub _is_conditional_protocol {
	return defined($ENV{'SERVER_PROTOCOL'}) && ($ENV{'SERVER_PROTOCOL'} =~ $CONDITIONAL_PROTOCOL);
}

# Purpose: say whether this is a GET request.  There is no method when running
#	from the command line, which is treated as GET
# Entry criteria: none
# Exit status: true if it is
# Side effects: none
sub _is_get {
	return (!defined($ENV{'REQUEST_METHOD'})) || ($ENV{'REQUEST_METHOD'} eq 'GET');
}

# Purpose: the X-Cache and X-Cache-Lookup headers
# Entry criteria: $cached and $lookup are "HIT" or "MISS"
# Exit status: an arrayref of the two headers
# Side effects: none
sub _x_cache_headers {
	my ($cached, $lookup) = @_;

	my $from = $info ? ' from ' . $info->host_name() : '';
	return [ "X-Cache: $cached$from", "X-Cache-Lookup: $lookup$from" ];
}

# Purpose: work out the response to a Range header.  Only a single range of
#	bytes is supported
# Entry criteria: $b is the body, $range the Range header
# Exit status: a hashref of the new status, body and Content-Range header, or
#	undef if the range isn't one that we support, in which case the header is
#	ignored and the whole body is sent.
#	206: the part of the body asked for
#	416: a valid range which is outside of the body, so has no body
# Side effects: none
sub _apply_range {
	my ($b, $range) = @_;

	return unless($range =~ /^bytes=(\d*)-(\d*)$/);
	my ($first, $last) = ($1, $2);
	my $length = length($b);

	# "bytes=-" says nothing
	return if(($first eq '') && ($last eq ''));

	# A backwards range is invalid, so is ignored (RFC 7233 2.1)
	return if(($first ne '') && ($last ne '') && ($first > $last));

	if($first eq '') {
		# "bytes=-n" is the last n bytes, all of it if there are
		# fewer than n.  The last 0 bytes can't be satisfied
		$first = ($last >= $length) ? 0 : $length - $last;
		$last = $length - 1;
	} elsif(($last eq '') || ($last >= $length)) {
		# A range past the end stops at the end
		$last = $length - 1;
	}

	# A range starting at or after the end can't be satisfied
	if(($first >= $length) || ($first > $last)) {
		return { status => $HTTP_RANGE_NOT_SATISFIABLE, content_range => "bytes */$length" };
	}

	return {
		status => $HTTP_PARTIAL_CONTENT,
		body => substr($b, $first, $last - $first + 1),
		content_range => "bytes $first-$last/$length",
	};
}

# Purpose: the values of a header in a block of headers
# Entry criteria: $headers is the block, $name the header's name
# Exit status: an arrayref of the values, which may be empty
# Side effects: none
sub _header_values {
	my ($headers, $name) = @_;

	return [ defined($headers) ?
		(map { /^[^:]+:\s*(.*?)\s*$/ ? $1 : () } grep { /^\Q$name\E:/i } split(/\r?\n/, $headers)) :
		() ];
}

# Purpose: say whether this response may be kept and given to other clients
# Entry criteria: $headers and $body are the script's headers and body
# Exit status: 1 if it may, otherwise 0
# Side effects: none
sub _is_storable {
	my ($headers, $body) = @_;

	# It would log the next client in as this one
	return 0 if(@{_header_values($headers, 'Set-Cookie')} || @{_header_values($headers, 'Set-Cookie2')});

	# It would give this client's form token to the next one
	return 0 if(_has_form_token($body));

	foreach my $control(@{_header_values($headers, 'Cache-Control')}) {
		foreach my $directive(split(/\s*,\s*/, lc($control))) {
			(my $name = $directive) =~ s/\s*=.*$//;
			return 0 if($NO_CACHE_DIRECTIVES{$name});
		}
	}

	# Accept-Encoding is dealt with here, and lingua is part of the key.
	# Anything else isn't part of the key, so the page would be given to
	# clients that it wasn't meant for
	foreach my $vary(@{_header_values($headers, 'Vary')}) {
		foreach my $name(split(/\s*,\s*/, lc($vary))) {
			next if($name eq 'accept-encoding');
			next if(($name eq 'accept-language') && $lingua);
			return 0;
		}
	}

	# An HTML page with no </html> suggests that the script died part way
	# through, so don't give the partial page to other clients
	if(_is_html() && defined($body) && ($body =~ /<html\b/i) && ($body !~ /<\/html\s*+>/i)) {
		_log('debug', 'Not storing an HTML page with no </html>');
		return 0;
	}
	return 1;
}

# Purpose: say whether the request method may be answered from a cache or with
#	a 304.  There is no method when running from the command line
# Entry criteria: none
# Exit status: true if it may
# Side effects: none
sub _is_safe_method {
	return (!defined($ENV{'REQUEST_METHOD'})) || $SAFE_METHODS{$ENV{'REQUEST_METHOD'}};
}

# Purpose: say whether the client has logged in
# Entry criteria: none
# Exit status: true if it has
# Side effects: none
sub _is_logged_in {
	return $ENV{'HTTP_AUTHORIZATION'} || $ENV{'REMOTE_USER'};
}

# Purpose: the client's cookies, except for Google Analytics ones and the token
#	that protects forms, which are different for each client but don't change
#	the output.  A page with a form is sent that token in a Set-Cookie header,
#	so _is_storable() doesn't store it
# Entry criteria: none
# Exit status: an arrayref of the cookies, as "name=value"
# Side effects: none
sub _client_cookies {
	return [ $ENV{'HTTP_COOKIE'} ?
		(grep { !/^(?:__utm[abcz]|\Q$FORM_TOKEN_COOKIE\E=)/ } split(/;\s*/, $ENV{'HTTP_COOKIE'})) :
		() ];
}

# Purpose: say whether this page includes the client's own form token.
#	_client_cookies() ignores the cookie that holds it, on the understanding
#	that it doesn't change the output.  A script that puts its value into the
#	page has made the page per client
# Entry criteria: $body is the page
# Exit status: 1 if it does, otherwise 0
# Side effects: none
sub _has_form_token {
	my $body = shift;

	return 0 unless($ENV{'HTTP_COOKIE'} && defined($body));

	foreach my $cookie(split(/;\s*/, $ENV{'HTTP_COOKIE'})) {
		next unless($cookie =~ /^\Q$FORM_TOKEN_COOKIE\E=(.+)$/);
		my $token = $1;
		return 1 if(index($body, $token) >= 0);

		# The cookie may be encoded, what's printed may not be
		if($token =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge) {
			return 1 if(index($body, $token) >= 0);
		}
	}
	return 0;
}

# Purpose: the directives in the request's Cache-Control header
# Entry criteria: none
# Exit status: a hashref of lower case name to value (undef when there is no
#	value)
# Side effects: none
sub _cache_control {
	my %directives;

	if(defined(my $control = $ENV{'HTTP_CACHE_CONTROL'})) {
		foreach my $directive(split(/\s*,\s*/, lc($control))) {
			my ($name, $value) = split(/\s*=\s*/, $directive, 2);
			next unless(defined($name) && length($name));
			$value =~ s/^"(.*)"$/$1/ if(defined($value));
			$directives{$name} = $value;
		}
	}
	return \%directives;
}

# Purpose: the max-age directive in the request.  This comes from the client,
#	so it mustn't be trusted to be a number
# Entry criteria: none
# Exit status: the number of seconds, or undef if there isn't a valid one
# Side effects: none
sub _client_max_age {
	my $max_age = _cache_control()->{'max-age'};

	return (defined($max_age) && ($max_age =~ /^\d+$/)) ? $max_age : undef;
}

=head1 MESSAGES

Every message that CGI::Buffer gives starts with "CGI::Buffer: ".
Each can be replaced, for example to translate it, by giving init() a
C<messages> hash.
Placeholders are written C<%{name}> followed by a sprintf conversion, e.g.
C<%{key}s>.
A message may instead be a hash of plural forms, C<one> and C<other>, chosen by
its count.

    CGI::Buffer::init(messages => {
	unknown_option => 'init: option inconnue %{option}s ignoree',
	too_late => {
	    one => 'Trop tard, %{count}d caractere a ete imprime',
	    other => 'Trop tard, %{count}d caracteres ont ete imprimes',
	},
    });

    Key             Placeholders      Meaning
    --------------  ----------------  ------------------------------------------
    too_late        count             The cache was set up after printing
    unknown_option  option            init() was given an option it doesn't know
    bad_option      option, reason    init() was given an option of the wrong type
    failed          what, error       Something non-essential, e.g. the cache, failed
    no_cache_data   key               The page was cached, but now can't be read
    no_cache_body   key, fields       A cache entry has no body, so is removed
    logger_method   method            The logger lacks a method, so is ignored
    no_script_path  -                 CGI::Info can't find the script (fatal)
    no_script_age   path, error       The script's file can't be read (logged)
    no_info         -                 A CGI::Info object can't be created (fatal)
    send_failed     error             Processing the output failed; it's sent as is
    lint            where, text       An error found by HTML::Lint

None of the messages refers to a person, so there are no gendered forms.

=head1 LIMITATIONS

=over 4

=item * All of the state is in package variables, and the work is done in an
END block.
That fits CGI, where each request is a new process, but it means CGI::Buffer
can't be used for more than one request, can't be reset, and can only be tested
by running a script in another process.
L<FCGI::Buffer> is the object-oriented version for persistent processes.

=item * HTML is optimised with regular expressions, not an HTML parser.
They are written to run in linear time and to leave C<< <pre> >> and
C<< <textarea> >> alone, but HTML that's unusual enough can still be changed in
ways that are visible, e.g. whitespace in an element styled with
C<white-space: pre>.
L<HTML::Packer> can take quadratic time on many unterminated C<< <script> >>
tags.

=item * Links to this site are shortened to absolute paths
(C</foo/bar.htm>), not relative ones (C<../bar.htm>).
Relative links would save a few more bytes, but break pages that use
C<< <base href> >>, and pages reached through more than one path.

=item * Only one byte range is supported, and Range is ignored when there's a
server-side cache.

=item * The server-side cache key can't include headers named by Vary, since
it's needed before the script prints them; such pages aren't stored.

=item * Only HTML is checked for having been cut short by the script dying.

=item * lint_content sends HTML::Lint's errors to the client, and the
X-CGI-Buffer header gives the version of CGI::Buffer.
Neither should be relied upon in production.

=item * init()'s options are checked by hand, rather than with
L<Params::Validate::Strict>, and private routines are private by convention
rather than enforced with L<Sub::Private>.
Both add about 50ms to every request, since a CGI program is compiled afresh
each time.
For the same reason CGI::Info is only loaded when it's needed, so a script that
uses CGI::Info must load it itself.

=item * The server-side cache's duration isn't taken from the Expires or
Cache-Control: max-age headers that the script gives.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

CGI::Buffer should be safe even in scripts which produce lots of different
output, e.g. e-commerce situations.
On such pages, however, I strongly urge to setting generate_304 to 0 and
sending the HTTP header "Cache-Control: no-cache".

When using L<Template>, ensure that you don't use it to output to STDOUT,
instead you will need to capture into a variable and print that.
For example:

    my $output;
    $template->process($input, $vars, \$output) || ($output = $template->error());
    print $output;

Can produce buggy JavaScript if you use the <!-- HIDING technique.
This is a bug in L<JavaScript::Packer>, not CGI::Buffer.
See https://github.com/nevesenin/javascript-packer-perl/issues/1#issuecomment-4356790

Mod_deflate can confuse this when compressing output.
Ensure that deflation is off for .pl files:

    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png|pl)$ no-gzip dont-vary

If-None-Match uses the weak comparison of RFC 9110, so a client that has the
compressed version of a page is sent a 304 when it asks for the uncompressed
one, and vice versa.

I advise adding CGI::Buffer as the last use statement so that it is
cleared up first.  In particular it should be loaded after
L<Log::Log4perl>, if you're using that, so that any messages it
produces are printed after the HTTP headers have been sent by
CGI::Buffer;

CGI::Buffer is not compatible with FastCGI, use L<FCGI::Buffer> instead.

Please report any bugs or feature requests to C<bug-cgi-buffer at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Buffer>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<HTML::Packer>, L<HTML::Lint>, L<FCGI::Buffer>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Buffer

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/CGI-Buffer>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Buffer>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/CGI-Buffer>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=CGI-Buffer>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=CGI::Buffer>

=back

=head1 ACKNOWLEDGEMENTS

The inspiration and code for some of this is cgi_buffer by Mark
Nottingham: L<https://www.mnot.net/blog/2003/04/24/etags>.

=head1 LICENSE AND COPYRIGHT

The licence for cgi_buffer is:

    "(c) 2000 Copyright Mark Nottingham <mnot@pobox.com>

    This software may be freely distributed, modified and used,
    provided that this copyright notice remain intact.

    This software is provided 'as is' without warranty of any kind."

The rest of the program is Copyright 2011-2026 Nigel Horne,
and is released under the following licence: GPL2

=cut

1; # End of CGI::Buffer
