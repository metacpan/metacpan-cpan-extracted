# connect_front, or priority level
# message length limit



# Copyright 2007, 2008, 2009, 2010, 2015 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Glib::Ex::DirBroadcast;
use 5.008;
use strict;
use warnings;
use Carp 'carp','croak';
use File::Spec;

use Class::Singleton 1.03; # 1.03 for _new_instance()
use base 'Class::Singleton';
*_new_instance = \&new;

use constant MAXLEN => 16384;


sub new {
  my ($class, $directory) = @_;
  return bless { directory => $directory }, $class;
}

sub DESTROY {
  my ($self) = @_;
  delete $self->{'listen_source_ids'};
  # close socket before removing file
  delete $self->{'listen_sock'};
  if (my $filename = delete $self->{'listen_filename'}) {
    ### DirBroadcast remove: $filename
    unlink ($filename);
  }
}

sub directory {
  my ($self, $newval) = @_;
  ref($self) or $self = $self->instance;

  if (@_ < 2) { return $self->{'directory'}; }
  if ($self->{'listen_source_ids'}) {
    croak 'DirBroadcast: cannot set directory after listen';
  }
  $self->{'directory'} = $newval;
}

# connections is a hashref of key to arrayref of subrs, ie.
#
#   $self->{'connections'} = { 'foo' => [ \&handler1, \&handler2 ],
#                              'bar' => [ \&handler3, \&handler4 ] };
#
sub connect {
  my ($self, $key, $subr) = @_;
  ref($self) or $self = $self->instance;

  my $aref = ($self->{'connections'}->{$key} ||= []);
  push @$aref, $subr;
}
sub connect_first {
  my ($self, $key, $subr) = @_;
  ref($self) or $self = $self->instance;
  my $aref = ($self->{'connections'}->{$key} ||= []);
  unshift @$aref, $subr;
}

sub connect_for_object {
  my ($self, $key, $subr, $obj) = @_;
  ref($self) or $self = $self->instance;

  require Scalar::Util;
  Scalar::Util::weaken ($obj);
  my $csubr;
  $csubr = sub {
    if ($obj) {
      $subr->($obj, @_);
    } else {
      _disconnect ($self, $key, $csubr);
    }
  };
  $self->connect ($key, $csubr);
}

sub _disconnect {
  my ($self, $key, $subr) = @_;
  if (my $aref = $self->{'connections'}->{$key}) {
    @$aref = grep {$_ != $subr} @$aref;
  }
}

sub send_locally {
  my ($self, $key, @data) = @_;
  ref($self) or $self = $self->instance;

  if ($self->{'hold'}) {
    push @{$self->{'hold_list'}}, sub { send_locally ($self, $key, @data); };

  } else {
    if (my $aref = $self->{'connections'}->{$key}) {
      foreach my $subr (@$aref) {
        $subr->(@data);
      }
    }
  }
}

sub listen {
  my ($self) = @_;
  ref($self) or $self = $self->instance;

  if ($self->{'listen_source_ids'}) { return; }  # already done
  my $directory = $self->{'directory'};
  if (! defined $directory) {
    croak 'DirBroadcast cannot listen until broadcast directory is set';
  }

  require File::Path;
  File::Path::mkpath ($directory);

  require Sys::Hostname;
  my $hostname = Sys::Hostname::hostname();
  my $listen_filename = $self->{'listen_filename'}
    = File::Spec->catfile ($directory, "$hostname.$$");
  unlink ($listen_filename);  # possible previous leftover

  # as usual socket() and friends get FD_CLOEXEC set automatically, no need
  # to do anything special to avoid propagating $listen_sock fd down to
  # subprocess jobs
  require Socket;
  require IO::Socket;
  my $listen_sock = $self->{'listen_sock'}
    = do { local $^F = 0; # ensure close-on-exec for the socket
           IO::Socket->new (Domain => Socket::AF_UNIX(),
                            Type   => Socket::SOCK_DGRAM(),
                            Local  => $listen_filename) };
  binmode ($listen_sock, ':raw') or die;
  ### DirBroadcast listen: $listen_filename, $listen_sock->fileno

  require Glib;
  require App::Chart::Glib::Ex::MoreUtils;
  require Glib::Ex::SourceIds;

  $self->{'listen_source_ids'}
    = Glib::Ex::SourceIds->new
      (Glib::IO->add_watch ($listen_sock->fileno,
                            ['in', 'hup', 'err'],
                            \&_do_listen_read,
                            App::Chart::Glib::Ex::MoreUtils::ref_weak($self)));
}

