package CGI::WebGzip;
our $VERSION = '0.13';
use strict;

# Compression level.
my $level = 9;
# Compression status (undef if compression is used).
my $status = undef;
# Callback.
my $callback = undef;


##
## Interface.
##

# Import code.
# Usage:
#   use CGI::WebGzip(level);
sub import {
  setLevel($_[1]);
  if (!defined getAbility()) {
    startCapture();
  }
}

# Finish code.
END {
  flush();
}


# void flush()
# Flushes the compressed buffer immediately and releases STDOUT capture.
sub flush {
  #CGI::WebOut::_Debug("Finished %s, %s, %s", __PACKAGE__, $capture->line_pointer, tied(*STDOUT));
  my $data = stopCapture(); return if !defined $data;
  my ($headers, $body) = split /\r?\n\r?\n/, $data, 2;
  
  # Run compression.
  my ($newBody, $newHeaders, $stat);
  if (length($body) == 0) {
    ($newBody, $newHeaders) = ($body, $headers);
  } else {
    ($newBody, $newHeaders, $stat) = ob_gzhandler($body, $headers);
    $status = $stat;
  }

  # Run callback if defined. Callback may set additional cookies
  # printing Set-Cookie header. If callback returns 0, no data
  # is output by this function (presume callback did it itself).
  if ($callback) {
    $callback->($newBody, $newHeaders, $body) or return;
  }
  binmode(STDOUT);
  print $newHeaders;
  print "\r\n\r\n"; 
  print $newBody;
}


# bool getAbility()
# Returns non-false is we are in CGI mode and browser understands compression
# Also loads Compress::Zlib and silently returns false if not found.
# Returns undef if compression ca be used.
sub getAbility {
  if (!$ENV{SCRIPT_NAME}) {
    return "no: not a CGI script";
  }
  my $acc = $ENV{HTTP_ACCEPT_ENCODING}||"";
  if ($acc !~ /\bgzip\b/i) {
    return "no: incompatible browser";
  }
  if (!eval { require Compress::Zlib }) {
    return "no: Compress::Zlib not found";
  }
  return undef;
}


# bool isCompressibleType($type)
# Returns true if MIME type $type is compressible.
sub isCompressibleType {
  my ($type) = @_;
  return $type =~ m{^text/}i;
}


# CODE setCallback(CODE $func)
# Sets the new callback function. Returns previous.
sub setCallback {
  my $prev = $callback;
  $callback = $_[0];
  return $prev;
}


# int setLevel($level)
# Sets compression level. Returns previous.
sub setLevel {
  my $prev = $level;
  $level = defined $_[0]? $_[0] : 9;
  return $prev;
}


# string getStatus()
# Returns status string. If compression is failed, status string is 
# non-empty and contains diagnostic message. Otherwise it is undef.
sub getStatus {
  return $status;
}



##
## Compression abstraction level.
##

# ($compressedBody, $modifiedHeaders, $status) ob_gzhandler(string $body, [string $headers])
# Returns compressed data (additionally analysing headers, if present).
# In scalar context returns $compressedBody only.
# Input headers can be modified, thus this function returns $modifiedHeaders.
# Compression error message is returned in $status (or undef if everything is OK).
# This function can be used exactly as PHP's ob_gzhandler().
sub ob_gzhandler {
  my ($body, $h) = @_;
  $h ||= "";
  my $status = undef;

  # Process all the headers.
  my $ContentEncoding = undef;
  my $ContentType = undef;
  my $Status = undef;
  my @headers = ();
  foreach (split /\r?\n/, $h) {
    if (/^Content[-_]Encoding:\s*(.*)/i) {
      $ContentEncoding = $1;
      next;
    } 
    if (/^Content[-_]Type:\s*(.*)/i) {
      $ContentType = $1;
    }
    if (/^Status:\s*(\d+)/i) {
      $Status = $1;
    }
    push @headers, $_ if $_;
  }
  
  # Determine if we need to compress.
  my $needCompress = 1;
  if (defined $ContentType && !isCompressibleType($ContentType)) {
    $ContentType ||= "undef";
    $status = "no: incompatible Content-type ($ContentType)";
    $needCompress = undef;
  }
  if ($Status && $Status ne 200) {
    $status = "no: Status must be 200 (given $Status)";
    $needCompress = undef;
  }
  if (defined($status=getAbility())) {
    $needCompress = undef;
  }

  # Echo compression header.
  if ($needCompress) {
    $ContentEncoding = "gzip" . ($ContentEncoding? ", $ContentEncoding" : "")
      if !$ContentEncoding || $ContentEncoding !~ /\bgzip\b/i;
    push @headers, "Content-Encoding: $ContentEncoding";
    push @headers, "Vary: Accept-Encoding";
  }

  # Compress output.
  my $headers = join "\r\n", @headers;
  my $out = $needCompress? deflate_gzip($body, $level) : $body;

  return wantarray? ($out, $headers, $status) : $out;
}


