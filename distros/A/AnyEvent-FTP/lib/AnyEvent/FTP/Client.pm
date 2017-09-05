package AnyEvent::FTP::Client;

use 5.010;
use Moo;
use AnyEvent;
use AnyEvent::Socket qw( tcp_connect );
use AnyEvent::Handle;
use Carp qw( croak );
use Socket qw( unpack_sockaddr_in inet_ntoa );

# ABSTRACT: Simple asynchronous ftp client
our $VERSION = '0.16'; # VERSION


with 'AnyEvent::FTP::Role::Event';
with 'AnyEvent::FTP::Client::Role::ResponseBuffer';
with 'AnyEvent::FTP::Client::Role::RequestBuffer';


__PACKAGE__->define_events(qw( error close send greeting ));

has _connected => (
  is       => 'rw',
  default  => sub { 0 },
  init_arg => undef,
);


has timeout => (
  is      => 'rw',
  default => sub { 30 },
);


has passive => (
  is      => 'ro',
  default => sub { 1 },
);

foreach my $xfer (qw( Store Fetch List ))
{
  my $cb = sub {
    return shift->passive
    ? 'AnyEvent::FTP::Client::Transfer::Passive::'.$xfer
    : 'AnyEvent::FTP::Client::Transfer::Active::'.$xfer;
  };
  has '_'.lc($xfer) => ( is => 'ro', lazy => 1, default => $cb, init_arg => undef ),
}

sub BUILD
{
  my($self) = @_;
  $self->on_error(sub { warn shift });
  $self->on_close(sub {
    $self->clear_command;
    $self->_connected(0);
    delete $self->{handle};
  });

  require ($self->passive
    ? 'AnyEvent/FTP/Client/Transfer/Passive.pm'
    : 'AnyEvent/FTP/Client/Transfer/Active.pm');

  return;
}


sub connect
{
  my($self, $host, $port) = @_;

  if($host =~ /^ftp:/)
  {
    require URI;
    $host = URI->new($host);
  }

  my $uri;

  if(ref($host) && eval { $host->isa('URI') })
  {
    $uri = $host;
    $host = $uri->host;
    $port = $uri->port;
  }
  else
  {
    $port //= 21;
  }

  croak "Tried to reconnect while connected" if $self->_connected;

  my $cv = AnyEvent->condvar;
  $self->_connected(1);

  tcp_connect $host, $port, sub {
    my($fh) = @_;
    unless($fh)
    {
      $cv->croak("unable to connect: $!");
      $self->_connected(0);
      $self->clear_command;
      return;
    }

    # Get the IP address we are sending from for when
    # we use the PORT command (passive=0).
    $self->{my_ip} = do {
      my($port, $addr) = unpack_sockaddr_in getsockname $fh;
      inet_ntoa $addr;
    };

    $self->{handle} = AnyEvent::Handle->new(
      fh       => $fh,
      on_error => sub {
        my ($hdl, $fatal, $msg) = @_;
        $_[0]->destroy;
        $self->emit('error', $msg);
        $self->emit('close');
      },
      on_eof   => sub {
        $self->{handle}->destroy;
        $self->emit('close');
      },
    );

    $self->on_next_response(sub {
      my $res = shift;
      return $cv->croak($res) unless $res->is_success;
      $self->emit(greeting => $res);
      if(defined $uri)
      {
        my @start_commands = (
          [USER => $uri->user],
          [PASS => $uri->password],
        );
        push @start_commands, [CWD => $uri->path] if $uri->path ne '';
        $self->unshift_command(@start_commands, $cv);
      }
      else
      {
        $cv->send($res);
        $self->pop_command;
      }
    });

    $self->{handle}->on_read(sub {
      $self->{handle}->push_read( line => sub {
        my($handle, $line) = @_;
        $self->process_message_line($line);
      });
    });

  }, sub {
    $self->timeout;
  };

  return $cv;
}


