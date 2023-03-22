=head1 NAME

AnyEvent::MPV - remote control mpv (https://mpv.io)

=head1 SYNOPSIS

   use AnyEvent::MPV;

=head1 DESCRIPTION

This module allows you to remote control F<mpv> (a video player). It also
is an L<AnyEvent> user, you need to make sure that you use and run a
supported event loop.

There are other modules doing this, and I haven't looked much at them
other than to decide that they don't handle encodings correctly, and since
none of them use AnyEvent, I wrote my own. When in doubt, have a look at
them, too.

Knowledge of the L<mpv command
interface|https://mpv.io/manual/stable/#command-interface> is required to
use this module.

Features of this module are:

=over

=item uses AnyEvent, so integrates well into most event-based programs

=item supports asynchronous and synchronous operation

=item allows you to properly pass binary filenames

=item accepts data encoded in any way (does not crash when mpv replies with non UTF-8 data)

=item features a simple keybind/event system

=back

=head2 OVERVIEW OF OPERATION

This module forks an F<mpv> process and uses F<--input-ipc-client> (or
equivalent) to create a bidirectional communication channel between it and
the F<mpv> process.

It then speaks the somewhat JSON-looking (but not really being JSON)
protocol that F<mpv> implements to both send it commands, decode and
handle replies, and handle asynchronous events.

Here is a very simple client:

   use AnyEvent;
   use AnyEvent::MPV;
   
   my $videofile = "./xyzzy.mp4";

   my $mpv = AnyEvent::MPV->new (trace => 1);

   $mpv->start ("--", $videofile);

   my $timer = AE::timer 2, 0, my $quit = AE::cv;
   $quit->recv;

This starts F<mpv> with the two arguments C<--> and C<$videofile>, which
it should load and play. It then waits two seconds by starting a timer and
quits. The C<trace> argument to the constructor makes F<mpv> more verbose
and also prints the commands and responses, so you can have an idea what
is going on.

In my case, the above example would output something like this:

   [uosc] Disabled because original osc is enabled!
   mpv> {"event":"start-file","playlist_entry_id":1}
   mpv> {"event":"tracks-changed"}
    (+) Video --vid=1 (*) (h264 480x480 30.000fps)
   mpv> {"event":"metadata-update"}
   mpv> {"event":"file-loaded"}
   Using hardware decoding (nvdec).
   mpv> {"event":"video-reconfig"}
   VO: [gpu] 480x480 cuda[nv12]
   mpv> {"event":"video-reconfig"}
   mpv> {"event":"playback-restart"}

This is not usually very useful (you could just run F<mpv> as a simple
shell command), so let us load the file at runtime:

   use AnyEvent;
   use AnyEvent::MPV;
   
   my $videofile = "./xyzzy.mp4";

   my $mpv = AnyEvent::MPV->new (
      trace => 1,
      args  => ["--pause", "--idle=yes"],
   );

   $mpv->start;
   $mpv->cmd_recv (loadfile => $mpv->escape_binary ($videofile));
   $mpv->cmd ("set", "pause", "no");

   my $timer = AE::timer 2, 0, my $quit = AE::cv;
   $quit->recv;

This specifies extra arguments in the constructor - these arguments are
used every time you C<< ->start >> F<mpv>, while the arguments to C<<
->start >> are only used for this specific clal to0 C<start>. The argument
F<--pause> keeps F<mpv> in pause mode (i.e. it does not play the file
after loading it), and C<--idle=yes> tells F<mpv> to not quit when it does
not have a playlist - as no files are specified on the command line.

To load a file, we then send it a C<loadfile> command, which accepts, as
first argument, the URL or path to a video file. To make sure F<mpv> does
not misinterpret the path as a URL, it was prefixed with F<./> (similarly
to "protecting" paths in perls C<open>).

Since commands send I<to> F<mpv> are send in UTF-8, we need to escape the
filename (which might be in any encoding) using the C<esscape_binary>
method - this is not needed if your filenames are just ascii, or magically
get interpreted correctly, but if you accept arbitrary filenamews (e.g.
from the user), you need to do this.

The C<cmd_recv> method then queues the command, waits for a reply and
returns the reply data (or croaks on error). F<mpv> would, at this point,
load the file and, if everything was successful, show the first frame and
pause. Note that, since F<mpv> is implement rather synchronously itself,
do not expect commands to fail in many circumstances - for example, fit
he file does not exit, you will likely get an event, but the C<loadfile>
command itself will run successfully.

To unpause, we send another command, C<set>, to set the C<pause> property
to C<no>, this time using the C<cmd> method, which queues the command, but
instead of waiting for a reply, it immediately returns a condvar that cna
be used to receive results.

This should then cause F<mpv> to start playing the video.

It then again waits two seconds and quits.

Now, just waiting two seconds is rather, eh, unuseful, so let's look at
receiving events (using a somewhat embellished example):

   use AnyEvent;
   use AnyEvent::MPV;
   
   my $videofile = "xyzzy.mp4";

   my $quit = AE::cv;

   my $mpv = AnyEvent::MPV->new (
      trace => 1,
      args  => ["--pause", "--idle=yes"],
      on_event => sub {
         my ($mpv, $event, $data) = @_;

         if ($event eq "start-file") {
            $mpv->cmd ("set", "pause", "no");
         } elsif ($event eq "end-file") {
            print "end-file<$data->{reason}>\n";
            $quit->send;
         }
      },
   );

   $mpv->start;
   $mpv->cmd (loadfile => $mpv->escape_binary ($videofile));

   $quit->recv;

This example uses a global condvar C<$quit> to wait for the file to finish
playing. Also, most of the logic is now in an C<on_event> callback, which
receives an event name and the actual event object.

The two events we handle are C<start-file>, which is emitted by F<mpv>
once it has loaded a new file, and C<end-file>, which signals the end
of a file.

In the former event, we again set the C<pause> property to C<no> so the
movie starts playing. For the latter event, we tell the main program to
quit by invoking C<$quit>.

This should conclude the basics of operation. There are a few more
examples later in the documentation.

=head2 ENCODING CONVENTIONS

As a rule of thumb, all data you pass to this module to be sent to F<mpv>
is expected to be in unicode. To pass something that isn't, you need to
escape it using C<escape_binary>.

Data received from C<$mpv>, however, is I<not> decoded to unicode, as data
returned by F<mpv> is not generally encoded in unicode, and the encoding
is usually unspecified. So if you receive data and expect it to be in
unicode, you need to first decode it from UTF-8, but note that this might
fail. This is not a limitation of this module - F<mpv> simply does not
specify nor guarantee a specific encoding, or any encoding at all, in its
protocol.

=head2 METHODS

=over

=cut

package AnyEvent::MPV;

use common::sense;

use Fcntl ();
use Scalar::Util ();

use AnyEvent ();
use AnyEvent::Util ();

our $VERSION = '0.2';

sub OBSID() { 0x10000000000000 } # 2**52

our $JSON = eval { require JSON::XS; JSON::XS:: }
          || do  { require JSON::PP; JSON::PP:: };

our $JSON_CODER =

our $mpv_path; # last mpv path used
our $mpv_optionlist; # output of mpv --list-options

=item $mpv = AnyEvent::MPV->new (key => value...)

Creates a new C<mpv> object, but does not yet do anything. The support key-value pairs are:

=over

=item mpv => $path

The path to the F<mpv> binary to use - by default, C<mpv> is used and
therefore, uses your C<PATH> to find it.

=item args => [...]

Arguments to pass to F<mpv>. These arguments are passed after the
hardcoded arguments used by this module, but before the arguments passed
ot C<start>. It does not matter whether you specify your arguments using
this key, or in the C<start> call, but when you invoke F<mpv> multiple
times, typically the arguments used for all invocations go here, while
arguments used for specific invocations (e..g filenames) are passed to
C<start>.

=item trace => false|true|coderef

Enables tracing if true. In trace mode, output from F<mpv> is printed to
standard error using a C<< mpv> >> prefix, and commands sent to F<mpv>
are printed with a C<< >mpv >> prefix.

If a code reference is passed, then instead of printing to standard
errort, this coderef is invoked with a first arfgument being either
C<< mpv> >> or C<< >mpv >>, and the second argument being a string to
display. The default implementation simply does this:

   sub {
      warn "$_[0] $_[1]\n";
   }

=item on_eof => $coderef->($mpv)

=item on_event => $coderef->($mpv, $event, $data)

=item on_key => $coderef->($mpv, $string)

These are invoked by the default method implementation of the same name -
see below.

=back

=cut

sub new {
   my ($class, %kv) = @_;

   bless {
      mpv     => "mpv",
      args    => [],
      %kv,
   }, $class
}

=item $string = $mpv->escape_binary ($string)

This module excects all command data sent to F<mpv> to be in unicode. Some
things are not, such as filenames. To pass binary data such as filenames
through a comamnd, you need to escape it using this method.

The simplest example is a C<loadfile> command:

   $mpv->cmd_recv (loadfile => $mpv->escape_binary ($path));

=cut

# can be used to escape filenames
sub escape_binary {
   shift;
   local $_ = shift;
   # we escape every "illegal" octet using U+10e5df HEX. this is later undone in cmd
   s/([\x00-\x1f\x80-\xff])/sprintf "\x{10e5df}%02x", ord $1/ge;
   $_
}

=item $started = $mpv->start (argument...)

Starts F<mpv>, passing the given arguemnts as extra arguments to
F<mpv>. If F<mpv> is already running, it returns false, otherwise it
returns a true value, so you can easily start F<mpv> on demand by calling
C<start> just before using it, and if it is already running, it will not
be started again.

The arguments passwd to F<mpv> are a set of hardcoded built-in arguments,
followed by the arguments specified in the constructor, followed by the
arguments passwd to this method. The built-in arguments currently are
F<--no-input-terminal>, F<--really-quiet> (or F<--quiet> in C<trace>
mode), and C<--input-ipc-client> (or equivalent).

Some commonly used and/or even useful arguments you might want to pass are:

=over

=item F<--idle=yes> or F<--idle=once> to keep F<mpv> from quitting when you
don't specify a file to play.

=item F<--pause>, to keep F<mpv> from instantly starting to play a file, in case you want to
inspect/change properties first.

=item F<--force-window=no> (or similar), to keep F<mpv> from instantly opening a window, or to force it to do so.

=item F<--audio-client-name=yourappname>, to make sure audio streams are associated witht eh right program.

=item F<--wid=id>, to embed F<mpv> into another application.

=item F<--no-terminal>, F<--no-input-default-bindings>, F<--no-input-cursor>, F<--input-conf=/dev/null>, F<--input-vo-keyboard=no> - to ensure only you control input.

=back

The return value can be used to decide whether F<mpv> needs initializing:

   if ($mpv->start) {
      $mpv->bind_key (...);
      $mpv->cmd (set => property => value);
      ...
   }

You can immediately starting sending commands when this method returns,
even if F<mpv> has not yet started.

=cut

sub start {
   my ($self, @extra_args) = @_;

   return 0 if $self->{fh};

   $self->{obscb} = {};

   # cache optionlist for same "path"
   ($mpv_path, $mpv_optionlist) = ($self->{mpv}, scalar qx{\Q$self->{mpv}\E --list-options})
      if $self->{mpv} ne $mpv_path;

   my $options = $mpv_optionlist;

   my ($fh, $slave) = AnyEvent::Util::portable_socketpair
      or die "socketpair: $!\n";

   AnyEvent::Util::fh_nonblocking $fh, 1;

   $self->{pid} = fork;

   if ($self->{pid} eq 0) {
      AnyEvent::Util::fh_nonblocking $slave, 0;
      fcntl $slave, Fcntl::F_SETFD, 0;

      my $input_file = $options =~ /\s--input-ipc-client\s/ ? "input-ipc-client" : "input-file";

      exec $self->{mpv},
           qw(--no-input-terminal),
           ($self->{trace} ? "--quiet" : "--really-quiet"),
           "--$input_file=fd://" . (fileno $slave),
           @{ $self->{args} },
           @extra_args;
      exit 1;
   }

   $self->{fh} = $fh;

   my $trace = delete $self->{trace} || sub { };

   $trace = sub { warn "$_[0] $_[1]\n" } if $trace && !ref $trace;

   my $buf;

   Scalar::Util::weaken $self;

   $self->{rw} = AE::io $fh, 0, sub {
      if (sysread $fh, $buf, 8192, length $buf) {
         while ($buf =~ s/^([^\n]+)\n//) {
            $trace->("mpv>" => "$1");

            if ("{" eq substr $1, 0, 1) {
               eval {
                  my $reply = $JSON->new->latin1->decode ($1);

                  if (exists $reply->{event}) {
                     if (
                        $reply->{event} eq "client-message"
                        and $reply->{args}[0] eq "AnyEvent::MPV"
                     ) {
                        if ($reply->{args}[1] eq "key") {
                           (my $key = $reply->{args}[2]) =~ s/\\x(..)/chr hex $1/ge;
                           $self->on_key ($key);
                        }
                     } elsif (
                        $reply->{event} eq "property-change"
                        and OBSID <= $reply->{id}
                     ) {
                        if (my $cb = $self->{obscb}{$reply->{id}}) {
                           $cb->($self, $reply->{name}, $reply->{data});
                        }
                     } else {
                        $self->on_event (delete $reply->{event}, $reply);
                     }
                  } elsif (exists $reply->{request_id}) {
                     my $cv = delete $self->{cmdcv}{$reply->{request_id}};

                     unless ($cv) {
                        warn "no cv found for request id <$reply->{request_id}>\n";
                        next;
                     }

                     if (exists $reply->{data}) {
                        $cv->send ($reply->{data});
                     } elsif ($reply->{error} eq "success") { # success means error... eh.. no...
                        $cv->send;
                     } else {
                        $cv->croak ($reply->{error});
                     }

                  } else {
                     warn "unexpected reply from mpv, pleasew report: <$1>\n";
                  }
               };
               warn $@ if $@;
            } else {
               $trace->("mpv>" => "$1");
            }
         }
      } else {
         $self->stop;
         $self->on_eof;
      }
   };

   my $wbuf;
   my $reqid;

   $self->{_cmd} = sub {
      my $cv = AE::cv;

      $self->{cmdcv}{++$reqid} = $cv;

      my $cmd = $JSON->new->utf8->encode ({ command => ref $_[0] ? $_[0] : \@_, request_id => $reqid*1 });

      # (un-)apply escape_binary hack
      $cmd =~ s/\xf4\x8e\x97\x9f(..)/sprintf sprintf "\\x%02x", hex $1/ges; # f48e979f == 10e5df in utf-8

      $trace->(">mpv" => $cmd);

      $wbuf .= "$cmd\n";

      $self->{ww} ||= AE::io $fh, 1, sub {
         my $len = syswrite $fh, $wbuf;
         substr $wbuf, 0, $len, "";
         undef $self->{ww} unless length $wbuf;
      };

      $cv
   };

   1
}

sub DESTROY {
   $_[0]->stop;
}

=item $mpv->stop

Ensures that F<mpv> is being stopped, by killing F<mpv> with a C<TERM>
signal if needed. After this, you can C<< ->start >> a new instance again.

=cut

sub stop {
   my ($self) = @_;

   delete $self->{rw};
   delete $self->{ww};

   if ($self->{pid}) {

      close delete $self->{fh}; # current mpv versions should cleanup on their own on close

      kill TERM => $self->{pid};

   }

   delete $self->{pid};
   delete $self->{cmdcv};
   delete $self->{obsid};
   delete $self->{obscb};
   delete $self->{wbuf};
}

=item $mpv->on_eof

This method is called when F<mpv> quits - usually unexpectedly. The
default implementation will call the C<on_eof> code reference specified in
the constructor, or do nothing if none was given.

For subclassing, see I<SUBCLASSING>, below.

=cut

sub on_eof {
   my ($self) = @_;

   $self->{on_eof}($self) if $self->{on_eof};
}

=item $mpv->on_event ($event, $data)

This method is called when F<mpv> sends an asynchronous event. The default
implementation will call the C<on_event> code reference specified in the
constructor, or do nothing if none was given.

The first/implicit argument is the C<$mpv> object, the second is the
event name (same as C<< $data->{event} >>, purely for convenience), and
the third argument is the event object as sent by F<mpv> (sans C<event>
key). See L<List of events|https://mpv.io/manual/stable/#list-of-events>
in its documentation.

For subclassing, see I<SUBCLASSING>, below.

=cut

sub on_event {
   my ($self, $key) = @_;

   $self->{on_event}($self, $key) if $self->{on_event};
}

=item $mpv->on_key ($string)

Invoked when a key declared by C<< ->bind_key >> is pressed. The default
invokes the C<on_key> code reference specified in the constructor with the
C<$mpv> object and the key name as arguments, or do nothing if none was
given.

For more details and examples, see the C<bind_key> method.

For subclassing, see I<SUBCLASSING>, below.

=cut

sub on_key {
   my ($self, $key) = @_;

   $self->{on_key}($self, $key) if $self->{on_key};
}

=item $mpv->cmd ($command => $arg, $arg...)

Queues a command to be sent to F<mpv>, using the given arguments, and
immediately return a condvar.

See L<the mpv
documentation|https://mpv.io/manual/stable/#list-of-input-commands> for
details on individual commands.

The condvar can be ignored:

   $mpv->cmd (set_property => "deinterlace", "yes");

Or it can be used to synchronously wait for the command results:

   $cv = $mpv->cmd (get_property => "video-format");
   $format = $cv->recv;

   # or simpler:

   $format = $mpv->cmd (get_property => "video-format")->recv;

   # or even simpler:

   $format = $mpv->cmd_recv (get_property => "video-format");

Or you can set a callback:

   $cv = $mpv->cmd (get_property => "video-format");
   $cv->cb (sub {
      my $format = $_[0]->recv;
   });

On error, the condvar will croak when C<recv> is called.

=cut

sub cmd {
   my $self = shift;

   $self->{_cmd}->(@_)
}

=item $result = $mpv->cmd_recv ($command => $arg, $arg...)

The same as calling C<cmd> and immediately C<recv> on its return
value. Useful when you don't want to mess with F<mpv> asynchronously or
simply needs to have the result:

   $mpv->cmd_recv ("stop");
   $position = $mpv->cmd_recv ("get_property", "playback-time");

=cut

sub cmd_recv {
   &cmd->recv
}

=item $mpv->bind_key ($INPUT => $string)

This is an extension implement by this module to make it easy to get key events. The way this is implemented
is to bind a C<client-message> witha  first argument of C<AnyEvent::MPV> and the C<$string> you passed. This C<$string> is then
passed to the C<on_key> handle when the key is proessed, e.g.:

   my $mpv = AnyEvent::MPV->new (
      on_key => sub {
         my ($mpv, $key) = @_;

         if ($key eq "letmeout") {
            print "user pressed escape\n";
         }
      },
   );

   $mpv_>bind_key (ESC => "letmeout");

The key configuration is lost when F<mpv> is stopped and must be (re-)done
after every C<start>.

=cut

sub bind_key {
   my ($self, $key, $event) = @_;

   $event =~ s/([^A-Za-z0-9\-_])/sprintf "\\x%02x", ord $1/ge;
   $self->cmd (keybind => $key => "no-osd script-message AnyEvent::MPV key $event");
}

sub AnyEvent::MPV::Unobserve::DESTROY {
   my ($mpv, $obscb, $obsid) = @{$_[0]};

   delete $obscb->{$obsid};

   if ($obscb == $mpv->{obscb}) {
      $mpv->cmd (unobserve_property => $obsid+0);
   }
}

=item [$guard] = $mpv->observe_property ($name => $coderef->($mpv, $name, $value))

=item [$guard] = $mpv->observe_property_string ($name => $coderef->($mpv, $name, $value))

These methods wrap a registry system around F<mpv>'s C<observe_property>
and C<observe_property_string> commands - every time the named property
changes, the coderef is invoked with the C<$mpv> object, the name of the
property and the new value.

For a list of properties that you can observe, see L<the mpv
documentation|https://mpv.io/manual/stable/#property-list>.

Due to the (sane :) way F<mpv> handles these requests, you will always
get a property cxhange event right after registering an observer (meaning
you don't have to query the current value), and it is also possible to
register multiple observers for the same property - they will all be
handled properly.

When called in void context, the observer stays in place until F<mpv>
is stopped. In any otrher context, these methods return a guard
object that, when it goes out of scope, unregisters the observe using
C<unobserve_property>.

Internally, this method uses observer ids of 2**52 (0x10000000000000) or
higher - it will not interfere with lower ovserver ids, so it is possible
to completely ignore this system and execute C<observe_property> commands
yourself, whilst listening to C<property-change> events - as long as your
ids stay below 2**52.

Example: register observers for changtes in C<aid> and C<sid>. Note that
a dummy statement is added to make sure the method is called in void
context.

   sub register_observers {
      my ($mpv) = @_;

      $mpv->observe_property (aid => sub {
         my ($mpv, $name, $value) = @_;
         print "property aid (=$name) has changed to $value\n";
      });

      $mpv->observe_property (sid => sub {
         my ($mpv, $name, $value) = @_;
         print "property sid (=$name) has changed to $value\n";
      });

      () # ensure the above method is called in void context
   }

=cut

sub _observe_property {
   my ($self, $type, $property, $cb) = @_;

   my $obsid = OBSID + ++$self->{obsid};
   $self->cmd ($type => $obsid+0, $property);
   $self->{obscb}{$obsid} = $cb;

   defined wantarray and do {
      my $unobserve = bless [$self, $self->{obscb}, $obsid], AnyEvent::MPV::Unobserve::;
      Scalar::Util::weaken $unobserve->[0];
      $unobserve
   }
}

sub observe_property {
   my ($self, $property, $cb) = @_;

   $self->_observe_property (observe_property => $property, $cb)
}

sub observe_property_string {
   my ($self, $property, $cb) = @_;

   $self->_observe_property (observe_property_string => $property, $cb)
}

=back

=head2 SUBCLASSING

Like most perl objects, C<AnyEvent::MPV> objects are implemented as
hashes, with the constructor simply storing all passed key-value pairs in
the object. If you want to subclass to provide your own C<on_*> methods,
be my guest and rummage around in the internals as much as you wish - the
only guarantee that this module dcoes is that it will not use keys with
double colons in the name, so youc an use those, or chose to simply not
care and deal with the breakage.

If you don't want to go to the effort of subclassing this module, you can
also specify all event handlers as constructor keys.

=head1 SEE ALSO

L<AnyEvent>, L<the mpv command documentation|https://mpv.io/manual/stable/#command-interface>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

