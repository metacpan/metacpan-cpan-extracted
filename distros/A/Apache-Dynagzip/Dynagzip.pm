package Apache::Dynagzip;

use 5.004;
use strict;
use Apache::Constants qw(:response :methods :http);
use Compress::LeadingBlankSpaces;
use Compress::Zlib 1.16;
use Apache::File;
use Apache::Log ();
use Apache::URI();
use Apache::Util;
use Fcntl qw(:flock);
use FileHandle;

use vars qw($VERSION $BUFFERSIZE %ENV);
$VERSION = "0.16";
$BUFFERSIZE = 16384;
use constant MAGIC1	=> 0x1f ;
use constant MAGIC2	=> 0x8b ;
use constant OSCODE	=> 3 ;
use constant MIN_HDR_SIZE => 10 ; # minimum gzip header size
use constant MIN_CHUNK_SIZE_DEFAULT => 8;            # when gzip only
use constant MIN_CHUNK_SIZE_SOURCE_DEFAULT => 32768; # when gzip only
use constant CHUNK_PARTIAL_FLUSH_DEFAULT => 'On';
use constant MIN_CHUNK_SIZE_PP_DEFAULT => 8192;      # for no gzip case
use constant MAX_ATTEMPTS_TO_TRY_FLOCK => 10;  # max limit seconds to sleep, waiting for flock()
use constant PAGE_LIFE_TIME_DEFAULT    => 300; # sec

sub can_gzip_for_this_client {
	# This is the only place where I decide whether or not the main request
	# could be served with gzip compression.
	# call model: my $can_gzip = can_gzip_for_this_client($r);
	my $r = shift;
	my $result = undef; # false is default
	local $^W = 0; # no warnings when Accept-Encoding does not exist:
	if ($r->header_in('Accept-Encoding') =~ /gzip/){
		$result = 1; # true
	}
	# See Apache::CompressClientFixup for all known exceptions...
	#
	return $result;
}

sub retrieve_all_cgi_headers_via { # call model: my $hdrs = retrieve_all_cgi_headers_via ($fh);
	my $fh = shift;
	my $headers;
	{
		local $/ = "\n\n";
		$headers = <$fh>;
	}
	return $headers;
}

sub send_lightly_compressed_stream { # call model: send_lightly_compressed_stream($r, $fh);
	# Transfer the stream from filehandle $fh to standard output
	# using "blank-space compression only...
	#
	my $r = shift;
	my $fh = shift;
	my $body = ''; # incoming content
	my $buf;
	my $lbr = Compress::LeadingBlankSpaces->new();
	while (defined($buf = <$fh>)){
		if ($buf = $lbr->squeeze_string ($buf)) {
			$body .= $buf;
			print ($buf);
		}
	}
	return $body;
}
sub send_lightly_compressed_stream_chunked { # call model: send_lightly_compressed_stream_chunked($r, $fh, $minChSize);
	# Transfer the stream chunked from filehandle $fh to standard output
	# using "blank-space compression only...
	#
	my $r = shift;
	my $fh = shift;
	my $minChunkSizePP = shift;
	my $body = ''; # incoming content
	my $buf;
	my $chunkBody = '';
	my $lbr = Compress::LeadingBlankSpaces->new();

	while (defined($buf = <$fh>)){
		$buf = $lbr->squeeze_string ($buf);
		if (length($buf) > 0){
			$chunkBody .= $buf;
		}
		if (length($chunkBody) > $minChunkSizePP){ # send it...
			$body .= $chunkBody;
			print (chunk_out($chunkBody));
			$chunkBody = '';
		}
	}
	if (length($chunkBody) > 0){ # send it...
		$body .= $chunkBody;
		print (chunk_out($chunkBody));
		$chunkBody = '';
	}
	return $body;
}

sub chunkable { # call model: $var = chunkable($r);
	# Check if the response could be chunked
	#
	my $r = shift;
	my $result = undef;
	# this is to downgrade to HTTP/1.0 for MSIE requests over SSL
	# works in conjunction with this snippet from httpd.conf:
	# SetEnvIf User-Agent ".*MSIE.*" \
	# nokeepalive ssl-unclean-shutdown \
	# downgrade-1.0 force-response-1.0
	#
	if ( $ENV{'downgrade-1.0'} or $ENV{'force-response-1.0'} ) {
		$result = 0;
	} elsif ($r->protocol =~ /http\/1\.(\d+)/io) {
		# any HTTP/1.X is OK, just X==0 will be evaluated to FALSE in result
		$result = $1;
	}
	return $result;
}

sub chunk_out { # call model: my $chunk = chunk_out ($string);
	my $HttpEol = "\015\012";  # HTTP end of line marker (see RFC 2068)
	my $source = shift;
	return  sprintf("%x",length($source)).$HttpEol.$source.$HttpEol;
}

sub kill_over_env { # just to clean up the unnessessary environment
	delete($ENV{HISTSIZE});
	delete($ENV{HOSTNAME});
	delete($ENV{LOGNAME});
	delete($ENV{HISTFILESIZE});
	delete($ENV{SSH_TTY});
	delete($ENV{MAIL});
	delete($ENV{MACHTYPE});
	delete($ENV{TERM});
	delete($ENV{HOSTTYPE});
	delete($ENV{OLDPWD});
	delete($ENV{HOME});
	delete($ENV{INPUTRC});
	delete($ENV{SUDO_GID});
	delete($ENV{SHELL});
	delete($ENV{SUDO_UID});
	delete($ENV{USER});
	delete($ENV{SUDO_USER});
	delete($ENV{SSH_CLIENT});
	delete($ENV{OSTYPE});
	delete($ENV{PWD});
	delete($ENV{SHLVL});
	delete($ENV{SUDO_COMMAND});
	delete($ENV{_});
	delete($ENV{HTTP_CONNECTION});
}

sub cgi_headers_from_script {
	# boolin function to determine whether it was configured to retrieve CGI headers from script, or not.
	# 
	# Could it be possible to have Content-Type coming from the previous filter?
	# call model: my $condition = cgi_headers_from_script($r);
	my $r = shift;
	my $res = lc $r->dir_config('UseCGIHeadersFromScript') eq 'on';
	return $res;
}

