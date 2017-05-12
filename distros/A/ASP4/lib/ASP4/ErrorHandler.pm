
package ASP4::ErrorHandler;

use strict;
use warnings 'all';
use base 'ASP4::HTTPHandler';
use vars __PACKAGE__->VARS;
use MIME::Base64;
use Data::Dumper;


sub run
{
  my ($s, $context) = @_;
  
  my $error = $Stash->{error};
  $s->print_error( $error );
  $s->send_error( $error );
}# end run()


sub print_error
{
  my ($s, $error) = @_;
  
  $Response->ContentType('text/html');

  if( $ENV{HTTP_HOST} eq 'localhost' )
  {
    $Response->Write( Dumper(\%$error) );
  }
  else
  {
    $Response->Write( $s->error_html( $error ) );
  }# end if()
  
  $Response->Flush;
}# end print_error()


sub send_error
{
  my ($s, $error) = @_;
  
  $Server->Mail(
    To                          => $Config->errors->mail_errors_to,
    From                        => $Config->errors->mail_errors_from,
    Subject                     => "ASP4: Error in @{[ $ENV{HTTP_HOST} ]}@{[ $ENV{REQUEST_URI} ]}",
    'content-type'              => 'text/html',
    'content-transfer-encoding' => 'base64',
    Message                     => encode_base64( $s->error_html($error) ),
    smtp                        => $Config->errors->smtp_server,
  );
}# end send_error()


sub error_html
{
  my ($s, $error) = @_;
  
  my $msg = <<"ERROR";
<!DOCTYPE html>
<html>
<head><title>500 Server Error</title>
<meta charset="utf-8" />
<style type="text/css">
HTML,BODY {
  background-color: #FFFFFF;
}
HTML,BODY,P,DIV {
  font-family: Arial, Helvetica, Sans-Serif;
}
HTML,BODY,P,PRE,DIV {
  font-size: 12px;
}
H1 {
  font-size: 50px;
  font-weight: bold;
}
PRE {
  padding-right: 10px;
  line-height: 16px;
}
.code {
  margin-top: 20px;
  margin-left: 15px;
  width: 95%;
  padding: 10px;
  overflow: auto;
  border: solid 1px #808080;
  background-color: #FFFFCC;
}
.clear {
  clear: both;
}
.label {
  text-align: right;
  padding-right: 5px;
  float: left;
  width: 80px;
  font-weight: bold;
}
.info {
  float: left;
  color: #CC0000;
}
</style>
<body>
<h1>500 Server Error</h1>
<h2>@{[ $error->message ]}</h2>
<div><div class="label">URL:</div> <div class="info"><code>@{[ $ENV{HTTP_HOST} ]}@{[ $ENV{REQUEST_URI} ]}</code></div></div>
<div class="clear"></div>
<div><div class="label">File:</div> <div class="info"><code>@{[ $error->file ]}</code></div></div>
<div class="clear"></div>
<div><div class="label">Line:</div> <div class="info">@{[ $error->line ]}</div></div>
<div class="clear"></div>
<div><div class="label">Time:</div> <div class="info">@{[ HTTP::Date::time2iso() ]}</div></div>
<div class="clear"></div>
<h2>Stacktrace follows below:</h2>
<div class="code"><pre>@{[ $error->stacktrace ]}</pre></div>
<div class="clear"></div>
<h3>\%ENV</h3>
<div class="code"><pre>
HTTP_REFERER:     '@{[ $Server->HTMLEncode($ENV{HTTP_REFERER}||'NONE') ]}'
HTTP_COOKIE:      '@{[ $Server->HTMLEncode($ENV{HTTP_COOKIE}||'NONE') ]}'
HTTP_USER_AGENT:  '@{[ $Server->HTMLEncode($ENV{HTTP_USER_AGENT}||'NONE') ]}'
REMOTE_ADDR:      '@{[ $Server->HTMLEncode($ENV{REMOTE_ADDR}||'NONE') ]}'
</pre></div>
<h3>\$Form</h3>
<div class="code"><pre>@{[ Dumper($Form) ]}</pre></div>
<div class="clear"></div>
<div style="display: none;">
</body>
</html>
ERROR
  
  return $msg;
}# end error_html()


1;# return true:

=pod

=head1 NAME

ASP4::ErrorHandler - Default fatal error handler

=head1 SYNOPSIS

In your C<asp4-config.json>:

  ...
    "errors": {
      "error_handler":    "ASP4::ErrorHandler",
      "mail_errors_to":   "you@server.com",
      "mail_errors_from": "root@localhost",
      "smtp_server":      "localhost"
    },
  ...

=head1 DESCRIPTION

This class provides a default error handler which does the following:

1) Makes a simple HTML page and prints it to the browser, telling the user
that an error has just occurred.

2) Sends that same HTML to the email address specified in the config, using the
SMTP server also specified in the config.  The email subject will look something like:

  ASP4: Error in your-site.com/index.asp

=head1 SUBCLASSING

To subclass C<ASP4::ErrorHandler> you must do the following:

  package My::ErrorHandler;
  
  use strict;
  use warnings 'all';
  use base 'ASP4::ErrorHandler';
  use vars __PACKAGE__->VARS;
  
  sub run {
    my ($s, $context) = @_;
    
    my $error = $Stash->{error};
    
    # $error is an ASP4::Error object.
  
    # Do something here about the error.
    $s->print_error( $error );
    $s->send_error( $error );
  }
  
  1;# return true:

=head1 METHODS

=head2 error_html( $error )

Returns a string of html suitable for printing to the browser or emailing.

=head2 print_error( $error )

Prints the error html to the browser.

=head2 send_error( $error )

Sends the error html to the email address specified in the config, using C<<$Server->Mail(...)>>
and the smtp server specified in the config.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut

