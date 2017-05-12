package Apache::DebugInfo;

#---------------------------------------------------------------------
#
# usage: various - see the perldoc below
#
#---------------------------------------------------------------------

use 5.005;
use mod_perl 1.2401;
use Apache::Constants qw( OK DECLINED );
use Apache::File;
use Apache::Log;
use Data::Dumper;
use strict;

$Apache::DebugInfo::VERSION = '0.05';

# set debug level
#  0 - messages at info or debug log levels
#  1 - verbose output at info or debug log levels
$Apache::DebugInfo::DEBUG = 0;

sub handler {
#---------------------------------------------------------------------
# this is kinda clunky, but we have to build in some intelligence
# about where the various methods will do the most good
#---------------------------------------------------------------------
  
  my $r           = shift;

  my $log         = $r->server->log;

#  local $^W; # turn off annoying warnings here

  return OK unless $r->dir_config('DebugInfo') =~ m/On/i;
 
  $log->info("Using Apache::DebugInfo") 
    if $Apache::DebugInfo::DEBUG;

  my $object = Apache::DebugInfo->new($r);
  
  $object->timestamp 
    if $r->dir_config('DebugTimestamp');
  $object->mark_phases('All') 
    if $r->dir_config('DebugMarkPhases');

  $object->headers_in('PerlInitHandler')
    if $r->dir_config('DebugHeadersIn');
  $object->pid('PerlInitHandler')
    if $r->dir_config('DebugPID');
  $object->get_handlers('PerlInitHandler')
    if $r->dir_config('DebugGetHandlers');
  $object->dir_config('PerlInitHandler')
    if $r->dir_config('DebugDirConfig');

  $object->notes('PerlCleanupHandler')
    if $r->dir_config('DebugNotes');
  $object->pnotes('PerlCleanupHandler')
    if $r->dir_config('DebugPNotes');
  $object->headers_out('PerlCleanupHandler')
    if $r->dir_config('DebugHeadersOut');

  $log->info("Exiting Apache::DebugInfo") 
    if $Apache::DebugInfo::DEBUG;

  return OK;
}

sub new {
#---------------------------------------------------------------------
# create a new Apache::DebugInfo object
#---------------------------------------------------------------------
  
  my ($class, $r)       = @_;

  my %self              = ();

  my $log               = $r->server->log;

  $self{request}        = $r;
  $self{log}            = $log;

  $self{ip}             = $r->connection->remote_ip;
  $self{uri}            = $r->uri;

  $self{ip_list}        = $r->dir_config('DebugIPList');
  $self{type_list}      = $r->dir_config('DebugTypeList');

  my $file              = $r->dir_config('DebugFile');
  
  $self{fh}             = Apache::File->new(">>$file") if $file;

  if ($self{fh}) {
    $log->info("\tusing $file for output") 
      if $Apache::DebugInfo::DEBUG;
  }
  elsif ($file) {
    $r->log_error("Can't open $file - $! - using STDERR instead");
    $self{fh} = *STDERR;
  }
  else {
    $log->info("\tno file specified - using STDERR for output")
      if $Apache::DebugInfo::DEBUG;
    $self{fh} = *STDERR;
  }

  return bless \%self, $class;
}

sub headers_in {
#---------------------------------------------------------------------
# dump all of the incoming request headers
#---------------------------------------------------------------------
  
  my $self              = shift;

  my @phases            = @_;

  my $r                 = $self->{request};
  my $log               = $self->{log};
  my $fh                = $self->{fh};
  my $ip                = $self->{ip};
  my $uri               = $self->{uri};

  $log->info("Using Apache::DebugInfo::headers_in")
     if $Apache::DebugInfo::DEBUG;

#---------------------------------------------------------------------
# if there are arguments, push the routine onto the handler stack
#---------------------------------------------------------------------

  if (@phases) {
    _push_on_stack($self, @phases);
    $log->info("Exiting Apache::DebugInfo::headers_in") 
      if $Apache::DebugInfo::DEBUG;
    return;
  }

#---------------------------------------------------------------------
# otherwise, just print in a neat and tidy format
#---------------------------------------------------------------------

  print $fh "\nDebug headers_in for [$ip] $uri during " .
    $r->current_callback . "\n";

  $r->headers_in->do(sub {
    my ($field, $value) = @_;
    if ($field =~ m/Cookie/) {
      my @values = split /; /, $value;
      foreach my $cookie (@values) {
        print $fh "\t$field => $cookie\n";
      }
    }
    else { 
      print $fh "\t$field => $value\n";
    }
    1;
  });   

#---------------------------------------------------------------------
# wrap up...
#---------------------------------------------------------------------

  $log->info("Exiting Apache::DebugInfo::headers_in") 
    if $Apache::DebugInfo::DEBUG;

  # return declined so that Apache::DebugInfo doesn't short circuit
  # Perl*Handlers that stop the chain after the first OK (like
  # PerlTransHandler and PerlTypeHandler)

  return DECLINED;
}