sub handler { # it is supposed to be only a dispatcher since now...

	my $r = shift;
	my $HttpEol = "\015\012";  # HTTP end of line marker (see RFC 2068)
	my $fh = undef; # will be the reference to the incoming data stream

	my $qualifiedName = join(' ', __PACKAGE__, 'default_content_handler');

	# make sure to dispatch the request appropriately:
	# I serve Perl & Java streams through the Apache::Filter Chain only.
	my $filter = lc $r->dir_config('Filter') eq 'on';
	my $binaryCGI = undef; # It might be On when Filter is Off ONLY.
	unless ($filter){
		$binaryCGI = lc $r->dir_config('BinaryCGI') eq 'on';
	}
	# I assume the Light Compression Off as default:
	my $light_compression = lc $r->dir_config('LightCompression') eq 'on';

	# There are no way to compress and/or chunk the response to internally redirected request.
	# No safe support could be provided for the server-side caching in this case.
	# No way to send back the Content-Length even when one exists for the plain file...
	# Just send back the content assuming it is text/html (or whatever is declared by the main response):
	unless ($r->is_main){
		# this is rdirected request;
		# No control over the HTTP headers:
		my $message = ' No control over the chunks is provided. Light Compression is ';
		if ($light_compression) {
			$message .= 'On.';
		} else {
			$message .= 'Off.';
		}
		$message .= ' Source comes from ';
		if ($filter) {
			$message .= 'Filter Chain.';
		} elsif ($binaryCGI) {
			$message .= 'Binary CGI.';
		} else {
			$message .= 'Plain File.';
		}
		$r->log->warn($qualifiedName.' is serving the redirected request for '.$r->the_request
			.' targeting '.$r->filename.' via '.$r->uri.$message);

		if ($filter) {
			# make filter-chain item with no chunks...
			$r = $r->filter_register;
			$fh = $r->filter_input();
			unless ($fh){
				my $message = ' Fails to obtain the Filter data handle for ';
				$r->log->error($qualifiedName.' aborts:'.$message.$r->filename);
				return SERVER_ERROR;
			}

			# Inside the filter chain there are no need to prpogate CGI headers.
			# All headers are already generated (presumably) by the previous filter(s).
			if ($r->header_out('Content-Type')) {
				$r->log->debug($qualifiedName
					.' has Content-Type='.$r->header_out('Content-Type')
					.' for '.$r->the_request);
			} else {
				# create default Content-Type HTTP header:
				$r->log->debug($qualifiedName
					.' creates default Content-Type for '.$r->the_request);
				$r->content_type("text/html");
			}
			$r->send_http_header;

			if ($r->header_only){
				$r->log->warn($qualifiedName.' request for HTTP header only is done OK for '
					.$r->the_request);
				return OK;
			}
			if ($light_compression) {
				send_lightly_compressed_stream($r, $fh);
			} else { # no light compression
				while (<$fh>) {
					print ($_);
				}
			}
			$r->log->warn($qualifiedName.' is done OK for '.$r->the_request
					.' '.$r->bytes_sent.' bytes sent');
			return OK;
		} # if ($filter)

		unless ($binaryCGI) { # Transfer a Plain File responding to redirected request

			unless (-e $r->finfo){
				$r->log->error($qualifiedName.' aborts: file does not exist: '.$r->filename);
				return NOT_FOUND;
			}
			if ($r->method_number != M_GET){
				my $message = ' is not allowed for redirected request targeting ';
				$r->log->error($qualifiedName.' aborts: '.$r->method.$message.$r->filename);
				return HTTP_METHOD_NOT_ALLOWED;
			}
			unless ($fh = Apache::File->new($r->filename)){
				my $message = ' file permissions deny server access to ';
				$r->log->error($qualifiedName.' aborts:'.$message.$r->filename);
				return FORBIDDEN;
			}
			# since the file is opened successfully, I need to flock() it...
			my $success = 0;
			my $tries = 0;
			while ($tries++ < MAX_ATTEMPTS_TO_TRY_FLOCK){
				last if $success = flock ($fh, LOCK_SH|LOCK_NB);
				$r->log->warn($qualifiedName.' is waiting for read flock of '.$r->filename);
				sleep (1); # wait a second...
			}
			unless ($success){
				$fh->close;
				$r->log->error($qualifiedName.' aborts: Fails to obtain flock on '.$r->filename);
				return SERVER_ERROR;
			}
			# I send no HTTP headers here just for case...
			if ($light_compression) {
				send_lightly_compressed_stream($r, $fh);
			} else { # no light compression
				$r->send_fd($fh);
			}
			$fh->close;
			$r->log->warn($qualifiedName.' is done OK for '.$r->the_request
						.' '.$r->bytes_sent.' bytes sent');
			return OK;
		} # unless ($binaryCGI)

		# It is Binary CGI to transfer:

		# double-check the target file's existance and access permissions:
		unless (-e $r->finfo){
			$r->log->error($qualifiedName.' aborts: File does not exist: '.$r->filename);
			return NOT_FOUND;
		}
		my $filename = $r->filename();
		unless (-f $filename and -x _ ) {
			$r->log->error($qualifiedName.' aborts: no exec permissions for '.$r->filename);
			return SERVER_ERROR;
		}
		$r->chdir_file();

		# make %ENV appropriately:
		my $gwi = 'CGI/1.1';
		$ENV{GATEWAY_INTERFACE} = $gwi;
		kill_over_env();

		if ($r->method eq 'POST'){ # it NEVER has notes...
			# POST features:
			# since the stdin has a broken structure when passed through the perl-UNIX-pipe
			# I emulate the appropriate GET request to the pp-binary...
			delete($ENV{CONTENT_LENGTH});
			delete($ENV{CONTENT_TYPE});
			my $content = $r->content;
			$ENV{QUERY_STRING} = $content;
			$ENV{REQUEST_METHOD} = 'GET';
		}
		unless ($fh = FileHandle->new("$filename |")) {
			$r->log->error($qualifiedName.' aborts: Fails to obtain incoming data handle for '.$r->filename);
			return NOT_FOUND;
		}
		# lucky to proceed:
		my $headers = retrieve_all_cgi_headers_via ($fh);
		$r->send_cgi_header($headers);
		if ($r->header_only){
			$fh->close;
			$r->log->warn($qualifiedName.' request for HTTP header only is done OK for '.$r->the_request);
			return OK;
		}
		if ($light_compression) {
			local $\;
			send_lightly_compressed_stream($r, $fh);
		} else { # no any compression:
			local $\;
			while (<$fh>) {
				print ($_);
			}
		}
		$fh->close;
		$r->log->warn($qualifiedName.' is done OK for '.$r->the_request
				.' '.$r->bytes_sent.' bytes sent');
		return OK;
	} # unless ($r->is_main)
	
	# This is the main request,
	# =========================
	# check if it worths to gzip for the client:
	my $can_gzip = can_gzip_for_this_client($r);

	my $message = ' Light Compression is ';
	if ($light_compression) {
		$message .= 'On.';
	} else {
		$message .= 'Off.';
	}
	$message .= ' Source comes from ';
	if ($filter) {
		$message .= 'Filter Chain.';
	} elsif ($binaryCGI) {
		$message .= 'Binary CGI.';
	} else {
		$message .= 'Plain File.';
	}
	$message .= ' The client '.($r->header_in("User-agent") || '');
	if ($can_gzip){
		$message .= ' accepts GZIP.';
	} else {
		$message .= ' does not accept GZIP.';
	}
	$r->log->info($qualifiedName.' is serving the main request for '.$r->the_request
		.' targeting '.$r->filename.' via '.$r->uri.$message);
	$r->header_out("X-Module-Sender" => __PACKAGE__);

	# Client Local Cache Control (see rfc2068):
	# The Expires entity-header field gives the date/time after which the response should be
	# considered stale. A stale cache entry may not normally be returned by a cache
	# (either a proxy cache or an user agent cache) unless it is first validated with the origin server
	# (or with an intermediate cache that has a fresh copy of the entity).
	# The format is an absolute date and time as defined by HTTP-date in section 3.3;
	# it MUST be in RFC1123-date format: Expires = "Expires" ":" HTTP-date
	my $life_length = $r->dir_config('pageLifeTime') || PAGE_LIFE_TIME_DEFAULT;
	my $now = time() + $life_length;
	my $time_format_gmt = '%A, %d-%B-%Y %H:%M:%S %Z';
	my $date_gmt = Apache::Util::ht_time($now, $time_format_gmt);
	$r->header_out("Expires" => $date_gmt) unless $r->header_out("Expires");

	# Advanced control over the client/proxy Cache:
	#
    {
	local $^W = 0;
	my $extra_vary = $r->dir_config('Vary');
	my $current_vary = $r->header_out("Vary");
	my $new_vary = join (',',$current_vary,$extra_vary);
	$r->header_out("Vary" => $new_vary) if $extra_vary;
    }

my $can_chunk = chunkable($r); # check if it is HTTP/1.1 or higher
unless ($can_chunk) {
	# No chunks for HTTP/1.0. Close connection instead...
	$r->header_out('Connection','close'); # for HTTP/1.0
	$r->log->debug($qualifiedName.' is serving the main request in no-chunk mode for '.$r->the_request);
	unless ($can_gzip) { # send plain content
		# server-side cache control might be in effect, if ordered...
		$r->log->info($qualifiedName.' no gzip for '.$r->the_request);
		if ($filter) {
			# create the filter-chain with no chunks...
			$r = $r->filter_register;
			$fh = $r->filter_input();
			unless ($fh){
				my $message = ' Fails to obtain the Filter data handle for ';
				$r->log->error($qualifiedName.' aborts:'.$message.$r->filename);
				return SERVER_ERROR;
			}
			# Inside the filter chain there are no need to prpogate CGI headers.
			# All headers are already generated (presumably) by the previous filter(s).
			if ($r->header_out('Content-Type')) {
				$r->log->debug($qualifiedName
					.' has Content-Type='.$r->header_out('Content-Type')
					.' for '.$r->the_request);
			} else {
				# create default Content-Type HTTP header:
				$r->log->debug($qualifiedName
					.' creates default Content-Type for '.$r->the_request);
				$r->content_type("text/html");
			}
			$r->send_http_header;

			if ($r->header_only){
				my $message = ' request for HTTP header only is done OK for ';
				$r->log->info($qualifiedName.$message.$r->the_request);
				return OK;
			}
			my $body = ''; # incoming content
			if ($light_compression) {
				$body = send_lightly_compressed_stream($r, $fh);
			} else { # no light compression
				while (<$fh>) {
					$body .= $_ if $r->notes('ref_cache_files'); # accumulate all here
					# to create the effective compression within the later stage,
					# when the caching is ordered...
					print ($_);
				}
			}
			if ($r->notes('ref_cache_files')){
				$r->notes('ref_source' => \$body);
				$r->log->info($qualifiedName.' cache copy is referenced for '.$r->filename);
			}
			$r->log->info($qualifiedName.' is done OK for '.$r->filename
					.' '.$r->bytes_sent.' bytes sent');
			return OK;
		} # if ($filter)

		unless ($binaryCGI) { # Transfer a Plain File responding to the main request

			unless (-e $r->finfo){
				$r->log->error($qualifiedName.' aborts: file does not exist: '.$r->filename);
				return NOT_FOUND;
			}
			if ($r->method_number != M_GET){
				my $message = ' is not allowed for request targeting ';
				$r->log->error($qualifiedName.' aborts: '.$r->method.$message.$r->filename);
				return HTTP_METHOD_NOT_ALLOWED;
			}
			unless ($fh = Apache::File->new($r->filename)){
				my $message = ' file permissions deny server access to ';
				$r->log->error($qualifiedName.' aborts:'.$message.$r->filename);
				return FORBIDDEN;
			}
			# since the file is opened successfully, I need to flock() it...
			my $success = 0;
			my $tries = 0;
			while ($tries++ < MAX_ATTEMPTS_TO_TRY_FLOCK){
				last if $success = flock ($fh, LOCK_SH|LOCK_NB);
				$r->log->warn($qualifiedName.' is waiting for read flock of '.$r->filename);
				sleep (1); # wait a second...
			}
			unless ($success){
				$fh->close;
				$r->log->error($qualifiedName.' aborts: Fails to obtain flock on '.$r->filename);
				return SERVER_ERROR;
			}
			$r->send_http_header;
			if ($r->header_only){
				$r->log->info($qualifiedName.' request for header only is OK for ', $r->filename);
				return OK;
			}
			my $body = ''; # incoming content
			if ($light_compression) {
				$body = send_lightly_compressed_stream($r, $fh);
			} else { # no light compression
				while (<$fh>) {
					$body .= $_ if $r->notes('ref_cache_files'); # accumulate all here
					# to create the effective compression within the later stage,
					# when the caching is ordered...
					print ($_);
				}
			}
			$fh->close;

			if ($r->notes('ref_cache_files')){
				$r->notes('ref_source' => \$body);
				$r->log->info($qualifiedName.' cache copy is referenced for '.$r->filename);
			}
			$r->log->warn($qualifiedName.' is done OK for '.$r->the_request
				.' targeted '.$r->filename.' '.$r->bytes_sent.' bytes sent');
			return OK;
		} # unless ($binaryCGI)

		# It is Binary CGI to transfer with no gzip compression:
		#
		# double-check the target file's existance and access permissions:
		unless (-e $r->finfo){
			$r->log->error($qualifiedName.' aborts: file does not exist: '.$r->filename);
			return NOT_FOUND;
		}
		my $filename = $r->filename();
		unless (-f $filename and -x _ ) {
			$r->log->error($qualifiedName.' aborts: no exec permissions for '.$r->filename);
			return SERVER_ERROR;
		}
		$r->chdir_file();

		# make %ENV appropriately:
		my $gwi = 'CGI/1.1';
		$ENV{GATEWAY_INTERFACE} = $gwi;
		kill_over_env();

		if ($r->method eq 'POST'){ # it NEVER has notes...
			# POST features:
			# since the stdin has a broken structure when passed through the perl-UNIX-pipe
			# I emulate the appropriate GET request to the pp-binary...
			delete($ENV{CONTENT_LENGTH});
			delete($ENV{CONTENT_TYPE});
			my $content = $r->content;
			$ENV{QUERY_STRING} = $content;
			$ENV{REQUEST_METHOD} = 'GET';
		}
		unless ($fh = FileHandle->new("$filename |")) {
			$r->log->error($qualifiedName.' aborts: Fails to obtain incoming data handle for '.$r->filename);
			return NOT_FOUND;
		}
		# lucky to proceed:
		my $headers = retrieve_all_cgi_headers_via ($fh);
		$r->send_cgi_header($headers);
		if ($r->header_only){
			$fh->close;
			$r->log->warn($qualifiedName.' request for HTTP header only is done OK for '.$r->the_request);
			return OK;
		}
		my $body = ''; # incoming content
		if ($light_compression) {
			local $\;
			$body = send_lightly_compressed_stream($r, $fh);
		} else { # no any compression, just chunked:
			local $\;
			my $chunkBody = '';
			while (<$fh>) {
				$body .= $_ if $r->notes('ref_cache_files'); # accumulate all here
				# to create the effective compression within the later stage,
				# when the caching is ordered...
				print ($_);
			}
		}
		$fh->close;

		if ($r->notes('ref_cache_files')){
			$r->notes('ref_source' => \$body);
			$r->log->info($qualifiedName.' cache copy is referenced for '.$r->filename);
		}
		$r->log->info($qualifiedName.' is done OK for '.$r->the_request
				.' '.$r->bytes_sent.' bytes sent');
		return OK;

	} # unless ($can_gzip)

	# Can gzip with no chunks:
	$r->content_encoding('gzip');
	$r->header_out('Vary','Accept-Encoding');

	# retrieve settings from config:
	my $minChunkSize = $r->dir_config('minChunkSize') || MIN_CHUNK_SIZE_DEFAULT;
	my $minChunkSizeSource = $r->dir_config('minChunkSizeSource') || MIN_CHUNK_SIZE_SOURCE_DEFAULT;

	if ($filter) {
		$r = $r->filter_register;
		$fh = $r->filter_input();
		unless ($fh){
			my $message = ' Fails to obtain the Filter data handle for ';
			$r->log->error($qualifiedName.' aborts:'.$message.$r->filename);
			return SERVER_ERROR;
		}
		# Inside the filter chain there are no need to prpogate CGI headers.
		# All headers are already generated (presumably) by the previous filter(s).
		if ($r->header_out('Content-Type')) {
			$r->log->debug($qualifiedName
				.' has Content-Type='.$r->header_out('Content-Type')
				.' for '.$r->the_request);
		} else {
			# create default Content-Type HTTP header:
			$r->log->debug($qualifiedName
				.' creates default Content-Type for '.$r->the_request);
			$r->content_type("text/html");
		}
		$r->send_http_header;

		if ($r->header_only){
			$r->log->info($qualifiedName.' request for HTTP header only is done OK for '
				.$r->the_request);
			return OK;
		}
		my $body = ''; # incoming content
		# Create the deflation stream:
		my ($gzip_handler, $status) = deflateInit(
		     -Level      => Z_BEST_COMPRESSION(),
		     -WindowBits => - MAX_WBITS(),);
		unless ($status == Z_OK()){ # log the Error:
			my $message = 'Cannot create a deflation stream. ';
			$r->log->error($qualifiedName.' aborts: '.$message.' gzip status='.$status
					.' '.$r->bytes_sent.' bytes sent');
			return SERVER_ERROR;
		}
		# Create the first outgoing portion of the content:
		my $gzipHeader = pack("C" . MIN_HDR_SIZE, MAGIC1, MAGIC2, Z_DEFLATED(), 0,0,0,0,0,0, OSCODE);
		my $chunkBody = $gzipHeader; # this is just a portion to output this times...

		my $partialSourceLength = 0;	# the length of the source
						# associated with the portion gzipped in current chunk
		my $lbr = Compress::LeadingBlankSpaces->new();
		while (<$fh>) {
			$_ = $lbr->squeeze_string($_) if $light_compression;
			my $localPartialFlush = 0; # should be false default inside this loop
			$body .= $_; # accumulate all here to create the effective compression
				     # within the cleanup stage, when the caching is ordered...
			$partialSourceLength += length($_); # to deside if the partial flush is required
			if ($partialSourceLength > $minChunkSizeSource){
				$localPartialFlush = 1; # just true
				$partialSourceLength = 0; # for the next pass
			}
			my ($out, $status) = $gzip_handler->deflate(\$_);
			if ($status == Z_OK){
				$chunkBody .= $out; # it may bring nothing indeed...
				$chunkBody .= $gzip_handler->flush(Z_PARTIAL_FLUSH) if $localPartialFlush;
			} else { # log the Error:
				$gzip_handler = undef; # clean it up...
				my $message = 'Cannot gzip the Current Section. ';
				$r->log->error($qualifiedName.' aborts: '.$message.' gzip status='.$status
						.' '.$r->bytes_sent.' bytes sent');
				return SERVER_ERROR;
			}
			if (length($chunkBody) > $minChunkSize ){ # send it...
				print ($chunkBody);
				$chunkBody = ''; # for the next iteration
			}
		}
		$chunkBody .= $gzip_handler->flush();
		$gzip_handler = undef; # clean it up...
		# Append the checksum:
		$chunkBody .= pack("V V", crc32(\$body), length($body));
		print ($chunkBody);
		$chunkBody = '';

		if ($r->notes('ref_cache_files')){
			$r->notes('ref_source' => \$body);
			$r->log->info($qualifiedName.' cache copy is referenced for '.$r->filename);
		}
		$r->log->info($qualifiedName.' is done OK for '.$r->filename
				.' '.$r->bytes_sent.' bytes sent');
		return OK;
	} # if ($filter)

	unless ($binaryCGI) { # Transfer a Plain File gzipped, responding to the main request

		unless (-e $r->finfo){
			$r->log->error($qualifiedName.' aborts: file does not exist: '.$r->filename);
			return NOT_FOUND;
		}
		if ($r->method_number != M_GET){
			my $message = ' is not allowed for redirected request targeting ';
			$r->log->error($qualifiedName.' aborts: '.$r->method.$message.$r->filename);
			return HTTP_METHOD_NOT_ALLOWED;
		}
		unless ($fh = Apache::File->new($r->filename)){
			my $message = ' file permissions deny server access to ';
			$r->log->error($qualifiedName.' aborts:'.$message.$r->filename);
			return FORBIDDEN;
		}
		# since the file is opened successfully, I need to flock() it...
		my $success = 0;
		my $tries = 0;
		while ($tries++ < MAX_ATTEMPTS_TO_TRY_FLOCK){
			last if $success = flock ($fh, LOCK_SH|LOCK_NB);
			$r->log->warn($qualifiedName.' is waiting for read flock of '.$r->filename);
			sleep (1); # wait a second...
		}
		unless ($success){
			$fh->close;
			$r->log->error($qualifiedName.' aborts: Fails to obtain flock on '.$r->filename);
			return SERVER_ERROR;
		}
		$r->content_type("text/html") unless $r->content_type;
		$r->send_http_header;
		if ($r->header_only){
			$r->log->info($qualifiedName.' request for header only is OK for ', $r->filename);
			return OK;
		}
		# Create the deflation stream:
		my ($gzip_handler, $status) = deflateInit(
		     -Level      => Z_BEST_COMPRESSION(),
		     -WindowBits => - MAX_WBITS(),);
		unless ($status == Z_OK()){ # log the Error:
			$fh->close; # and unlock...
			my $message = 'Cannot create a deflation stream. ';
			$r->log->error($qualifiedName.' aborts: '.$message.'gzip status='.$status);
			return SERVER_ERROR;
		}
		# Create the first outgoing portion of the content:
	    my $gzipHeader = pack("C" . MIN_HDR_SIZE, MAGIC1, MAGIC2, Z_DEFLATED(), 0,0,0,0,0,0, OSCODE);
		my $chunkBody = $gzipHeader;

		my $body = ''; # incoming content
		my $partialSourceLength = 0; # the length of the source associated with the portion gzipped in current chunk
		my $lbr = Compress::LeadingBlankSpaces->new();
		while (<$fh>) {
			$_ = $lbr->squeeze_string($_) if $light_compression;
			my $localPartialFlush = 0; # should be false default inside this loop
			$body .= $_;    # accumulate all here to create the effective compression within the cleanup stage,
					# when the caching is ordered...
			$partialSourceLength += length($_); # to deside if the partial flush is required
			if ($partialSourceLength > $minChunkSizeSource){
				$localPartialFlush = 1; # just true
				$partialSourceLength = 0; # for the next pass
			}
			my ($out, $status) = $gzip_handler->deflate(\$_);
			if ($status == Z_OK){
				$chunkBody .= $out; # it may bring nothing indeed...
				$chunkBody .= $gzip_handler->flush(Z_PARTIAL_FLUSH) if $localPartialFlush;
			} else { # log the Error:
				$fh->close; # and unlock...
				$gzip_handler = undef; # clean it up...
				my $message = 'Cannot gzip the Current Section. ';
				$r->log->error($qualifiedName.' aborts: '.$message.' gzip status='.$status
						.' '.$r->bytes_sent.' bytes sent');
				return SERVER_ERROR;
			}
			if (length($chunkBody) > $minChunkSize ){ # send it...
				print ($chunkBody);
				$chunkBody = ''; # for the next iteration
			}
		}
		$fh->close; # and unlock...
		$chunkBody .= $gzip_handler->flush();
		$gzip_handler = undef; # clean it up...
		# Append the checksum:
		$chunkBody .= pack("V V", crc32(\$body), length($body)) ;
		print ($chunkBody);
		$chunkBody = '';
		if ($r->notes('ref_cache_files')){
			$r->notes('ref_source' => \$body);
			$r->log->info($qualifiedName.' cache copy is referenced for '.$r->filename);
		}
		$r->log->info($qualifiedName.' is done OK for '.$r->filename
				.' '.$r->bytes_sent.' bytes sent');
		return OK;
	} # unless ($binaryCGI)

	# It is Binary CGI to transfer with gzip compression:
	#
	# double-check the target file's existance and access permissions:
	unless (-e $r->finfo){
		$r->log->error($qualifiedName.' aborts: file does not exist: '.$r->filename);
		return NOT_FOUND;
	}
	my $filename = $r->filename();
	unless (-f $filename and -x _ ) {
		$r->log->error($qualifiedName.' aborts: no exec permissions for '.$r->filename);
		return SERVER_ERROR;
	}
	$r->chdir_file();

	# make %ENV appropriately:
	if ($r->notes('PP_PATH_TRANSLATED')){
		$r->log->info($qualifiedName.' has notes: PP_PATH_TRANSLATED='.$r->notes('PP_PATH_TRANSLATED'));
		my $gwi = 'CGI/1.1';
		$ENV{GATEWAY_INTERFACE} = $gwi;
		kill_over_env();

		$ENV{QUERY_STRING} = $r->notes('PP_QUERY_STRING');
		$ENV{SCRIPT_NAME} = $r->notes('PP_SCRIPT_NAME');
		$ENV{DOCUMENT_NAME}='index.html';
		$ENV{DOCUMENT_PATH_INFO}='';

		$ENV{REQUEST_URI} = $ENV{SCRIPT_NAME}.'?'.$ENV{QUERY_STRING};
		$ENV{PATH_INFO} = $r->notes('PP_PATH_INFO');
		$ENV{DOCUMENT_URI} = $ENV{PATH_INFO};
		$ENV{PATH_TRANSLATED} = $r->notes('PP_PATH_TRANSLATED');
	} else {
		$r->log->info($qualifiedName.' has no notes.');
	}
	if ($r->method eq 'POST'){ # it NEVER has notes...
                my $gwi = 'CGI/1.1';
                $ENV{GATEWAY_INTERFACE} = $gwi;
		kill_over_env();

		# POST features:
		# since the stdin has a broken structure when passed through the perl-UNIX-pipe
		# I emulate the appropriate GET request to the pp-binary...
		delete($ENV{CONTENT_LENGTH});
		delete($ENV{CONTENT_TYPE});
		my $content = $r->content;
		$ENV{QUERY_STRING} = $content;
		$ENV{REQUEST_METHOD} = 'GET';
	}
	unless ($fh = FileHandle->new("$filename |")) {
		$r->log->error($qualifiedName.' aborts: Fails to obtain incoming data handle for '.$r->filename);
		return NOT_FOUND;
	}
	# lucky to proceed:
	my $headers = retrieve_all_cgi_headers_via ($fh);
	$r->send_cgi_header($headers);
	if ($r->header_only){
		$fh->close;
		$r->log->info($qualifiedName.' request for HTTP header only is done OK for '.$r->the_request);
		return OK;
	}

	# Create the deflation stream:
	my ($gzip_handler, $status) = deflateInit(
	     -Level      => Z_BEST_COMPRESSION(),
	     -WindowBits => - MAX_WBITS(),);
	unless ($status == Z_OK()){ # log the Error:
		my $message = 'Cannot create a deflation stream. ';
		$r->log->error($qualifiedName.' aborts: '.$message.' gzip status='.$status
				.' '.$r->bytes_sent.' bytes sent');
		return SERVER_ERROR;
	}
	# Create the first outgoing portion of the content:
	my $gzipHeader = pack("C" . MIN_HDR_SIZE, MAGIC1, MAGIC2, Z_DEFLATED(), 0,0,0,0,0,0, OSCODE);
	my $chunkBody = $gzipHeader;
	my $body = ''; # incoming content
	my $partialSourceLength = 0; # the length of the source associated with the portion gzipped in current chunk

	my $buf;
	{
	local $\;
	my $lbr = Compress::LeadingBlankSpaces->new();
	while (defined($buf = <$fh>)){
		$buf = $lbr->squeeze_string($buf) if $light_compression;
		next unless $buf;
		$body .= $buf;
		my $localPartialFlush = 0; # should be false default inside this loop
		$partialSourceLength += length($buf); # to deside if the partial flush is required
		if ($partialSourceLength > $minChunkSizeSource){
			$localPartialFlush = 1; # just true
			$partialSourceLength = 0; # for the next pass
		}
		my ($out, $status) = $gzip_handler->deflate(\$buf);
		if ($status == Z_OK){
			$chunkBody .= $out; # it may bring nothing indeed...
			$chunkBody .= $gzip_handler->flush(Z_PARTIAL_FLUSH) if $localPartialFlush;
		} else { # log the Error:
			$fh->close;
			$gzip_handler = undef; # clean it up...
			$r->log->error($qualifiedName.' aborts: Cannot gzip this section. gzip status='
					.$status.' '.$r->bytes_sent.' bytes sent');
			return SERVER_ERROR;
		}
		if (length($chunkBody) > $minChunkSize ){ # send it...
			print ($chunkBody);
			$chunkBody = ''; # for the next iteration
		}
	}
	}
	$fh->close;
	$chunkBody .= $gzip_handler->flush();
	$gzip_handler = undef; # clean it up...
	# Append the checksum:
	$chunkBody .= pack("V V", crc32(\$body), length($body)) ;
	print ($chunkBody);
	$chunkBody = '';
	if ($r->notes('ref_cache_files')){
		$r->notes('ref_source' => \$body);
		$r->log->info($qualifiedName.' cache copy is referenced for '.$r->filename);
	}
	$r->log->info($qualifiedName.' is done OK for '.$r->filename
			.' '.$r->bytes_sent.' bytes sent');
	return OK;

} # unless ($can_chunk)

	# This is HTTP/1.1 or higher:
	$r->header_out('Transfer-Encoding','chunked'); # to overwrite the default Apache behavior...
	unless ($can_gzip) {
		# Send chunked content, which might be lightly compressed only, when the compression is ordered...
		# server-side cache control might be in effect, if ordered...
		#
		my $minChunkSizePP = $r->dir_config('minChunkSizePP') || MIN_CHUNK_SIZE_PP_DEFAULT;
		$r->log->info($qualifiedName.' no gzip for '.$r->the_request
			.' min_chunk_size='.$minChunkSizePP);

		if ($filter) {
			# make filter-chain item with chunks...
			$r = $r->filter_register;
			$fh = $r->filter_input();
			unless ($fh){
				my $message = ' Fails to obtain the Filter data handle for ';
				$r->log->error($qualifiedName.' aborts:'.$message.$r->filename);
				return SERVER_ERROR;
			}
			# Inside the filter chain there are no need to prpogate CGI headers.
			# All headers are already generated (presumably) by the previous filter(s).
			if ($r->header_out('Content-Type')) {
				$r->log->debug($qualifiedName
					.' has Content-Type='.$r->header_out('Content-Type')
					.' for '.$r->the_request);
			} else {
				# create default Content-Type HTTP header:
				$r->log->debug($qualifiedName
					.' creates default Content-Type for '.$r->the_request);
				$r->content_type("text/html");
			}
			$r->send_http_header;

			if ($r->header_only){
				$r->log->info($qualifiedName.' request for HTTP header only is done OK for '.$r->the_request);
				return OK;
			}
			my $body = ''; # incoming content
			if ($light_compression) {
				$body = send_lightly_compressed_stream_chunked($r, $fh, $minChunkSizePP);
			} else { # no light compression
				my $chunkBody = '';
				while (<$fh>) {
					$body .= $_ if $r->notes('ref_cache_files'); # accumulate all here
					# to create the effective compression within the later stage,
					# when the caching is ordered...
					$chunkBody .= $_;
					if (length($chunkBody) > $minChunkSizePP){ # send it...
						print (chunk_out($chunkBody));
						$chunkBody = ''; # for the next iteration
					}
				}
				if (length($chunkBody) > 0){ # send it...
					print (chunk_out($chunkBody));
					$chunkBody = '';
				}
			}
			# Append the empty chunk to finish the deal:
			print ('0'.$HttpEol.$HttpEol);

			if ($r->notes('ref_cache_files')){
				$r->notes('ref_source' => \$body);
				$r->log->info($qualifiedName.' cache copy is referenced for '.$r->filename);
			}
			$r->log->info($qualifiedName.' is done OK for '.$r->filename
					.' '.$r->bytes_sent.' bytes sent');
			return OK;
		} # if ($filter)

		unless ($binaryCGI) { # Transfer a Plain File responding to the main request

			unless (-e $r->finfo){
				$r->log->error($qualifiedName.' aborts: file does not exist: '.$r->filename);
				return NOT_FOUND;
			}
			if ($r->method_number != M_GET){
				my $message = ' is not allowed for request targeting ';
				$r->log->error($qualifiedName.' aborts: '.$r->method.$message.$r->filename);
				return HTTP_METHOD_NOT_ALLOWED;
			}
			unless ($fh = Apache::File->new($r->filename)){
				my $message = ' file permissions deny server access to ';
				$r->log->error($qualifiedName.' aborts:'.$message.$r->filename);
				return FORBIDDEN;
			}
			# since the file is opened successfully, I need to flock() it...
			my $success = 0;
			my $tries = 0;
			while ($tries++ < MAX_ATTEMPTS_TO_TRY_FLOCK){
				last if $success = flock ($fh, LOCK_SH|LOCK_NB);
				$r->log->warn($qualifiedName.' is waiting for read flock of '.$r->filename);
				sleep (1); # wait a second...
			}
			unless ($success){
				$fh->close;
				$r->log->error($qualifiedName.' aborts: Fails to obtain flock on '.$r->filename);
				return SERVER_ERROR;
			}
			$r->send_http_header;
			if ($r->header_only){
				$r->log->info($qualifiedName.' request for header only is OK for ', $r->filename);
				return OK;
			}
			my $body = ''; # incoming content
			if ($light_compression) {
				$body = send_lightly_compressed_stream_chunked($r, $fh, $minChunkSizePP);
			} else { # no light compression
				my $chunkBody = '';
				while (<$fh>) {
					$body .= $_ if $r->notes('ref_cache_files'); # accumulate all here
					# to create the effective compression within the later stage,
					# when the caching is ordered...
					$chunkBody .= $_;
					if (length($chunkBody) > $minChunkSizePP){ # send it...
						print (chunk_out($chunkBody));
						$chunkBody = ''; # for the next iteration
					}
				}
				if (length($chunkBody) > 0){ # send it...
					print (chunk_out($chunkBody));
					$chunkBody = '';
				}
			}
			$fh->close;
			# Append the empty chunk to finish the deal:
			print ('0'.$HttpEol.$HttpEol);

			if ($r->notes('ref_cache_files')){
				$r->notes('ref_source' => \$body);
				$r->log->info($qualifiedName.' cache copy is referenced for '.$r->filename);
			}
			$r->log->warn($qualifiedName.' is done OK for '.$r->the_request
					.' targeted '.$r->filename.' '.$r->bytes_sent.' bytes sent');
			return OK;
		} # unless ($binaryCGI)

		# It is Binary CGI to transfer with no gzip compression:
		#
		# double-check the target file's existance and access permissions:
		unless (-e $r->finfo){
			$r->log->error($qualifiedName.' aborts: file does not exist: '.$r->filename);
			return NOT_FOUND;
		}
		my $filename = $r->filename();
		unless (-f $filename and -x _ ) {
			$r->log->error($qualifiedName.' aborts: no exec permissions for '.$r->filename);
			return SERVER_ERROR;
		}
		$r->chdir_file();

		# make %ENV appropriately:
		my $gwi = 'CGI/1.1';
		$ENV{GATEWAY_INTERFACE} = $gwi;
		kill_over_env();

		if ($r->method eq 'POST'){ # it NEVER has notes...
			# POST features:
			# since the stdin has a broken structure when passed through the perl-UNIX-pipe
			# I emulate the appropriate GET request to the pp-binary...
			delete($ENV{CONTENT_LENGTH});
			delete($ENV{CONTENT_TYPE});
			my $content = $r->content;
			$ENV{QUERY_STRING} = $content;
			$ENV{REQUEST_METHOD} = 'GET';
		}
		unless ($fh = FileHandle->new("$filename |")) {
			$r->log->error($qualifiedName.' aborts: Fails to obtain incoming data handle for '.$r->filename);
			return NOT_FOUND;
		}
		# lucky to proceed:
		my $headers = retrieve_all_cgi_headers_via ($fh);
		$r->send_cgi_header($headers);
		if ($r->header_only){
			$fh->close;
			$r->log->warn($qualifiedName.' request for HTTP header only is done OK for '.$r->the_request);
			return OK;
		}
		my $body = ''; # incoming content
		if ($light_compression) {
			local $\;
			$body = send_lightly_compressed_stream_chunked($r, $fh, $minChunkSizePP);
		} else { # no any compression, just chunked:
			local $\;
			my $chunkBody = '';
			while (<$fh>) {
				$body .= $_ if $r->notes('ref_cache_files'); # accumulate all here
				# to create the effective compression within the later stage,
				# when the caching is ordered...
				$chunkBody .= $_;
				if (length($chunkBody) > $minChunkSizePP){ # send it...
					print (chunk_out($chunkBody));
					$chunkBody = ''; # for the next iteration
				}
			}
			if (length($chunkBody) > 0){ # send it...
				print (chunk_out($chunkBody));
				$chunkBody = '';
			}
		}
		$fh->close;
		# Append the empty chunk to finish the deal:
		print ('0'.$HttpEol.$HttpEol);

		if ($r->notes('ref_cache_files')){
			$r->notes('ref_source' => \$body);
			$r->log->info($qualifiedName.' cache copy is referenced for '.$r->filename);
		}
		$r->log->warn($qualifiedName.' is done OK for '.$r->the_request
				.' '.$r->bytes_sent.' bytes sent');
		return OK;
	} # unless ($can_gzip)

	# GZIP the outgoing stream...
	# ===========================
	# retrieve settings from config:
	my $minChunkSize = $r->dir_config('minChunkSize') || MIN_CHUNK_SIZE_DEFAULT;
	my $minChunkSizeSource = $r->dir_config('minChunkSizeSource') || MIN_CHUNK_SIZE_SOURCE_DEFAULT;
	$r->log->info($qualifiedName.' starts gzip using minChunkSizeSource = '.$minChunkSizeSource.
		' minChunkSize = '.$minChunkSize.' for '.$r->filename);
	$r->content_encoding('gzip');
	$r->header_out('Transfer-Encoding','chunked'); # to overwrite the default Apache behavior...
	#
	# In reference to mod_gzip interoperability with poorly written proxies, 
	# Michael Schroepl recently wrote:
	# > You do need to include a header like
	# > 
	# > Vary: User-Agent,Accept-Encoding
	# > 
	# > with all responses, compressed or not.  If you don't, then it's your 
	# > fault, not the proxy's fault, when something fails.
	#
	$r->header_out('Vary','Accept-Encoding');

	# Advanced control over the client/proxy Cache:
	#
    {
	local $^W = 0;
	my $extra_vary = $r->dir_config('Vary');
	my $current_vary = $r->header_out("Vary");
	my $new_vary = join (',',$current_vary,$extra_vary);
	$r->header_out("Vary" => $new_vary) if $extra_vary;
    }

	if ($filter) {
		$r = $r->filter_register;
		$fh = $r->filter_input();
		unless ($fh){
			my $message = ' Fails to obtain the Filter data handle for ';
			$r->log->error($qualifiedName.' aborts:'.$message.$r->filename);
			return SERVER_ERROR;
		}
		# Inside the filter chain there are no need to prpogate CGI headers.
		# All headers are already generated (presumably) by the previous filter(s).
		if ($r->header_out('Content-Type')) {
			$r->log->debug($qualifiedName
				.' has Content-Type='.$r->header_out('Content-Type')
				.' for '.$r->the_request);
		} else {
			# create default Content-Type HTTP header:
			$r->log->debug($qualifiedName
				.' creates default Content-Type for '.$r->the_request);
			$r->content_type("text/html");
		}
		$r->send_http_header;

		if ($r->header_only){
			$r->log->info($qualifiedName.' request for HTTP header only is done OK for '
				.$r->the_request);
			return OK;
		}
		my $body = ''; # incoming content
		# Create the deflation stream:
		my ($gzip_handler, $status) = deflateInit(
		     -Level      => Z_BEST_COMPRESSION(),
		     -WindowBits => - MAX_WBITS(),);
		unless ($status == Z_OK()){ # log the Error:
			my $message = 'Cannot create a deflation stream. ';
			$r->log->error($qualifiedName.' aborts: '.$message.' gzip status='.$status
					.' '.$r->bytes_sent.' bytes sent');
			return SERVER_ERROR;
		}
		# Create the first outgoing portion of the content:
		my $gzipHeader = pack("C" . MIN_HDR_SIZE, MAGIC1, MAGIC2, Z_DEFLATED(), 0,0,0,0,0,0, OSCODE);
		my $chunkBody = $gzipHeader;

		my $partialSourceLength = 0;	# the length of the source
						# associated with the portion gzipped in current chunk
		my $lbr = Compress::LeadingBlankSpaces->new();
		while (<$fh>) {
			$_ = $lbr->squeeze_string($_) if $light_compression;
			my $localPartialFlush = 0; # should be false default inside this loop
			$body .= $_; # accumulate all here to create the effective compression
				     # within the cleanup stage, when the caching is ordered...
			$partialSourceLength += length($_); # to deside if the partial flush is required
			if ($partialSourceLength > $minChunkSizeSource){
				$localPartialFlush = 1; # just true
				$partialSourceLength = 0; # for the next pass
			}
			my ($out, $status) = $gzip_handler->deflate(\$_);
			if ($status == Z_OK){
				$chunkBody .= $out; # it may bring nothing indeed...
				$chunkBody .= $gzip_handler->flush(Z_PARTIAL_FLUSH) if $localPartialFlush;
			} else { # log the Error:
				$gzip_handler = undef; # clean it up...
				my $message = 'Cannot gzip the Current Section. ';
				$r->log->error($qualifiedName.' aborts: '.$message.'gzip status='.$status
						.' '.$r->bytes_sent.' bytes sent');
				return SERVER_ERROR;
			}
			if (length($chunkBody) > $minChunkSize ){ # send it...
				print (chunk_out($chunkBody));
				$chunkBody = ''; # for the next iteration
			}
		}
		$chunkBody .= $gzip_handler->flush();
		$gzip_handler = undef; # clean it up...
		# Append the checksum:
		$chunkBody .= pack("V V", crc32(\$body), length($body));
		print (chunk_out($chunkBody));
		$chunkBody = '';

		# Append the empty chunk to finish the deal:
		print ('0'.$HttpEol.$HttpEol);

		if ($r->notes('ref_cache_files')){
			$r->notes('ref_source' => \$body);
			$r->log->info($qualifiedName.' cache copy is referenced for '.$r->filename);
		}
		$r->log->info($qualifiedName.' is done OK for '.$r->filename
				.' '.$r->bytes_sent.' bytes sent');
		return OK;
	} # if ($filter)

	unless ($binaryCGI) { # Transfer a Plain File gzipped, responding to the main request

		unless (-e $r->finfo){
			$r->log->error($qualifiedName.' aborts: file does not exist: '.$r->filename);
			return NOT_FOUND;
		}
		if ($r->method_number != M_GET){
			my $message = ' is not allowed for redirected request targeting ';
			$r->log->error($qualifiedName.' aborts: '.$r->method.$message.$r->filename);
			return HTTP_METHOD_NOT_ALLOWED;
		}
		unless ($fh = Apache::File->new($r->filename)){
			my $message = ' file permissions deny server access to ';
			$r->log->error($qualifiedName.' aborts:'.$message.$r->filename);
			return FORBIDDEN;
		}
		# since the file is opened successfully, I need to flock() it...
		my $success = 0;
		my $tries = 0;
		while ($tries++ < MAX_ATTEMPTS_TO_TRY_FLOCK){
			last if $success = flock ($fh, LOCK_SH|LOCK_NB);
			$r->log->warn($qualifiedName.' is waiting for read flock of '.$r->filename);
			sleep (1); # wait a second...
		}
		unless ($success){
			$fh->close;
			$r->log->error($qualifiedName.' aborts: Fails to obtain flock on '.$r->filename);
			return SERVER_ERROR;
		}
#		$r->content_type("text/html") unless $r->header_out('Content-Type'); # It was a BUG
		$r->content_type("text/html") unless defined $r->content_type;
		$r->send_http_header;
		if ($r->header_only){
			$r->log->info($qualifiedName.' request for header only is OK for ', $r->filename);
			return OK;
		}
		# Create the deflation stream:
		my ($gzip_handler, $status) = deflateInit(
		     -Level      => Z_BEST_COMPRESSION(),
		     -WindowBits => - MAX_WBITS(),);
		unless ($status == Z_OK()){ # log the Error:
			$fh->close; # and unlock...
			my $message = 'Cannot create a deflation stream. ';
			$r->log->error($qualifiedName.' aborts: '.$message.'gzip status='.$status
					.' '.$r->bytes_sent.' bytes sent');
			return SERVER_ERROR;
		}
		# Create the first outgoing portion of the content:
		my $gzipHeader = pack("C" . MIN_HDR_SIZE, MAGIC1, MAGIC2, Z_DEFLATED(), 0,0,0,0,0,0, OSCODE);
		my $chunkBody = $gzipHeader;

		my $body = ''; # incoming content
		my $partialSourceLength = 0;	# the length of the source associated
						# with the portion gzipped in current chunk
		my $lbr = Compress::LeadingBlankSpaces->new();
		while (<$fh>) {
			$_ = $lbr->squeeze_string($_) if $light_compression;
			my $localPartialFlush = 0; # should be false default inside this loop
			$body .= $_;    # accumulate all over here in order to create
					# the effective compression within the cleanup stage,
					# when the caching is ordered...
			$partialSourceLength += length($_); # to deside if the partial flush is required
			if ($partialSourceLength > $minChunkSizeSource){
				$localPartialFlush = 1; # just true
				$partialSourceLength = 0; # for the next pass
			}
			my ($out, $status) = $gzip_handler->deflate(\$_);
			if ($status == Z_OK){
				$chunkBody .= $out; # it may bring nothing indeed...
				$chunkBody .= $gzip_handler->flush(Z_PARTIAL_FLUSH) if $localPartialFlush;
			} else { # log the Error:
				$fh->close; # and unlock...
				$gzip_handler = undef; # clean it up...
				my $message = 'Cannot gzip the Current Section. ';
				$r->log->error($qualifiedName.' aborts: '.$message.'gzip status='.$status
						.' '.$r->bytes_sent.' bytes sent');
				return SERVER_ERROR;
			}
			if (length($chunkBody) > $minChunkSize ){ # send it...
				print (chunk_out($chunkBody));
				$chunkBody = ''; # for the next iteration
			}
		}
		$fh->close; # and unlock...
		$chunkBody .= $gzip_handler->flush();
		$gzip_handler = undef; # clean it up...
		# Append the checksum:
		$chunkBody .= pack("V V", crc32(\$body), length($body)) ;
		print (chunk_out($chunkBody));
		$chunkBody = '';
		# Append the empty chunk to finish the deal:
		print ('0'.$HttpEol.$HttpEol);
		if ($r->notes('ref_cache_files')){
			$r->notes('ref_source' => \$body);
			$r->log->info($qualifiedName.' cache copy is referenced for '.$r->filename);
		}
		$r->log->info($qualifiedName.' is done OK for '.$r->filename
				.' '.$r->bytes_sent.' bytes sent');
		return OK;
	} # unless ($binaryCGI)

	# This is Binary CGI to transfer with gzip compression:
	#
	# double-check the target file's existance and access permissions:
	unless (-e $r->finfo){
		$r->log->error($qualifiedName.' aborts: file does not exist: '.$r->filename);
		return NOT_FOUND;
	}
	my $filename = $r->filename();
	unless (-f $filename and -x _ ) {
		$r->log->error($qualifiedName.' aborts: no exec permissions for '.$r->filename);
		return SERVER_ERROR;
	}
	$r->chdir_file();

	# make %ENV appropriately:
	if ($r->notes('PP_PATH_TRANSLATED')){
		$r->log->info($qualifiedName.' has notes: PP_PATH_TRANSLATED='.$r->notes('PP_PATH_TRANSLATED'));
		my $gwi = 'CGI/1.1';
		$ENV{GATEWAY_INTERFACE} = $gwi;
		kill_over_env();

		$ENV{QUERY_STRING} = $r->notes('PP_QUERY_STRING');
		$ENV{SCRIPT_NAME} = $r->notes('PP_SCRIPT_NAME');
		$ENV{DOCUMENT_NAME}='index.html';
		$ENV{DOCUMENT_PATH_INFO}='';

		$ENV{REQUEST_URI} = $ENV{SCRIPT_NAME}.'?'.$ENV{QUERY_STRING};
		$ENV{PATH_INFO} = $r->notes('PP_PATH_INFO');
		$ENV{DOCUMENT_URI} = $ENV{PATH_INFO};
		$ENV{PATH_TRANSLATED} = $r->notes('PP_PATH_TRANSLATED');
	} else {
		$r->log->info($qualifiedName.' has no notes.');
	}
	if ($r->method eq 'POST'){ # it NEVER has notes...
                my $gwi = 'CGI/1.1';
                $ENV{GATEWAY_INTERFACE} = $gwi;
		kill_over_env();

		# POST features:
		# since the stdin has a broken structure when passed through the perl-UNIX-pipe
		# I emulate the appropriate GET request to the pp-binary...
		delete($ENV{CONTENT_LENGTH});
		delete($ENV{CONTENT_TYPE});
		my $content = $r->content;
		$ENV{QUERY_STRING} = $content;
		$ENV{REQUEST_METHOD} = 'GET';
	}
	unless ($fh = FileHandle->new("$filename |")) {
		$r->log->error($qualifiedName.' aborts: Fails to obtain incoming data handle for '.$r->filename);
		return NOT_FOUND;
	}
	# lucky to proceed:
	my $headers = retrieve_all_cgi_headers_via ($fh);
	$r->send_cgi_header($headers);
	if ($r->header_only){
		$fh->close;
		$r->log->warn($qualifiedName.' request for HTTP header only is done OK for '.$r->the_request);
		return OK;
	}

	# Create the deflation stream:
	my ($gzip_handler, $status) = deflateInit(
	     -Level      => Z_BEST_COMPRESSION(),
	     -WindowBits => - MAX_WBITS(),);
	unless ($status == Z_OK()){ # log the Error:
		my $message = 'Cannot create a deflation stream. ';
		$r->log->error($qualifiedName.' aborts: '.$message.'gzip status='.$status
				.' '.$r->bytes_sent.' bytes sent');
		return SERVER_ERROR;
	}
	# Create the first outgoing portion of the content:
	my $gzipHeader = pack("C" . MIN_HDR_SIZE, MAGIC1, MAGIC2, Z_DEFLATED(), 0,0,0,0,0,0, OSCODE);
	my $chunkBody = $gzipHeader;
	my $body = ''; # incoming content
	my $partialSourceLength = 0;	# the length of the source associated
					# with the portion gzipped in current chunk
	my $buf;
	{
		local $\;
		my $lbr = Compress::LeadingBlankSpaces->new();
		while (defined($buf = <$fh>)){
			$buf = $lbr->squeeze_string($buf) if $light_compression;
			next unless $buf;
			$body .= $buf;
			my $localPartialFlush = 0; # should be false default inside this loop
			$partialSourceLength += length($buf); # to deside if the partial flush is required
			if ($partialSourceLength > $minChunkSizeSource){
				$localPartialFlush = 1; # just true
				$partialSourceLength = 0; # for the next pass
			}
			my ($out, $status) = $gzip_handler->deflate(\$buf);
			if ($status == Z_OK){
				$chunkBody .= $out; # it may bring nothing indeed...
				$chunkBody .= $gzip_handler->flush(Z_PARTIAL_FLUSH) if $localPartialFlush;
			} else { # log the Error:
				$fh->close;
				$gzip_handler = undef; # clean it up...
				$r->log->error($qualifiedName.' aborts: Cannot gzip this section. gzip status='
						.$status.' '.$r->bytes_sent.' bytes sent');
				return SERVER_ERROR;
			}
			if (length($chunkBody) > $minChunkSize ){ # send it...
				print (chunk_out($chunkBody));
				$chunkBody = ''; # for the next iteration
			}
		}
	}
	$fh->close;
	$chunkBody .= $gzip_handler->flush();
	$gzip_handler = undef; # clean it up...
	# Append the checksum:
	$chunkBody .= pack("V V", crc32(\$body), length($body)) ;
	print (chunk_out($chunkBody));
	$chunkBody = '';
	# Append the empty chunk to finish the deal:
	print ('0'.$HttpEol.$HttpEol);
	if ($r->notes('ref_cache_files')){
		$r->notes('ref_source' => \$body);
		$r->log->info($qualifiedName.' cache copy is referenced for '.$r->filename);
	}
	$r->log->info($qualifiedName.' is done OK for '.$r->filename
			.' '.$r->bytes_sent.' bytes sent');
	return OK;
}