sub login
{
  my($self, $user, $pass) = @_;
  $self->push_command(
    [ USER => $user ],
    [ PASS => $pass ]
  );
}


sub retr
{
  my($self, $filename, $local) = (shift, shift, shift);
  my $args   = ref $_[0] eq 'HASH' ? (\%{$_[0]}) : ({@_});
  $self->_fetch->new({
    command     => [ RETR => $filename ],
    local       => $local,
    client      => $self,
    restart     => $args->{restart},
  });
}


sub stor
{
  my($self, $filename, $local) = @_;
  $self->_store->new(
    command     => [STOR => $filename],
    local       => $local,
    client      => $self,
  );
}


sub stou
{
  my($self, $filename, $local) = @_;
  my $xfer;
  my $cb = sub {
    my $name = shift->get_file;
    $xfer->{remote_name} = $name if defined $name;
    return;
  };
  $xfer = $self->_store->new(
    command     => [STOU => $filename, $cb],
    local       => $local,
    client      => $self,
  );
}


# for this to work under ProFTPd: AllowStoreRestart off
sub appe
{
  my($self, $filename, $local) = @_;
  $self->_store->new(
    command     => [APPE => $filename],
    local       => $local,
    client      => $self,
  );
}


sub list
{
  my($self, $location, $verb) = @_;
  $verb //= 'LIST';
  my @lines;
  my $cv = AnyEvent->condvar;
  $self->_list->new(
    command     => [ $verb => $location ],
    local       => \@lines,
    client      => $self,
  )->cb(sub {
    my $res = eval { shift->recv };
    $cv->croak($@) if $@;
    $cv->send(\@lines);
  });
  $cv;
}


sub nlst
{
  my($self, $location) = @_;
  $self->list($location, 'NLST');
}


sub rename
{
  my($self, $from, $to) = @_;
  $self->push_command(
    [ RNFR => $from ],
    [ RNTO => $to   ],
  );
}


sub pwd
{
  my($self) = @_;
  my $cv = AnyEvent->condvar;
  $self->push_command(['PWD'])->cb(sub {
    my $res = eval { shift->recv } // $@;
    my $dir = $res->get_dir;
    if($dir) { $cv->send($dir) }
    else { $cv->croak($res) }
  });
  $cv;
}


sub size
{
  my($self, $path) = @_;
  my $cv = AnyEvent->condvar;
  $self->push_command(['SIZE', $path])->cb(sub {
    my $res = eval { shift->recv };
    if(my $error = $@)
    { $cv->croak($error) }
    else
    { $cv->send($res->message->[0]) }
  });
  $cv;
}


(eval sprintf('sub %s { shift->push_command([ %s => @_])};1', lc $_, $_)) // die $@
  for qw( CWD CDUP NOOP ALLO SYST TYPE STRU MODE REST MKD RMD STAT HELP DELE RNFR RNTO USER PASS ACCT MDTM );


sub quit
{
  my($self) = @_;
  my $cv = AnyEvent->condvar;

  my $res;

  $self->push_command(['QUIT'])->cb(sub {
    $res = eval { shift->recv } // $@;
  });

  my $save = $self->{event}->{close};
  $self->{event}->{close} = [ sub {
    if(defined $res && $res->is_success)
    { $cv->send($res) }
    elsif(defined $res)
    { $cv->croak($res) }
    else
    { $cv->croak("did not receive QUIT response from server") }
    $_->() for @$save;
    $self->{event}->{close} = $save;
  } ];

  return $cv;
}


