package Apache2::ClickPath::Store;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);

use APR::Pool ();
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::ServerRec ();
use Apache2::ServerUtil ();
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Connection ();
use Apache2::Module ();
use Apache2::CmdParms ();
use Apache2::Directive ();
use Apache2::Log ();
use Apache2::Const -compile => qw(DECLINED OK NOT_FOUND
				  SERVER_ERROR HTTP_BAD_REQUEST HTTP_GONE
				  OR_ALL RSRC_CONF
				  TAKE1 RAW_ARGS NO_ARGS
				  LOG_DEBUG);
use APR::Const -compile => qw(SUCCESS);
use CGI v3.08 -compile=>qw(param);
use File::Spec ();
use File::Path qw{rmtree};
use Cwd ();
use Perl::AtEndOfScope;
use Fcntl qw/:flock/;

our $VERSION = '1.9';

our $cleanupdefault=60;

my @directives=
  (
   {
    name         => 'ClickPathStorePath',
    func         => __PACKAGE__ . '::ClickPathStorePath',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::TAKE1,
    errmsg       => 'ClickPathStorePath uri',
   },
   {
    name         => 'ClickPathStoreDirectory',
    func         => __PACKAGE__ . '::ClickPathStoreDirectory',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::TAKE1,
    errmsg       => 'ClickPathStoreDirectory local-directory',
   },
   {
    name         => 'ClickPathStoreTimeout',
    func         => __PACKAGE__ . '::ClickPathStoreTimeout',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::TAKE1,
    errmsg       => 'ClickPathStoreTimeout seconds',
   },
   {
    name         => 'ClickPathStoreCleanupInterval',
    func         => __PACKAGE__ . '::ClickPathStoreCleanupInterval',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::TAKE1,
    errmsg       =>
      'ClickPathStoreCleanupInterval seconds (default: '.$cleanupdefault.')',
   },
  );
Apache2::Module::add(__PACKAGE__, \@directives);

sub postconfig {
  my($conf_pool, $log_pool, $temp_pool, $s) = @_;

  for( $s=Apache2::ServerUtil->server; $s; $s=$s->next ) {
    my $cfg=Apache2::Module::get_config( __PACKAGE__, $s );
    if( $cfg ) {
      if( exists $cfg->{ClickPathStorePath} ) {
	$s->add_config( ['<Location '.$cfg->{ClickPathStorePath}.'>',
			 'SetHandler modperl',
			 'PerlResponseHandler '.__PACKAGE__.'::handler',
			 '</Location>'] );
      } else {
	$s->add_config( ['SetHandler modperl',
			 'PerlResponseHandler '.__PACKAGE__.'::handler'] );
      }
    }
  }

  return Apache2::Const::OK;
}

sub setPostConfigHandler {
  my $h=Apache2::ServerUtil->server->get_handlers('PerlPostConfigHandler')||[];
  unless( grep $_==\&postconfig, @{$h} ) {
    Apache2::ServerUtil->server->push_handlers
	('PerlPostConfigHandler'=>\&postconfig);
  }
}

sub ClickPathStorePath {
  my($I, $parms, $arg)=@_;
  local $_;

  Apache2::Module::get_config( __PACKAGE__, $parms->server )
      ->{"ClickPathStorePath"}=$arg;
  setPostConfigHandler;

  return;
}

sub ClickPathStoreDirectory {
  my($I, $parms, $arg)=@_;

  $arg=File::Spec->catfile( Apache2::ServerUtil::server_root, $arg )
    unless( File::Spec->file_name_is_absolute( $arg ) );
  Apache2::Module::get_config( __PACKAGE__, $parms->server )
      ->{"ClickPathStoreDirectory"}=$arg;
  setPostConfigHandler;

  return;
}

sub ClickPathStoreTimeout {
  my($I, $parms, $arg)=@_;
  local $_;

  Apache2::Module::get_config( __PACKAGE__, $parms->server )
      ->{"ClickPathStoreTimeout"}=$arg;
  setPostConfigHandler;

  return;
}