1;

__END__

=head1 NAME

Apache::Dynagzip - mod_perl extension for C<Apache-1.3.X> to compress the response with C<gzip> format.

=head1 ABSTRACT

This Apache handler provides dynamic content compression of the response data stream
for C<HTTP/1.0> and C<HTTP/1.1> requests.
Standard C<gzip> compression is optionally combined with an C<extra light> compression
that eliminates leading blank spaces and/or blank lines within the source document.
An C<extra light> compression could be applied even when the client (browser)
is not capable to decompress C<gzip> format.

Handler helps to compress the outbound
HTML content usually by 3 to 20 times, and provides a list of useful features.
This is particularly useful for compressing outgoing web content
that is dynamically generated on the fly (using templates, DB data, XML,
etc.), when at the time of the request it is impossible to determine the
length of the document to be transmitted. Support for Perl, Java, and C
source generators is provided.

Besides the benefits of reduced document size, this approach gains efficiency
from being able to overlap the various phases of data generation, compression,
transmission, and decompression. In fact, the browser can start to
decompress a document, which has not yet been completely generated.

=head1 SYNOPSIS

There is more then one way to configure Apache to use this handler...

=head2 Compress regular (static) HTML files

 ======================================================
 Static html file (size=149208) no light compression:
 ======================================================
 httpd.conf:

  PerlModule Apache::Dynagzip
  <Files ~ "*\.html">
      SetHandler perl-script
      PerlHandler Apache::Dynagzip
  </Files>

 client-side log:

  C05 --> S06 GET /html/wowtmovie.html HTTP/1.1
  C05 --> S06 Accept: */*
  C05 --> S06 Referer: http://devl4.outlook.net/html/
  C05 --> S06 Accept-Language: en-us
  C05 --> S06 Accept-Encoding: gzip, deflate
  C05 --> S06 User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)
  C05 --> S06 Host: devl4.outlook.net
  C05 --> S06 Pragma: no-cache
  C05 --> S06 Accept-Charset: ISO-8859-1
  == Body was 0 bytes ==

  C05 <-- S06 HTTP/1.1 200 OK
  C05 <-- S06 Date: Fri, 31 May 2002 17:36:57 GMT
  C05 <-- S06 Server: Apache/1.3.22 (Unix) Debian GNU/Linux mod_perl/1.26
  C05 <-- S06 X-Module-Sender: Apache::Dynagzip
  C05 <-- S06 Transfer-Encoding: chunked
  C05 <-- S06 Expires: Friday, 31-May-2002 17:41:57 GMT
  C05 <-- S06 Vary: Accept-Encoding
  C05 <-- S06 Content-Type: text/html; charset=iso-8859-1
  C05 <-- S06 Content-Encoding: gzip
  C05 <-- S06 == Incoming Body was 9411 bytes ==
  == Transmission: text gzip chunked ==
  == Chunk Log ==
  a (hex) = 10 (dec)
  1314 (hex) = 4884 (dec)
  3ed (hex) = 1005 (dec)
  354 (hex) = 852 (dec)
  450 (hex) = 1104 (dec)
  5e6 (hex) = 1510 (dec)
  0 (hex) = 0 (dec)
  == Latency = 0.170 seconds, Extra Delay = 0.440 seconds
  == Restored Body was 149208 bytes ==

 ======================================================
 Static html file (size=149208) with light compression:
 ======================================================
 httpd.conf:

  PerlModule Apache::Dynagzip
  <Files ~ "*\.html">
        SetHandler perl-script
        PerlHandler Apache::Dynagzip
        PerlSetVar LightCompression On
  </Files>

 client-side log:

  C05 --> S06 GET /html/wowtmovie.html HTTP/1.1
  C05 --> S06 Accept: */*
  C05 --> S06 Referer: http://devl4.outlook.net/html/
  C05 --> S06 Accept-Language: en-us
  C05 --> S06 Accept-Encoding: gzip, deflate
  C05 --> S06 User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)
  C05 --> S06 Host: devl4.outlook.net
  C05 --> S06 Pragma: no-cache
  C05 --> S06 Accept-Charset: ISO-8859-1
  == Body was 0 bytes ==

  C05 <-- S06 HTTP/1.1 200 OK
  C05 <-- S06 Date: Fri, 31 May 2002 17:49:06 GMT
  C05 <-- S06 Server: Apache/1.3.22 (Unix) Debian GNU/Linux mod_perl/1.26
  C05 <-- S06 X-Module-Sender: Apache::Dynagzip
  C05 <-- S06 Transfer-Encoding: chunked
  C05 <-- S06 Expires: Friday, 31-May-2002 17:54:06 GMT
  C05 <-- S06 Vary: Accept-Encoding
  C05 <-- S06 Content-Type: text/html; charset=iso-8859-1
  C05 <-- S06 Content-Encoding: gzip
  C05 <-- S06 == Incoming Body was 8515 bytes ==
  == Transmission: text gzip chunked ==
  == Chunk Log ==
  a (hex) = 10 (dec)
  119f (hex) = 4511 (dec)
  3cb (hex) = 971 (dec)
  472 (hex) = 1138 (dec)
  736 (hex) = 1846 (dec)
  0 (hex) = 0 (dec)
  == Latency = 0.280 seconds, Extra Delay = 0.820 seconds
  == Restored Body was 128192 bytes ==