sub _do_listen_read {
  my ($fd, $conditions, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return 0; # Glib::SOURCE_REMOVE

  ### DirBroadcast read: $fd, $conditions
  my $buf;
  my $ret = $self->{'listen_sock'}->recv ($buf, MAXLEN, 0);
  if (! defined $ret) {
    warn __PACKAGE__." listen read error: $!";
    delete $self->{'listen_source_ids'};
    delete $self->{'listen_sock'};
    return 0; # Glib::SOURCE_REMOVE
  }
  ### receive: " bytes=".length($buf), "'$ret'"
  require Storable;
  my $args;
  if (! eval { $args = Storable::thaw ($buf); 1 }) {
    carp "DirBroadcast: error thawing message, ignoring";
    return 1; # Glib::SOURCE_CONTINUE
  }

  ### $args
  $self->send_locally (@$args);
  return 1; # Glib::SOURCE_CONTINUE
}

my $send_sock;

sub send {
  my ($self, $key, @data) = @_;
  ref($self) or $self = $self->instance;

  if ($self->{'hold'}) {
    ### send hold back: $key
    push @{$self->{'hold_list'}}, sub { $self->send ($key, @data); };
    return;
  }
  #### send: $key, \@data

  $self->send_locally ($key, @data);

  my $directory = $self->{'directory'};
  require IO::Dir;
  my $dh = IO::Dir->new ($directory) || return;
  my @filenames = $dh->read;
  $dh->close;

  my $pattern = ($self->{'pattern'} ||= do {
    require Sys::Hostname;
    my $hostname = Sys::Hostname::hostname();
    qr/^\Q$hostname\E\.[0-9]+$/o
  });

  my $frozen;
  foreach my $filename (@filenames) {
    if ($filename !~ $pattern) { next; }
    $filename = File::Spec->catfile ($directory, $filename);

    if ($filename eq ($self->{'listen_filename'}||'')) {
      next;  # ourselves
    }
    ### DirBroadcast to: $filename

    # send_sock created on first of any DirBroadcast instance and then kept
    # open
    $send_sock ||= do {
      require IO::Socket;
      require Socket;
      my $sock = do {
        local $^F = 0; # ensure close-on-exec for the socket
        IO::Socket->new (Domain => Socket::AF_UNIX(),
                         Type   => Socket::SOCK_DGRAM());
      };
      $sock->blocking(0);
      binmode ($sock, ':raw') or die;
      $sock
    };

    # put off freezing until we find someone to send to
    if (! defined $frozen) {
      require Storable;
      $frozen = Storable::freeze ([$key, @data]);
      if (length ($frozen) > MAXLEN) {
        croak 'DirBroadcast: message too long: ',length($frozen);
      }
    }

    my $sun = Socket::sockaddr_un ($filename);
    my $sent = $send_sock->send ($frozen, 0, $sun);
    if (! defined $sent || $sent != length($frozen)) {
      ### send: (! defined $sent && "removing, error $!") || "removing, short send $sent bytes"
      unlink ($filename);
    }
  }
}

sub hold {
  my ($self) = @_;
  ref($self) or $self = $self->instance;
  return App::Chart::Glib::Ex::DirBroadcast::Hold->new ($self);
}

package App::Chart::Glib::Ex::DirBroadcast::Hold;
use strict;
use warnings;

sub new {
  my ($class, $dirb) = @_;
  my $self = bless { }, $class;
  $self->{'target'} = $dirb;
  require Scalar::Util;
  Scalar::Util::weaken ($self->{'target'});
  $dirb->{'hold'} ++;
  return $self;
}

sub DESTROY {
  my ($self) = @_;
  my $dirb = delete $self->{'target'} || return;
  if (-- $dirb->{'hold'}) { return; }

  my $hold_list = $dirb->{'hold_list'};
  ### DirBroadcast::Hold now run: $hold_list
  while (my $subr = shift @$hold_list) {
    $subr->();
  }
}

1;
__END__

=head1 NAME

App::Chart::Glib::Ex::DirBroadcast -- broadcast messages through a directory of named pipes

=head1 SYNOPSIS

 use App::Chart::Glib::Ex::DirBroadcast;
 App::Chart::Glib::Ex::DirBroadcast->directory ('/my/directory');
 App::Chart::Glib::Ex::DirBroadcast->listen;

 App::Chart::Glib::Ex::DirBroadcast->connect ('my-key', sub { print @_; });

 App::Chart::Glib::Ex::DirBroadcast->send ('my-key', "hello\n");

=head1 DESCRIPTION

DirBroadcast is a message broadcasting system based on named pipes in a
given directory, with a Glib main loop IO watch listening and calling
connected handlers.  It's intended for use between multiple running copies
of a single application so they can notify each other of changes to files
etc.

Messages have a string "key" which is a name or type decided by the
application, and then any parameters which Storable can handle
(L<Storable>).  You can have either a single broadcast directory used for
all purposes, or create multiple DirBroadcast objects.  The method functions
described below take either the class name C<App::Chart::Glib::Ex::DirBroadcast> for the
single global, or a DirBroadcast object.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Glib::Ex::DirBroadcast->new ($directory) >>

Create and return a new DirBroadcast object communicating through the given
C<$directory>.  C<$directory> is created if it doesn't already exist (with a
C<croak> if that fails).

    my $dirb = App::Chart::Glib::Ex::DirBroadcast->new ('/var/run/myapp')