sub ClickPathStoreCleanupInterval {
  my($I, $parms, $arg)=@_;
  local $_;

  Apache2::Module::get_config( __PACKAGE__, $parms->server )
      ->{"ClickPathStoreCleanupInterval"}=$arg;
  setPostConfigHandler;

  return;
}

sub cleanup {
  my ($c, $cfg)=@{$_[0]};

  my $d=$cfg->{"ClickPathStoreDirectory"};
  my $tmout=$cfg->{"ClickPathStoreTimeout"};
  my $interval=$cfg->{"ClickPathStoreCleanupInterval"}||$cleanupdefault;
  my $time=time;

  unless( -f "$d/#lastcleanup" ) {
    open my $f, ">$d/#lastcleanup"
      or do {
	$c->base_server->log->error('['.__PACKAGE__."] Cannot create $d/#lastcleanup: $!");
	return;
      };
    undef $f;
  }

  open my $f, "<$d/#lastcleanup"
    or do {
      $c->base_server->log->error('['.__PACKAGE__."] Cannot open $d/#lastcleanup: $!");
      return;
    };

  flock $f, LOCK_EX|LOCK_NB or return; # another cleanup is running

  my $lasttime=(stat "$d/#lastcleanup")[9];

  if( $time-$lasttime>$interval ) {
    utime $time, $time, "$d/#lastcleanup";

    opendir my $D, $d
      or do {
	$c->base_server->log->error('['.__PACKAGE__."] Cannot opendir $d: $!");
	return;
      };
    my @l=readdir $D;
    closedir $D;

    $c->base_server->log->debug("Cleaning up $d");

    foreach my $el (@l) {
      next if( $el=~/^\.\.?$/ ); # skip . and ..
      next if( $el eq '#lastcleanup' );

      # cleanup is done in 2 stages. At first the directory name is
      # prepended a hash sign (#) and another cleanup interval
      # is waited to let pending requests be served. Then at stage 2 the
      # directory is removed.
      if( $time-(stat $d.'/'.$el)[9]>$tmout ) {
	if( $el=~/^#/ ) {
	  # stage 2
	  $c->base_server->log->info('['.__PACKAGE__."] $d/$el has expired: deleting");
	  rmtree $d.'/'.$el;
	} else {
	  # stage 1
	  $c->base_server->log->info('['.__PACKAGE__."] $d/$el has expired: marking for deletion");
	  rename "$d/$el", "$d/#$el"
	    or do {
	      $c->log->error('['.__PACKAGE__."] Cannot rename $d/$el to $d/#$el: $! -- deleting $el");
	      rmtree $d.'/'.$el;
	    };
	}
      }
    }
  }
}