sub headers_out {
#---------------------------------------------------------------------
# dump all of the outbound response headers
#---------------------------------------------------------------------

  my $self              = shift;

  my @phases            = @_;

  my $r                 = $self->{request};
  my $log               = $self->{log};
  my $fh                = $self->{fh};
  my $ip                = $self->{ip};
  my $uri               = $self->{uri};

  $log->info("Using Apache::DebugInfo::headers_out")
     if $Apache::DebugInfo::DEBUG;

  if (@phases) {
    _push_on_stack($self, @phases);
    $log->info("Exiting Apache::DebugInfo::headers_out") 
      if $Apache::DebugInfo::DEBUG;
    return;
  }

  print $fh "\nDebug headers_out for [$ip] $uri during " .
    $r->current_callback . "\n";

  $r->headers_out->do(sub {
    my ($field, $value) = @_;
    if ($field =~ m/Cookie/) {
      my @values = split /;/, $value;
      print $fh "\t$field => $values[0]\n";
      for (my $i=1;$i < @values; $i++) {
        print $fh "\t\t=> $values[$i]\n";
      }
    }
    else { 
      print $fh "\t$field => $value\n";
    }
    1;
  });   

  $log->info("Exiting Apache::DebugInfo::headers_out") 
    if $Apache::DebugInfo::DEBUG;

  return DECLINED;
}

sub notes {
#---------------------------------------------------------------------
# dump all the notes for the request
#---------------------------------------------------------------------

  my $self              = shift;

  my @phases            = @_;

  my $r                 = $self->{request};
  my $log               = $self->{log};
  my $fh                = $self->{fh};
  my $ip                = $self->{ip};
  my $uri               = $self->{uri};

  $log->info("Using Apache::DebugInfo::notes")
     if $Apache::DebugInfo::DEBUG;

  if (@phases) {
    _push_on_stack($self, @phases);
    $log->info("Exiting Apache::DebugInfo::notes") 
      if $Apache::DebugInfo::DEBUG;
    return;
  }

  print $fh "\nDebug notes for [$ip] $uri during " .
    $r->current_callback . "\n";

  $r->notes->do(sub {
    my ($field, $value) = @_;
    print $fh "\t$field => $value\n";
    1;
  });   

  $log->info("Exiting Apache::DebugInfo::notes") 
    if $Apache::DebugInfo::DEBUG;

  return DECLINED;
}

sub pnotes {
#---------------------------------------------------------------------
# dump all the pnotes for the request
#---------------------------------------------------------------------
  
  my $self              = shift;

  my @phases            = @_;

  my $r                 = $self->{request};
  my $log               = $self->{log};
  my $fh                = $self->{fh};
  my $ip                = $self->{ip};
  my $uri               = $self->{uri};

  $log->info("Using Apache::DebugInfo::pnotes")
     if $Apache::DebugInfo::DEBUG;

  if (@phases) {
    _push_on_stack($self, @phases);
    $log->info("Exiting Apache::DebugInfo::pnotes") 
      if $Apache::DebugInfo::DEBUG;
    return;
  }

  my $pnotes = $r->pnotes;

  print $fh "\nDebug pnotes for [$ip] $uri during " .
    $r->current_callback . "\n";

  my %hash = %$pnotes;

  foreach my $field (sort keys %hash) {

    my $value = $hash{$field};
    my $d = Data::Dumper->new([$value]);

    $d->Pad("\t\t");
    $d->Indent(1);
    $d->Quotekeys(0);
    $d->Terse(1);
    print $fh "\t$field => " . $d->Dump;
  }

  $log->info("Exiting Apache::DebugInfo::pnotes") 
    if $Apache::DebugInfo::DEBUG;

  return DECLINED;
}