# string deflate_gzip($text, $level);
# Compresses the input string and returns result.
sub deflate_gzip {
  my ($d, $st) = Compress::Zlib::deflateInit(-Level => defined $_[1]? $_[1] : 9);
  my ($out, $Status) = $d->deflate($_[0]);
  my ($outF, $StatusF) = $d->flush();
  $out = $out.$outF;

  # Shamanian code - without them nothing works! Hmmm...
  my $pre = pack('CCCCCCCC', 0x1f,0x8b,0x08,0x00,0x00,0x00,0x00,0x00);
  $out = $pre . substr($out, 0, -4) . pack('V', Compress::Zlib::crc32($_[0])) . pack('V', length($_[0]));

  return $out;
}



##
## STDOUT capture abstraction level.
##

# Capture object.
my $capture = undef;

# Starts STDOUT capturing.
sub startCapture {
  # Tie STDOUT only once.
  return if $capture;
  $capture = tie *STDOUT, "CGI::WebGzip::Tie";
}

# Finishes STDOUT capturing.
sub stopCapture {
  return undef if !$capture;
  my $obj = tied *STDOUT;
  my $data = join "", @$obj;
  $obj = $capture = undef;
  untie(*STDOUT);
  return $data;
}

# Package to tie STOUT. Captures all the output.
package CGI::WebGzip::Tie;
sub TIEHANDLE  { return bless [], $_[0] } 
sub PRINT      { 
  my $th = shift; 
  push @$th, map { 
    if (!defined $_) {
      eval { require Carp } and Carp::carp("Use of uninitialized value in print"); 
      ""
    } else {
      $_
    }
  } @_;
}
sub PRINTF     { 
  my $th = shift; 
  push @$th, sprintf map { 
    if (!defined $_) {
      eval { require Carp } and Carp::carp("Use of uninitialized value in printf"); 
      ""
    } else {
      $_
    }
  } @_;
}
sub WRITE      { goto &PRINT; }
sub CLOSE      { CGI::WebGzip::flush() }
sub BINMODE    { }

return 1;
__END__


=head1 NAME

CGI::WebGzip - Perl extension for GZipping script output

=head1 SYNOPSIS

  # Usual code working with STDOUT:
  use CGI::WebGzip;
  print "Content-type: text/html\n\n";
  print "Hello, world!";


  # Lesser compression (by default 9, now - 5)
  use CGI::WebGzip(5);


  # Set callback function which would be called after compressing,
  # but before any output. You may set cookie in this function to
  # display them later on the page (using JavaScript).
  use CGI::WebGzip;
  BEGIN {
      CGI::WebGzip::setCallback(sub {
          my ($nL, $oL) = (length $_[0], length $_[2]);
          print sprintf "Set-Cookie: page_size=%d,%d; path=/\n", $oL, $nL;
          return 1;
      });
  }


  # Working together with CGI::WebOut.
  use CGI::WebGzip;
  use CGI::WebOut;
  print "Hello, world!";


  # Work in FastCGI environment.
  require CGI::WebGzip;
  while (read request) {
     CGI::WebGzip::import;  # captures output
     ...
     CGI::WebGzip::flush(); # releases output
  }


=head1 OVERVIEW

In PHP, you may write: C<ob_start("ob_gzhandler")> and get all the output 
GZip-ed automatically. CGI::WebGzip does the same thing. Is you include this module 
in the beginning of your program, it whill capture all the output. When
the script ends, CGI::WebGzip compresses captured data and send it to browser.

If browser is incompatible with GZip encoding, output will not be captured,
and data will not be compressed.


=head1 DESCRIPTION

=over 9

=item use CGI::WebGzip([compression_level])

Captures all the script output for deflating. Default compression level 
is 9 (maximum). Value 0 means no compression.

=item void flush()

Flushes the compressed buffer immediately and releases STDOUT capture. 
Usable in FastCGI environment together with manual C<import()> call 
(see synopsis above).

=item bool getAbility()

Returns undef if we are in CGI mode, browser supports compression 
and Compress::Zlib is found. Otherwise returns non-empty diagnostic message.

=item bool isCompressibleType($type)

Returns true if page of this MIME type can be compressed.

=item CODE setCallback(CODE $func)

Sets the callback function called AFTER compression process, but BEFORE 
any output. You may print additional headers in this function (for example,
set cookies). If this function returns false, compressed data would not be
printed later (presume function does it itself). Arguments:

  bool callback(string $compressedBody, string $headers, string $originalBody)

Returns previous callback reference.

=item int setLevel($level)

Sets another compression level. Returns previous.

=item string getStatus()

You may determine if the compression was performed by this function. It 
returns undef if data has been compressed or non-empty diagnostic message otherwise.

=item ($compressedBody, $modifiedHeaders, $status) ob_gzhandler(string $body [,string $headers])

Returns compressed data (additionally analysing headers, if present).
In scalar context returns C<$compressedBody> only.
Input headers can be modified, thus this function returns C<$modifiedHeaders>.
In C<$status> compression feruse message is returned (or undef if everything is OK).
This function can be used exactly as PHPs C<ob_gzhandler()>.

=item string deflate_gzip($text, $level);

Compresses the input string and returns result.

=back

=head2 EXPORT

None by default.

=head2 DEPENDENCIES

CGI::WebGzip depends on Compress::Zlib only. If this library is not found, no
error messages are generated.

=head1 AUTHOR

Dmitry Koterov <koterov at cpan dot org>


=head1 SEE ALSO

L<Compress::Zlib>, L<CGI::WebOut> 

=cut