Default values for the C<minChunkSizeSource> and C<minChunkSize> will be in effect in this case.
In order to overwrite them one can try for example

        <IfModule mod_perl.c>
                PerlModule Apache::Dynagzip
		<Files ~ "*\.html">
                        SetHandler perl-script
                        PerlHandler Apache::Dynagzip
			PerlSetVar minChunkSizeSource 36000
			PerlSetVar minChunkSize 9
		</Files>
	</IfModule>

=head2 Compress the output stream of the Perl scripts

 ===============================================================================
 GET dynamically generated (by perl script) html file with no light compression:
 ===============================================================================
 httpd.conf:

 PerlModule Apache::Filter
 PerlModule Apache::Dynagzip
 <Directory /var/www/perl/>
      SetHandler perl-script
      PerlHandler Apache::RegistryFilter Apache::Dynagzip
      PerlSetVar Filter On
      PerlSendHeader Off
      PerlSetupEnv On
      AllowOverride None
      Options ExecCGI FollowSymLinks
      Order allow,deny
      Allow from all
 </Directory>

 client-side log:

  C05 --> S06 GET /perl/start_example.cgi HTTP/1.1
  C05 --> S06 Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/msword, */*
  C05 --> S06 Accept-Language: en-us
  C05 --> S06 Accept-Encoding: gzip, deflate
  C05 --> S06 User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)
  C05 --> S06 Host: devl4.outlook.net
  C05 --> S06 Accept-Charset: ISO-8859-1
  == Body was 0 bytes ==

  C05 <-- S06 HTTP/1.1 200 OK
  C05 <-- S06 Date: Sat, 01 Jun 2002 16:59:47 GMT
  C05 <-- S06 Server: Apache/1.3.22 (Unix) Debian GNU/Linux mod_perl/1.26
  C05 <-- S06 X-Module-Sender: Apache::Dynagzip
  C05 <-- S06 Transfer-Encoding: chunked
  C05 <-- S06 Expires: Saturday, 01-June-2002 17:04:47 GMT
  C05 <-- S06 Vary: Accept-Encoding
  C05 <-- S06 Content-Type: text/html; charset=iso-8859-1
  C05 <-- S06 Content-Encoding: gzip
  C05 <-- S06 == Incoming Body was 758 bytes ==
  == Transmission: text gzip chunked ==
  == Chunk Log ==
  a (hex) = 10 (dec)
  2db (hex) = 731 (dec)
  0 (hex) = 0 (dec)
  == Latency = 0.220 seconds, Extra Delay = 0.050 seconds
  == Restored Body was 1434 bytes ==

 ============================================================================
 GET dynamically generated (by perl script) html file with light compression:
 ============================================================================
 httpd.conf:

  PerlModule Apache::Filter
  PerlModule Apache::Dynagzip
 <Directory /var/www/perl/>
        SetHandler perl-script
	PerlHandler Apache::RegistryFilter Apache::Dynagzip
	PerlSetVar Filter On
	PerlSetVar LightCompression On
	PerlSendHeader Off
	PerlSetupEnv On
	AllowOverride None
	Options ExecCGI FollowSymLinks
	Order allow,deny
        Allow from all
 </Directory>

 client-side log:

  C05 --> S06 GET /perl/start_example.cgi HTTP/1.1
  C05 --> S06 Accept: */*
  C05 --> S06 Accept-Language: en-us
  C05 --> S06 Accept-Encoding: gzip, deflate
  C05 --> S06 User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)
  C05 --> S06 Host: devl4.outlook.net
  C05 --> S06 Pragma: no-cache
  C05 --> S06 Accept-Charset: ISO-8859-1
  == Body was 0 bytes ==

  C05 <-- S06 HTTP/1.1 200 OK
  C05 <-- S06 Date: Sat, 01 Jun 2002 17:09:13 GMT
  C05 <-- S06 Server: Apache/1.3.22 (Unix) Debian GNU/Linux mod_perl/1.26
  C05 <-- S06 X-Module-Sender: Apache::Dynagzip
  C05 <-- S06 Transfer-Encoding: chunked
  C05 <-- S06 Expires: Saturday, 01-June-2002 17:14:14 GMT
  C05 <-- S06 Vary: Accept-Encoding
  C05 <-- S06 Content-Type: text/html; charset=iso-8859-1
  C05 <-- S06 Content-Encoding: gzip
  C05 <-- S06 == Incoming Body was 750 bytes ==
  == Transmission: text gzip chunked ==
  == Chunk Log ==
  a (hex) = 10 (dec)
  2d3 (hex) = 723 (dec)
  0 (hex) = 0 (dec)
  == Latency = 0.280 seconds, Extra Delay = 0.000 seconds
  == Restored Body was 1416 bytes ==