sub dir_config {
#---------------------------------------------------------------------
# dump all the PerlSetVar and PerlAddVar variables for the request
#---------------------------------------------------------------------

  my $self              = shift;

  my @phases            = @_;

  my $r                 = $self->{request};
  my $log               = $self->{log};
  my $fh                = $self->{fh};
  my $ip                = $self->{ip};
  my $uri               = $self->{uri};

  $log->info("Using Apache::DebugInfo::dir_config")
     if $Apache::DebugInfo::DEBUG;

  if (@phases) {
    _push_on_stack($self, @phases);
    $log->info("Exiting Apache::DebugInfo::dir_config") 
      if $Apache::DebugInfo::DEBUG;
    return;
  }

  print $fh "\nDebug dir_config for [$ip] $uri during " .
    $r->current_callback . "\n";

  $r->dir_config->do(sub {
    my ($field, $value) = @_;
    print $fh "\t$field => $value\n";
    1;
  });   

  $log->info("Exiting Apache::DebugInfo::dir_config") 
    if $Apache::DebugInfo::DEBUG;

  return DECLINED;
}

sub pid {
#---------------------------------------------------------------------
# I know this is a waste of code for just printing $$, but I thought
# it would be nice to have a consistent interface.  whatever...
#---------------------------------------------------------------------
  
  my $self              = shift;

  my @phases            = @_;

  my $r                 = $self->{request};
  my $log               = $self->{log};
  my $fh                = $self->{fh};
  my $ip                = $self->{ip};
  my $uri               = $self->{uri};

  $log->info("Using Apache::DebugInfo::pid")
     if $Apache::DebugInfo::DEBUG;

  if (@phases) {
    _push_on_stack($self, @phases);
    $log->info("Exiting Apache::DebugInfo::pid") 
      if $Apache::DebugInfo::DEBUG;
    return;
  }

  print $fh "\nDebug pid for [$ip] $uri during " .
    $r->current_callback . "\n\t$$\n";

  $log->info("Exiting Apache::DebugInfo::pid") 
    if $Apache::DebugInfo::DEBUG;

  return DECLINED;
}

sub get_handlers {
#---------------------------------------------------------------------
# list all the enabled handlers for this request
# PerlInitHandler and PerlCleanupHandler have been omitted for
# the time being...
#---------------------------------------------------------------------
  
  my $self              = shift;

  my @phases            = @_;

  my @all               = qw (PerlPostReadRequestHandler
                              PerlHeaderParserHandler
                              PerlTransHandler
                              PerlAccessHandler
                              PerlAuthenHandler
                              PerlAuthzHandler
                              PerlTypeHandler
                              PerlFixupHandler
                              PerlLogHandler
                              PerlCleanupHandler);

  my $r                 = $self->{request};
  my $log               = $self->{log};
  my $fh                = $self->{fh};
  my $ip                = $self->{ip};
  my $uri               = $self->{uri};

  $log->info("Using Apache::DebugInfo::get_handlers")
     if $Apache::DebugInfo::DEBUG;

  if (@phases) {
    _push_on_stack($self, @phases);
    $log->info("Exiting Apache::DebugInfo::get_handlers") 
      if $Apache::DebugInfo::DEBUG;
    return;
  }

  print $fh "\nDebug get_handlers for [$ip] $uri during " .
    $r->current_callback . "\n";

  foreach my $phase (@all) {
    my $handlers = $r->get_handlers($phase);
    foreach my $key (@$handlers) {
      print $fh "\t$key => enabled as $phase\n";
    }
  }

  $log->info("Exiting Apache::DebugInfo::get_handlers") 
    if $Apache::DebugInfo::DEBUG;

  return DECLINED;
}

sub mark_phases{
#---------------------------------------------------------------------
# mark the start of each phase of the request
#
# PerlInitHandler and PerlCleanupHandler have been omitted for
# the time being...
#---------------------------------------------------------------------

  my $self              = shift;

  my @phases            = @_;

  my $r                 = $self->{request};
  my $log               = $self->{log};
  my $fh                = $self->{fh};
  my $ip                = $self->{ip};
  my $uri               = $self->{uri};

  my @all               = qw (PerlPostReadRequestHandler
                              PerlHeaderParserHandler
                              PerlTransHandler
                              PerlAccessHandler
                              PerlAuthenHandler
                              PerlAuthzHandler
                              PerlTypeHandler
                              PerlFixupHandler
                              PerlLogHandler
                              PerlCleanupHandler);

  $log->info("Using Apache::DebugInfo::mark_phases")
     if $Apache::DebugInfo::DEBUG;

  if (@phases) {
    # make a special exception if 'All' is passed
    @phases = @all if $phases[0] =~ m/All/i;

    _unshift_on_stack($self, @phases);
    $log->info("Exiting Apache::DebugInfo::mark_phases") 
      if $Apache::DebugInfo::DEBUG;
    return;
  }

  print $fh "\n*** In " . $r->current_callback ." for [$ip] $uri\n\n";

  $log->info("Exiting Apache::DebugInfo::mark_phases") 
    if $Apache::DebugInfo::DEBUG;

  return DECLINED;
}