sub site
{
  require AnyEvent::FTP::Client::Site;
  AnyEvent::FTP::Client::Site->new(shift);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Client - Simple asynchronous ftp client

=head1 VERSION

version 0.16

=head1 SYNOPSIS

Non blocking example:

 use strict;
 use warnings;
 use AnyEvent;
 use AnyEvent::FTP::Client;
 
 my $client = AnyEvent::FTP::Client->new( passive => 1);
 
 my $done = AnyEvent->condvar;
 
 # connect to CPAN ftp server
 $client->connect('ftp://ftp.cpan.org/pub/CPAN/src')->cb(sub {
 
   # use binary mode
   $client->type('I')->cb(sub {
       
     # download the file directly into a filehandle
     open my $fh, '>', 'perl-5.16.3.tar.gz';
     $client->retr('perl-5.16.3.tar.gz', $fh)->cb(sub {
       # notify anyone listening to $done that
       # the transfer is complete
       $done->send;
     });
   });
 
 });
 
 # receive the done message once the transfer is
 # complete.  In real code you'd probably not
 # want to do this because your event loop may
 # not support blocking.
 $done->recv;

Same, but using recv to wait for each command to complete (not supported in all event loops):

 use strict;
 use warnings;
 use AnyEvent;
 use AnyEvent::FTP::Client;
 
 my $client = AnyEvent::FTP::Client->new( passive => 1);
 
 my $done = AnyEvent->condvar;
 
 # connect to CPAN ftp server
 $client->connect('ftp://ftp.cpan.org/pub/CPAN/src')->recv;
 
 # use binary mode
 $client->type('I')->recv;
       
 # download the file directly into a filehandle
 open my $fh, '>', 'perl-5.16.3.tar.gz';
 $client->retr('perl-5.16.3.tar.gz', $fh)->recv;

=head1 DESCRIPTION

This class provides an AnyEvent client interface to the File
Transfer Protocol (FTP).

=head1 ROLES

This class consumes these roles:

=over 4

=item *

L<AnyEvent::FTP::Role::Event>

=item *

L<AnyEvent::FTP::Client::Role::ResponseBuffer>

=item *

L<AnyEvent::FTP::Client::Role::RequestBuffer>

=back

=head1 EVENTS

For details on the event interface see L<AnyEvent::FTP::Role::Event>.

=head2 send

This event gets fired on every command sent to the remote server.  Keep
in mind that some methods of L<AnyEvent::FTP> may make multiple FTP commands
in order to implement their functionality (for example, C<recv>, C<stor>, etc).
One use of this event is to print out commands as they are sent for debugging:

 $client->on_send(sub {
   my($cmd, $arguments) = @_;
   $arguments //= '';
   # hide passwords
   $arguments = 'XXXX' if $cmd =~ /^pass$/i;
   say "CLIENT: $cmd $arguments";
 });

=head2 error

This event is emitted when there is a network error with the remote server.
It passes in a string which describes in human readable description of what
went wrong.

 $client->on_error(sub {
   my($message) = @_;
   warn "network error: $message";
 });

=head2 close

This event is emitted when the connection with the remote server is closed,
either due to an error, or when you send the FTP C<QUIT> command using the
C<quid> method.

 $client->on_close(sub {
   # called when connection closed
 });

=head2 greeting

This event gets fired on the first response returned from the server.  This
is usually a C<220> message which may or may not reveal the server software.

 $client->on_greeting(sub {
   # $res is a AnyEvent::FTP::Client::Response
   my($res) = @_;
   if($res->message->[0] =~ /ProFTPD/)
   {
     # detected a ProFTPD server
   }
 });

=head2 each_response

This event gets fired for each response returned from the server.  This can
be useful for printing the responses for debugging.

 $client->on_each_response(sub {
   # $res isa AnyEvent::FTP::Client::Response
   my($res) = @_;
   print "SERVER: $res\n";
 });

=head2 next_response

Works just like C<each_response> event, but only gets fired for the next response
received.

=head1 ATTRIBUTES

=head2 timeout

Timeout for the initial connection to the FTP server.  The default
is 30.

=head2 passive

If set to true (the default) then data will be transferred using the
passive (PASV) command, meaning the server will open a port for the
client to connect to.  If set to false then data will be transferred
using data port (PORT) command, meaning the client will open a port
for the server to send to.

=head1 METHODS

Unless otherwise specified, these methods will return an AnyEvent condition variable
(AnyEvent->condvar) or an object that implements its interface (methods C<recv>, C<cb>).
On success the C<send> will be used on the condition variable, on failure C<croak> will be
used instead.  Unless otherwise specified the object sent (for both success and failure)
will be an instance of L<AnyEvent::FTP::Client::Response>.

As an example, here is a fairly thorough handling of a response to the standard FTP C<HELP>
command:

 $client->help->cb(sub {
   my $res = eval { shift->recv };
   if(my $error = $@)
   {
     # $error isa AnyEvent::FTP::Client::Response with a 4xx or 5xx
     # code
     my $code = $error->code;
     # the message component is always a list ref, even if
     # the response had just one message line
     my @msg  = @{ $error->message };
     # $error is stringified into something human readable when
     # it is streated as a string
     warn "error trying FTP HELP command: $error";
   }
   else
   {
     # $res isa AnyEvent::FTP::Client::Response with a 2xx or 3xx
     # code
     my $code = $res->code;
     # the message component is always a list ref, even if
     # the response had just one message line
     my @msg = @{ $res->message };
     # $res is stringified into something human readable when
     # it is streated as a string
     print "help message: $res";
   }
 });

=head2 connect

 $client->connect(@remote_host);

Connect to the FTP server.  The remote host may be specified in one
of these ways:

=over 4

=item $client-E<gt>connect($host, [ $port ])

The host and port of the remote server.  If not specified, the default FTP port will be used (21).

=item $client-E<gt>connect($uri)

The URI of the remote FTP server.  C<$uri> must be either an instance of L<URI> with the C<ftp>
scheme, or a string with an FTP URL.

If you use this method to connect to the FTP server, connect will also attempt to login with
the username and password specified in the URL (or anonymous FTP if no credentials are
specified).

If there is a path included in the URL, then connect will also do a C<CWD> so that you start
in that directory.

=back

=head2 login

 $client->login($user, $pass);

Attempt to login to the FTP server which has already been connected to using
the C<connect> method.  This is not necessary if you used C<connect> with a URI.

=head2 retr

 $client->retr($filename, $local, %options)

Retrieve the given file from the server and use C<$local> to store the results.

Returns an instance of L<AnyEvent::FTP::Client::Transfer>, which supports the
AnyEvent condition variable interface (that is it has C<cb> and C<recv> methods).
Its callback will be called when the transfer is complete.

C<$local> may be one of

=over 4

=item scalar reference

The contents of the file will be stored in the scalar referred to by the reference.

 my $local;
 $client->retr('foo.txt', \$local);

=item file handle

The content of the remote file will be written into the local file handle as it is
received

 open my $fh, '>', 'foo.txt';
 binmode $fh;
 $client->retr('foo.txt', $fh);

=item the name of the local file

If C<$local> is just a regular non reference scalar, then it will be treated as the
local filename, which will be created and written to as data is received from the
server.

 $client->retr('foo.txt', 'foo.txt');

=item subroutine reference / callback reference

The contents of the file will be passed to the callback as they are received.

 $client->retr('foo.txt', sub {
     my ($data) = @_;
     # Do something with $data
   },
 );

=back

In order to resume a transfer, you need to include the C<restart> option after the
C<$local> argument.  Here is an example:

 # assumes foo.txt (partial download) exists in the current
 # loacal directory and foo.txt (full file) exists in the
 # current remote directory.
 my $filename = 'foo.txt';
 open my $fh, '>>', $filename;
 binmode $fh;
 $client->retr($filename, $fh, restart => tell $fh);

=head2 stor

 $client->stor($filename, $local);

Send a file to the server with the given remote filename (C<$filename>)
and using C<$local> as a source.

Returns an instance of L<AnyEvent::FTP::Client::Transfer>, which supports the
AnyEvent condition variable interface (that is it has C<cb> and C<recv> methods).
Its callback will be called when the transfer is complete.

C<$local> may be one of

=over 4

=item scalar reference

The contents of the file will be retrieved from the scalar referred to by the reference.

 my $local = 'some data for foo.txt';
 $client->stor('foo.txt', \$local);

=item file handle

The contents of the file will be read from the file handle.

 open my $fh, '<', 'foo.txt';
 binmode $fh;
 $client->stor('foo.txt', $fh);

=item the name of the local file

If C<$local> is just a regular non reference scalar, then it will be treated as the
local filename, which will be opened and read from in order to create the file on
the server.

 $client->stor('foo.txt', 'foo.txt');

=back

=head2 stou

 $client->stou($filename, $local)

Works exactly like the C<stor> method, except use the FTP C<STOU> command instead of
C<STOR>.  Since the remote filename is optional for C<STOU> you may pass in C<undef>
as the remote filename.  You can get the remote filename after the fact using the
C<remote_name> method.

 my $xfer;
 $xfer = $client->stou(undef, $local)->cb(sub {
   my $remote_filename = $xfer->remote_name;
 });

=head2 appe

 $client->appe($filename, $local);

Works exactly like the C<stor> method, except use the FTP C<APPE> command instead of
C<STOR>.  This method will append C<$local> to the remote file.  One way to resume an
upload to the remote FTP server would be to open the local file, determine the remote
file's size and seek to that position in the local file and use the C<appe> method
with C<$local> as that file handle, as in this example:

 # assume that foo.txt is in the current local dir
 # and the remote local dir
 my $filename = "foo.txt";
 $client->size($filename)->cb(sub {
   my $size = shift->recv;
   open my $fh, '<', $filename;
   binmode $fh;
   seek $fh, $size, 0;
   $client->appe($filename, $fh);
 });

Note that the C<SIZE> command is an extension to FTP, and may not be available on all
servers.

=head2 list

 $client->list($location)

Execute the FTP C<LIST> command.  The results will be sent as a list reference
(instead of a L<AnyEvent::FTP::Client::Response> object) to the returned condition
variable.

 use strict;
 use warnings;
 use AnyEvent;
 use AnyEvent::FTP::Client;
 
 my $client = AnyEvent::FTP::Client->new;
 
 my $cv = AnyEvent->condvar;
 
 # connect to CPAN ftp server
 $client->connect('ftp://ftp.cpan.org/pub/CPAN/src')->cb(sub {
 
   # execute LIST command and print results to stdout
   $client->list->cb(sub {
     my $list = shift->recv;
     print "$_\n" for @$list;
     $cv->send;
   });
 
 });
 
 $cv->recv;

=head2 nlst

 $client->nlst($location);

Works exactly like the C<list> method, except the FTP C<NLST> command is used.
The main difference is that this method returns filenames only.

=head2 rename

 $client->rename($from, $to);

This method renames the remote file from C<$from> to C<$to>.
It uses the FTP C<RNFR> and C<RNTO> commands and thus this:

 my $cv = $client->rename($from, $to);

is a short cut for:

 my $cv;
 $client->rnfr($from)->cb(sub {
   $cv = $client->rnto($to);
 });

Although C<$cv> may not be defined right away, so use the second with care.

=head2 cwd

 $client->cwd( $dir );

Change to the given directory on the remote server.

=head2 pwd

 $client->pwd;

Gets the current working directory on the remote server.  This gets just the string
representing the directory path instead of a L<AnyEvent::FTP::Client::Response> object.

=head2 cdup

 $client->cdup

Change to the parent directory on the remote server.  This is usually the same
as

 $client->cwd('..');

=head2 type

 $client->type

Set the transfer type.  You almost always want to set to binary mode immediately
after logging on:

 $client->type('I');

=head2 rest

 $client->rest

This command is used to resume a download transfer.  Typically you would
not use this method directly, but instead add a C<restart> option on
the C<retr> method instead.

=head2 mkd

 $client->mkd( $path );

Create a directory on the remote server.

=head2 rmd

 $client->rmd( $path );

Remove a directory on the remote server.

=head2 help

 $client->help;

Gets a list of commands understood by the server.
The actual format depends on the server.

=head2 dele

 $client->dele( $path );

Delete the file on the remote server.

=head2 rnfr

 $client->rnfr;

Specify the old name for renaming a file.  See C<rename> method for a shortcut.

=head2 rnto

 $client->rnto;

Specify the new name for renaming a file.  See C<rename> method for a shortcut.

=head2 noop

 $client->noop;

Don't do anything.  The server will send an OK reply.

=head2 allo

 $client->allo( $size );

Send the FTP C<ALLO> command.  Is not used by modern FTP servers.  See RFC959 for details.

=head2 syst

 $client->syst;

Returns the type of operating system used by the server.

=head2 stru

 $client->stru;

Specify the file structure mode.  This is not used by modern FTP servers.  See RFC959 for details.

=head2 mode

 $client->mode

Specify the transfer mode.  This is not used by modern FTP servers.  See RFC959 for details.

=head2 stat

 $client->stat;
 $client->stat($path);

Get information about a file or directory on the remote server.  The actual format is totally
server dependent.

=head2 user

 $client->user( $username );

Specify the user to login as.  See C<connect> or C<login> methods for a shortcut.

=head2 pass

 $client->pass( $pass );

Specify the password to use for login.  See C<connect> or C<login> methods for a shortcut.

=head2 acct

 $client->acct( $acct );

Specify user's account.  This is sometimes used for authentication and authorization when you login
to some servers, but is seldom used today in practice.  See RFC959 for details.

=head2 size

 $client->size( $path );

Get the size of the remote file specified by C<$path>.  This is an extension to the FTP
standard specified in RFC3659, and may not be implemented by older (or even newer)
servers.

Send the size of the file on success, instead of the response object.

=head2 mdtm

 $client->mdtm( $path );

Get the modification time of the remote file specified by C<$path>.  This is an extension to the FTP standard
specified in RFC3659, and may not be implemented by older (or even newer) servers.

=head2 quit

 $client->quit;

Send the FTP C<QUIT> command and close the connection to the remote server.

=head2 site

 $client->site;

The C<site> method provides an interface to site specific FTP commands.  Many
FTP servers will support an extended set of commands using the standard FTP
C<SITE> command.  This command will not check to see if the site commands are
supported by the remote server, so it is up to you to determine if you can
really use these interfaces yourself.

=over 4

=item $client-E<gt>site-E<gt>microsoft

For commands specific to Microsoft's IIS FTP server.
See L<AnyEvent::FTP::Client::Site::Microsoft>.

=item $client-E<gt>site-E<gt>net_ftp_server

For commands specific to L<Net::FTPServer>.
See L<AnyEvent::FTP::Client::Site::NetFtpServer>.

=item $client-E<gt>site-E<gt>proftpd

For commands specific to proftpd.
See L<AnyEvent::FTP::Client::Site::Proftpd>.

=back

=head1 EXAMPLES

Here are some longer examples.  They are also included with the
L<AnyEvent::FTP> distribution in its C<example> directory.

=head2 fget.pl

Given a URL to a file, this script will fetch the file and store it
on your local machine.  If you use the C<-d> option you can see the
FTP commands and their responses as they happen.

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use autodie;
 use 5.010;
 use AnyEvent::FTP::Client;
 use URI;
 use URI::file;
 use Term::ProgressBar;
 use Term::Prompt qw( prompt );
 use Getopt::Long qw( GetOptions );
 use Path::Class qw( file );
 
 my $debug = 0;
 my $progress = 0;
 my $active = 0;
 
 GetOptions(
   'd' => \$debug,
   'p' => \$progress,
   'a' => \$active,
 );
     
 my $remote = shift;
 
 unless(defined $remote)
 {
   say STDERR "usage: perl fget.pl [ -d | -p ] [ -a ] remote";
   say STDERR "  where remote is a URL for a file on an FTP server";
   say STDERR "  and local is a local filename (optional) where to transfer it to";
   say STDERR "  -d (optional) prints FTP commands and responses";
   say STDERR "  -p (optional) displays a progress bar as the file uploads";
   say STDERR "  -a (optional) use active mode transfer";
   exit 2;
 }
 
 $remote = URI->new($remote);
 
 unless($remote->scheme eq 'ftp')
 {
   say STDERR "only FTP URLs are supported";
   exit 2;
 }
 
 unless(defined $remote->password)
 {
   $remote->password(prompt('p', 'Password: ', '', ''));
   say '';
 }
 
 do {
   my $from = $remote->clone;
   $from->password(undef);
   
   say "SRC: ", $from;
 };
 
 my @path = split /\//, $remote->path;
 my $fn = pop @path;
 if(-e $fn)
 {
   say STDERR "local file already exists";
   exit 2;
 }
 
 my $ftp = AnyEvent::FTP::Client->new( passive => $active ? 0 : 1 );
 
 $ftp->on_send(sub {
   my($cmd, $arguments) = @_;
   $arguments //= '';
   $arguments = 'XXXX' if $cmd eq 'PASS';
   say "CLIENT: $cmd $arguments"
     if $debug;
 });
 
 $ftp->on_each_response(sub {
   my $res = shift;
   if($debug)
   {
     say sprintf "SERVER: [ %d ] %s", $res->code, $_ for @{ $res->message };
   }
 });
 
 $ftp->connect($remote->host, $remote->port)->recv;
 $ftp->login($remote->user, $remote->password)->recv;
 $ftp->type('I')->recv;
 
 $ftp->cwd(join '/', '', @path)->recv;
 
 my $remote_size;
 
 if($progress)
 {
   my $listing = $ftp->list($fn)->recv;
   foreach my $class (qw( File::Listing File::Listing::Ftpcopy ))
   {
     my $parsed_listing = eval qq{ use $class; ${class}::parse_dir(\$listing->[0]) };
     next if $@;
     my ($name, $type, $size, $mtime, $mode) = @{ $parsed_listing->[0] };
     $remote_size = $size;
     last;
   }
   
   if(defined $remote_size)
   {
   }
   else
   {
     say STDERR "could not determine size of remote file, cannot provide progress bar";
     $progress = 0;
   }
 }
 
 open my $fh, '>', $fn;
 
 my $xfer = $ftp->retr($fn);
 my $pb;
 my $count = 0;
 
 $xfer->on_open(sub {
   my $handle = shift;
   $pb = Term::ProgressBar->new({ count => $remote_size })
     if $progress;
   $handle->on_read(sub {
     $handle->push_read(sub {
       print $fh $_[0]{rbuf};
       $pb->update($count += length($_[0]{rbuf})) if $pb;
       $_[0]{rbuf} = '';
     });
   });
 });
 
 $xfer->recv;
 
 close $fh;
 
 $ftp->quit->recv;

=head2 fls.pl

Here is a similar example, which does a directory listing on a FTP
directory URL.  If you use the C<-d> option to see the FTP commands
and their responses as they happen.  You can use the C<-l> option
to see the long form of the file listing.

 use strict;
 use warnings;
 use 5.010;
 use URI;
 use AnyEvent::FTP::Client;
 use Term::Prompt qw( prompt );
 use Getopt::Long qw( GetOptions );
 
 my $debug = 0;
 my $method = 'nlst';
 
 GetOptions(
   'd' => \$debug,
   'l' => sub { $method = 'list' },
 );
 
 my $ftp = AnyEvent::FTP::Client->new;
 
 if($debug)
 {
   $ftp->on_send(sub {
     my($cmd, $arguments) = @_;
     $arguments //= '';
     $arguments = 'XXXX' if $cmd eq 'PASS';
     say "CLIENT: $cmd $arguments";
   });
 
   $ftp->on_each_response(sub {
     my $res = shift;
     say sprintf "SERVER: [ %d ] %s", $res->code, $_ for @{ $res->message };
   });
 
 }
 
 my $uri = shift;
 
 unless(defined $uri)
 {
   say STDERR "usage: perl fls.pl URL\n";
   exit 2;
 }
 
 $uri = URI->new($uri);
 
 unless($uri->scheme eq 'ftp')
 {
   say STDERR "only FTP URL accpeted";
   exit 2;
 }
 
 unless(defined $uri->password)
 {
   $uri->password(prompt('p', 'Password: ', '', ''));
   say '';
 }
 
 my $path = $uri->path;
 $uri->path('');
 
 $ftp->connect($uri);
 
 say $_ for @{ $ftp->$method($path)->recv };

=head2 fput.pl

This script uploads a local file to the remote given a local filename
and a remote FTP URL.

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use autodie;
 use 5.010;
 use AnyEvent::FTP::Client;
 use URI;
 use URI::file;
 use Term::ProgressBar;
 use Term::Prompt qw( prompt );
 use Getopt::Long qw( GetOptions );
 use Path::Class qw( file );
 
 my $debug = 0;
 my $progress = 0;
 my $active = 0;
 
 GetOptions(
   'd' => \$debug,
   'p' => \$progress,
   'a' => \$active,
 );
 
 my $local = shift;
 my $remote = shift;
 
 unless(defined $local && defined $remote)
 {
   say STDERR "usage: perl fput.pl [ -d | -p ] [ -a ] local remote";
   say STDERR "  where local is a local file";
   say STDERR "  and remote is a URL for a FTP server";
   say STDERR "  -d (optional) prints FTP commands and responses";
   say STDERR "  -p (optional) displays a progress bar as the file uploads";
   say STDERR "  -a (optional) use an active transfer instead of passive";
   exit 2;
 }
 
 $local  = file($local);
 $remote = URI->new($remote);
 
 unless($remote->scheme eq 'ftp')
 {
   say STDERR "only FTP URLs are supported";
   exit 2;
 }
 
 unless(defined $remote->password)
 {
   $remote->password(prompt('p', 'Password: ', '', ''));
   say '';
 }
 
 do {
   my $from = URI::file->new_abs($local);
   my $to = $remote->clone;
   $to->password(undef);
   
   say "SRC: ", $from;
   say "DST: ", $to;
 };
 
 my $ftp = AnyEvent::FTP::Client->new( passive => $active ? 0 : 1 );
 
 $ftp->on_send(sub {
   my($cmd, $arguments) = @_;
   $arguments //= '';
   $arguments = 'XXXX' if $cmd eq 'PASS';
   say "CLIENT: $cmd $arguments"
     if $debug;
 });
 
 $ftp->on_each_response(sub {
   my $res = shift;
   if($debug)
   {
     say sprintf "SERVER: [ %d ] %s", $res->code, $_ for @{ $res->message };
   }
 });
 
 
 $ftp->connect($remote->host, $remote->port)->recv;
 $ftp->login($remote->user, $remote->password)->recv;
 $ftp->type('I')->recv;
 
 if(defined $remote->path)
 {
   $ftp->cwd($remote->path)->recv;
 }
 
 open my $fh, '<', $local;
 binmode $fh;
 
 my $buffer;
 my $count;
 
 my $pb;
 
 my $xfer = $ftp->stor($local->basename);
 
 $xfer->on_open(sub {
   my $whandle = shift;
   $pb = Term::ProgressBar->new({ count => -s $fh })
     if $progress;
   $whandle->on_drain(sub {
     $pb->update($count) if $pb;
     my $ret = read $fh, $buffer, 1024 * 512;
     $count += $ret;
     if($ret > 0)
     {
       $whandle->push_write($buffer);
     }
     else
     {
       $pb->update($count) if $pb;
       $whandle->push_shutdown;
       close $fh;
     }
   });
 });
 
 $xfer->recv;
 
 $ftp->quit->recv;

=head1 SEE ALSO

=over 4

=item *

L<AnyEvent::FTP>

=item *

L<AnyEvent::FTP::Server>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