sub handler {
  my $r=shift;

  my $restorecwd=Perl::AtEndOfScope->new( sub{chdir shift}, Cwd::getcwd );

  my $cfg=Apache2::Module::get_config( __PACKAGE__, $r->server );

  my $d=$cfg->{"ClickPathStoreDirectory"};

  if( $cfg->{"ClickPathStoreTimeout"} ) {
    # Call cleanup at the end of a connection. So keep-alive requests
    # are served at full speed.
    $r->connection->pool->cleanup_register( \&cleanup, [$r->connection, $cfg] )
      unless( $r->connection->keepalives );
  }

  my ($what, $session, $k, $v, $param);

  if( $r->main and		# is subreq
      $param=$r->pnotes( 'Apache2::ClickPath::StoreClient::storeparams' ) ) {
    ($what, $session, $k, $v)=@{$param}{qw{a s k v}};
  } else {
    $CGI::Q=CGI->new( $r );
    $what=CGI::param( 'a' );
    $session=CGI::param( 's' );
    $k=CGI::param( 'k' );
    $v=CGI::param( 'v' );
  }
  $d.='/'.$session;

  $session=~m!^[^/]+$! or return Apache2::Const::HTTP_BAD_REQUEST;
  $k=~m!^\w+$! or return Apache2::Const::HTTP_BAD_REQUEST;

  my $time=time;
  if( $what eq 'set' ) {
    unless( chdir $d ) {
      mkdir $d or do {
	$r->log->error( '['.__PACKAGE__."] Cannot create directory $d: $!" );
	return Apache2::Const::SERVER_ERROR;
      };
      chdir $d or do {
	$r->log->error( '['.__PACKAGE__."] Cannot chdir to $d: $!" );
	return Apache2::Const::SERVER_ERROR;
      };
    }
    utime $time, $time, '.';	# update times to prevent cleanup
    open my $f, ">$k" or do {
      $r->log->error( '['.__PACKAGE__."] Cannot write $d/$k: $!" );
      return Apache2::Const::SERVER_ERROR;
    };
    print $f $v or do {
      $r->log->error( '['.__PACKAGE__."] Cannot write $d/$k: $!" );
      return Apache2::Const::SERVER_ERROR;
    };
    close $f;
    $r->content_type( 'text/plain' );
    $r->print( 'ok' );
    return Apache2::Const::OK;
  } elsif( $what eq 'get' ) {
    chdir $d or return Apache2::Const::NOT_FOUND;
    utime $time, $time, '.';	# update times to prevent cleanup
    return Apache2::Const::NOT_FOUND unless( -f $k );
    $r->content_type( 'application/octet-stream' );
    # catch non-existent file
    eval {$r->sendfile( $k );};
    if( $@ ) {
      $r->log->error( '['.__PACKAGE__."] Cannot sendfile $d/$k: $!" );
      return Apache2::Const::NOT_FOUND;
    }
    return Apache2::Const::OK;
  } else {
    return Apache2::Const::NOT_FOUND;
  }
}

1;

__END__

=head1 NAME

Apache2::ClickPath::Store - use Apache2::ClickPath sessions to store
information

=head1 SYNOPSIS

 LoadModule perl_module ".../mod_perl.so"
 PerlLoadModule Apache2::ClickPath::Store
 ClickPathStoreDirectory "some_directory"
 ClickPathStorePath "/uri"
 ClickPathStoreTimeout 300
 ClickPathStoreCleanupInterval 60

=head1 DESCRIPTION

C<Apache2::ClickPath::Store> and C<Apache2::ClickPath::StoreClient> can
be used in conjunction with C<Apache2::ClickPath> to store arbitrary
information for a session. The information itself is stored on a WEB
server and accessed via HTTP. C<Apache2::ClickPath::Store> implements the
server side and C<Apache2::ClickPath::StoreClient> the client side.

The system is designed to work for a WEB server cluster as well as for a
single WEB server. Assuming there is a cluster consisting of N machines
all using C<Apache2::ClickPath> to provide session identifiers. Then each
WEB server can manage its own information store running on the same server
or all servers can use a single or a few dedicated information stores. The
information store is simply another WEB server or C<< <Location> >> running
C<Apache2::ClickPath::Store>.

Here each WEB server manages its very own information store:

  +-------------------------+
  |     +----------------+  |
  |     | Cluster        |  |
  |     |                |  |
  |     | +-------------+|  | access the server's very own
  |     | | Server 1    ||  | information store
  |     | |             ||  |
  |     | |        *--------+
  |     | | StoreClient ||
  |     | |        *--------+
  |     | |.............||  |
  |     | | <Loc /store>||  | access a foreign
  +------>|  Info Store ||  | information store
        | | </Loc>      ||  |
        | +-------------+|  |
        |                |  |
        | ...            |  |
        |                |  |
        | +-------------+|  |
        | | Server N    ||  |
        | |.............||  |
        | | <Loc /store>||  |
  +------>|  Info Store ||  |
  |     | | </Loc>      ||  |
  |     | +-------------+|  |
  |     +----------------+  |
  +-------------------------+

