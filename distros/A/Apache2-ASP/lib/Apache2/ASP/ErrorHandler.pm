
package Apache2::ASP::ErrorHandler;

use strict;
use warnings 'all';
use base 'Apache2::ASP::HTTPHandler';
use vars __PACKAGE__->VARS;
use MIME::Base64;


#==============================================================================
sub run
{
  my ($s, $context) = @_;
  
  my $error = $Stash->{error};

  my $msg = <<"ERROR";
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html>
<head><title>500 Server Error</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
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
#code {
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
<h2>@{[ $error->{title} ]}</h2>
<div><div class="label">File:</div> <div class="info"><code>@{[ $error->{file} ]}</code></div></div>
<div class="clear"></div>
<div><div class="label">Line:</div> <div class="info">@{[ $error->{line} ]}</div></div>
<div class="clear"></div>
<div><div class="label">Time:</div> <div class="info">@{[ HTTP::Date::time2iso() ]}</div></div>
<div class="clear"></div>
<h2>Stacktrace follows below:</h2>
<div id="code"><pre>@{[ $error->{stacktrace} ]}</pre></div>
<div style="display: none;">
</body>
</html>
ERROR
  
  $Response->Write( $msg );
  $Server->Mail(
    To                          => $Config->errors->mail_errors_to,
    From                        => $Config->errors->mail_errors_from,
    Subject                     => "Apache2::ASP: Error in @{[ $ENV{HTTP_HOST} ]}@{[ $context->r->uri ]}",
    'content-type'              => 'text/html',
    'content-transfer-encoding' => 'base64',
    Message                     => encode_base64( $msg ),
    smtp                        => $Config->errors->smtp_server,
  );

}# end run()

1;# return true:

=pod

=head1 NAME

Apache2::ASP::ErrorHandler - Default fatal error handler

=head1 SYNOPSIS

In your C<apache2-asp-config.xml>:

  <?xml version="1.0" ?>
  <config>
    ...
    <errors>
      <error_handler>Apache2::ASP::ErrorHandler</error_handler>
      <mail_errors_to>you@your-site.com</mail_errors_to>
      <mail_errors_from>root@localhost</mail_errors_from>
      <smtp_server>localhost</smtp_server>
    </errors>
    ...
  </config>

=head1 DESCRIPTION

This class provides a default error handler which does the following:

1) Makes a simple HTML page and prints it to the browser, telling the user
that an error has just occurred.

2) Sends that same HTML to the email address specified in the config, using the
SMTP server also specified in the config.  The email subject will look something like:

  Apache2::ASP: Error in your-site.com/index.asp

=head1 SUBCLASSING

To subclass C<Apache2::ASP::ErrorHandler> you must do the following:

  package My::ErrorHandler;
  
  use strict;
  use warnings 'all';
  use base 'Apache2::ASP::ErrorHandler';
  use vars __PACKAGE__->VARS;
  
  sub run {
    my ($s, $context) = @_;
    
    my $error = $Stash->{error};
    
    # $error looks like this:
    $VAR1 = {
      title       => 'Cannot call execute with a reference',
      file        => '/tmp/PAGE_CACHE/mysite/index_asp.pm',
      line        => 45,
      stacktrace  => # Output from Carp::confess,
    };
  
    # Do something here about the error.
  }
  
  1;# return true:

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut

