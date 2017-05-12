# Apache::ErrorControl
#
#   description: Apache Error Templating Engine
#
#   author: DJ <dj@boxen.net>
#
# $Id: ErrorControl.pm,v 1.26 2004/09/09 04:02:26 dj Exp $

package Apache::ErrorControl;

use strict;
use warnings;

# BEGIN BLOCK {{{
BEGIN {
  ## Modules
  use HTML::Template::Set;
  use Apache::Constants qw(:common);
  use Apache::File ();
  use Apache::Request;
  use Class::Date;
  use MIME::Entity;

  ## Constants
  use constant TRUE  => 1;
  use constant FALSE => 0;

  ## Variables
  use vars (qw($VERSION));

  $VERSION = do {my @r=(q$Revision: 1.26 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r};
}
# }}}


# Handler Function {{{
sub handler {
  my $r = shift;
  my $self = bless({}, __PACKAGE__);

  # Set Apache::ErrorControl as a subprocess_env/prev->subprocess_env/%ENV
  $r->subprocess_env('APACHE_ERROR_CONTROL', $VERSION);
  if ($r->prev()) {
    $r->prev()->subprocess_env('APACHE_ERROR_CONTROL', $VERSION);
  }
  $ENV{'APACHE_ERROR_CONTROL'} = $VERSION;


  # Define Variables {{{
  my $file          = $r->filename;
  my $c             = $r->connection;
  my $s             = $r->server;

  # check for test mode/hardcoded mode
  if ($r->uri() =~ /\/(\d+)[\/]?$/) {
    $self->{error_code} = $1;
  } else {
    unless ($r->prev()) {
      # return FORBIDDEN if the handler is being accessed directly
      return FORBIDDEN;
    } else {
      # return FORBIDDEN if the handler for some reason has OK for the
      # prev->status
      $self->{error_code} = $r->prev()->status();

      return FORBIDDEN if ($self->{error_code} == OK);
    }
  }

  $self->{document_root} = $r->document_root();

  unless (exists $self->{error_code} and $self->{error_code}) {
    die "Unable to find Error Code, very odd!\n";
  }

  $self->{template_dir} = $r->dir_config("TemplateDir");
  $self->{default_template} = $r->dir_config("DefaultTemplate");

  my $template = $self->find_error_template();

  unless (defined $template and -f $template) {
    die "Unable to find DefaultTemplate or derrived template!\n";
  }

  # try and derrive the MTA Program and setup the email_on hash
  my $MTA_Prog;
  my %email_on = ();
  my $disable_email = $r->dir_config("DisableEmail");
  unless ($disable_email) {
    $MTA_Prog = $r->dir_config("MTA");
    if ($MTA_Prog) {
      # bah, how else do i check -f when its got a -t or something?
      my ($path) = split(/\s+/, $MTA_Prog);
      unless (defined $path and -f $path) {
        undef($MTA_Prog);
      }
    }
    unless ($MTA_Prog) {
      if (-f "/var/qmail/bin/qmail-inject") {
        $MTA_Prog = "/var/qmail/bin/qmail-inject";
      } elsif (-f "/usr/sbin/sendmail") {
        $MTA_Prog = "/usr/sbin/sendmail -t";
      } elsif (-f "/usr/lib/sendmail") {
        $MTA_Prog = "/usr/lib/sendmail -t";
      }
    }
    # build the email_on hash, defaulting to 500
    my $have_email_on = FALSE;
    my @email_on = $r->dir_config()->get("EmailOn");
    if (@email_on) {
      foreach my $ec (@email_on) {
        next unless (defined $ec and $ec);
        $email_on{$ec} = TRUE;
        $have_email_on = TRUE;
      }
    }
    unless ($have_email_on) {
      # default to email_on Internal Server Error's
      $email_on{'500'} = TRUE;
    }
  }

  my $date_format = $r->dir_config("DateFormat");
  # }}}


  # Load Template {{{
  my %tmpl_args = ();
  if ($self->{template_dir}) {
    $tmpl_args{path} = $self->{template_dir};
  }

  my $tmpl = new HTML::Template::Set(
    %tmpl_args,
    filename      => $template,
    cache         => TRUE,
#    debug         => TRUE,
    associate_env => TRUE
  );
  # }}}


  # Setup Template Params {{{

  # build a hash of the params, so we dont try and set anything that doesnt
  # exist in the template
  my %params;
  map { $params{$_} = TRUE } $tmpl->param();

  # build a list of emails to send emails to, unless DisableEmail is turned on,
  # there isnt an EmailOn for this error code or the MTA_Prog is not defined.
  my (@email) = ();
  unless ($disable_email) {
    if (exists $email_on{$self->{error_code}} and $MTA_Prog) {
      my @email_to = $r->dir_config()->get('EmailTo');
      if (@email_to) {
        # push the emails specified in EmailTo
        foreach my $email (@email_to) {
          next unless ($email);
          push(@email, $email);
        }
      }
      my $email_server_admin = $r->dir_config('EmailServerAdmin');
      if ($email_server_admin) {
        # default to adding the server_admin to the @email if there are no
        # EmailOn's or EmailServerAdmin is on
        my $server_admin = $s->server_admin();
        unless (grep(/^\Q$server_admin\E$/, @email)) {
          push(@email, $server_admin);
        }
      }
      if (exists $params{'webmaster_email'}) {
        # if a webmaster_email is specified add it to the @email, unless it
        # already exists in the array
        my $webmaster_email = $tmpl->param('webmaster_email');

        # lets not add the webmaster_email if its in EmailTo
        unless (grep(/^\Q$webmaster_email\E$/, @email)) {
          push(@email, $webmaster_email);
        }
      }
    }
  }

  my $notes = ($r->prev()) ? $r->prev()->notes() : undef;

  # set the current error_code's TMPL_IF on (if the TMPL_IF exists)
  #  i.e. <TMPL_IF NAME="404">
  if (exists $params{$self->{error_code}}) {
    $tmpl->param( $self->{error_code} => TRUE );
  } elsif (exists $params{'unknown_error'}) {
    $tmpl->param( unknown_error => TRUE );
  }
  # set the error_code TMPL_VAR
  #   i.e. <TMPL_VAR NAME="error_code"> (which is substituted with 404)
  if (exists $params{error_code}) {
    $tmpl->param( error_code => $self->{error_code} );
  }
  # set the error_note if its defined
  if (exists $params{'error_notes'} 
  and $notes and exists $notes->{'error-notes'}) {
    $tmpl->param( error_notes => $notes->{'error-notes'} );
  }

  # load the 'date_format' from the template if its set
  if (exists $params{date_format}) {
    $date_format = $tmpl->param('date_format');
  }

  # make the date string (formatted or default)
  my $formatted_date;
  if (exists $params{date}) {
    my $date = new Class::Date(time);
    if ($date_format) {
      $formatted_date = $date->strftime($date_format);
    } else {
      $formatted_date = $date->string();
    }
    $tmpl->param( date => $formatted_date );
  }

  # build the 'requestor' TMPL_VAR (made up from the remote host/ip)
  my $requestor;
  my $remote_host = $c->remote_host();
  my $remote_ip   = $c->remote_ip();
  if ($remote_host and $remote_ip) {
    $requestor = $remote_host. ' ('. $remote_ip. ')';
  } elsif ($remote_ip) {
    $requestor = $remote_ip;
  } else {
    $requestor = 'unknown';
  }

  # use the r->user in the requestor if its available
  if ($c->user()) {
    $requestor = $c->user(). ' ('. $requestor. ')';
  }

  if (exists $params{requestor}) {
    $tmpl->param( requestor => $requestor );
  }

  # build the 'base_url' TMPL_VAR (made up from the server_name etc)
  my $base_url;
  if (exists $ENV{'HTTPS'} and $ENV{'HTTPS'}) {
    $base_url = 'https://';
  } else {
    $base_url = 'http://';
  }
  $base_url .= $s->server_hostname();

  if (exists $params{base_url}) {
    $tmpl->param( base_url => $base_url );
  }

  # build the 'request_url' TMPL_VAR (made up from the base_urlm
  # the url and the args)
  my $request_url = $base_url;
  if ($r->prev()) {
    $request_url .= $r->prev()->uri();
    if ($r->prev()->args()) {
      $request_url .= '?'. $r->prev()->args();
    }
  } else {
    $request_url .= $r->uri();
    if ($r->args()) {
      $request_url .= '?'. $r->args();
    }
  }

  if (exists $params{request_url}) {
    $tmpl->param( request_url => $request_url );
  }
  # }}}


  # Send Email For Internal Server Error {{{
  if (@email > 0) {
    # build our email
    my $mobj = MIME::Entity->build(
      'From'        => 'Apache::ErrorControl <apache-errorcontrol@'.
        $s->server_hostname(). '>',
      'Subject'     => 'Error '. $self->{error_code}. ' on '.
        $s->server_hostname(),
      'Type'        => 'multipart/mixed',
      'X-Mailer'    => 'Apache::ErrorControl'
    );

    my $body = 'Time: '. $formatted_date. "\n".
                'Requested URL: '. $request_url. "\n".
                'Requested By: '. $requestor. "\n\n".
                "--------------------\n".
                "Apache::ErrorControl\n\n";

    $mobj->attach(
      Data     => $body,
      Type     => 'text/plain'
    );

    # Construct Included Debug
    my %content;
    my ($headers_in, $headers_out, $err_headers_out, $subprocess_env);
    if ($r->prev()) {
      %content         =  $r->prev()->content();
      $headers_in      =  $r->prev()->headers_in();
      $headers_out     =  $r->prev()->headers_out();
      $err_headers_out =  $r->prev()->err_headers_out();
      $subprocess_env  =  $r->prev()->subprocess_env();
    }
    # NB: retrieval of POST data will only work on status 204, 304, 400, 408,
    # 411, 413, 414, 500, 501, 503 - hey one of them is 500 so im happy :D :D

    my %files = (
      headers_in      =>  $headers_in,
      headers_out     =>  $headers_out,
      err_headers_out =>  $err_headers_out,
      notes           =>  $notes,
      subprocess_env  =>  $subprocess_env,
      post_data       =>  \%content,
      env             =>  \%ENV
    );

    foreach my $file (keys %files) {
      my $string = $self->apache_table_to_string($files{$file});
      if ($string) {
        $mobj->attach(
          Data     =>  $string,
          Filename =>  $file. '.txt',
          Type     =>  'text/plain',
          Encoding =>  'base64'
        );
      }
    }

    foreach my $email_address (@email) {
      $mobj->head()->replace('To', $email_address);

      open(MTAHANDLE,"|$MTA_Prog")
        or die "Failed to open MTA: ". $MTA_Prog. ": $!\n";
      $mobj->print(\*MTAHANDLE);
      close(MTAHANDLE);
    }
  }
  # }}}


  # Send Headers {{{
  $r->content_type('text/html; charset=ISO-8859-1');
  $r->send_http_header;
  # }}}


  # Send Template {{{
  $r->print($tmpl->output());
  # }}}

  return;
}
# }}}


# Apache Table To String Function {{{
sub apache_table_to_string {
  my ($self, $table) = @_;

  return unless ($table);

  my @string = ();

  while(my($key,$val) = each %$table) {
    next unless ($key);
    my $string = sprintf("%-15s", $key);
    $string .= $val if ($val);
    push(@string, $string);
  }

  return join("\n", @string);
}
# }}}


# Find Error Template Function {{{
#  im not sure why I chose to allow so many paths/filenames but I think its
#  better to be flexiable.
sub find_error_template {
  my ($self) = @_;

  my $error_code = $self->{error_code} || undef;

  my @paths;
  if ($self->{document_root}) {
    push(@paths, $self->{document_root});
  }
  if ($self->{template_dir}) {
    push(@paths, $self->{template_dir});
  }

  foreach my $path (@paths) {
    if (defined $error_code) {
      if (-f $path. '/'. $error_code) {
        return $path. '/'. $error_code;
      } elsif (-f $path. '/'. $error_code. '.html') {
        return $path. '/'. $error_code. '.html';
      } elsif (-f $path. '/'. $error_code. '.tmpl') {
        return $path. '/'. $error_code. '.tmpl';
      }
    }
    if (-f $path. '/allerrors') {
      return $path. '/allerrors';
    } elsif (-f $path. '/allerrors.html') {
      return $path. '/allerrors.html';
    } elsif (-f $path. '/allerrors.tmpl') {
      return $path. '/allerrors.tmpl';
    }
  }

  if (exists $self->{default_template} and $self->{default_template}) {
    if (-f $self->{default_template}) {
      return $self->{default_template};
    } elsif (-f $self->{template_dir}. '/'. $self->{default_template}) {
      return $self->{template_dir}. '/'. $self->{default_template};
    } elsif (-f $self->{document_root}. '/'. $self->{default_template}) {
      return $self->{document_root}. '/'. $self->{default_template};
    }
  }
}
# }}}

1;

END { }

__END__

=pod

=head1 NAME

Apache::ErrorControl - Apache Handler for Templating Apache Error Documents

=head1 SYNOPSIS

in your httpd.conf

  PerlModule Apache::ErrorControl

  <Location /error>
    SetHandler perl-script
    PerlHandler Apache::ErrorControl

    PerlSetVar TemplateDir /usr/local/apache/templates
  </Location>

  ErrorDocument 400 /error
  ErrorDocument 401 /error
  ErrorDocument 402 /error
  ErrorDocument 403 /error
  ErrorDocument 404 /error
  ErrorDocument 500 /error

in your template (allerrors.tmpl):

  <TMPL_SET NAME="webmaster_email">dj@boxen.net</TMPL_SET>

  <HTML>
    <HEAD>
      <TITLE>Error <TMPL_VAR NAME="error_code"></TITLE>
    </HEAD>

    <BODY>
      <TMPL_IF NAME="404">
        <H1>Error 404: File Not Found</H1>
        <HR><BR>

        <p>The file you were looking for is not here, we must have
          deleted it - or you just might be mentally retarded</p>
      </TMPL_IF>
      <TMPL_IF NAME="500">
        <H1>Error 500: Internal Server Error</H1>
        <HR><BR>

        <p>We are currently experiencing problems with our server,
          please call back later</p>
      </TMPL_IF>

      <p><b>Time of Error:</b> <TMPL_VAR NAME="date"></p>
      <p><b>Requested From:</b> <TMPL_VAR NAME="requestor"></p>
      <p><b>Requested URL:</b> <TMPL_VAR NAME="request_url"></p>
      <p><b>Website Base URL:</b> <TMPL_VAR NAME="base_url"></p>
      <p><b>Contact Email:</b> support@mouse.com</p>
    </BODY>
  </HTML>

=head1 DESCRIPTION

This mod_perl content handler will make templating your ErrorDocument pages
easy. Basically you add a couple of entries to your httpd.conf file restart
apache, make your template and your cruising.

The module uses L<HTML::Template::Set> (which is essentially HTML::Template
with the ability to use TMPL_SET tags). So for help templating your error
pages please see: L<HTML::Template::Set> and L<HTML::Template>. Also check
the B<OPTIONS> section of this documentation for available TMPL_SET/TMPL_IF
and TMPL_VAR params.

By default when an error 500 (internal server error) is encountered an error
email is sent about it. the addresses emailed depend on the options specified.
please see the B<OPTIONS> section for help configuring this. you can also
extend the system to send error emails on more than just internal server
errors, please see the B<EmailOn> option for how to do this.

Templates are looked up in the following order: the I<document root> is scanned
for 'allerrors', 'allerrors.tmpl', I<error code> or I<error code>.tmpl. if
no templates are found the B<TemplateDir> is scanned for the same files. if
no templates are found the B<DefaultTemplate> is used and if its not set
the system 'B<die>s'.

Because so many places are checked for the templates its possible to have
one global error handler and have different templates for each virtual host
and also allow for defaults. It also means you can have a general catch-all
template (allerrors/allerrors.tmpl) as well as single templates (i.e. 500.tmpl).
Generally I just use allerrors.tmpl and use TMPL_IF's to display custom content
per error message, but you can set it up any way you want.

=head1 MOTIVATION

I wanted to write a mod_perl handler so I could template error messages.
I also wanted to make it extensible enough that I could have a global error
handler and it would cover all the virtual webservers and have different
templates for each of them - ergo - the birth of Apache::ErrorControl.

=head1 TESTING

Obviously you will need the ability to test your templates, and trying to
generate each I<error code> would be a pain in the ass. So to counter this
I have implemented a B<testing>/B<static> mode. Basically you call the handler
with "/I<error code>" tacked on the end. You can also use this to define static
error pages if you dont want the system to "automagically" determine the
I<error code>.

to test error 401:

  http://www.abc.com/error/401

to statically configure error 401:

  ErrorDocument 401 /error/401

I dont see why you would want to statically configure an I<error code>, unless
of course you run into problems for some reason and are forced to.

=head1 ERROR EMAILS

This module has the ability to send an email on an error. you can define
what error code to email on and what email addresses to send emails to, please
see the B<OPTIONS> section on how to do this. the error email contains various
attached files and these are present in the email depending on weather or not
their data could be retrieved. the attached files are detailed below.

=over 4

=item *

B<headers_in.txt> - the inwards headers, a snapshot of the L<Apache::Table>
retrieved from C<$r-E<gt>prev()-E<gt>headers_in()>.

=item *

B<headers_out.txt> - the outwards headers, a snapshot of the L<Apache::Table>
retrieved from C<$r-E<gt>prev()-E<gt>headers_out()>.

=item *

B<err_headers_out.txt> - the outwards error headers, a snapshot of the
L<Apache::Table> retrieved from C<$r-E<gt>prev()-E<gt>err_headers_out()>.

=item *

B<subprocess_env.txt> - the sub process environment, a snapshot of the
L<Apache::Table> retrieved from C<$r-E<gt>prev()-E<gt>subprocess_env()>.

=item *

B<env.txt> - a snapshot of the ENV (global environment variables) hash.

=item *

B<post_data.txt> - the I<POST> data, a snapshot of the
hash from C<$r-E<gt>prev()-E<gt>content()>. this is the only way I know of
retrieving the I<POST> data and it will B<*ONLY*> be present during
I<error codes>: 204, 304, 400, 408, 411, 413, 414, 500, 501, 503 which doesnt
worry me since 500 is one of the mentioned codes - but you may need the
I<POST> data for a different I<error code>. I<GET> data of course is tacked
onto the end of the request_uri.  the I<POST> data will also not appear
unless the I<Content-Type> is C<application/x-www-form-urlencoded>.

=back

=head2 EXAMPLE EMAIL

Below is an example email (obviously missing the file attachments).

  Subject: Error 500 on www.abc.com

  Time: 2004-05-05 14:27:22
  Requested URL: http://www.abc.com/testing/testing123.cgi
  Requested By: dj (dj.abc.com (10.0.0.10))

  --------------------
  Apache::ErrorControl

=head1 OPTIONS

=head2 HTTPD CONFIG

=over 4

=item *

B<TemplateDir> - the directory of your templates, this path will be used
when looking up the template for the error message (looking in it for either
I<error code>, I<error code>.tmpl, allerrors, allerrors.tmpl - then falling back
to looking for the files mentioned before under the I<document root> - then
falling back to using the B<DefaultTemplate> - then 'B<die>ing').
the B<TemplateDir> is also passed to L<HTML::Template::Set> as the B<path>
option.

  PerlSetVar TemplateDir "/usr/local/apache/templates"

=item *

B<DefaultTemplate> - the default template file to use, can be just a filename
(to be looked up under B<TemplateDir>) or the full path to the file.

  PerlSetVar DefaultTemplate "myerrors.tmpl"

=item *

B<MTA> - (Mail Transport Agent), basically the path to the program to send
email with (i.e. sendmail, qmail-send etc). dont forget to provide any options
needed for your MTA to function correctly (i.e. B<-t> for sendmail).

  PerlSetVar MTA "/usr/lib/sendmail -t"

=item *

B<DateFormat> - you can specify the date format to use in emails and in the
templates here. just provide a B<strftime> format. this can be overrided on a
per template basis with the B<date_format> TMPL_SET param. if this isnt
specified a default date format is used.

  PerlSetVar DateFormat "%Y-%m-%d %H:%M:%S"

=item *

B<EmailTo> - to specify globally email addresses to send messages to please
use this option. use a PerlAddVar for each email you wish to send to.

  PerlAddVar EmailTo "dj@abc.com.au"
  PerlAddVar EmailTo "dj@xyz.com.au"

=item *

B<EmailServerAdmin> - if you want the I<server admin> to receive a copy of the
email please turn this option on (set it to 1). this is more useful in a
virtual hosting environment where the I<server admin> is different for
each virtual host.

  PerlSetVar EmailServerAdmin 1

B<DisableEmail> - if you want to disable error emails all together then
set this to true. this is a good way of disabling emails during fixing a
problem (rather than removing all the email settings, directive by directive,
template by template).

  PerlSetVar DisableEmail 1

=item *

B<EmailOn> - if you want to recieve emails for more than just internal
server errors (500) then specify an EmailOn for each using a PerlAddVar
instead of a PerlSetVar.

  PerlAddVar EmailOn 403
  PerlAddVar EmailOn 500

=back

=head2 TEMPLATE

=head3 TMPL_SET

=over 4

=item *

B<webmaster_email> - this paramater allows you to set add an email address
to send error messages to on a per-template basis.

  <TMPL_SET NAME="webmaster_email">dj@abc.com</TMPL_SET>

=item *

B<date_format> - this option overrides the B<DateFormat> HTTPD CONF entry
on a per-template basis.

  <TMPL_SET NAME="date_format">%d-%m-%Y %H:%M:S</TMPL_SET>

=back

=head3 TMPL_VAR / TMPL_IF

=over 4

=item *

B<requestor> - the requestor of the page either "user (hostname (ip))",
"user (ip)", "hostname (ip)" or "ip", depending if their ip resolves or not.
NB: unless you have "HostnameLookups On" in you httpd.conf you will never
see the users hostname.

  <TMPL_VAR NAME="requestor">

=item *

B<base_url> - the base url of the website, i.e. http://www.abc.com

  <TMPL_VAR NAME="base_url">

=item *

B<request_url> - the full request url including arguments, i.e.
http://www.abc.com/stuff/stuffed.cgi?abc=yes&no=yes

  <TMPL_VAR NAME="request_url">

=item *

B<date> - the date/time of the error (format depending on the
B<DateFormat> / B<date_format>.

  <TMPL_VAR NAME="date">

=item *

B<error_code> - the I<error code>, i.e. 404, 403, 500 etc

  <TMPL_VAR NAME="error_code">

=item *

B<*error_code*> - the actual I<error code> itself is set as a param (if the
param exists). if there is no TMPL_IF or TMPL_VAR
defined for the I<error code> encountered the param B<unknown_error> is
turned on (obviously only if it too is defined).
personally I cant see why anyone would ever need B<unknown_error> but ive
added it here anyways.

  <TMPL_IF NAME="404">
    Error 404 - File Not Found
  </TMPL_IF>

=item *

B<unknown_error> - if the B<*error_code*> is not defined as a TMPL_VAR or
TMPL_IF and there is a TMPL_IF / TMPL_VAR by the name of B<unknown_error> it is
set to TRUE (1). as mentioned above I cannot see why anyone would want this.

  <TMPL_IF NAME="unknown_error">
    Error <TMPL_VAR NAME="error_code"> - Unknown
  </TMPL_IF>

=item *

B<error_notes> - the error-notes (C<$r-E<gt>prev()-E<gt>notes('error-notes')>,
see L<Apache>). this is more useful in say a staging environment that has
mod_perl applications. it is the error message, for mod_perl applications
it includes the complete error message but for normal cgi applications
it just includes 'premature end of script headers'.

  <TMPL_IF NAME="error_notes">
    <h2>Error Notes</h2>
    <pre>
    <TMPL_VAR NAME="error_notes">
    </pre>
  </TMPL_IF>

=item *

B<env_*> - all env_* params are available, see L<HTML::Template::Set>
for details.

  <TMPL_VAR NAME="env_server_name">

=back

=head1 OPTIMISATION

As the module loads L<HTML::Template::Set> with the B<cache> option all
templates are automatically cached. To further increase the performance you
should look at the documentation of L<HTML::Template> for instructions on how
to pre-load your templates under mod_perl. If you do not use this methodology
L<HTML::Template> will only cache your templates per apache child process and
upon using them (i.e. before you will notice the benefits of using cache each
apache child process needs to load each template).

=head1 CAVEATS

This module may be missing something that you feel it needs, it has
everything I have wanted though. If you want a feature added please email me
or send me a patch.

One thing to note is that if you go to your handler directly
(i.e. http://www.abc.com/error) the system will return I<FORBIDDEN>. this will
also happen if your I<error code> is ever 200 (I<OK>) (which it should never be
unless you are accessing the handler directly). If you are interested in
testing your templates see the B<TESTING> section.

=head1 BUGS

I am aware of no bugs - if you find one, just drop me an email and i'll
try and nut it out (or email a patch, that would be tops!).

=head1 SEE ALSO

L<HTML::Template::Set>, L<HTML::Template>, L<Apache>

=head1 AUTHOR

David J Radunz <dj@boxen.net>

=head1 LICENSE

Apache::ErrorControl : Apache Handler for Templating Apache Error Documents

Copyright (C) 2004 David J Radunz (dj@boxen.net)

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,
or

b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file ARTISTIC.  If not, I'll be glad to provide one.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