And here is a centralized information store:


   here work
   Apache2::ClickPath and
   Apache2::ClickPath::StoreClient
  +----------------+
  | Cluster        |                   and here
  |                |                   Apache2::ClickPath::Store
  | +-------------+|                  +------------+
  | | Server 1    ||                  |            |
  | |             ||    info store    |            |
  | |        *----------------------->|   Info     |
  | |             ||      access      |            |
  | +-------------+|  +-------------->|   store    |
  |                |  |               |            |
  | ...            |  |               |            |
  |                |  |               +------------+
  | +-------------+|  |
  | | Server N    ||  |
  | |             ||  |
  | |        *--------+
  | |             ||
  | +-------------+|
  +----------------+

=head2 Protocol

The store offers a simple HTTP-form interface to get and set information
items. It doesn't matter whether GET or POST requests are used. The data
is accepted in C<multipart/form-data> or C<application/x-www-form-urlencoded>.
The following CGI-parameter control how the data is accessed:

=over 4

=item B<a>

can be either C<get> or C<set> and defines whether the data is read or written.

=item B<s>

the session identifier. All data is stored in a session-oriented way. Normally
this is a session that was generated by C<Apache2::ClickPath> but in
principle it could be any string not containing a slash (C</>). It must not
start with a hash sign (#).

=item B<k>

within a session data is accessed via a key. The key is a string of characters
all matching Perl's C<\w> regular expression. A particular data item is
identified by combination of session and key.

=item B<v>

this parameter is valid only if C<a> is C<set>. It contains the actual data
to be written.

=back

Normally the store answers a request with HTTP status code 200 (OK). In case
of a read operation the response body contains just the data item. The HTTP
content-type is set to C<application/octet-stream>. In case of a write
operation the string C<ok> is returned with the content-type set to
C<text/plain>.

If something went wrong it is indicated by the HTTP status code. The store
returns the following codes:

=over 4

=item B<500> Server Error

this indicates a configuration error. Maybe the data directory doesn't exist
or is not writeable.

=item B<400> Bad Request

an invalid key or session identifier was used.

=item B<404> Not Found

the data item identified by the combination of session and key was not found.
If the item had once existed then it was possibly hit by a timeout.

=back

=head1 CONFIGURATION

C<Apache2::ClickPath::Store> is loaded with a C<PerlLoadModule> directive and
then configured with the following directives. At least
C<ClickPathStoreDirectory> must be given to use the store.

=over 4

=item B<ClickPathStoreDirectory>

sets the directory where the session data is stored. Under this directory
subdirectories will be created one for each session. These subdirectories
then will contain data files one for each data item.

If a relative path is given it is treated relative to C<ServerRoot>.

=item B<ClickPathStorePath>

set an URI where the store is located. That directive effectively created
a C<< <Location> >> section where the store runs. The following lines have
the same effect as C<ClickPathStorePath /store>:

 <Location /store>
     SetHandler modperl
     PerlResponseHandler Apache2::ClickPath::Store::handler
 </Location>

If omitted the whole server is configured as store.

=item B<ClickPathStoreTimeout>

=item B<ClickPathStoreCleanupInterval>

These 2 directives control data expiring and removal. If a timeout is set
(in seconds) each time a connection is hung up a cleanup handler is run. The
first thing it checks if at least a cleanup interval is passed by since its
last run. If no nothing is done. If yes it finds all subdirectories of
C<ClickPathStoreDirectory> that are not modified for more than a timeout
period. Each time a data item is accessed (read or written) its directories
modification time is adjusted. Thus, checking the modification time of the
directory checks if the session data was in use for the last timeout
period or not.

Then each expired directory is marked by prepending a hash sign (#) to its
name. This way the data is not accessible anymore but pending operations
in parallel processes can finish normally.

C<ClickPathStoreTimeout> specifies the timeout period in seconds.
C<ClickPathStoreCleanupInterval> specifies after how many seconds the cleanup
handler should run again. It defaults to 60.

=back

=head1 SEE ALSO

L<Apache2::ClickPath>
L<Apache2::ClickPath::StoreClient>
L<http://perl.apache.org>,
L<http://httpd.apache.org>

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2005 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