sub ip {
#---------------------------------------------------------------------
# get or set the ip addresses or subnets for which output will
# be generated
#---------------------------------------------------------------------

  my $self              = shift;
 
  return $self->{ip_list} ? $self->{ip_list} : "ALL" unless @_;

  my $ip_list           = shift;

  my $log               = $self->{log};

  $self->{ip_list}      = $ip_list;

  $log->info("\twill check client ip address against $ip_list")
     if $Apache::DebugInfo::DEBUG;

  return 1;
}

sub type {
#---------------------------------------------------------------------
# get or set the file extensions for which output will be generated
#---------------------------------------------------------------------

  my $self              = shift;
 
  return $self->{type_list} ? $self->{type_list} : "ALL" unless @_;

  my $type_list         = shift;

  my $log               = $self->{log};

  $self->{type_list}    = $type_list;

  $log->info("\twill check requested uri against $type_list")
     if $Apache::DebugInfo::DEBUG;

  return 1;
}

sub file {
#---------------------------------------------------------------------
# get or set the output file
#---------------------------------------------------------------------

  my $self              = shift;

  return $self->{fh} unless @_;
 
  my $file              = shift;

  my $r                 = $self->{request};
  my $log               = $self->{log};

  $self->{fh}           = Apache::File->new(">>$file");

  if ($self->{fh}) {
    $log->info("\tusing $file for output")
       if $Apache::DebugInfo::DEBUG;
  } else {
    $r->log_error("Cannot open $file - $! - using STDERR instead");
    $self->{fh} = *STDERR;
  }

  return 1;
}

sub timestamp {
#---------------------------------------------------------------------
# print a timestamp to STDOUT
#---------------------------------------------------------------------

  my $self              = shift;

  my @phases            = @_;

  my $log               = $self->{log};
  my $fh                = $self->{fh};

  $log->info("Using Apache::DebugInfo::timestamp")
     if $Apache::DebugInfo::DEBUG;

  if (@phases) {
    _push_on_stack($self, @phases);
    $log->info("Exiting Apache::DebugInfo::timestamp") 
      if $Apache::DebugInfo::DEBUG;
    return;
  }

  print $fh "\n**** Apache::DebugInfo - " . scalar(localtime) . "\n"; 

  $log->info("Exiting Apache::DebugInfo::timestamp") 
     if $Apache::DebugInfo::DEBUG;

  return DECLINED;
}

#*********************************************************************
# the below methods are not part of the external API
#*********************************************************************

sub _push_on_stack {
#---------------------------------------------------------------------
# add the methods to the back of various Perl*Handler phases
# this method is for internal use only
#---------------------------------------------------------------------

  my ($self, @phases) = @_;

  my $r                       = $self->{request};
  my $log                     = $self->{log};

  unless ($self->_match_ip && $self->_match_type) {
    $log->info("\trequest does not meet critera - skipping")
      if $Apache::DebugInfo::DEBUG;
    return 1;
  }

  my ($debug) = (caller 1)[3] =~ /.*::(.*)/;

  foreach my $phase (@phases) {
    # disable direct PerlHandler calls as it spits Registry scripts
    # to the browser...
    next if $phase =~ m/PerlHandler/;

    $r->push_handlers($phase => sub { $self->$debug() });
    $log->info("\t$phase debugging enabled for $debug")
      if $Apache::DebugInfo::DEBUG;
   }
   return 1;
}

