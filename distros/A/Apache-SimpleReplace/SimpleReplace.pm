package Apache::SimpleReplace;

#---------------------------------------------------------------------
#
# usage: PerlHandler Apache::SimpleReplace
#        PerlSetVar  TEMPLATE "/templates/templ.html"
#        PerlSetVar  REPLACE  "|"              # character or string 
#                                                defaults to "|"
#        PerlSetVar  Filter On                 # optional - will work
#                                                within Apache::Filter
#---------------------------------------------------------------------

use 5.004;
use mod_perl 1.21;
use Apache::Constants qw( OK DECLINED SERVER_ERROR );
use Apache::File;
use Apache::Log;
use strict;

$Apache::SimpleReplace::VERSION = '0.06';

# set debug level
#  0 - messages at info or debug log levels
#  1 - verbose output at info or debug log levels
$Apache::SimpleReplace::DEBUG = 0;

sub handler {
#---------------------------------------------------------------------
# initialize request object and variables
#---------------------------------------------------------------------
  
  my $r         = shift;

  my $filter       = $r->dir_config('Filter') || undef;

  $r->log->info("Using Apache::SimpleReplace");

  # redefine $r as necessary for Apache::Filter 1.013 and above
  if (lc($filter) eq 'on') {
    $r->server->log->info("\tregistering handler with Apache::Filter")
       if $Apache::SimpleReplace::DEBUG;
    $r = $r->filter_register;
  }

  my $log       = $r->server->log;

  my $template  = $r->dir_config('TEMPLATE');
  my $replace   = $r->dir_config('REPLACE') || "|";

#---------------------------------------------------------------------
# do some preliminary stuff...
#---------------------------------------------------------------------

  unless ($r->content_type eq 'text/html') {
    $log->info("\trequest is not for an html document - skipping...") 
      if $Apache::SimpleReplace::DEBUG;
    $log->info("Exiting Apache::SimpleReplace");  
    return DECLINED; 
  }
 
#---------------------------------------------------------------------
# wrap the template around the requested file...
#---------------------------------------------------------------------
  
  $log->info("\tlooking for \'$replace\' in template $template") 
    if $Apache::SimpleReplace::DEBUG;

  # open the template handle
  my $tph = Apache::File->new($template);

  unless ($tph) {
    $log->error("\tcannot open template! $!");
    $log->info("Exiting Apache::SimpleReplace");  
    return SERVER_ERROR;
  }

  my ($rqh, $status);

  # open the request handle
  if ($filter) {
    $log->info("\tgetting input from Apache::Filter")
      if $Apache::SimpleReplace::DEBUG;
    ($rqh, $status) = $r->filter_input;
    undef $rqh unless $status == OK;     # just to be sure...
  } else {
    $log->info("\tgetting input from requested file")
      if $Apache::SimpleReplace::DEBUG;
    $rqh = Apache::File->new($r->filename);
  }

  unless ($rqh) {
    $log->error("\tcannot open request! $!");
    $log->info("Exiting Apache::SimpleReplace");
    return SERVER_ERROR;
  }

  $r->send_http_header('text/html');

  # send output
  while (<$tph>) {
    if (/\Q$replace/) {
      $log->info("\t\'$replace\' found - replacing with request") 
        if $Apache::SimpleReplace::DEBUG;  

      my ($left, $right) = split /\Q$replace/;
  
      print $left;            # output the left side of substitution

      $r->send_fd($rqh);      # Apache::Filter > 1.013 overrides
                              # send_fd()

      print $right;           # ouptut the right side of substitution
    }
    else {
      print;                  # print each template line
    }
  }
 
#---------------------------------------------------------------------
# wrap up...
#---------------------------------------------------------------------

   $log->info("Exiting Apache::SimpleReplace");

   return OK;
}

1;
 
__END__

=head1 NAME 

Apache::SimpleReplace - a simple template framework

=head1 SYNOPSIS

httpd.conf:

 <Location /someplace>
    SetHandler perl-script
    PerlHandler Apache::SimpleReplace

    PerlSetVar  TEMPLATE "/templates/format1.html"
    PerlSetVar  REPLACE "the content goes here"
 </Location>  

Apache::SimpleReplace is Filter aware, meaning that it can be used
within an Apache::Filter framework without modification.  Just
include the directive
  
  PerlSetVar Filter On

and modify the PerlHandler directive accordingly.  As of version
0.06, Apache::SimpleReplace requires Apache::Filter 1.013 or
better - users of Apache::Filter 1.011 or less should use version
0.05.

=head1 DESCRIPTION

Apache::SimpleReplace provides a simple way to insert content within
an established template for uniform content delivery.  While the end
result is similar to Apache::Sandwich, Apache::SimpleReplace offers
several advantages.

  o It does not use separate header and footer files, easing the
    pain of maintaining syntactically correct HTML in seperate files.

  o It is Apache::Filter aware, thus it can both accept content from
    other content handlers as well as pass its changes on to others
    later in the chain.

=head1 EXAMPLE

/usr/local/apache/templates/format1.html:

  <html>
      <head><title>your template</title></head>
              <title>your template</title>
      <body bgcolor="#778899">
              some headers, banners, whatever...
              <p>
  the content goes here
              </p>
              <p>some footers, modification dates, whatever...
      </body>
  </html> 

 httpd.conf:

  <Location /someplace>
     SetHandler perl-script
     PerlHandler Apache::SimpleReplace Apache::SSI

     PerlSetVar  TEMPLATE "templates/format1.html"
     PerlSetVar  REPLACE "the content goes here"
     PerlSetVar  Filter On
  </Location>

Now, a request to http://localhost/someplace/foo.html will insert
the contents of foo.html in place of "the content goes here" in the
format1.html template and pass those results to Apache::SSI
The result is a nice and tidy way to control any custom headers, 
footers, background colors, or images in a single html file.

=head1 NOTES

As of 0.02, TEMPLATE is no longer relative to the ServerRoot.

REPLACE defaults to "|", though it may be any character or string
you like - metacharacters are disabled in the search, so sorry, no 
regex for now... 
 
Verbose debugging is enabled by setting
$Apache::SimpleReplace::DEBUG=1 or greater.  To turn off all debug
information, set your apache LogLevel directive above info level.

This is alpha software, and as such has not been tested on multiple
platforms or environments.  It requires PERL_LOG_API=1, 
PERL_FILE_API=1, and maybe other hooks to function properly.

=head1 FEATURES/BUGS

If Apache::SimpleReplace finds more than one match for REPLACE in
the template, it will insert the request for the first occurrence
only.  All other replacement strings will just be stripped from the
template.

Currently, Apache::SimpleReplace will return DECLINED if the
content-type of the request is not 'text/html'.

=head1 SEE ALSO

perl(1), mod_perl(3), Apache(3), Apache::Filter(3)

=head1 AUTHOR

Geoffrey Young <geoff@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2000, Geoffrey Young.  All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
