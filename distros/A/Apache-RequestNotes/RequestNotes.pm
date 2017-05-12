package Apache::RequestNotes;

#---------------------------------------------------------------------
#
# usage: PerlInitHandler Apache::RequestNotes
#        PerlSetVar  MaxPostSize 1024          optional size in bytes
#                                              allowed to be POSTed
#
#        PerlSetVar  DisableUploads On         forbid file uploads 
#        
#---------------------------------------------------------------------

use 5.004;
use mod_perl 1.21;
use Apache::Constants qw( OK );
use Apache::Cookie;
use Apache::Log;
use Apache::Request;
use strict;

$Apache::RequestNotes::VERSION = '0.06';

# set debug level
#  0 - messages at info or debug log levels
#  1 - verbose output at info or debug log levels
$Apache::RequestNotes::DEBUG = 0;

sub handler {
#---------------------------------------------------------------------
# initialize request object and variables
#---------------------------------------------------------------------
  
  my $r         = shift;
  my $log       = $r->server->log;

  my $maxsize   = $r->dir_config('MaxPostSize') || 1024;
  my $uploads   = $r->dir_config('DisableUploads') =~ m/Off/i ? 0 : 1;

  my %cookies   = ();               # hash for cookie names and values

  $Apache::RequestNotes::err = undef;

#---------------------------------------------------------------------
# do some preliminary stuff...
#---------------------------------------------------------------------

  $log->info("Using Apache::RequestNotes");

#---------------------------------------------------------------------
# grab the cookies
#---------------------------------------------------------------------

  my %cookiejar = Apache::Cookie->new($r)->parse;

  foreach (sort keys %cookiejar) {
    my $cookie = $cookiejar{$_};

    $cookies{$cookie->name} = $cookie->value; 

    $log->info("\tcookie: name = ", $cookie->name,
       ", value = ", $cookie->value) if $Apache::RequestNotes::DEBUG;
  }

#---------------------------------------------------------------------
# parse the form data
#---------------------------------------------------------------------

  # this routine works for either a get or post request
  my $apr = Apache::Request->instance($r, POST_MAX => $maxsize,
                                          DISABLE_UPLOADS => $uploads);

  # I assume that Apache::RequestNotes is going to do the job of
  # of calling Apache::Request->new().  Hopefully, this is ok...
  my $status = $apr->parse;

  if ($status) {
    # I don't know what to do here, but rather than return
    # SERVER_ERROR, do something that says there was a parse failure.
    # GET data is still available, but POST looks hosed...
    # problems with uploads are caught here as well.

    $Apache::RequestNotes::err = $status;
   
    $log->error("Apache::RequestNotes encountered a parsing error!");
    $log->info("Exiting Apache::RequestNotes");
    return OK;
  }

  my $input = $apr->parms;   # this is a hashref tied to Apache::Table

  if ($Apache::RequestNotes::DEBUG) {
    $input->do(sub {
      my ($key, $value) = @_;
      $log->info("\tquery string: name = $key, value = $value");
      1;
    });
  }
  
#---------------------------------------------------------------------
# create an array of all Apache::Upload objects
#---------------------------------------------------------------------

  my @uploads = $apr->upload;    # all the Apache::Upload objects

  foreach my $upload (@uploads) {
    $log->info("\tupload: size = ", $upload->size,
       ", type = ", $upload->type) if $Apache::RequestNotes::DEBUG; 
  }

#---------------------------------------------------------------------
# put the form and cookie data in a pnote for access by other handlers
#---------------------------------------------------------------------

  $r->pnotes(INPUT => $input);
  $r->pnotes(UPLOADS => \@uploads) if @uploads;
  $r->pnotes(COOKIES => \%cookies) if %cookies;

#---------------------------------------------------------------------
# wrap up...
#---------------------------------------------------------------------

  $log->info("Exiting Apache::RequestNotes");

  return OK;
}

1;

__END__

=head1 NAME

Apache::RequestNotes - pass form and cookie data around in pnotes

=head1 SYNOPSIS

