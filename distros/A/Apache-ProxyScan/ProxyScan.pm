
package Apache::ProxyScan;

use strict;
use vars qw($VERSION);

use LWP::UserAgent ();
use URI::URL;
use File::MMagic;

use Apache::Const qw(OK DECLINED :log);
use APR::Const qw(:error SUCCESS);
use APR::Table;
use Apache::RequestRec;
use Apache::RequestUtil;
use Apache::RequestIO;
use Apache::Log;
use Apache::Response ();

$VERSION = "0.92";
# create a mime type detector once. 
# You need File::Magic even if you don't use it
my $MIME = File::MMagic::new('/etc/httpd/conf/magic');

sub handler {
  my($r) = @_;
  return DECLINED unless $r->proxyreq;
  return DECLINED if ($r->method eq "CONNECT");

  # If there are Trusted Extensions DECLINE the requests here
  my $filetype = $r->dir_config("ProxyScanTrustedExtension");
  if (defined $filetype) {
    my %extension;
    foreach (split(/\s+/, $filetype)) {
      s/^\.//igs;
      $extension{lc("$_")} = 1;
    }
    my @pc = (URI::URL->new($r->uri))->path_components;
    my $ext = pop @pc;
    if ($ext =~ s/^.*\.([^.]+)/$1/igs) {
      if (defined $extension{lc("$ext")}) {
	$r->log->warn($r, "Trusted File Extension: ".$r->uri);
	return DECLINED;
      }
    }
  }
  $r->handler("perl-script"); #ok, let's do it
  $r->push_handlers(PerlHandler => \&proxy_handler);
  return OK;
}

sub proxy_handler {
  my($r) = @_;
  # get the configuration variables
  my $scanner = $r->dir_config("ProxyScanScanner");
  my $tmpdir = $r->dir_config("ProxyScanTempDir") || '/tmp/';
  my $presendsize = $r->dir_config("ProxyScanPredeliverSize") || 102400;
  my $trustmime = $r->dir_config("ProxyScanTrustedMIME");
  if (defined $trustmime) {
    $trustmime =~ s/\*/.*/igs;
    $trustmime = join('|', split(/\s+/, $trustmime));
  } 

  # create the request
  my $request = new HTTP::Request $r->method, $r->uri;
  
  # copy request headers
  my $table = $r->headers_in;
  foreach my $key (keys %{$table}) {
      $request->header($key,$table->{$key});
  }
  
  # transfer request if it's POST
  # try to handle without content length
  if ($r->method eq 'POST') {
    my $len = $r->headers_in->{'Content-length'};
    if (defined $len) {
      my $buf;
      $r->read($buf, $len);
      $request->content($buf);
    } else {
      $request->content(scalar $r->content);
    }
  }
  
  # do a predeliver
  # if you do predelivering there are several problems with the
  # http protocol. For this reason we do it only for large files.
  # This makes downloading easier, because the save-as window still
  # appears.
  my $callcount = 0;
  my $delivered = 0;
  my $headersent = 0;
  my $trustworthy = 0;
  my $file;
  my $outfile = undef;
  
  my $fetchref = sub {
    my($data, $res, $protocol) = @_;
    if ($callcount == 0) {
      my $mime = $MIME->checktype_contents($data);
      if ((defined $trustmime ) && ($mime =~ m§^($trustmime)$§i)) {
	$trustworthy = 1;
	$r->log->warn($r, "Trusted MIME Type: ".$r->uri);
	prepareheaders(\$r,\$res);
	$r->rflush();
      } else {
	# make a nice filename
	my @chars = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
	$file = substr($r->uri , 0, 200);
	$file =~ s/[^A-Z0-9]+/_/igs;
	$file .= join("", @chars[ map { rand @chars } ( 1 .. 16 ) ] );
	open($outfile, ">$tmpdir/$file");
	my $len =  $res->header('Content-Length');
	if ($len > $presendsize) {
	  $r->log->warn($r,"started predelivery on: ".$r->uri);
	  $res->remove_header('Content-Length');
	  prepareheaders(\$r,\$res);
	  $r->rflush();
	  $headersent=1;
	  print substr $data,0,5; 
	  $delivered += 5;
	  $r->rflush;
	}
      }
    }
    $callcount++;
    if ($trustworthy) {
      print $data;
    } else { 
      print $outfile $data;
    }
    return;
  };
  
  # download request in unique directory
  
  my $res = (LWP::UserAgent->new(parse_head => 0))->simple_request($request,$fetchref,4096);
  if (defined $outfile) {
    close($outfile);
  }
  
  # if an error occurs, res->content contains server error
  # we are paraniod so we scan the server message too
  # DNS Errors are reported by LWP::UA as Code 500 with empty content
  if (!$res->is_success) {
    open(my $fh, ">$tmpdir/$file");
    my $msg = $res->content;
    if (($res->code == 500) && ($msg eq "")) {
      $msg = $res->message;
    }
    print $fh $msg;
    close($fh);
  }
  
  # try to scan file
  if (!$trustworthy) {
    open(my $fh,"$scanner '$tmpdir/$file' |");
    my @msg=<$fh>;
    close($fh);
    my $scanrc = $?;
    
    # feed reponse back into our request_rec*
    if (!$headersent) {
      prepareheaders(\$r,\$res);
    }

    # The following return code combinations from scanner
    #  rc  file
    #   0  exists    clean, return file
    #   0  deleted   not allowed, fixed error Message
    #  !0  exists    scan failed, fixed error Message
    #  !0  deleted   infected, return stdout
    
    if ($scanrc == 0) {
      if (-e "$tmpdir/$file") {
        if (!$headersent) {
          $r->rflush();
        }
        $r->sendfile("$tmpdir/$file", $delivered);
      } else {
        if ($res->is_error) {
          if (!$headersent) {
	    $r->rflush();
          }
	  $r->print($res->error_as_HTML);
        } else {
          my $msg=join("\n", @msg);
          generateError(\$r, "Scanner Error", "Scanning ".$r->uri.":\n$msg");
        }
      }
    } else {
      if (-e "$tmpdir/$file") {
        my $msg=join("\n", @msg);
        generateError(\$r, "Scanner Error", "Scanning ".$r->uri.":\n$msg");
      } else {
        $r->headers_out->set("content-length" => undef);
        $r->send_cgi_header(join('', @msg));
	my $entry = join('', @msg);
	$entry =~ s/<.*?>//igs;
	$r->log_error("Virus Alert: ".$r->uri."\n$entry"); 
      }
    }
    unlink "$tmpdir/$file" if (-e "$tmpdir/$file");
  }
  return OK;
}