=item C<< App::Chart::Glib::Ex::DirBroadcast->directory ($directory) >>

=item C<< App::Chart::Glib::Ex::DirBroadcast->directory () >>

=item C<< $dirb->directory ($directory) >>

=item C<< $dirb->directory () >>

Get or set the filesystem directory used for broadcasts.

=item C<< App::Chart::Glib::Ex::DirBroadcast->send ($key, $data, ...) >>

=item C<< App::Chart::Glib::Ex::DirBroadcast->send_locally ($key, $data, ...) >>

=item C<< $dirb->send ($key, $data, ...) >>

=item C<< $dirb->send_locally ($key, $data, ...) >>

Send a message of C<$key> and optional C<$data> values.  C<send> broadcasts
to all processes, including the current process, or C<send_locally> just to
the current process.

A send within the current process just means direct calls to functions
registered by C<connect> below.  This takes place immediately within the
C<send> or C<send_locally>, there's no queuing and the current process
doesn't have to have a C<listen> active.

The data values can be anything C<Storable> can freeze (see L<Storable>).
For C<send_locally> there's no copying, the values are simply passed to the
connected functions, so the values can be anything at all.

=item C<< App::Chart::Glib::Ex::DirBroadcast->listen () >>

=item C<< $dirb->listen () >>

Create a named pipe in the broadcast directory to receive messages from
other processes, and setup a C<< Glib::IO->add_watch >> to call the
functions registered with C<connect> when a message is received.

=item C<< App::Chart::Glib::Ex::DirBroadcast->connect ($key, $subr) >>

=item C<< $dirb->connect ($key, $subr) >>

Connect coderef C<$subr> to be called for messages of C<$key>.  The
arguments to C<$subr> are the data values passed to C<send>.

=item C<< App::Chart::Glib::Ex::DirBroadcast->connect_for_object ($key, $objsubr, $obj) >>

=item C<< $dirb->connect_for_object ($key, $osubr, $obj) >>

Connect coderef C<$osubr> to be called for notifications of C<$key>, for as
long as Perl object C<$obj> exists.  C<$obj> is the first argument in each
call, followed by the notify data,

    sub my_func {
      my ($obj, $data...) = @_;
    }

If C<$obj> is destroyed then C<$osubr> is no longer called.  Only a weak
reference to C<$obj> is kept, so just because it wants to hear about some
notifications it won't keep it alive forever.

=back

=head1 SEE ALSO

L<Glib>, L<Glib::MainLoop>

=cut