httpd.conf:

  PerlInitHandler Apache::RequestNotes
  PerlSetVar MaxPostSize 1024
  PerlSetVar DisableUploads On

  MaxPostSize is in bytes and defaults to 1024, thus is optional.
  DisableUploads defaults to On, and likewise is optional.

=head1 DESCRIPTION

Apache::RequestNotes provides a simple interface allowing all phases
of the request cycle access to cookie or form input parameters in a
consistent manner.  Behind the scenes, it uses libapreq functions to
parse request data and puts references to the data objects in pnotes.

=head1 EXAMPLE

httpd.conf:

  PerlInitHandler Apache::RequestNotes

some Perl*Handler or Registry script:

  my $input      = $r->pnotes('INPUT');   # Apache::Table reference
  my $uploads    = $r->pnotes('UPLOADS'); # Apache::Upload array ref
  my $cookies    = $r->pnotes('COOKIES'); # hash reference
  
  # GET and POST data
  my $foo        = $input->get('foo');

  # uploaded files
  foreach my $upload (@$uploads) {
    my $name     = $upload->name'
    my $fh       = $upload->fh;
    my $size     = $upload->size;
  }

  # cookie data
  my $bar        = $cookies->{'bar'};

After using Apache::RequestNotes:
  o $cookies contains a reference to a hash with the names and values
    of all cookies sent back to your domain and path.

  o $input contains a reference to an Apache::Table object and can be
    accessed via Apache::Table methods - if a form contains both GET
    and POST data, both are available via $input.

  o $uploads contains a reference to an array containing all the
    Apache::Upload objects for the request, which can be used to
    access uploaded file information.

Once Apache::RequestNotes has been called, all other phases can have
access to the form input and cookie data without parsing it
themselves. This relieves some strain, especially when the GET or POST
data is required by numerous handlers along the way.

=head1 NOTES

It should be noted that Apache::Request 0.3103 and above now offers
the Apache::Request->instance() method, which offers the ability
to access the same Apache::Request object over and over again.
While the availability of instance() does absorb the problems that
prompted Apache::RequestNotes, namely the ability to read from POST
more than once, you still have to parse the various data yourself.
Thus, the utility of Apache::RequestNotes is now simply the ability
to have a common API for all your handlers to use.

Apache::RequestNotes can really be called from just about any request
phase.  Thus, if you need to postpone data parsing until after uri 
translation, using RequestNotes as a PerlFixupHandler should work
just fine.  Keep in mind that Apache::RequestNotes returns OK, which
would preclude it's use in conjuction with other PerlTransHandlers
and PerlTypeHandlers (but it doesn't really belong there anyway).

MaxPostSize applies to file uploads as well as POST data, so if you
plan on uploading files bigger than 1K, you will need to the override
the default value.

$Apache::RequestNotes:err is set if libapreq reports a problem
parsing the form data, thus it can be used to verify whether $input
and $uploads contain valid objects.  Apache::RequestNotes will _not_
return SERVER_ERROR in the event libapreq encounters an error.  This
may change in future releases.

Verbose debugging is enabled by setting the variable
$Apache::RequestNotes::DEBUG to 1 or greater. To turn off all debug
information, set your apache LogLevel above info level.

This is alpha software, and as such has not been tested on multiple
platforms or environments.  It requires PERL_INIT=1, PERL_LOG_API=1,
and maybe other hooks to function properly. Doug MacEachern's libapreq
is also required - you can get it from CPAN under the Apache tree.

=head1 FEATURES/BUGS

Since POST data cannot be read more than once per request, it is 
improper to both use this module and try to gather form data again
via CGI.pm or by reading it yourself from a cgi script or handler
later in the request cycle.  Unlike versions of RequestNotes prior
to 0.06, however, you can call Apache::Request->instance($r) without
impunity - Apache::Request->new($r) is off limits, though.

=head1 SEE ALSO

perl(1), mod_perl(1), Apache(3), Apache::Request(3), libapreq(1),
Apache::Table(3)

=head1 AUTHOR

Geoffrey Young <geoff@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2000, Geoffrey Young.  All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