sub generateError {
  my $r = shift @_;
  my $title = shift @_;
  my $text = shift @_;   

  $$r->log_error("$title: $text");  

  $text =~ s/[^A-Z0-9_\s\n]/sprintf("&#%d;", ord($&))/eigs;
  $text =~ s/\n/<BR>/igs;
  
  my $msg = "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">\n<html><head>\n<title>$title</title>\n</head><body>\n<h1>$title</h1>\n$text\n</body></html>\n";
  
  $$r->content_type("text/html");
  $$r->headers_out->set("content-length" => length($msg));
  $$r->rflush();
  $$r->print("$msg");
  
  return 1;
}

sub prepareheaders {
  my $r = shift @_;
  my $res = shift @_;
  $$r->content_type($$res->header('Content-type'));
  $$r->status($$res->code);
  $$r->status_line($$res->status_line);
  my $table = $$r->headers_out;
  $$res->scan(sub {
		$table->add(@_) if ($_[0] !~ m/^Client[_-]/i);
	      });
  return 1;
}


1;

__END__

=head1 NAME

Apache::ProxyScan - proxy module to integrate content scanners

=head1 SYNOPSIS

  # httpd.conf 
  # example for clamav
  PerlTransHandler  Apache::ProxyScan
  PerlSetVar        ProxyScanScanner "/usr/local/bin/clamav.pl"
  PerlSetVar        ProxyScanTempDir /var/cache/virus/dl/
  PerlSetVar        ProxyScanPredeliverSize     102400
  PerlSetVar        ProxyScanTrustedExtension   ".html .htm"
  PerlSetVar        ProxyScanTrustedExtension   "image/* text/html"
  PerlSetEnv 	    SCAN_TMP 	   /var/cache/virus/av/

=head1 DESCRIPTION