=head2 Compress the outgoing stream from the CGI binary

 ====================================================================================
 GET dynamically generated (by C-written binary) html file with no light compression:
 ====================================================================================
 httpd.conf:

 PerlModule Apache::Dynagzip
 <Directory /var/www/cgi-bin/>
     SetHandler perl-script
     PerlHandler Apache::Dynagzip
     AllowOverride None
     Options +ExecCGI
     PerlSetupEnv On
     PerlSetVar BinaryCGI On
     Order allow,deny
     Allow from all
 </Directory>

 client-side log:

  C05 --> S06 GET /cgi-bin/mylook.cgi HTTP/1.1
  C05 --> S06 Accept: */*
  C05 --> S06 Accept-Language: en-us
  C05 --> S06 Accept-Encoding: gzip, deflate
  C05 --> S06 User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)
  C05 --> S06 Host: devl4.outlook.net
  C05 --> S06 Pragma: no-cache
  C05 --> S06 Accept-Charset: ISO-8859-1
  == Body was 0 bytes ==

  C05 <-- S06 HTTP/1.1 200 OK
  C05 <-- S06 Date: Fri, 31 May 2002 23:18:17 GMT
  C05 <-- S06 Server: Apache/1.3.22 (Unix) Debian GNU/Linux mod_perl/1.26
  C05 <-- S06 X-Module-Sender: Apache::Dynagzip
  C05 <-- S06 Transfer-Encoding: chunked
  C05 <-- S06 Expires: Friday, 31-May-2002 23:23:17 GMT
  C05 <-- S06 Vary: Accept-Encoding
  C05 <-- S06 Content-Type: text/html; charset=iso-8859-1
  C05 <-- S06 Content-Encoding: gzip
  C05 <-- S06 == Incoming Body was 1002 bytes ==
  == Transmission: text gzip chunked ==
  == Chunk Log ==
  a (hex) = 10 (dec)
  3cf (hex) = 975 (dec)
  0 (hex) = 0 (dec)
  == Latency = 0.110 seconds, Extra Delay = 0.110 seconds
  == Restored Body was 1954 bytes ==

 =================================================================================
 GET dynamically generated (by C-written binary) html file with light compression:
 =================================================================================
  httpd.conf:

   PerlModule Apache::Dynagzip
   <Directory /var/www/cgi-bin/>
       SetHandler perl-script
       PerlHandler Apache::Dynagzip
       AllowOverride None
       Options +ExecCGI
       PerlSetupEnv On
       PerlSetVar BinaryCGI On
       PerlSetVar LightCompression On
       Order allow,deny
       Allow from all
   </Directory>

 client-side log:

  C05 --> S06 GET /cgi-bin/mylook.cgi HTTP/1.1
  C05 --> S06 Accept: */*
  C05 --> S06 Accept-Language: en-us
  C05 --> S06 Accept-Encoding: gzip, deflate
  C05 --> S06 User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)
  C05 --> S06 Host: devl4.outlook.net
  C05 --> S06 Pragma: no-cache
  C05 --> S06 Accept-Charset: ISO-8859-1
  == Body was 0 bytes ==

  C05 <-- S06 HTTP/1.1 200 OK
  C05 <-- S06 Date: Fri, 31 May 2002 23:37:45 GMT
  C05 <-- S06 Server: Apache/1.3.22 (Unix) Debian GNU/Linux mod_perl/1.26
  C05 <-- S06 X-Module-Sender: Apache::Dynagzip
  C05 <-- S06 Transfer-Encoding: chunked
  C05 <-- S06 Expires: Friday, 31-May-2002 23:42:45 GMT
  C05 <-- S06 Vary: Accept-Encoding
  C05 <-- S06 Content-Type: text/html; charset=iso-8859-1
  C05 <-- S06 Content-Encoding: gzip
  C05 <-- S06 == Incoming Body was 994 bytes ==
  == Transmission: text gzip chunked ==
  == Chunk Log ==
  a (hex) = 10 (dec)
  3c7 (hex) = 967 (dec)
  0 (hex) = 0 (dec)
  == Latency = 0.170 seconds, Extra Delay = 0.110 seconds
  == Restored Body was 1862 bytes ==

