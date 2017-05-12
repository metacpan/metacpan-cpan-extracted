##-*- Mode: CPerl -*-
##
## File: DDC::Filter.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DDC Query utilities: server filters (wrapper sockets)
##======================================================================

package DDC::Filter;
use DDC::Client;
use NetServer::Generic;
use Socket;
use IO::Socket::INET;
use DateTime;
use Carp;
use strict;

##======================================================================
## Globals
our $ilen = length(pack('I',0));
our @ISA = qw(DDC::Client Exporter);

our %LOGLEVELS =
  (
   silent => 0,
   error  => 1,
   warn   => 2,
   info   => 3,
   trace  => 4,
   debug  => 255,
   default => 'info',
  );

our @EXPORT = qw();
our %EXPORT_TAGS =
  (
   log => [qw(%LOGLEVELS)],
  );
$EXPORT_TAGS{all} = [map {@$_} values(%EXPORT_TAGS)];
our @EXPORT_OK = @{$EXPORT_TAGS{all}};


##======================================================================
## Constructors etc

## $filter = $CLASS_OR_OBJ->new(%args)
##  + %args:
##    (
##     connect=>\%connectArgs,  ##-- passed to IO::Socket::INET->new(), ##-- client args
##     bind   =>\%bindArgs,     ##-- args to NetServer::Generic->new()
##     logfile  => $filename,   ##-- for logging (defualt=&STDERR)
##     loglevel => $level,      ##-- log level
##    )
##
##  + additional object structure:
##    (
##     server=>$server,         ##-- a NetServer::Generic object for listening
##    )
##
##  + default %connectArgs:
##     PeerAddr=>'localhost',
##     PeerPort=>50000,
##     Proto=>'tcp',
##     Type=>SOCK_STREAM,
##     Blocking=>1,
##
##  + default %bindArgs:
##     #hostname=>'localhost',
##     port=>$60000,
##     mode=>"forking",
##     allowed=>['127.0.0.1'],
##     listen=>Socket::SOMAXCONN()
##     timeout=>60,
##
sub new {
  my ($that,%args) = @_;
  my %bind = (
	      ##-- defaults
	      #hostname=>'localhost',
	      port=>60000,
	      mode=>'forking',
	      allowed=>['127.0.0.1'],
	      listen=>Socket::SOMAXCONN(),
	      timeout=>60,

	      ##-- user args
	      (defined($args{'bind'}) ? %{$args{'bind'}} : qw()),
	     );
  delete($args{'bind'});

  return $that->SUPER::new(
			   ##-- connection args
			   bind    =>\%bind,
			   logfile => '&STDERR',
			   loglevel => 'default',

			   ##-- user args
			   %args,
			  );
}

##======================================================================
## Logging

## $fh = $filter->logfh()
sub logfh {
  my $filter = shift;
  return $filter->{logfh} if (defined($filter->{logfh}));
  my $logfh = IO::File->new(">>$filter->{logfile}")
    or confess(ref($filter), "::logmsg(): open failed for logfile '$filter->{logfile}': $!");
  return $logfh;
}

## $filter = $filter->logclose()
sub logclose {
  my $filter = shift;
  $filter->{logfh}->close() if (defined($filter->{logfh}));
  delete($filter->{logfh});
}

## undef = logmsg($level,@message)
sub logmsg {
  my ($filter,$level) = (shift,shift);
  my $flevel = $filter->{loglevel};
  $flevel = $LOGLEVELS{$flevel} while (defined($LOGLEVELS{$flevel}));
  $level  = $LOGLEVELS{$level} while (defined($LOGLEVELS{$level}));
  return if ($level > $flevel);
  my $logfh = $filter->logfh();
  my $dt = DateTime->now();
  $logfh->print(
		$dt->ymd, ' ', $dt->hms, ': ', 
		ref($filter), "[$$]: ", @_, "\n"
	       );
}


##======================================================================
## Server Methods: run

## undef = $filter->run()
sub run {
  my $filter = shift;
  my $server = $filter->{server} = NetServer::Generic->new(%{$filter->{bind}});
  $server->callback($filter->_callback());
  return $server->run();
}

##======================================================================
## Server Methods: callback

## \&callback_sub = $filter->_callback($netserver_generic)
sub _callback {
  my $filter = shift;
  return sub {
    ##-- read client data
    my $ns      = shift;
    my $sclient = DDC::Client->new(connect=>$filter->{connect});
    $sclient->open();

    my $chost = $ns->{sock}->peerhost.':'.$ns->{sock}->peerport;
    my $shost = $sclient->{sock}->peerhost.':'.$sclient->{sock}->peerport;
    $filter->logmsg('info', "connect from client $chost --> server $shost");

    my $cdata   = $filter->readData($ns->{sock});
    my $fcdata  = $filter->filterInput($cdata);
    $filter->logmsg('debug', "got query=($cdata)->($fcdata) from client $chost");
    $filter->logmsg('trace', "got query from client $chost");

    $sclient->send($fcdata);
    $filter->logmsg('trace', "passed on query from client $chost to upstream server $shost");

    my $sdata   = $sclient->readData();
    $filter->logmsg('trace', "got response from upstream server $shost");

    my $fsdata  = $filter->filterOutput($sdata);
    $filter->logmsg('debug', "got response=($sdata)->($fsdata) from upstream server $shost");

    $filter->sendfh($ns->{sock}, $fsdata);
    $filter->logmsg('trace', "passed response from upstream server $shost to client $chost");

    $filter->logclose();
  }
}

