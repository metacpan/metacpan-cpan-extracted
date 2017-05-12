package Apache::Session::Counted;
use Apache::Session::Serialize::Storable;

use strict;
use vars qw(@ISA);
@ISA = qw(Apache::Session);
use vars qw($VERSION $RELEASE_DATE);
$VERSION = sprintf "%d.%03d", q$Revision: 1.118 $ =~ /(\d+)\.(\d+)/;
$RELEASE_DATE = q$Date: 2002/04/15 12:39:07 $;

use Apache::Session 1.50;
use File::CounterFile;

{
  package Apache::Session::CountedStore;
  use Symbol qw(gensym);

  use strict;

  sub new { bless {}, shift }

  # write. Note that we alias insert and update
  sub update {
    my $self    = shift;
    my $session = shift;
    my $storefile = $self->storefilename($session);
    my $fh = gensym;
    unless ( open $fh, ">$storefile\0" ) {
      warn qq{A:S:Counted: Could not open file $storefile for writing: $!
Maybe you haven't initialized the storage directory with
 use Apache::Session::Counted;
 Apache::Session::CountedStore->tree_init("$session->{args}{Directory}","$session->{args}{DirLevels}");
I'm trying to band-aid by creating this directory};
      require File::Basename;
      my $dir = File::Basename::dirname($storefile);
      require File::Path;
      File::Path::mkpath($dir);
      warn "A:S:Counted: mkdir on directory $dir successfully done.";
    }
    if ( open $fh, ">$storefile\0" ) {
      print $fh $session->{serialized}; # $fh->print might fail in some perls
      close $fh;
    } else {
      die "Giving up. Could not open file $storefile for writing: $!";
    }
  }
  *insert = \&update;

  # retrieve
  sub materialize {
    my $self    = shift;
    my $session = shift;
    my $sessionID = $session->{data}{_session_id} or die "Got no session ID";
    my($host) = $sessionID =~ /(?:([^:]+)(?::))/;
    my($content);

    if ($host &&
        $session->{args}{HostID} &&
        $session->{args}{HostID} ne $host
       ) {
      # warn sprintf("configured hostID[%s]host from argument[%s]",
      #              $session->{args}{HostID},
      #              $host);
      my $surl;
      if (exists $session->{args}{HostURL}) {
        $surl = $session->{args}{HostURL}->($host,$sessionID);
      } else {
        $surl = sprintf "http://%s/?SESSIONID=%s", $host, $sessionID;
      }
      # warn "surl[$surl]";
      if ($surl) {
        require LWP::UserAgent;
        require HTTP::Request::Common;
        my $ua = LWP::UserAgent->new;
        $ua->timeout($session->{args}{Timeout} || 10);
        my $req = HTTP::Request::Common::GET $surl;
        my $result = $ua->request($req);
        if ($result->is_success) {
          $content = $result->content;
        } else {
          $content = Storable::nfreeze {};
        }
      } else {
        $content = Storable::nfreeze {};
      }
      $session->{serialized} = $content;
      return;
    }

    my $storefile = $self->storefilename($session);
    my $fh = gensym;
    if ( open $fh, "<$storefile\0" ) {
      local $/;
      $session->{serialized} = <$fh>;
      close $fh or die $!;
      if ($content && $content ne $session->{serialized}) {
        warn "A:S:Counted: content and serialized are NOT equal";
        require Dumpvalue;
        my $dumper = Dumpvalue->new;
        $dumper->set(unctrl => "quote");
        warn sprintf "A:S:Counted: content[%s]serialized[%s]",
            $dumper->stringify($content),
                $dumper->stringify($session->{serialized});
      }
    } else {
      warn "A:S:Counted: Could not open file $storefile for reading: $!";
      $session->{data} = {};
      $session->{serialized} = $session->{serialize}->($session);
    }
  }

  sub remove {
    warn "A:S:Counted: remove not implemented"; # doesn't make sense
                                                # for our concept of a
                                                # session
    return;

    my $self    = shift;
    my $session = shift;
    my $storefile = $self->storefilename($session);
    unlink $storefile or
        warn "A:S:Counted: Object $storefile does not exist in the data store";
  }

  sub tree_init {
    my $self    = shift;
    my $dir = shift;
    my $levels = shift;
    my $n = 0x100 ** $levels;
    warn "A:S:Counted: Creating directory $dir
 and $n subdirectories in $levels level(s)\n";
    warn "A:S:Counted: This may take a while\n" if $levels>1;
    require File::Path;
    $|=1;
    my $feedback =
        sub {
          $n--;
          printf "\r$n directories left             " unless $n % 256;
          print "\n" unless $n;
        };
    File::Path::mkpath($dir);
    make_dirs($dir,$levels,$feedback); # function for speed
  }

  sub make_dirs {
    my($dir, $levels, $feedback) = @_;
    $levels--;
    for (my $i=0; $i<256; $i++) {
      my $subdir = sprintf "%s/%02x", $dir, $i;
      -d $subdir or mkdir $subdir, 0755 or die "Couldn't mkdir $subdir: $!";
      $feedback->();
      make_dirs($subdir, $levels, $feedback) if $levels;
    }
  }

  sub storefilename {
    my $self    = shift;
    my $session = shift;
    die "The argument 'Directory' for object storage must be passed as an argument"
       unless defined $session->{args}{Directory};
    my $dir = $session->{args}{Directory};
    my $levels = $session->{args}{DirLevels} || 0;
    # here we depart from TreeStore:
    my $sessionID = $session->{data}{_session_id} or die "Got no session ID";
    my($host,$file) = $sessionID =~ /(?:([^:]+)(?::))?([\da-f]+)/;
    die "Too short ID part '$file' in session ID'" if length($file)<8;
    while ($levels) {
      $file =~ s|((..){$levels})|$1/|;
      $levels--;
    }
    "$dir/$file";
  }
}

# Counted is locked by definition
sub release_all_locks {
  return;
}

*get_lock_manager = \&release_all_locks;
*release_read_lock = \&release_all_locks;
*release_write_lock = \&release_all_locks;
*acquire_read_lock = \&release_all_locks;
*acquire_write_lock = \&release_all_locks;

sub TIEHASH {
  my $class = shift;

  my $session_id = shift;
  my $args       = shift || {};

  my $self = {
              args         => $args,

              data         => { _session_id => $session_id },
              # we always *have* read and write lock and need not care
              lock         => Apache::Session::READ_LOCK|Apache::Session::WRITE_LOCK,
              status       => 0,
              lock_manager => undef,
              generate     => undef,
              serialize    => \&Apache::Session::Serialize::Storable::serialize,
              unserialize  => \&Apache::Session::Serialize::Storable::unserialize,
            };

  bless $self, $class;
  $self->{object_store} = Apache::Session::CountedStore->new($self);

  #If a session ID was passed in, this is an old hash.
  #If not, it is a fresh one.

  if (defined $session_id) {
    $self->make_old;
    $self->restore; # calls materialize and unserialize via Apache::Session
    if (
        exists $self->{data} &&
        exists $self->{data}{_session_id} &&
        defined $self->{data}{_session_id} && # protect agains unini warning
        $session_id eq $self->{data}{_session_id}
       ) {
      # Fine. Validated. Kind of authenticated.
      # ready for a new session ID, keeping state otherwise.
      $self->make_modified if $self->{args}{AlwaysSave};
    } else {
      # oops, somebody else tried this ID, don't show him data.
      delete $self->{data};
      $self->make_new;
    }
  }
  # if we have no counterfile, we cannot generate an ID, that's OK:
  # this session will not need to be written.
  $self->{data}->{_session_id} = $self->generate_id() if
      $self->{args}{CounterFile};
  # no make_new here, session-ID doesn't count as data

  return $self;
}

sub generate_id {
  my $self = shift;
  # wants counterfile
  my $cf = $self->{args}{CounterFile} or
      die "Argument CounterFile needed in the attribute hash to the tie";
  my $c;
  eval { $c = File::CounterFile->new($cf,"0"); };
  if ($@) {
    warn "A:S:Counted: Counterfile problem, trying to repair...";
    if (-e $cf) {
      warn "A:S:Counted: Retrying after removing $cf.";
      unlink $cf; # May fail. stupid enough that we are here.
      $c = File::CounterFile->new($cf,"0");
    } else {
      require File::Basename;
      my $dirname = File::Basename::dirname($cf);
      my @mkdir;
      while (! -d $dirname) {
        push @mkdir, $dirname;
        $dirname = File::Basename::dirname($dirname);
      }
      while (@mkdir) {
        my $dirname = pop @mkdir;
        mkdir $dirname, 0755 or die "Couldn't mkdir $dirname. Please create it with appropriate permissions";
      }
      $c = File::CounterFile->new($cf,"0");
    }
    warn "A:S:Counted: Counterfile problem successfully reapired.";
  }
  my $rhexid = sprintf "%08x", $c->inc;
  my $hexid = scalar reverse $rhexid; # optimized for treestore. Not
                                      # everything in one directory

  # we have entropy as bad as rand(). Typically not very good.
  my $password = sprintf "%08x%08x", rand(0xffffffff), rand(0xffffffff);

  if (exists $self->{args}{HostID}) {
    return sprintf "%s:%s_%s", $self->{args}{HostID}, $hexid, $password;
  } else {
    return $hexid . "_" . $password;
  }
}

1;

=head1 NAME

Apache::Session::Counted - Session management via a File::CounterFile

=head1 SYNOPSIS

 tie %s, 'Apache::Session::Counted', $sessionid, {
                                Directory => <root of directory tree>,
                                DirLevels => <number of dirlevels>,
                                CounterFile => <filename for File::CounterFile>,
                                AlwaysSave => <boolean>,
                                HostID => <string>,
                                HostURL => <callback>,
                                Timeout => <seconds>,
                                                 }

=head1 DESCRIPTION

This session module is based on Apache::Session, but it persues a
different notion of a session, so you probably have to adjust your
expectations a little.

The dialog that is implemented within an HTTP based application is a
nonlinear chain of events. The user can decide to use the back button
at any time without informing the application about it. A proper
session management must be prepared for this and must maintain the
state of every single event. For handling the notion of a session and
the notion of a registered user, the application has to differentiate
carefully between global state of user data and a user's session
related state. Some data may expire after a day, others may be
regarded as unexpirable. This module is solely responsible for
handling session related data. Saving unexpirable user related data
must be handled by the calling application.

In Apache::Session::Counted, a session-ID only lasts from one request
to the next at which point a new session-ID is computed by the
File::CounterFile module. Thus what you have to treat differently than
in Apache::Session are those parts that rely on the session-ID as a
fixed token per user. Accordingly, there is no option to delete a
session. The remove method is simply disabled as old session data will
be overwritten as soon as the counter is reset to zero.

The usage of the module is via a tie as described in the synopsis. The
arguments have the following meaning:

=over

=item Directory, DirLevels

Works similar to filestore but as most file systems are slow on large
directories, works in a tree of subdirectories.

=item CounterFile

A filename to be used by the File::CounterFile module. By changing
that file or the filename periodically, you can achieve arbitrary
patterns of key generation. If you do not specify a CounterFile, you
promise that in this session there is no need to generate a new ID and
that the whole purpose of this object is to retrieve previously stored
session data. Thus no new session file will be written. If you break
your promise and write something to the session hash, the retrieved
session file will be overwritten.

=item AlwaysSave

A boolean which, if true, forces storing of session data in any case.
If false, only a STORE, DELETE or CLEAR trigger that the session file
will be written when the tied hash goes out of scope. This has the
advantage that you can retrieve an old session without storing its
state again.

=item HostID

A string that serves as an identifier for the host we are running on.
This string will become part of the session-ID and must not contain a
colon. This can be used in a cluster environment so that a load
balancer or other interested parties can retrieve the session data
again.

=item HostURL

A callback that returns the service URL that can be called to get at
the session data from another host. This is needed in a cluster
environment. Two arguments are passed to this callback: HostID and
Session-ID. The URL must return the serialized data in Storable's
nfreeze format. The Apache::Session::Counted module can be used to set
such an URL up. If HostURL is not defined, the default is

    sprintf "http://%s/?SESSIONID=%s", <host>, <session-ID>;

The callback can return false to signal that there is no session to
retrieve (e.g. when the host or id argument is illegal).

=item Timeout

Sets the timeout for LWP::UserAgent for retrieving a session from a
different host. Default is 10 seconds.

=back

=head2 What this model buys you

=over

=item storing state selectively

You need not store session data for each and every request of a
particular user. There are so many CGI requests that can easily be
handled with two hidden fields and do not need any session support on
the server side, and there are others where you definitely need
session support. Both can appear within the same application.
Apache::Session::Counted allows you to switch session writing on and
off during your application without effort. (In fact, this advantage
is shared with the clean persistence model of Apache::Session)

=item keeping track of transactions

As each request of a single user remains stored until you restart the
counter, there are all previous states of a single session close at
hand. The user presses the back button 5 times and changes a decision
and simply opens a new branch of the same session. This can be an
advantage and a disadvantage. I tend to see it as a very strong
feature. Your milage may vary.

=item counter

You get a counter for free which you can control just like
File::CounterFile (because it B<is> File::CounterFile).

=item cleanup

Your data storage area cleans up itself automatically. Whenever you
reset your counter via File::CounterFile, the storage area in use is
being reused. Old files are being overwritten in the same order they
were written, giving you a lot of flexibility to control session
storage time and session storage disk space.

=item performance

The notion of daisy-chained sessions simplifies the code of the
session handler itself quite a bit and it is likely that this
simplification results in an improved performance (not tested yet due
to lack of benchmarking apps for sessions). There are less file stats
and less sections that need locking, but without real world figures,
it's hard to tell.

=back

As with other modules in the Apache::Session collection, the tied hash
contains a key C<_session_id>. You must be aware that the value of this
hash entry is not the same as the one you passed in when you retrieved
the session (if you retrieved a session at all). So you have to make
sure that you send your users a new session-id in each response, and
that this is never the old one.

As an implemenation detail it may be of interest to you, that the
session ID in Apache::Session::Counted consists of two or three parts:
an optional host alias given by the HostID paramter, followed by a
colon. Then an ordinary number which is a simple counter which is
followed by an underscore. And finally a session-ID like the one in
Apache::Session. The number part is used as an identifier of the
session and the ID part is used as a password. The number part is
easily predictable, but the second part is reasonable unpredictable.
We use the first part for implementation details like storage on the
disk and the second part to verify the ownership of that token.

=head1 PREREQUISITES

Apache::Session::Counted needs Apache::Session and File::CounterFile,
all available from the CPAN. The HostID and HostURL parameters for a
cluster solution need LWP installed.

=head1 EXAMPLES

The following example resets the counter every 24 hours and keeps the
totals of every day as a side effect:

  my(@t) = localtime;
  tie %session, 'Apache::Session::Counted', $sid,
  {
   Directory => ...,
   DirLevels => ...,
   CounterFile => sprintf("/some/dir/%04d-%02d-%02d", $t[5]+1900,$t[4]+1,$t[3])
  };


The same effect can be accomplished with a fixed filename and an
external cronjob that resets the counter like so:

  use File::CounterFile;
  $c=File::CounterFile->new("/usr/local/apache/data/perl/sessiondemo/counter");
  $c->lock;
  $c-- while $c>0;
  $c->unlock;


=head1 AUTHOR

Andreas Koenig <andreas.koenig@anima.de>

=head1 COPYRIGHT

This software is copyright(c) 1999-2002 Andreas Koenig. It is free
software and can be used under the same terms as perl, i.e. either the
GNU Public Licence or the Artistic License.

=cut

