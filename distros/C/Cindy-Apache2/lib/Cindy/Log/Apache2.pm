# $Id: Apache2.pm 68 2013-01-27 14:52:38Z jo $
# Cindy::Log - Logging for Cindy
#
# Copyright (c) 2008 Joachim Zobel <jz-2008@heute-morgen.de>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#


package Cindy::Log::Apache2;

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT= qw(DEBUG INFO WARN ERROR FATAL); 

use Apache2::RequestUtil ();
use Apache2::Log;
use Apache2::Const -compile => qw(OK DECLINED SERVER_ERROR :log);
use APR::Const    -compile => qw(:error SUCCESS);

use Apache2::ServerUtil ();

sub rlog
{
  my $r = Apache2::RequestUtil->request()
  or die "Please enable PerlOptions +GlobalRequest.";
  return $r;
}

my $error_pnote = 'error-collector';

sub ERROR 
{
  rlog->log_error(@_);
 
  if (rlog->subprocess_env('CINDY_FATALS_TO_BROWSER')) {
    my $r = Apache2::RequestUtil->request();
    $r->custom_response(Apache2::Const::SERVER_ERROR,
                        error_page(@_));
  }
}

sub error_page
{
  my ($msg) = @_;
  $msg =~ s/&/&amp;/g;
  $msg =~ s/</&lt;/g; 
  return qq|<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html>
<head>
  <title>500 Internal Server Error</title>
</head>
<body>
  <h1>Cindy reported an Error</h1>
<pre>
$msg
</pre>  
</body>
</html>
|;
}

sub WARN 
{
  rlog->warn(@_);
}

sub INFO
{
  rlog->log_rerror(Apache2::Log::LOG_MARK(), Apache2::Const::LOG_INFO,
                   APR::Const::SUCCESS, @_);
}

sub DEBUG
{
  rlog->log_rerror(Apache2::Log::LOG_MARK(), Apache2::Const::LOG_DEBUG,
                   APR::Const::SUCCESS, @_);
}

1;

