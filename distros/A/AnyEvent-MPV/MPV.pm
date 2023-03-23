=head1 NAME

AnyEvent::MPV - remote control mpv (https://mpv.io)

=head1 SYNOPSIS

   use AnyEvent::MPV;

   my $videofile = "path/to/file.mkv";
   use AnyEvent;
   my $mpv = AnyEvent::MPV->new (trace => 1);
   $mpv->start ("--idle=yes");
   $mpv->cmd (loadfile => $mpv->escape_binary ($videofile));
   my $quit = AE::cv;
   $mpv->register_event (end_file => $quit);
   $quit->recv;


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
   
   my $videofile = "./xyzzy.mkv";

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
   
   my $videofile = "./xyzzy.mkv";

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
   
   my $videofile = "xyzzy.mkv";

   my $quit = AE::cv;

   my $mpv = AnyEvent::MPV->new (
      trace => 1,
      args  => ["--pause", "--idle=yes"],
   );

   $mpv->start;

   $mpv->register_event (start_file => sub {
      $mpv->cmd ("set", "pause", "no");
   });

   $mpv->register_event (end_file => sub {
      my ($mpv, $event, $data) = @_;

      print "end-file<$data->{reason}>\n";
      $quit->send;
   });

   $mpv->cmd (loadfile => $mpv->escape_binary ($videofile));

   $quit->recv;

This example uses a global condvar C<$quit> to wait for the file to finish
playing. Also, most of the logic is now implement in event handlers.

The two events handlers we register are C<start-file>, which is emitted by
F<mpv> once it has loaded a new file, and C<end-file>, which signals the
end of a file (underscores are internally replaced by minus signs, so you
cna speicfy event names with either).

In the C<start-file> event, we again set the C<pause> property to C<no>
so the movie starts playing. For the C<end-file> event, we tell the main
program to quit by invoking C<$quit>.

This should conclude the basics of operation. There are a few more
examples later in the documentation.

=head2 ENCODING CONVENTIONS

As a rule of thumb, all data you pass to this module to be sent to F<mpv>
is expected to be in unicode. To pass something that isn't, you need to
escape it using C<escape_binary>.

Data received from F<mpv>, however, is I<not> decoded to unicode, as data
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

our $VERSION = '1.0';

sub OBSID() { 0x10000000000000 } # 2**52

our $JSON = eval { require JSON::XS; JSON::XS:: }
          || do  { require JSON::PP; JSON::PP:: };

our $JSON_ENCODER = $JSON->new->utf8;
our $JSON_DECODER = $JSON->new->latin1;

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
                  my $reply = $JSON_DECODER->decode ($1);

                  if (defined (my $event = delete $reply->{event})) {
                     if (
                        $event eq "client-message"
                        and $reply->{args}[0] eq "AnyEvent::MPV"
                     ) {
                        if ($reply->{args}[1] eq "key") {
                           (my $key = $reply->{args}[2]) =~ s/\\x(..)/chr hex $1/ge;
                           $self->on_key ($key);
                        }
                     } elsif (
                        $event eq "property-change"
                        and OBSID <= $reply->{id}
                     ) {
                        if (my $cb = $self->{obscb}{$reply->{id}}) {
                           $cb->($self, $event, $reply->{data});
                        }
                     } else {
                        if (my $cbs = $self->{evtcb}{$event}) {
                           for my $evtid (keys %$cbs) {
                              my $cb = $cbs->{$evtid}
                                 or next;
                              $cb->($self, $event, $reply);
                           }
                        }

                        $self->on_event ($event, $reply);
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

      my $cmd = $JSON_ENCODER->encode ({ command => ref $_[0] ? $_[0] : \@_, request_id => $reqid*1 });

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
   delete $self->{evtid};
   delete $self->{evtcb};
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

This is an extension implement by this module to make it easy to get key
events. The way this is implemented is to bind a C<client-message> witha
first argument of C<AnyEvent::MPV> and the C<$string> you passed. This
C<$string> is then passed to the C<on_key> handle when the key is
proessed, e.g.:

   my $mpv = AnyEvent::MPV->new (
      on_key => sub {
         my ($mpv, $key) = @_;

         if ($key eq "letmeout") {
            print "user pressed escape\n";
         }
      },
   );

   $mpv_>bind_key (ESC => "letmeout");

You cna find a list of key names L<in the mpv
documentation|https://mpv.io/manual/stable/#key-names>.

The key configuration is lost when F<mpv> is stopped and must be (re-)done
after every C<start>.

=cut

sub bind_key {
   my ($self, $key, $event) = @_;

   $event =~ s/([^A-Za-z0-9\-_])/sprintf "\\x%02x", ord $1/ge;
   $self->cmd (keybind => $key => "no-osd script-message AnyEvent::MPV key $event");
}

=item [$guard] = $mpv->register_event ($event => $coderef->($mpv, $event, $data))

This method registers a callback to be invoked for a specific
event. Whenever the event occurs, it calls the coderef with the C<$mpv>
object, the C<$event> name and the event object, just like the C<on_event>
method.

For a lst of events, see L<the mpv
documentation|https://mpv.io/manual/stable/#list-of-events>. Any
underscore in the event name is replaced by a minus sign, so you can
specify event names using underscores for easier quoting in Perl.

In void context, the handler stays registered until C<stop> is called. In
any other context, it returns a guard object that, when destroyed, will
unregister the handler.

You can register multiple handlers for the same event, and this method
does not interfere with the C<on_event> mechanism. That is, you can
completely ignore this method and handle events in a C<on_event> handler,
or mix both approaches as you see fit.

Note that unlike commands, event handlers are registered immediately, that
is, you can issue a command, then register an event handler and then get
an event for this handler I<before> the command is even sent to F<mpv>. If
this kind of race is an issue, you can issue a dummy command such as
C<get_version> and register the handler when the reply is received.

=cut

sub AnyEvent::MPV::Unevent::DESTROY {
   my ($evtcb, $event, $evtid) = @{$_[0]};
   delete $evtcb->{$event}{$evtid};
}

sub register_event {
   my ($self, $event, $cb) = @_;

   $event =~ y/_/-/;

   my $evtid = ++$self->{evtid};
   $self->{evtcb}{$event}{$evtid} = $cb;

   defined wantarray
      and bless [$self->{evtcb}, $event, $evtid], AnyEvent::MPV::Unevent::
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

sub AnyEvent::MPV::Unobserve::DESTROY {
   my ($mpv, $obscb, $obsid) = @{$_[0]};

   delete $obscb->{$obsid};

   if ($obscb == $mpv->{obscb}) {
      $mpv->cmd (unobserve_property => $obsid+0);
   }
}

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

=head1 EXAMPLES

Here are some real-world code snippets, thrown in here mainly to give you
some example code to copy.

=head2 doomfrontend

At one point I replaced mythtv-frontend by my own terminal-based video
player (based on rxvt-unicode). I toyed with the diea of using F<mpv>'s
subtitle engine to create the user interface, but that is hard to use
since you don't know how big your letters are. It is also where most of
this modules code has originally been developed in.

It uses a unified input queue to handle various remote controls, so its
event handling needs are very simple - it simply feeds all events into the
input queue:

   my $mpv = AnyEvent::MPV->new (
      mpv   => $MPV,
      args  => \@MPV_ARGS,
      on_event => sub {
	 input_feed "mpv/$_[1]", $_[2];
      },
      on_key => sub {
	 input_feed $_[1];
      },
      on_eof => sub {
	 input_feed "mpv/quit";
      },
   );

   ...

   $mpv->start ("--idle=yes", "--pause", "--force-window=no");

It also doesn't use complicated command line arguments - the file search
options have the most impact, as they prevent F<mpv> from scanning
directories with tens of thousands of files for subtitles and more:

   --audio-client-name=doomfrontend
   --osd-on-seek=msg-bar --osd-bar-align-y=-0.85 --osd-bar-w=95
   --sub-auto=exact --audio-file-auto=exact

Since it runs on a TV without a desktop environemnt, it tries to keep complications such as dbus
away and the screensaver happy:

   # prevent xscreensaver from doing something stupid, such as starting dbus
   $ENV{DBUS_SESSION_BUS_ADDRESS} = "/"; # prevent dbus autostart for sure
   $ENV{XDG_CURRENT_DESKTOP} = "generic";

It does bind a number of keys to internal (to doomfrontend) commands:

   for (
      List::Util::pairs qw(
         ESC   return
         q     return
         ENTER enter
         SPACE pause
         [     steprev
         ]     stepfwd
         j     subtitle
         BS    red
         i     green
         o     yellow
         b     blue
         D     triangle
         UP    up
         DOWN  down
         RIGHT right
         LEFT  left
      ),
      (map { ("KP$_" => "num$_") } 0..9),
      KP_INS => 0, # KP0, but different
   ) {
      $mpv->bind_key ($_->[0] => $_->[1]);
   }

It also reacts to sponsorblock chapters, so it needs to know when vidoe
chapters change. Preadting C<AnyEvent::MPV>, it handles observers
manually:

   $mpv->cmd (observe_property => 1, "chapter-metadata");

It also tries to apply an F<mpv> profile, if it exists:

   eval {
      # the profile is optional
      $mpv->cmd ("apply-profile" => "doomfrontend");
   };

Most of the complicated parts deal with saving and restoring per-video
data, such as bookmarks, playing position, selected audio and subtitle
tracks and so on. However, since it uses L<Coro>, it can conveniently
block and wait for replies, which is n ot possible in purely event based
programs, as you are not allowed to block inside event callbacks in most
event loops. This simplifies the code quite a bit.

When the file to be played is a Tv recording done by mythtv, it uses the
C<appending> protocol and deinterlacing:

   if (is_myth $mpv_path) {
      $mpv_path = "appending://$mpv_path";
      $initial_deinterlace = 1;
   }

Otherwise, it sets some defaults and loads the file (I forgot what the
C<dummy> argument is for, but I am sure it is needed by some F<mpv>
version):

   $mpv->cmd ("script-message", "osc-visibility", "never", "dummy");
   $mpv->cmd ("set", "vid", "auto");
   $mpv->cmd ("set", "aid", "auto");
   $mpv->cmd ("set", "sid", "no");
   $mpv->cmd ("set", "file-local-options/chapters-file", $mpv->escape_binary ("$mpv_path.chapters"));
   $mpv->cmd ("loadfile", $mpv->escape_binary ($mpv_path));
   $mpv->cmd ("script-message", "osc-visibility", "auto", "dummy");

Handling events makes the main bulk of video playback code. For example,
various ways of ending playback:

      if ($INPUT eq "mpv/quit") { # should not happen, but allows user to kill etc. without consequence
         $status = 1;
         mpv_init; # try reinit
         last;

      } elsif ($INPUT eq "mpv/idle") { # normal end-of-file
         last;

      } elsif ($INPUT eq "return") {
         $status = 1;
         last;

Or the code that actually starts playback, once the file is loaded:

   our %SAVE_PROPERTY = (aid => 1, sid => 1, "audio-delay" => 1);
   
   ...

   my $oid = 100;

      } elsif ($INPUT eq "mpv/file-loaded") { # start playing, configure video
         $mpv->cmd ("seek", $playback_start, "absolute+exact") if $playback_start > 0;

         my $target_fps = eval { $mpv->cmd_recv ("get_property", "container-fps") } || 60;
         $target_fps *= play_video_speed_mult;
         set_fps $target_fps;

         unless (eval { $mpv->cmd_recv ("get_property", "video-format") }) {
            $mpv->cmd ("set", "file-local-options/lavfi-complex", "[aid1] asplit [ao], showcqt=..., format=yuv420p [vo]");
         };

         for my $prop (keys %SAVE_PROPERTY) {
            if (exists $PLAYING_STATE->{"mpv_$prop"}) {
               $mpv->cmd ("set", "$prop", $PLAYING_STATE->{"mpv_$prop"} . "");
            }

            $mpv->cmd ("observe_property", ++$oid, $prop);
         }

         play_video_set_speed;
         $mpv->cmd ("set", "osd-level", "$OSD_LEVEL");
         $mpv->cmd ("observe_property", ++$oid, "osd-level");
         $mpv->cmd ("set", "pause", "no");

         $mpv->cmd ("set_property", "deinterlace", "yes")
            if $initial_deinterlace;

There is a lot going on here. First it seeks to the actual playback
position, if it is not at the start of the file (it would probaby be more
efficient to set the starting position before loading the file, though,
but this is good enough).

Then it plays with the display fps, to set it to something harmonious
w.r.t. the video framerate.

If the file does not have a video part, it assumes it is an audio file and
sets a visualizer.

Also, a number of properties are not global, but per-file. At the moment,
this is C<audio-delay>, and the current audio/subtitle track, which it
sets, and also creates an observer. Again, this doesn'T use the observe
functionality of this module, but handles it itself, assigning obsevrer
ids 100+ to temporary/per-file observers.

Lastly, it sets some global (or per-youtube-uploader) parameters, such as
speed, and unpauses. Property changes are handled like other input events:

      } elsif ($INPUT eq "mpv/property-change") {
         my $prop = $INPUT_DATA->{name};

         if ($prop eq "chapter-metadata") {
            if ($INPUT_DATA->{data}{TITLE} =~ /^\[SponsorBlock\]: (.*)/) {
               my $section = $1;
               my $skip;

               $skip ||= $SPONSOR_SKIP{$_}
                  for split /\s*,\s*/, $section;

               if (defined $skip) {
                  if ($skip) {
                     # delay a bit, in case we get two metadata changes in quick succession, e.g.
                     # because we have a skip at file load time.
                     $skip_delay = AE::timer 2/50, 0, sub {
                        $mpv->cmd ("no-osd", "add", "chapter", 1);
                        $mpv->cmd ("show-text", "skipped sponsorblock section \"$section\"", 3000);
                     };
                  } else {
                     undef $skip_delay;
                     $mpv->cmd ("show-text", "NOT skipping sponsorblock section \"$section\"", 3000);
                  }
               } else {
                  $mpv->cmd ("show-text", "UNRECOGNIZED sponsorblock section \"$section\"", 60000);
               }
            } else {
               # cancel a queued skip
               undef $skip_delay;
            }

         } elsif (exists $SAVE_PROPERTY{$prop}) {
            $PLAYING_STATE->{"mpv_$prop"} = $INPUT_DATA->{data};
            ::state_save;
         }

This saves back the per-file properties, and also handles chapter changes
in a hacky way.

Most of the handlers are very simple, though. For example:

      } elsif ($INPUT eq "pause") {
         $mpv->cmd ("cycle", "pause");
         $PLAYING_STATE->{curpos} = $mpv->cmd_recv ("get_property", "playback-time");
      } elsif ($INPUT eq "right") {
         $mpv->cmd ("osd-msg-bar", "seek",  30, "relative+exact");
      } elsif ($INPUT eq "left") {
         $mpv->cmd ("osd-msg-bar", "seek", -5, "relative+exact");
      } elsif ($INPUT eq "up") {
         $mpv->cmd ("osd-msg-bar", "seek", +600, "relative+exact");
      } elsif ($INPUT eq "down") {
         $mpv->cmd ("osd-msg-bar", "seek", -600, "relative+exact");
      } elsif ($INPUT eq "select") {
         $mpv->cmd ("osd-msg-bar", "add", "audio-delay", "-0.100");
      } elsif ($INPUT eq "start") {
         $mpv->cmd ("osd-msg-bar", "add", "audio-delay", "0.100");
      } elsif ($INPUT eq "intfwd") {
         $mpv->cmd ("no-osd", "frame-step");
      } elsif ($INPUT eq "audio") {
         $mpv->cmd ("osd-auto", "cycle", "audio");
      } elsif ($INPUT eq "subtitle") {
         $mpv->cmd ("osd-auto", "cycle", "sub");
      } elsif ($INPUT eq "triangle") {
         $mpv->cmd ("osd-auto", "cycle", "deinterlace");

Once a file has finished playing (or the user strops playback), it pauses,
unobserves the per-file observers, and saves the current position for to
be able to resume:

   $mpv->cmd ("set", "pause", "yes");

   while ($oid > 100) {
      $mpv->cmd ("unobserve_property", $oid--);
   }

   $PLAYING_STATE->{curpos} = $mpv->cmd_recv ("get_property", "playback-time");

And thats most of the F<mpv>-related code.

=head2 F<Gtk2::CV>

F<Gtk2::CV> is low-feature image viewer that I use many times daily
because it can handle directories with millions of files without falling
over. It also had the ability to play videos for ages, but it used an
older, crappier protocol to talk to F<mpv> and used F<ffprobe> before
playing each file instead of letting F<mpv> handle format/size detection.

After writing this module, I decided to upgprade Gtk2::CV by making use
of it, with the goal of getting rid of F<ffprobe> and being ablew to
reuse F<mpv> processes, which would have a multitude of speed benefits
(for example, fork+exec of F<mpv> caused the kernel to close all file
descriptors, which could take minutes if a large file was being copied via
NFS, as the kernel waited for thr buffers to be flushed on close - not
having to start F<mpv> gets rid of this issue).

Setting up is only complicated by the fact that F<mpv> needs to be
embedded into an existing window. To keep control of all inputs,
F<Gtk2::CV> puts an eventbox in front of F<mpv>, so F<mpv> receives no
input events:

   $self->{mpv} = AnyEvent::MPV->new (
      trace => $ENV{CV_MPV_TRACE},
   );

   # create an eventbox, so we receive all input events
   my $box = $self->{mpv_eventbox} = new Gtk2::EventBox;
   $box->set_above_child (1);
   $box->set_visible_window (0);
   $box->set_events ([]);
   $box->can_focus (0);

   # create a drawingarea that mpv can display into
   my $window = $self->{mpv_window} = new Gtk2::DrawingArea;
   $box->add ($window);

   # put the drawingarea intot he eventbox, and the eventbox into our display window
   $self->add ($box);

   # we need to pass the window id to F<mpv>, which means we need to realise
   # the drawingarea, so an X window is allocated for it.
   $self->show_all;
   $window->realize;
   my $xid = $window->window->get_xid;

Then it starts F<mpv> using this setup:

   local $ENV{LC_ALL} = "POSIX";
   $self->{mpv}->start (
      "--no-terminal",
      "--no-input-terminal",
      "--no-input-default-bindings",
      "--no-input-cursor",
      "--input-conf=/dev/null",
      "--input-vo-keyboard=no",

      "--loop-file=inf",
      "--force-window=yes",
      "--idle=yes",

      "--audio-client-name=CV",

      "--osc=yes", # --osc=no displays fading play/pause buttons instead

      "--wid=$xid",
   );

   $self->{mpv}->cmd ("script-message" => "osc-visibility" => "never", "dummy");
   $self->{mpv}->cmd ("osc-idlescreen" => "no");

It also prepares a hack to force a ConfigureNotify event on every vidoe
reconfig:

   # force a configurenotify on every video-reconfig
   $self->{mpv_reconfig} = $self->{mpv}->register_event (video_reconfig => sub {
      my ($mpv, $event, $data) = @_;

      $self->mpv_window_update;
   });

The way this is done is by doing a "dummy" resize to 1x1 and back:

   $self->{mpv_window}->window->resize (1, 1),
   $self->{mpv_window}->window->resize ($self->{w}, $self->{h});

Without this, F<mpv> often doesn't "get" the correct window size. Doing
it this way is not nice, but I didn't fine a nicer way to do it.

When no file is being played, F<mpv> is hidden and prepared:

   $self->{mpv_eventbox}->hide;

   $self->{mpv}->cmd (set_property => "pause" => "yes");
   $self->{mpv}->cmd ("playlist_remove", "current");
   $self->{mpv}->cmd (set_property => "video-rotate" => 0);
   $self->{mpv}->cmd (set_property => "lavfi-complex" => "");

Loading a file is a bit more complicated, as bluray and DVD rips are
supported:

   if ($moviedir) {
      if ($moviedir eq "br") {
         $mpv->cmd (set => "bluray-device" => $path);
         $mpv->cmd (loadfile => "bd://");
      } elsif ($moviedir eq "dvd") {
         $mpv->cmd (set => "dvd-device" => $path);
         $mpv->cmd (loadfile => "dvd://");
      }
   } elsif ($type eq "video/iso-bluray") {
      $mpv->cmd (set => "bluray-device" => $path);
      $mpv->cmd (loadfile => "bd://");
   } else {
      $mpv->cmd (loadfile => $mpv->escape_binary ($path));
   }

After this, C<Gtk2::CV> waits for the file to be loaded, video to be
configured, and then queries the video size (to resize its own window)
and video format (to decide whether an audio visualizer is needed for
audio playback). The problematic word here is "wait", as this needs to be
imploemented using callbacks.

This made the code much harder to write, as the whole setup is very
asynchronous (C<Gtk2::CV> talks to the command interface in F<mpv>, which
talks to the decode and playback parts, all of which run asynchronously
w.r.t. each other. In practise, this can mean that C<Gtk2::CV> waits for
a file to be loaded by F<mpv> while the command interface of F<mpv> still
deals with the previous file and the decoder still handles an even older
file). Adding to this fact is that Gtk2::CV is bound by the glib event
loop, which means we cannot wait for replies form F<mpv> anywhere, so
everything has to be chained callbacks.

The way this is handled is by creating a new empty hash ref that is unique
for each loaded file, and use it to detect whether the event is old or
not, and also store C<AnyEvent::MPV> guard objects in it:

   # every time we loaded a file, we create a new hash
   my $guards = $self->{mpv_guards} = { };

Then, when we wait for an event to occur, delete the handler, and, if the
C<mpv_guards> object has changed, we ignore it. Something like this:

   $guards->{file_loaded} = $mpv->register_event (file_loaded => sub {
      delete $guards->{file_loaded};
      return if $guards != $self->{mpv_guards};

Commands do not have guards since they cnanot be cancelled, so we don't
have to do this for commands. But what prevents us form misinterpreting
an old event? Since F<mpv> (by default) handles commands synchronously,
we can queue a dummy command, whose only purpose is to tell us when all
previous commands are done. We use C<get_version> for this.

The simplified code looks like this:

   Scalar::Util::weaken $self;

   $mpv->cmd ("get_version")->cb (sub {

      $guards->{file_loaded} = $mpv->register_event (file_loaded => sub {
         delete $guards->{file_loaded};
         return if $guards != $self->{mpv_guards};

         $mpv->cmd (get_property => "video-format")->cb (sub {
            return if $guards != $self->{mpv_guards};

            # video-format handling
            return if eval { $_[0]->recv; 1 };

            # no video? assume audio and visualize, cpu usage be damned
            $mpv->cmd (set => "lavfi-complex" => ...");
         });

         $guards->{show} = $mpv->register_event (video_reconfig => sub {
            delete $guards->{show};
            return if $guards != $self->{mpv_guards};

            $self->{mpv_eventbox}->show_all;

            $w = $mpv->cmd (get_property => "dwidth");
            $h = $mpv->cmd (get_property => "dheight");

            $h->cb (sub {
               $w = eval { $w->recv };
               $h = eval { $h->recv };

               $mpv->cmd (set_property => "pause" => "no");

               if ($w && $h) {
                  # resize our window
               }

            });
         });

      });

   });

Most of the rest of the code is much simpler and just deals with forwarding user commands:

   } elsif ($key == $Gtk2::Gdk::Keysyms{Right}) { $mpv->cmd ("osd-msg-bar" => seek => "+10");
   } elsif ($key == $Gtk2::Gdk::Keysyms{Left} ) { $mpv->cmd ("osd-msg-bar" => seek => "-10");
   } elsif ($key == $Gtk2::Gdk::Keysyms{Up}   ) { $mpv->cmd ("osd-msg-bar" => seek => "+60");
   } elsif ($key == $Gtk2::Gdk::Keysyms{Down} ) { $mpv->cmd ("osd-msg-bar" => seek => "-60");
   } elsif ($key == $Gtk2::Gdk::Keysyms{a})   ) { $mpv->cmd ("osd-msg-msg" => cycle => "audio");
   } elsif ($key == $Gtk2::Gdk::Keysyms{j}    ) { $mpv->cmd ("osd-msg-msg" => cycle => "sub");
   } elsif ($key == $Gtk2::Gdk::Keysyms{o}    ) { $mpv->cmd ("no-osd" => "cycle-values", "osd-level", "2", "3", "0", "2");
   } elsif ($key == $Gtk2::Gdk::Keysyms{p}    ) { $mpv->cmd ("no-osd" => cycle => "pause");
   } elsif ($key == $Gtk2::Gdk::Keysyms{9}    ) { $mpv->cmd ("osd-msg-bar" => add => "ao-volume", "-2");
   } elsif ($key == $Gtk2::Gdk::Keysyms{0}    ) { $mpv->cmd ("osd-msg-bar" => add => "ao-volume", "+2");

=head1 SEE ALSO

L<AnyEvent>, L<the mpv command documentation|https://mpv.io/manual/stable/#command-interface>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