=head1 INTRODUCTION

From a historical point of view this package was developed primarily in order to compress the output
of a proprietary CGI binary written in C that was
widely used by Outlook Technologies, Inc. in order to deliver uncompressed dynamically generated
HTML content over the Internet using C<HTTP/1.0> since the mid-'90s.
We were then presented with the challenge of using the content compression
features over C<HTTP/1.1> on busy production servers, especially those serving heavy traffic on virtual hosts
of popular American broadcasting companies.

The very first our attempts to implement a static gzip approach in order to compress the
dynamic content helped us to scale effectively the bandwidth at
the cost of significantly increased latency of the content delivery.

That was why I came up with an idea to use chunked data transmission of
the gzipped content, sharing a real time between the server side data
creation/compression, media data transmission, and the client side data
decompression/presentation in order to provide end users with the partially
displayed content as soon as it's possible in particular conditions of the
user's connection.

At the time we decided to go for dynamic compression there were no
appropriate software on the market. Even later in
February 2002 Nicholas Oxhøj wrote to the mod_perl mailing list about his
experience of finding Apache gzipper for the streaming outgoing content:

=for html
<blockquote>

I<"... I have been experimenting with all the different Apache compression modules
I have been able to find, but have not been able to get the desired result.
I have tried Apache::GzipChain, Apache::Compress, mod_gzip and mod_deflate, with
different results.  One I cannot get to work at all. Most work, but seem to collect
all the output before compressing it and sending it to the browser...>

I<... Wouldn't it be nice to have some option to specify that the handler should flush
and send the currently compressed output every time it had received a certain amount
of input or every time it had generated a certain amount of output?..>

I<... So I am basically looking for anyone who has had any success in achieving this
kind of "streaming" compression, who could direct me at an appropriate Apache module.">

=for html
</blockquote>

Unfortunately for him, C<Apache::Dynagzip> has not yet been publicly available at that time...

Since relesed this handler is especially useful when one needs to compress the outgoing
web content that is dynamically generated on the fly using templates,
DB data, XML, etc., and when at the time of the request it is impossible
to determine the length of the response.

Content provider can benefit additionally from the fact that handler begins the transmission
of compressed data concurent to further document creation.
On the other hand, the internal buffer inside the
handler prevents Apache from the creation of too short chunks over C<HTTP/1.1>.

In order to simplify the use of this handler on public/open-source sites,
the capability of content compression over HTTP/1.0 was added to this handler since the version 0.06.
This helps to avoid dynamic invocation of other Apache handlers
for the content generation phase.

=head2 Acknowledgments

Thanks to Tom Evans, Valerio Paolini, and Serge Bizyayev for their valuable idea contributions and multiple testing.
Thanks to Igor Sysoev and Henrik Nordstrom those helped me to understand better the HTTP/1.0 compression features.
Thanks to Vlad Jebelev for the patch that helps to survive possible dynamical Apache downgrade
from HTTP/1.1 to HTTP/1.0 (especially serving MSIE requests over SSL).
Thanks to Rob Bloodgood and Damyan Ivanov for the patches those help to eliminate some unnecessary warnings.
Thanks to John Siracusa for the hint that helps to control the content type properly.
Thanks to Richard Chen for the bug report concerning some uncompressed responses.

Obviously, I hold a full responsibility for how all those contributions are implemented.

=head1 DESCRIPTION

The main pupose of this package is to serve the C<content generation phase> within the mod_perl enabled
C<Apache 1.3.X>, providing dynamic on the fly compression of outgoing web content.
This is done through the use of C<zlib> library via the C<Compress::Zlib> perl interface
to serve both C<HTTP/1.0> and C<HTTP/1.1> requests from clients/browsers,
capable to understand C<gzip> format and decompress it on the fly.
This handler does never C<gzip> content for clients/browsers
those do not declare the ability to decompress C<gzip> format.