This module provides the integration of any commandline virus scanning tool
into the proxy chain of apache. It works better than cgi solutions because
this module uses libwww-perl as it's web client, feeding the response
back into the Apache API request_rec structure. For this reason there are
no troubles with authentication nor cookie sites.

`PerlHandler' will only be invoked if the request is a proxy request,
otherwise, your normal server configuration will handle the request.
The normal server configuration will also handle the CONNECT requests if
defined for this.

I tested it with clamav, sophos, rav and mcafee.

=head1 PARAMETERS

This module is configured with PerlSetVar and PerlSetEnv.

=head2 ProxyScanScanner

This is the command executed to scan the downloaded file before delivering.
We use standard executables, normally perl.

The only parameter given to the executable is the temporary filename of the 
file to be tested.

The script must return 0 if the file is clean and tested und the file
must not be deleted. 
If the return code ist not 0 and the file still exists, we assume that the
call of the scanner wrapper failed. The file is not deliverd.
If the return code ist not 0 and the file is deleted, then the Handler
returns the standard output of the wrapper script.

=head2 ProxyScanTempDir

This is the directory where LWP::UserAgent downloads the requested files.
Make sure that it provides enough space for you surf load.

  PerlSetVar        ProxyScanTempDir /var/cache/virus/dl/

Often the scanner itself have another place where to store their temporary
files. Make sure that it provides enough space, too. 

=head2 ProxyScanPredeliverSize

There are usability problem downloading large files, because the files are
download first, then checked and then delivered. This causes problems with 
timeouts and "non-responding" browsers.

If the Content-Length of the response is bigger than ProxyScanPredeliverSize
the header is delivered immediately including 5 bytes of content.
Then the file is downloaded and scanned and delivered if clean.
If there is a virus found, there is a major problem to report this to
the user, because the header including Content-Type is sent yet.
In this case we do not deliver any more bytes but add the standard error
page. The average user would not read this message, but ProxyScan prevented
the download of a infected file.

If not defined a value of 102400 (100 K) is preset.

=head2 ProxyScanTrustedExtension

This is the most dangerous option. You are able to configure file extensions
that are delivered unchecked. File Extensions are not really trustworthy, so
only define Trusted Extensions if you know about the implication.
It is mainly to decrease the load.
The request is handled via the original apache proxy module, so make sure
you activated this.

=head2 ProxyScanTrustedMIME

This is the better solution to prevent av scanning on special files.
This time MimeMagic tests are done an the first 4K of the file. If the
detected MimeType is in TrustedMIME it would be delivered without checking
and in time.

The syntax of the ProxyScanTrustedMIME is

  ProxyScanTrustedMIME "image/* text/html"

This allows every image to pass and every text/HTML file unchecked.

=head2 PerlSetEnv

The scripts starting the scan processes try to set the path for the temporary
files created by the scanner itself.

  PerlSetEnv 	    SCAN_TMP 	   /var/cache/virus/av/

=head1 EXAMPLES

I need more example configuration for other scanner products.
If a file is infected, the scanner should delete it.

In Apache-ProxyScan-X.XX/eg/ are wrapper scripts for several virus scanner.

=head1 TODO

I need tests and examples for the integration of other content scanner 
products, free and non free. (Kaspersky, Trendmicro, AntiVir)

Other things nice-to-have would be real configuration directives, a special
logfile for ProxyScan, a memory for infected files to deliver real error
messages if the user tries a second download and a cleanup of the delivered
http headers.

=head1 SUPPORT

The latest version of this module can be found at CPAN and at
L<http://www.sourcentral.org/Apache-ProxyScan/>. 
Send questions and suggestions directly to the author (see below).

=head1 SEE ALSO

L<mod_perl>, L<Apache>, L<LWP::UserAgent>

=head1 AUTHOR

Oliver Paukstadt <cpan@sourcentral.org>

Based on Apache::ProxyPassThrough from Bjoern Hansen and Doug MacEachern

=head1 COPYRIGHT

Copyright (c) 2002-2003 Oliver Paukstadt. All rights reserved.
This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 FORTUNE

 DA FORCE COMING DOWN WITH MAYHEM  
 LOOKING AT MY WATCH TIME 3.A.M.

