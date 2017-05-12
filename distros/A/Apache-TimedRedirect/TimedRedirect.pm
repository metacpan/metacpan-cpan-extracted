package Apache::TimedRedirect;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(
);
$VERSION = '0.13';


# Preloads.

use Time::Period;
use Apache::Constants qw(OK DECLINED REDIRECT);
sub handler {
  # the request object
  my $r = shift;  
  # get the uri requested
  my $uri = $r->uri;
  # get the url to redirect too
  my $rurl = $r->dir_config('redirecturl');
  # get the time window in Time::Period format
  # Note READ Time::Period carefully hr{4am-5am}
  # is 4:00am - 5:59:59am
  my $tw = $r->dir_config('timewindow');
  my $uriregex = $r->dir_config('uriregex');
  my $log = $r->dir_config('log') or 0;
  # this allows weebbymaster to bypass redirect
  my $xip = $r->dir_config('excludeip') or 'NONE';
  # get the host ip and see if its 'special'
  my $rh = $r->connection()->remote_ip();
  # allow a host IP through
  return DECLINED if $rh eq $xip;
  # check if timewindow and URI request match
  if (inPeriod(time(), $tw) == 1 && $uri =~ /$uriregex/) {
    print STDERR "TimedRedirect: $rh requesting $uri matched $uriregex  during time period: $tw redirected: $rurl\n" if $log;
    $r->header_out(Location=>$rurl);
    return REDIRECT;
  } else {
    return DECLINED;
  }

}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 NAME

Apache::TimedRedirect - an Apache (mod_perl) TransHandler 

=head1 SYNOPSIS

  use Apache::TimedRedirect;

  requires TimePeriod be installed (go to nearest CPAN)
  requires Apache have mod_perl installed.

  httpd.conf entry...
  **** NOTE *** 
  CANNOT be inside <LOCATION></LOCATION> tags
  PerlTransHandler Apache::TimedRedirect
  PerlSetVar B<redirecturl> http://www.somewhere.far/
  PerlSetVar B<timewindow> 'hr {6am-8pm}'
  PerlSetVar B<uriregex> foo|bar|do or maybe \..*(foo)>
  PerlSetVar B<log> 1 
  PerlSetVar B<excludeip> 127.0.0.0

=head1 DESCRIPTION

Apache::TimedRedirect is a mod_perl TransHandler module that allows the
configuration of a timed redirect. In other words if someone enters a
a website  and the URI matches a regex AND it is within a
certain time period they will be redirected somewhere else.

It was first created to 'politely' redirect visitors away from database
driven sections of a website while the databases were being refreshed.

=head2 PerlSetVar's

B<redirecturl> -- the place where visitors are sent if B<timewindow>
and B<uriregex> are true.

B<timewindow> -- the time period(s) at which redirect should
place. The format is detailed in Time::Period manpage.

B<uriregex> a perl regex describing the URI constraints for redirection

B<log> log info via STDERR .

B<excludeip> host IP address (XXX.XXX.XXX.XXX) of a host that is
allowed to bypass redirection. This is a literal ip not a regex.

Remember that this is embedding itself in the your Apache webserver so
you should test before committing to production. We have used it with
Apache 1.3.0, 1.2.5 with mod_perl 1.12 and 1.15 in medium traffic
sites (400k-500k hits weekly).


=head1 AUTHOR

Peter G. Marshall, mitd@mitd.com
Thanks to Patrick Ryan for Time::Period that made this a snap.

Copyright (c) 1998 Peter G. Marshall. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself


=head1 SEE ALSO

L<perl(1)>, L<Time::Period(3)>, L<mod_perl(1)>

=cut