In fact, this handler mainly serves as a kind of
customizable filter of outbound web content for C<Apache 1.3.X>.

This handler is supposed to be used within C<Apache::Filter> chain mostly in order to serve the
outgoing content that is dynamically generated on the fly by Perl and/or Java.
It is featured to serve the regular CGI binaries (C-written for examle)
as a standalong handler out of C<Apache::Filter> chain.
As an extra option, this handler can be used to compress dynamically the huge static
files, and to transfer gzipped content in the form of a stream back to the
client browser. For the last purpose C<Apache::Dynagzip> handler should be configured as
a standalong handler out of C<Apache::Filter> chain too.

Working over C<HTTP/1.0> this handler indicates the end of data stream by closing connection.
Indeed, over C<HTTP/1.1> the outgoing data is compressed within a chunked outgoing stream,
keeping the connection alive. Resonable control over the chunk-size is provided in this case.

In order to serve better the older web clients,
an C<extra light> compression is provided independently in order to remove
unnecessary leading blank spaces and/or blank lines
from the outgoing web content. This C<extra light> compression could be combined with
the main C<gzip> compression, when necessary.

The list of features of this handler includes:

=over 4

=item ·
Support for both HTTP/1.0 and HTTP/1.1 requests.

=item ·
Reasonable control over the size of content chunks for HTTP/1.1.

=item ·
Support for Perl, Java, or C/C++ CGI applications in order to provide dynamic on-the-fly compression of outbound content.

=item ·
Optional C<extra light> compression for all browsers, including older ones that incapable to decompress gzipped content.

=item ·
Optional control over the duration of the content's life in client/proxy local cache.

=item ·
Limited control over the proxy caching.

=item ·
Optional support for server-side caching of dynamically generated content.

=back

=head2 Compression Features

C<Apache::Dynagzip> provides content compression for both C<HTTP/1.0> and C<HTTP/1.1>
in accordance with the type of the initial request.

There are two types of compression, which could be applied to outgoing content by this handler:

  - extra light compression
  - gzip compression

These compressions could be applied independently, or in combination.

An C<extra light> compression is provided in order to remove leading blank spaces and/or blank lines
from the outgoing web content. It is supposed to serve the ASCII data types like C<html>,
C<JavaScript>, C<css>, etc. The implementation of C<extra light> compression is turned off
by default. It could be turned on with the statement

  PerlSetVar LightCompression On

in C<httpd.conf>. The value "On" is case-insensitive.
Any other value turns the C<extra light> compression off.

The main C<gzip> format is described in rfc1952.
This type of compression is applied when the client is recognized as one capable
to decompress C<gzip> format on the fly. In this version the decision is under the control
of whether the client sends the C<Accept-Encoding: gzip> HTTP header within the request, or not.

On C<HTTP/1.1>, when the C<gzip> compression is in effect, handler keeps the resonable control
over the size of the chunks and over the compression ratio
using the combination of two internal variables (those could be set in C<httpd.conf>):

  minChunkSizeSource
  minChunkSize

C<minChunkSizeSource> defines the minimum length of the source stream that C<zlib> may
accumulate in its internal buffer.

=over 4

=item Note:

The compression ratio depends on the length of the data
accumulated in that buffer;
More data we keep -- better ratio will be achieved...

=back

When the length defined by the C<minChunkSizeSource> is exceeded, the handler flushes the
internal buffer of C<zlib> and transfers the accumulated portion of the compressed data
into the own internal buffer in order to create a chunk when appropriate.

This buffer is not necessarily be fransfered to Appache immediately. The decision is
under the control of the C<minChunkSize> internal variable. When the size of the buffer
exceeds the value of C<minChunkSize> the handler chunks the internal buffer
and transfers the accumulated data to the Client.

This approach helps to create the effective compression combined with the limited latency.

For example, when I use

  PerlSetVar minChunkSizeSource 16000
  PerlSetVar minChunkSize 8

in my C<httpd.conf> in order to compress the dynamically generated content of the size of some
54,000 bytes, the client side log

  C05 --> S06 GET /pipe/pp-pipe.pl/big.html?try=chunkOneMoreTime HTTP/1.1
  C05 --> S06 Accept: */*
  C05 --> S06 Accept-Language: en-us
  C05 --> S06 Accept-Encoding: gzip, deflate
  C05 --> S06 User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)
  C05 --> S06 Host: devl4.outlook.net
  C05 --> S06 Accept-Charset: ISO-8859-1
  == Body was 0 bytes ==
  
  ## Sockets 6 of 4,5,6 need checking ##
  C05 <-- S06 HTTP/1.1 200 OK
  C05 <-- S06 Date: Thu, 21 Feb 2002 20:01:47 GMT
  C05 <-- S06 Server: Apache/1.3.22 (Unix) Debian GNU/Linux mod_perl/1.26
  C05 <-- S06 Transfer-Encoding: chunked
  C05 <-- S06 Vary: Accept-Encoding
  C05 <-- S06 Content-Type: text/html; charset=iso-8859-1
  C05 <-- S06 Content-Encoding: gzip
  C05 <-- S06 == Incoming Body was 6034 bytes ==
  == Transmission: text gzip chunked ==
  == Chunk Log ==
  a (hex) = 10 (dec)
  949 (hex) = 2377 (dec)
  5e6 (hex) = 1510 (dec)
  5c5 (hex) = 1477 (dec)
  26e (hex) = 622 (dec)
  0 (hex) = 0 (dec)
  == Latency = 0.990 seconds, Extra Delay = 0.110 seconds
  == Restored Body was 54655 bytes ==

shows that the first chunk consists of the gzip header only (10 bytes).
This chunk was sent back to web client as soon as the handler received the first portion of the data
generated by the CGI script. The data itself at that moment has been
storied in the zlib's internal buffer, because the C<minChunkSizeSource> is big enough.

=over 4

=item Note:

Longer we allow zlib to keep its internal buffer -- better compression ratio it makes for us...

=back

So far, in this example we have obtained the compression ratio at about 9 times.

In this version the handler provides defaults:

  minChunkSizeSource = 32768
  minChunkSize = 8

In case of C<gzip> compressed response to C<HTTP/1.0> request, handler uses C<minChunkSize>
and C<minChunkSizeSource> values in order to
limit the minimum size of internal buffers
providing appropriate compression ratio and avoiding multiple short outputs to the core Apache.

=head2 Chunking Features

On C<HTTP/1.1> this handler overwrites the default Apache behavior, and keeps own control over the
chunk-size when it is possible. In fact, handler provides the soft control over the chunk-size only:
It does never cut the incoming string in order to create a chunk of a particular size.
Instead, it controls the minimum size of the chunk only.
I consider this approach reasonable, because to date the HTTP chunk-size is not coordinated with the
packet-size on transport level.

In case of gzipped output the minimum size of the chunk is under the control of internal variable

  minChunkSize

In case of uncompressed output, or the C<extra light> compression only,
the minimum size of the chunk is under the control of internal variable

  minChunkSizePP

In this version handler provides defaults:

  minChunkSize = 8
  minChunkSizePP = 8192

You may overwrite the default values of these variables in your C<httpd.conf> if necessary.

=over 4

=item Note:

The internal variable C<minChunkSize> should be treated carefully
together with the C<minChunkSizeSource> (see Compression Features).

In this version handler does not keep control over the chunk-size
when it serves the internally redirected request.
An appropriate warning is placed to C<error_log> in this case.

=back

=head2 Filter Chain Features

As a member of C<Apache::Filter> chain, C<Apache::Dynagzip> handler is
supposed to be the last executable filter in the chain due to the features of it's
functions.

=head2 CGI Compatibility

When serving CGI binary this version of the handler is CGI/1.1 compatible.
It accepts CGI headers from the binary and produces a set of required HTTP headers
followed by gzipped content.

=head2 POST Request Features

I have to serve the POST requests for CGI binary with special care,
because in this case the handler
is standing along and have to serve all data flow in both directions
at the time when C<stdin> is tied into
Apache, and could not be exposed to CGI binary transparently.

To solve the problem I alter POST with GET request internally
doing the required incoming data transformations on the fly.

This could cause a problem, when you have a huge incoming stream from your client (more than 4K bytes).
Another problem could appear if your CGI binary is capable to distinguish POST and GET requests internally.

=head2 Control over the Client Cache

The control over the lifetime of the response in client's cache is provided
through implementation of C<Expires> HTTP header:

The Expires entity-header field gives the date/time after which the response should be considered stale.
A stale cache entry may not normally be returned by a cache (either a proxy cache or an user agent cache)
unless it is first validated with the origin server (or with an intermediate cache that has a fresh copy
of the entity). The format is an absolute date and time as defined by HTTP-date in section 3.3;
it MUST be in rfc1123-date format:

C<Expires = "Expires" ":" HTTP-date>

This handler creates the C<Expires> HTTP header, adding the C<pageLifeTime> to the date-time
of the request. The internal variable C<pageLifeTime> has default value

  pageLifeTime = 300 # sec.

that could be overwriten in C<httpd.conf> for example as:

  PerlSetVar pageLifeTime 1800

to make the C<pageLifeTime = 30 minutes>.

During the lifetime the client (browser) will
not even try to access the server when user requests the same URL again.
Instead, it restarts the page from the local cache.

It's important to point out here, that all initial JavaScripts will be restarted indeed,
so you can rotate your advertisements and dynamic content when needed.

The second important point should be mentioned here: when user clicks the "Refresh" button, the
browser will reload the page from the server unconditionally. This is right behavior,
because it is exactly what the human user expects from "Refresh" button.

=over 4

=item Notes:

The lifetime defined by C<Expires> depends on accuracy of time settings on client machine.
If the client's local clock is running 1 hour back, the cached copy of
the page will be alive 60 minutes longer on that machine.

C<Apache::Dynagzip> never overwrites C<Expires> header set by earlier handler inside the filter-chain.

=back

=head2 Support for the Server-Side Cache

In order to support the Server-Side Cache
I place a reference to the dynamically generated document to the C<notes()>
when the Server-Side Cache Support is ordered.
The referenced document could be already compressed with
an C<extra light> compression (if an C<extra light> compression is in effect for the current request).

In this case the regular dynamic C<gzip> compression takes place as usual
and the effective C<gzip> compression is supposed to take place within the C<log> stage
of the request processing flow.

You usually should not care about this feature of C<Apache::Dynagzip>
unless you use it in your own chain of handlers for the various phases of the request processing.

=head2 Control over the Proxy Cache.

Control over the (possible) proxy cache is provided through the implementation of C<Vary>
HTTP header.
Within C<Apache::Dynagzip> this header is under the control of few simple rules:

=over 4

=item *

C<Apache::Dynagzip> does never generate this header unless C<gzip> compression is provided.

=item *

The value of C<Accept-Encoding> is always provided for this header, accompanying C<gzip> compression.

=item *

Advanced control over the proxy cache is provided since the version 0.07
with optional extension of Vary HTTP header.
This extension could be placed into your configuration file, using directive

C<PerlSetVar Vary E<lt>valueE<gt>>

Particularly, it might be helpful to indicate the content, which depends on some conditions,
other than just compression features.
For example, when the content is personalized, someone might wish to use
the "*" C<Vary> extension in order to prevent any proxy caching.

When the outgoing content is gzipped, this extension will be appended to the regular C<Vary> header,
like in the following example:

Using the following fragment within the C<httpd.conf>:

  PerlModule Apache::Dynagzip
  <Files ~ "*\.html">
    SetHandler perl-script
    PerlHandler Apache::Dynagzip
    PerlSetVar LightCompression On
    PerlSetVar Vary *
  </Files>

We can observe the client-side log in the form of:

  C05 --> S06 GET /devdoc/Dynagzip/Dynagzip.html HTTP/1.1
  C05 --> S06 Accept: */*
  C05 --> S06 Referer: http://devl4.outlook.net/devdoc/Dynagzip/
  C05 --> S06 Accept-Language: en-us
  C05 --> S06 Accept-Encoding: gzip, deflate
  C05 --> S06 User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)
  C05 --> S06 Host: devl4.outlook.net
  C05 --> S06 Pragma: no-cache
  C05 --> S06 Accept-Charset: ISO-8859-1
  == Body was 0 bytes ==
  
  C05 <-- S06 HTTP/1.1 200 OK
  C05 <-- S06 Date: Sun, 11 Aug 2002 21:28:43 GMT
  C05 <-- S06 Server: Apache/1.3.22 (Unix) Debian GNU/Linux mod_perl/1.26
  C05 <-- S06 X-Module-Sender: Apache::Dynagzip
  C05 <-- S06 Expires: Sunday, 11-August-2002 21:33:43 GMT
  C05 <-- S06 Vary: Accept-Encoding,*
  C05 <-- S06 Transfer-Encoding: chunked
  C05 <-- S06 Content-Type: text/html; charset=iso-8859-1
  C05 <-- S06 Content-Encoding: gzip
  C05 <-- S06 == Incoming Body was 11311 bytes ==
  == Transmission: text gzip chunked ==
  == Chunk Log ==
  a (hex) = 10 (dec)
  1c78 (hex) = 7288 (dec)
  f94 (hex) = 3988 (dec)
  0 (hex) = 0 (dec)
  == Latency = 0.160 seconds, Extra Delay = 0.170 seconds
  == Restored Body was 47510 bytes ==