##======================================================================
## Server Methods: filters

## $filtered_data = $filter->filterInput($data_from_client)
sub filterInput { return $_[1]; }

## $filtered_data = $filter->filterOutput($data_from_server)
sub filterOutput { return $_[1]; }



##======================================================================
## Client: open, close

## $io_socket = $dc->open()

## undef = $dc->close()

##======================================================================
## Client: Query: print(), read*()

## undef = $dc->send(@message_strings)
##  + sends @message_strings

## undef = $dc->sendfh($fh,@message_strings)

## $size = $dc->readSize()
## $size = $dc->readSize($fh)

## $data = $dc->readBytes($nbytes)
## $data = $dc->readBytes($nbytes,$fh)

## $data = $dc->readData()
## $data = $dc->readData($fh)

## $hits = $dc->readTableData()
## $hits = $dc->readTableData($fh)

##======================================================================
## Client: Hit Parsing

## \@hits = $dc->parseTableData($buf)
##  + returns an array-ref of hits
##  + each hit is a hash with bibliographic keys as well as:
##    (
##     keywords=>\@keywords,
##     context=>$context_string,
##    )

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=head1 NAME

DDC::Filter - DDC Query utilities: server filters (wrapper sockets)

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES

 use DDC::Client;
 use DDC::Filter;

 ##========================================================================
 ## Constructors etc

 $filter = $CLASS_OR_OBJ->new(%args);   ##-- new filter object

 ##========================================================================
 ## Logging

 $fh = $filter->logfh();                ##-- get log filehandle
 $filter = $filter->logclose();         ##-- close log filehandle
 undef = logmsg($level,@message);       ##-- log a message

 ##========================================================================
 ## Server Methods: run

 undef = $filter->run();                ##-- run the wrapper daemon

 ##========================================================================
 ## Server Methods: callback

 \&callback_sub = $filter->_callback($netserver_generic); ##-- top-level callback

 ##========================================================================
 ## Server Methods: filters

 $filtered_data = $filter->filterInput($data_from_client);  ##-- input filtering callback
 $filtered_data = $filter->filterOutput($data_from_server); ##-- output filtering callback

 ##========================================================================
 ## Inherited Methods

 # ... any DDC::Client method ...

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Filter: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DDC::Filter inherits from DDC::Client.

=item Variable: %LOGLEVELS

Hash mapping symbolic log levels to numeric values, exportable.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Filter: Constructors etc
=pod

=head2 Constructors etc

=over 4

=item new

 $filter = $CLASS_OR_OBJ->new(%args);

=over 4

=item %args:

   (
    connect=>\%connectArgs,  ##-- passed to IO::Socket::INET->new(), ##-- client args
    bind   =>\%bindArgs,     ##-- args to NetServer::Generic->new()
    logfile  => $filename,   ##-- for logging (defualt=&STDERR)
    loglevel => $level,      ##-- log level
   )

=item additional object structure:

   (
    server=>$server,         ##-- a NetServer::Generic object for listening
   )

=item default %connectArgs:

   PeerAddr=>'localhost',
   PeerPort=>50000,
   Proto=>'tcp',
   Type=>SOCK_STREAM,
   Blocking=>1,

(for connecting to the underlying DDC server).

=item default %bindArgs:

   #hostname=>'localhost',
   port=>$60000,
   mode=>"forking",
   allowed=>['127.0.0.1'],
   listen=>128,
   timeout=>60,

(for accepting incoming client connections).

=back

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Filter: Logging
=pod

=head2 Logging

=over 4

=item logfh

 $fh = $filter->logfh();

Get logging filehandle.

=item logclose

 $filter = $filter->logclose();

Close log filehandle.

=item logmsg

 undef = logmsg($level,@message);

Potentially log a message at $level.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Filter: Server Methods: run
=pod

=head2 Server Methods: run

=over 4

=item run

 undef = $filter->run();

Run the server, accepting incoming connections and calling callback(s) for each
incoming query.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Filter: Server Methods: callback
=pod

=head2 Server Methods: callback

=over 4

=item _callback

 \&callback_sub = $filter->_callback($netserver_generic);

Generic NetServer::Generic callback, called for each client.
The default implmentation calls the filterInput() and filterOutput()
methods, which should be sufficient for many applications.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DDC::Filter: Server Methods: filters
=pod

=head2 Server Methods: filters

=over 4

=item filterInput

 $filtered_data = $filter->filterInput($data_from_client);

This method may be overridden in derived classes to perform filtering
of data to be passed to the real DDC server.

The default implementation just returns $data_from_client unchanged.

=item filterOutput

 $filtered_data = $filter->filterOutput($data_from_server);

This method may be overridden in derived classes to perform filtering
of data to be passed back to the querying client.

The default implementation just returns $data_from_server unchanged.

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Footer
##======================================================================

=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2016 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