sub _unshift_on_stack {
#---------------------------------------------------------------------
# add a method to the front of various Perl*Handler phases
# this method is for internal use only
#---------------------------------------------------------------------

  my ($self, @phases) = @_;

  my $r                       = $self->{request};
  my $log                     = $self->{log};

  unless ($self->_match_ip && $self->_match_type) {
    $log->info("\trequest does not meet critera - skipping")
      if $Apache::DebugInfo::DEBUG;
    return 1;
  }

  my ($debug) = (caller 1)[3] =~ /.*::(.*)/;

  foreach my $phase (@phases) {
    next if $phase =~ m/PerlHandler/;

    my $handlers = $r->get_handlers($phase);

    # you can't just unshift @$handlers?
    push my @handlers, sub {$self->$debug()};

    foreach my $key (@$handlers) {
      push @handlers, $key;
    }

    $r->set_handlers($phase => \@handlers);

    $log->info("\t$phase debugging enabled for $debug")
      if $Apache::DebugInfo::DEBUG;
   }
   return 1;
}

sub _match_ip {
#---------------------------------------------------------------------
# see if the user's IP matches any given as DebugIPList
# this method is for internal use only
#---------------------------------------------------------------------
 
  my $self              = shift;

  my $r                 = $self->{request};
  my $log               = $self->{log};
  my $ip                = $self->{ip};

  my $ip_list           = $self->{ip_list};

  # return and continue if there is no ip list to check against
  return 1 unless $ip_list;
  
  my @ip_list           = split /\s+/, $ip_list;

  my $total             = 0;

  foreach my $match (@ip_list) {
    $log->info("\tchecking $ip against $match")
       if $Apache::DebugInfo::DEBUG;

    $total++ if ($ip =~ m/\Q$match/);
  }

  return $total;
}

sub _match_type {
#---------------------------------------------------------------------
# see if the requested file matches any given in DebugTypeList
# this method is for internal use only
#---------------------------------------------------------------------
 
  my $self              = shift;

  my $r                 = $self->{request};
  my $log               = $self->{log};
  my $ip                = $self->{ip};
  my $uri               = $self->{uri};

  my $type_list         = $self->{type_list};

  # return and continue if there is no type list to check against
  return 1 unless $type_list;
  
  my @type_list         = split /\s+/, $type_list;

  my $total             = 0;

  foreach my $match (@type_list) {
    $log->info("\tchecking $uri against $match")
       if $Apache::DebugInfo::DEBUG;

    $total++ if ($uri =~ m/\Q$match\E$/);
  }

  return $total;
}

1;

__END__

=head1 NAME

Apache::DebugInfo - log various bits of per-request data 

=head1 SYNOPSIS

There are two ways to use this module...

  1) using Apache::DebugInfo to control debugging automatically

    httpd.conf:

      PerlInitHandler Apache::DebugInfo
      PerlSetVar      DebugInfo On

      PerlSetVar      DebugPID On
      PerlSetVar      DebugHeadersIn On
      PerlSetVar      DebugDirConfig On
      PerlSetVar      DebugHeadersOut On
      PerlSetVar      DebugNotes On
      PerlSetVar      DebugPNotes On
      PerlSetVar      DebugGetHandlers On
      PerlSetVar      DebugTimestamp On
      PerlSetVar      DebugMarkPhases On

      PerlSetVar      DebugFile     "/path/to/debug_log"
      PerlSetVar      DebugIPList   "1.2.3.4 1.2.4."
      PerlSetVar      DebugTypeList ".html .cgi"

  2) using Apache::DebugInfo on the fly

    in handler or script:

      use Apache::DebugInfo;

      my $r = shift;

      my $debug = Apache::DebugInfo->new($r);

      # set the output file
      $debug->file("/path/to/debug_log");

      # get the ip addresses for which output is enabled
      my $ip_list = $debug->ip;

      # dump $r->headers_in right now
      $debug->headers_in;

      # log $r->headers_out after the response goes to the client
      $debug->headers_in('PerlCleanupHandler');

      # log all the $r->pnotes at Fixup and at Cleanup
      $debug->pnotes('PerlCleanupHandler','PerlFixupHandler');

=head1 DESCRIPTION

Apache::DebugInfo gives the programmer the ability to monitor various
bits of per-request data.

You can enable Apache::DebugInfo as a PerlInitHandler, in which case
it chooses what request phase to display the appropriate data.  The
output of data can be controlled by setting various variables to On:

  DebugInfo          - enable Apache::DebugInfo handler

  DebugPID           - dumps apache child pid during request init
  DebugHeadersIn     - dumps request headers_in during request init
  DebugDirConfig     - dumps PerlSetVar and PerlAddVar during request init
  DebugGetHandlers   - dumps enabled request handlers during init

  DebugHeadersOut    - dumps request headers_out during request cleanup
  DebugNotes         - dumps request notes during request cleanup
  DebugPNotes        - dumps request pnotes during request cleanup

  DebugTimestamp     - prints localtime at the start of each request
  DebugMarkPhases    - prints the name of the request phase when the
                       phase is entered, prior to any other handlers