=item *

Simple form

C<Vary: Accept-Encoding>

is provided as a default for the gzipped content.

=back

=head1 CUSTOMIZATION

C<Apache::Dynagzip> can be used in order

=over 4

=item *

to compress dynamic web content generated in C<Apache::Filter> chain;

=item *

to compress the output of CGI-compatible binary program;

=item *

to stream huge static files providing on the fly compression of the stream.

=back

These are the main regims, wich one can implement through the appropriate configuration of the handler.
Every main regim can be tuned with some specific settings and
can be accomplished with various control features.
All these specific settings and control features could be addressed through
additional configuration parameters unless provided defaults are sufficient.

=over 4

=item Note:

Do your best in order to avoid the implementation of this handler in internally redirected requests.
It does not help much in this case. Read your C<error_log> carefully in order to find appropriate
warnings. Tune your C<httpd.conf> carefully in order to take the most from opportunities offered
by this handler.

Always use accomplishing C<Apache::CompressClientFixup> handler in order to avoid C<gzip> compression
for known buggy web clients.

=back

=head2 Apache::Filter Chain

If your application is initially configured something like

  PerlModule HTML::Mason::ApacheHandler
  <Directory /path/to/subdirectory>
    <FilesMatch "\.html$">
      SetHandler perl-script
      PerlHandler HTML::Mason::ApacheHandler
    </FilesMatch>
  </Directory>

you might want just to replace it with the following:

  PerlModule HTML::Mason::ApacheHandler
  PerlModule Apache::Dynagzip
  PerlModule Apache::CompressClientFixup
  <Directory /path/to/subdirectory>
    <FilesMatch "\.html$">
      SetHandler perl-script
      PerlHandler HTML::Mason::ApacheHandler Apache::Dynagzip
      PerlSetVar Filter On
      PerlFixupHandler Apache::CompressClientFixup
      PerlSetVar LightCompression On
    </FilesMatch>
  </Directory>

in order to provide C<gzip> compression of your content. You should be all set safely after that.

In more common cases you need to replace the line

    PerlHandler HTML::Mason::ApacheHandler

in your initial configuration file with the set of the following lines:

    PerlHandler HTML::Mason::ApacheHandler Apache::Dynagzip
    PerlSetVar Filter On
    PerlFixupHandler Apache::CompressClientFixup

You might want to add optionally

    PerlSetVar LightCompression On

to reduce the size of the stream even for clients incapable to speak C<gzip>
(like I<Microsoft Internet Explorer> over HTTP/1.0).

Finally, make sure you have somewhere declared

  PerlModule Apache::Dynagzip
  PerlModule Apache::CompressClientFixup

Outgoing C<Content-Type> will be set to default C<text/html> unless you have another value
defined by core Apache or generated by another perl handler included in the chain.

In order to control the compression ratio and the minimum size of the chunk/buffer for gzipped content
you can optionally use directives

    PerlSetVar minChunkSizeSource <value>
    PerlSetVar minChunkSize <value>

for example you can try

    PerlSetVar minChunkSizeSource 32768
    PerlSetVar minChunkSize 8

which are the defaults in this version.

=over 4

=item Note:

You can improve the compression ratio when you increase the value of C<minChunkSizeSource>.

=back

In order to control the minimum size of the chunk for uncompressed content over HTTP/1.1
you can optionally use the directive

    PerlSetVar minChunkSizePP <value>

Default value is 8192 bytes in this version.

In order to control the C<pageLifeTime> in client's local cache you can optionally use the directive

    PerlSetVar pageLifeTime <value>

where the value stands for the life-length in seconds.

    PerlSetVar pageLifeTime 300

is default in this version.
C<Apache::Dynagzip> does not overwrite any existent C<Expires> HTTP header, whether one is set
by core Apache, or by the previous perl handler.

You might wish to place

    PerlSetVar Vary User-Agent

in your C<httpd.conf> file in order to notify possible proxies that you distinguish browsers in your content.
Alternatively, you might want to place

    PerlSetVar Vary *

in order to prevent all proxies from caching your content.

you may use C<Apache::Filter> chain to serve another sources, when you know what you are doing.
You might wish to write your own handler and include it into C<Apache::Filter> chain,
preprocessing the outgoing stream if necessary.

In order to use your own handler (that might be generating its own HTTP headers)
inside the Apache::Filter chain, make sure to register your handler with the Apache::Filter chain like

  $r->filter_register();

when necessary. See Apache::Filter documentation for details.

=head2 CGI-Compatible Binary

Use the directives like

  PerlModule Apache::Dynagzip
  PerlModule Apache::CompressClientFixup
  <Directory /path/to/subdirectory>
      SetHandler perl-script
      PerlHandler Apache::Dynagzip
      PerlSetVar BinaryCGI On
      Options +ExecCGI
      PerlFixupHandler Apache::CompressClientFixup
      PerlSetVar LightCompression On
  </Directory>

in order to indicate that the source-generator is supposed to be a CGI binary.
Don't use C<Apache::Filter> chain in this case.
Support for CGI/1.1 headers defaults to "On" for this type of source generators.

Outgoing C<Content-Type> will be set to default C<text/html> unless you have another value
defined by core Apache for this binary, or binary itself generates appropriate CGI header.

When your source is a very old CGI-application that fails to provide correct C<Content-Type> CGI header, use

    PerlSetVar UseCGIHeadersFromScript Off

in your C<httpd.conf> in order to overwrite the document's Content-Type to C<text/html>.
All other CGI headers generated by the binary will be disregarded in this case too.

Make sure that your POST requests do never exceed 4K bytes in body length.
Longer POST body is not supported in this version of C<Apache::Dynagzip>.

In order to control the compression ratio and the minimum size of the chunk/buffer for gzipped content
you can optionally use directives

    PerlSetVar minChunkSizeSource <value>
    PerlSetVar minChunkSize <value>

For example you can try

    PerlSetVar minChunkSizeSource 32768
    PerlSetVar minChunkSize 8

which are the defaults in this version.

=over 4

=item Note:

You can improve the compression ratio when you increase the value of C<minChunkSizeSource>.

=back

In order to control the minimum size of the chunk for uncompressed content over HTTP/1.1
you can optionally use the directive

    PerlSetVar minChunkSizePP <value>

Default value is 8192 bytes in this version.

In order to control the C<extra light> compression you can optionally use the directive

    PerlSetVar LightCompression <On/Off>

In order to turn "On" the C<extra light> compression, use the directive

    PerlSetVar LightCompression On

Any other value turns the C<extra light> compression "Off" (default).

In order to control the C<pageLifeTime> in client's local cache you can optionally use the directive

    PerlSetVar pageLifeTime <value>

where the value stands for the life-length in seconds.

    PerlSetVar pageLifeTime 300

is default in this version.

You might wish to place

    PerlSetVar Vary User-Agent

in your C<httpd.conf> file in order to notify possible proxies that you distinguish browsers in your content.
Alternatively, you might place

    PerlSetVar Vary *

in order to prevent all proxies from caching your content.


=head2 Stream Compression of Static File

It will be assumed the plain file transfer, when you use the standing-along handler with
no BinaryCGI directive:

  PerlModule Apache::Dynagzip
  PerlModule Apache::CompressClientFixup
  <Directory /path/to/subdirectory>
      SetHandler perl-script
      PerlHandler Apache::Dynagzip
      PerlFixupHandler Apache::CompressClientFixup
      PerlSetVar LightCompression On
  </Directory>

The C<Content-Type> is determined by Apache in this case.

In order to control the compression ratio and the minimum size of the chunk/buffer for gzipped content
you can optionally use directives

    PerlSetVar minChunkSizeSource <value>
    PerlSetVar minChunkSize <value>

For example you can try

    PerlSetVar minChunkSizeSource 32768
    PerlSetVar minChunkSize 8

which are the defaults in this version.

=over 4

=item Note:

You can improve the compression ratio when you increase the value of C<minChunkSizeSource>.

=back

In order to control the minimum size of the chunk for uncompressed content over HTTP/1.1
you can optionally use the directive

    PerlSetVar minChunkSizePP <value>

In order to control the C<extra light> compression you can optionally use the directive

    PerlSetVar LightCompression <On/Off>

In order to turn "On" the C<extra light> compression, use the directive

    PerlSetVar LightCompression On

Any other value turns the C<extra light> compression "Off" (default).

In order to control the C<pageLifeTime> in client's local cache you can optionally use the directive

    PerlSetVar pageLifeTime <value>

where the value stands for the life-length in seconds.

    PerlSetVar pageLifeTime 300

is default in this version.

You might wish to place

    PerlSetVar Vary *

in order to prevent all proxies from caching your content.

=head2 Dynamic Setup/Configuration from the Perl Code

Alternatively, one can control this handler from the own perl-written handler
serving the earlier phase of the request processing flow.
For example, I'm using dynamic installation of C<Apache::Dynagzip>
from my C<PerlTransHandler> in order to serve the server-side content cache appropriately.

  use Apache::RegistryFilter;
  use Apache::Dynagzip;

  . . .

  $r->handler("perl-script");
  $r->push_handlers(PerlHandler => \&Apache::RegistryFilter::handler);
  $r->push_handlers(PerlHandler => \&Apache::Dynagzip::handler);

In your perl code you can even extend the main C<config> settings (for the current request) with:

  $r->dir_config->set(minChunkSizeSource => 36000);
  $r->dir_config->set(minChunkSize => 6);

for example...

=head1 TROUBLESHOOTING

This handler fails to keep control over the chunk-size when it serves the internally redirected request.
At the same time it fails to provide C<gzip> compression.
A corresponding warning is placed to C<error_log> in this case.
Make the appropriate configuration tunings in order to avoid the implementation of this handler
for internally redirected request(s).

The handler logs C<error>, C<warn>, C<info>, and C<debug> messages to the Apache C<error_log> file.
Please, read it first in case of any trouble.

=head1 DEPENDENCIES

This module requires these other modules and libraries:

   Apache::Constants;
   Apache::File;
   Apache::Filter 1.019;
   Apache::Log;
   Apache::URI;
   Apache::Util;
   Fcntl;
   FileHandle;

   Compress::LeadingBlankSpaces;
   Compress::Zlib 1.16;
       
  Note 1: the Compress::Zlib 1.16 requires the Info-zip zlib 1.0.2 or better
        (it is NOT compatible with versions of zlib <= 1.0.1).
        The zlib compression library is available at http://www.gzip.org/zlib/
	
  note 2: it is recommended to have a mod_perl compiled with the EVERYTHING=1
        switch. However, Apache::Dynagzip uses just fiew phases of the request
        processing flow:
              Content generation phase
              Logging phase

It is strongly recommended to use C<Apache::CompressClientFixup> handler in order to avoid compression
for known buggy browsers. C<Apache::CompressClientFixup> package can be found on CPAN at
F<http://search.cpan.org/author/SLAVA/>.

=head1 AUTHOR

Slava Bizyayev E<lt>slava@cpan.orgE<gt> - Freelance Software Developer & Consultant.

=head1 COPYRIGHT AND LICENSE

I<Copyright (C) 2002 - 2004, Slava Bizyayev. All rights reserved.>

This package is free software.
You can use it, redistribute it, and/or modify it under the same terms as Perl itself.

The latest version of this module can be found on CPAN.

=head1 SEE ALSO

"Web Content Compression FAQ" at
F<http://perl.apache.org/docs/tutorials/client/compression/compression.html>

C<Compress::LeadingBlankSpaces> module can be found on CPAN.

C<Compress::Zlib> module can be found on CPAN.

The primary site for the C<zlib> compression library is
F<http://www.info-zip.org/pub/infozip/zlib/>.

C<Apache::Filter> module can be found on CPAN.

C<Apache::CompressClientFixup> module can be found on CPAN at
F<http://search.cpan.org/author/SLAVA/>.

C<RFC 1945> Hypertext Transfer Protocol HTTP/1.0.

C<RFC 2616> Hypertext Transfer Protocol HTTP/1.1.

F<http://www.ietf.org/rfc.html> - rfc search by number (+ index list)

F<http://cgi-spec.golux.com/draft-coar-cgi-v11-03-clean.html> CGI/1.1 rfc

F<http://perl.apache.org/docs/general/correct_headers/correct_headers.html>
"Issuing Correct HTTP Headers" by Andreas Koenig

=cut