Alternatively, you can control output activity on the fly by calling
Apache::DebugInfo methods directly (see METHODS below).

Additionally, the following optional variables hold special arguments:

  DebugFile          - absolute path of file that will store the info
                       don't forget to make the file writable by 
                       whichever user Apache runs as (likely nobody)
                       defaults to STDERR (which is likely error_log)

  DebugIPList        - a space delimited list of IP address for which
                       debugging is enabled
                       this can be a partial IP - 1.2.3 will match
                       1.2.3.5 and 1.2.3.6
                       if absent, defaults to all remote ip addresses

  DebugTypeList      - a space delimited list of file extensions for
                       which debugging is enabled (.cgi, .html...)
                       if absent, defaults to all types

=head1 METHODS

Apache::DebugInfo provides an object oriented interface to allow you 
to call the various methods from either a module, handler, or an
Apache::Registry script.

Constructor:
  new($r)        - create a new Apache::DebugInfo object
                   requires a valid Apache request object

Methods:
  The following methods can be called without any arguments, in which
  case the associated data is output immediately.  Optionally, each
  can be called with a list (either explicitly or as an array) of 
  Perl*Handlers, which will log the data during the appropriate
  phase:

  headers_in()   - display incoming HTTP headers

  headers_out()  - display outgoing HTTP headers

  notes()        - display strings set by $r->notes

  pnotes()       - display variables set by $r->pnotes

  pid()          - display the apache child process PID

  get_handlers() - display variables set by PerlSetVar and PerlAddVar

  dir_config()   - display the enabled handlers for this request

  timestamp()    - display the current system time

  mark_phases()  - display the phase before executing any other
                   handlers. if given the argument 'All', 
                   mark_phases  will display the entry into all
                   phases after the current phase.  calling with
                   no arguments outputs the current phase 
                   immediately.

  There are also the following methods available for manipulating
  the behavior of the above methods:

  file($file)    - get or set the output file
                   accepts an absolute filename as an argument
                   returns the output filehandle
                   defaults to, but overrides DebugFile above

  ip($list)      - get or set the ip list
                   accepts a space delimited list as an argument
                   defaults to, but overrides DebugIPList above

  type($list)    - get or set the file type list
                   accepts a space delimited list as an argument
                   defaults to, but overrides DebugTypeList above

=head1 NOTES

Setting DebugInfo to Off has no effect on the ability to make direct
method calls.  

Verbose debugging is enabled by setting the variable
$Apache::DebugInfo::DEBUG=1 to or greater.  To turn off all messages
set LogLevel above info.

This is alpha software, and as such has not been tested on multiple
platforms or environments.  It requires PERL_INIT=1, PERL_CLEANUP=1,
PERL_LOG_API=1, PERL_FILE_API=1, PERL_STACKED_HANDLERS=1, and maybe 
other hooks to function properly.

=head1 FEATURES/BUGS

Once a debug handler is added to a given request phase, it can
no longer be controlled by ip() or type(). file(), however, takes
affect on invocation.  This is because the matching is done when
the Perl*Handler is added to the stack, while the output file is
used when the Perl*Handler is actually executed.

Calling Apache::DebugInfo methods with 'PerlHandler' as an argument
has been disabled - doing so gets your headers and script printed
to the browser, so I thought I'd save the unaware from potential 
pitfalls.

Phase misspellings, like 'PelrInitHandler' pass through without
warning, in case you were wondering where your output went...

The get_handlers and mark_phases methods are incomplete, mainly due to
oversights in the mod_perl API.  Currently (as of mod_perl 1.2401),
they cannot function properly on the following callbacks: 
  PerlInitHandler
As such, they have been disabled until forthcoming corrections to the
API can be implemented.  PerlHeaderParserHandlers and 
PerlPostRequestHandlers function normally.

The output uri is whatever the uri was when new() was called (either
on the fly or in Apache::DebugInfo::handler).  Thus if the uri has
undergone translation since the new() call the original, not the new,
uri will be output.  This feature can be easily remedied, but having a
changing uri in the output may be confusing when debugging.  Future
behavior will be influenced by user feedback.

=head1 SEE ALSO

perl(1), mod_perl(1), Apache(3)

=head1 AUTHOR

Geoffrey Young <geoff@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2000, Geoffrey Young.  All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
