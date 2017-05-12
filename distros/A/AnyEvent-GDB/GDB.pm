=head1 NAME

AnyEvent::GDB - asynchronous GDB machine interface interface

=head1 SYNOPSIS

   use AnyEvent::GDB;

=head1 DESCRIPTION

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

It implements the GDB MI protocol, which can be used to talk to GDB
without having to parse the ever changing command syntax aimed at humans.

It properly quotes your commands and parses the data structures returned
by GDB.

At the moment, it's in an early stage of development, so expect changes,
and, over time, further features (such as breakpoint-specific callbacks
and so on).

=head1 EXAMPLE PROGRAM

To get you started, here is an example program that runs F</bin/ls>,
displaying the stopped information when hitting a breakpoint on C<_exit>:

   use Data::Dump;
   use AnyEvent::GDB;

   our $gdb = new AnyEvent::GDB
      trace => 1,
      on_exec_stopped => sub {
         ddx $_[0];
      },
   ;

   my $done

   ddx $gdb->cmd_sync (file_exec_and_symbols => "/bin/ls");
   ddx $gdb->cmd_sync (break_insert => "_exit");
   ddx $gdb->cmd_sync ("exec_run");

   AE::cv->recv;

=head2 PROTOCOL QUIRKS

=head3 Minus vs. underscores

The MI protocol uses C<-> to separate name components, while in Perl, you
use C<_> for this purpose.

This module usually accepts either form as input, and always converts
names with C<-> to names with C<_>, so the C<library-loaded> notify might
become C<notify_library_loaded>, and the C<host-name> result in that event
is stored in the C<host_name> hash element in Perl.

=head3 Output redirection

Unfortunately, GDB has no (portable) provision to separate GDB
input/output from program input/output. Obviously, without a distinction
between program I/O and GDB I/O it becomes impossible to safely control
GDB.

There are two ways for you around it: redirect stdin/stdout yourself, or
set a tty (eg. with the C<inferior_set_tty> command).

Unfortunately, the MI interface does not seem to support any kind
of I/O redirection, so this module helps you a bit, by setting the
C<exec-wrapper> variable with a console C<set> commmand. That is, this
module does soeQmthing like the following for you, providing proper file
descriptors for your actual stdin and stdout:

   set exec-wrapper <&5 >&6

The actual I/O redirection operators are also stored in C<< $gdb->{stdio}
>>, so you can even do it yourself, e.g. when providing your own wrapper:

   $self->cmd_raw ("set exec-wrapper $self->{stdio}", sub { });

(You need to use a raw command, as the "correct" C<gdb_set> MI command
silently ignores any C<exec-wrapper> setting).

=cut

package AnyEvent::GDB;

use common::sense;

use Carp ();
use Fcntl ();
use Scalar::Util ();

use AnyEvent ();
use AnyEvent::Util ();

our $VERSION = '0.2';

=head2 METHODS

=over 4

=item $gdb = new AnyEvent::GDB key => value...

Create a new GDB object using the given named parameters.

For initial experiments, it is highly recommended to run with tracing or
at least C<verbose> enabled. And don't forget to provide an C<on_eof>
callback.

   my $gdb = new AnyEvent::GDB
      on_eof => sub {
         print "We are done.\n";
      },
      trace => 1; # or verbose => 1, for less output

=over 4

=item exec => $path (default: "gdb")

The path of the GDB executable.

=item args => [$string...] (default: ["-n"])

An optional array of parameters to pass to GDB. This should not be
used to load a program executable, use the C<file_exec_and_symbols>,
C<target_attach> or similar MI commands instead.

=item trace => $boolean (default: 0)

If true, then all commands sent to GDB are printed to STDOUT prefixed with
"> ", and all replies received from GDB are printed to STDOUT prefixed
with "< ".

=item verbose => $boolean (default: true if trace is enabled, false otherwise)

If true, then log output and possibly other information is printed to
STDOUT.

=item on_xxxx => $callback->(...)

This specifies a callback for a specific event - see the L<EVENTS> section
later in this document.

=back

=cut

sub new {
   my ($class, %arg) = @_;

   my $self = bless {
      %arg,
   }, $class;

   my $exe = delete $self->{exec} // "gdb";
   my $arg = delete $self->{args} // [qw(-n)];

   $self->{verbose} = 1
      if $self->{trace} && !exists $self->{verbose};

   ($self->{fh}, my $fh2) = AnyEvent::Util::portable_socketpair;

   $self->{pid} = fork;

   open my $stdin , "<&STDIN" ;
   open my $stdout, ">&STDOUT";

   unless ($self->{pid}) {
      if (defined $self->{pid}) {
         open STDIN , "<&", $fh2;
         open STDOUT, ">&", $fh2;
         fcntl $stdin , Fcntl::F_SETFD, 0;
         fcntl $stdout, Fcntl::F_SETFD, 0;
         exec $exe, qw(--interpreter=mi2 -q), @$arg;
         kill 9, 0; # don't want to load the POSIX module just for this
      } else {
         Carp::croak "cannot fork: $!";
      }
   }

   AnyEvent::Util::fh_nonblocking $self->{fh}, 1;

   {
      Scalar::Util::weaken (my $self = $self);
      $self->{rw} = AE::io $self->{fh}, 0, sub {
         my $len = sysread $self->{fh}, $self->{rbuf}, 256, length $self->{rbuf};

         defined $len || $self->eof;

         $self->feed ("$1")
            while $self->{rbuf} =~ s/^([^\r\n]*)\r?\n//;
      };

      $self->{wcb} = sub {
         my $len = syswrite $self->{fh}, $self->{wbuf};
         substr $self->{wbuf}, 0, $len, "";
         delete $self->{ww} unless length $self->{wbuf};
      };
   }

   $self->{stdio} = sprintf "<&%d >&%d", fileno $stdin, fileno $stdout;

   $self->cmd_raw ("set exec-wrapper $self->{stdio}", sub { });

   $self
}

#sub DESTROY {
#)}

sub eof {
   my ($self) = @_;

   $self->event ("eof");

   %$self = ();
}

sub send {
   my ($self, $data) = @_;

   print "> $data"
      if $self->{trace};

   $self->{wbuf} .= $data;
   $self->{ww} ||= AE::io $self->{fh}, 1, $self->{wcb};
}

our %C_ESCAPE = (
   "\\" => "\\",
   '"' => '"',
   "'" => "'",
   "?" => "?",

   a => "\x07",
   b => "\x08",
   t => "\x09",
   n => "\x0a",
   v => "\x0b",
   f => "\x0c",
   r => "\x0d",
);

sub _parse_c_string {
   my $r = "";

   # syntax is not documented, so we do full C99, except unicode

   while () {
      if (/\G([^"\\\n]+)/gc) {
         $r .= $1;
      } elsif (/\G\\([abtnvfr\\"'?])/gc) {
         $r .= $C_ESCAPE{$1};
      } elsif (/\G\\([0-8]{1,3})/gc) {
         $r .= chr oct $1;
      } elsif (/\G\\x([0-9a-fA-F]+)/gc) {
         $r .= chr hex $1;
      } elsif (/\G"/gc) {
         last;
      } else {
         die "invalid string syntax\n";
      }
   }

   $r
}

sub _parse_value {
   if (/\G"/gc) { # c-string
      &_parse_c_string

   } elsif (/\G\{/gc) { # tuple
      my $r = &_parse_results;

      /\G\}/gc
         or die "tuple does not end with '}'\n";

      $r
      
   } elsif (/\G\[/gc) { # list
      my @r;

      until (/\G\]/gc) {
         # if GDB outputs "result" in lists, let me know and uncomment the following lines
#         # list might also contain key value pairs, but apparently
#         # those are supposed to be ordered, so we use an array in perl.
#         push @r, $1
#            if /\G([^=,\[\]\{\}]+)=/gc;

         push @r, &_parse_value;

         /\G,/gc
            or last;
      }

      /\G\]/gc
         or die "list does not end with ']'\n";

      \@r

   } else {
      die "value expected\n";
   }
}

sub _parse_results {
   my %r;

   # syntax for string is undocumented
   while (/\G([^=,\[\]\{\}]+)=/gc) {
      my $k = $1;

      $k =~ y/-/_/;

      $r{$k} = &_parse_value;

      /\G,/gc
         or last;
   }

   \%r
}

my %type_map = qw(
   * exec
   + status
   = notify
);

sub feed {
   my ($self, $line) = @_;

   print "< $line\n"
      if $self->{trace};

   for ($line) {
      if (/^\(gdb\)\s*$/gc) { # docs say "(gdb)", but reality says "(gdb) "
         # nop
      } else {
         /^([0-9]*)/gc; # [token], actually ([0-9]+)?
         my $token = $1;

         eval {
            if (/\G\^(done|running|connected|error|exit)/gc) { # result
               my $class = $1 eq "running" ? "done" : $1;
               # documented for error is an incompatible format, but in reality it is sane

               my $results = /\G,/gc ? &_parse_results : {};

               if (my $cb = delete $self->{cb}{$token}) {
                  # unfortunately, gdb sometimes outputs multiple result records for one command
                  $cb->($class, $results, delete $self->{console});
               }

            } elsif (/\G([*+=])([^,]+)/gc) { # *exec-async, +status-async, =notify-async
               my ($type, $class) = ($type_map{$1}, $2);

               my $results = /\G,/gc ? &_parse_results : {};

               $class =~ y/-/_/;

               $self->event ($type => $class, $results);
               $self->event ("$type\_$class" => $results);

            } elsif (/\G~"/gc) {
               push @{ $self->{console} }, &_parse_c_string;
            } elsif (/\G&"/gc) {
               my $log = &_parse_c_string;
               chomp $log;
               print "$log\n" if $self->{verbose};
               $self->event (log => $log);
            } elsif (/\G\@"/gc) {
               $self->event (target => &_parse_c_string);
            }
         };

         /\G(.{0,16})/gcs;
         $@ = "extra data\n" if !$@ and length $1;

         if ($@) {
            chop $@;
            warn "AnyEvent::GDB: parse error: $@, at ...$1\n";
            $self->eof;
         }
      }
   }
}

sub _q($) {
   return $_[0]
      if $_[0] =~ /^[A-Za-z0-9_]+$/; # we are a lot more strict than the spec

   local $_ = shift;
   utf8::encode $_; # just in case
   s/([^\x20-\x21\x23-\x5b\x5d-\x7e])/sprintf "\\x%02x", ord $1/ge;
   "\"$_\""
}

=item $gdb->cmd_raw ($command, $cb->($class, $results, $console))

Execute a raw command: C<$command> is sent unchanged to GDB. See C<cmd_>
for a description of the callback arguments.

Example: execute a CLI command and print its output.

   $gdb->cmd_raw ("info sh", sub {
      print "$_[3]\n";
   });

=cut

sub cmd_raw {
   my ($self, $cmd, $cb) = @_;

   my $token = ++$self->{token};
   $self->send ("$token$cmd\n");
   $self->{cb}{$token} = $cb;
}

=item $gdb->cmd ($command => [$option...], $parameter..., $cb->($class, $results, $console))

Execute a MI command and invoke the callback with the results.

C<$command> is a MI command name. The leading minus sign can be omitted,
and instead of minus signs, you can use underscores, i.e. all the
following command names are equivalent:

   "-break-insert"   # as documented in the GDB manual
   -break_insert     # using underscores and _ to avoid having to quote
   break_insert      # ditto, when e.g. used to the left of a =>
   "break-insert"    # no leading minus

The second argument is an optional array reference with options (i.e. it
can simply be missing). Each C<$option> is either an option name (similar
rules as with command names, i.e. no initial C<-->) or an array reference
with the first element being the option name, and the remaining elements
being parameters: [$option, $parameter...].

The remaining arguments, excluding the last one, are simply the parameters
passed to GDB.

All options and parameters will be properly quoted.

When the command is done, the callback C<$cb> will be invoked with
C<$class> being one of C<done>, C<connected>, C<error> or C<exit>
(note: not C<running>), C<$results> being a has reference with all the
C<variable=value> pairs from the result list.

C<$console> is an array reference with all the GDB console messages
written while command executes (for MI commands, this should always be
C<undef> and can be ignored).

Example: #todo#

=cut

sub cmd {
   my $cb = pop;
   my ($self, $cmd, @arg) = @_;

   $cmd =~ s/^[\-_]?/_/;
   $cmd =~ y/_/-/;

   $cmd .= " ";

   my $opt = ref $arg[0] ? shift @arg : [];

   for (@$opt) {
      $cmd .= "-";
      $cmd .= (_q $_) . " "
         for (ref) ? @$_ : $_;
   }

   # the MI syntax is inconsistent, providing "--" in case
   # parameters start with "-", but not allowing "-" as first
   # char of a parameter. in fact, "--" is flagged as unknown
   # option.
   if (@arg) {
#      $cmd .= "-- ";

      $cmd .= (_q $_) . " "
         for @arg;
   }

   # remove trailing " "
   substr $cmd, -1, 1, "";

   $self->cmd_raw ($cmd, $cb);
}

=item ($results, $console) = $gdb->cmd_sync ($command => [$option...], $parameter...])
=item $results = $gdb->cmd_sync ($command => [$option...], $parameter...])

Like C<cmd>, but blocks execution until the command has been executed, and
returns the results if sucessful. Croaks when GDB returns with an error.

This is purely a convenience method for small scripts: since it blocks
execution using a condvar, it is not suitable to be used inside callbacks
or modules.

That is, unless L<Coro> is used - with Coro, you can run multiple
C<cmd_sync> methods concurrently form multiple threads, with no issues.

=cut

sub cmd_sync {
   push @_, my $cv = AE::cv;
   &cmd;

   my ($class, $results, $console) = $cv->recv;

   Carp::croak $results->{msg}
      if $class eq "error";

   wantarray ? ($results, $console) : $results
}

sub event {
   my ($self, $event, @args) = @_;

#   if ($self->{verbose}) {
#      use Data::Dumper;
#      print Data::Dumper
#            ->new ([[$event, @args]])
#            ->Pair ("=>")
#            ->Useqq (1)
#            ->Indent (0)
#            ->Terse (1)
#            ->Quotekeys (0)
#            ->Sortkeys (1)
#            ->Dump,
#            "\n";
#   }

   my $cb;

   $cb = $self->can ("on_event")  and $cb->($self, $event, @args);
   $cb = $self->    {on_event}    and $cb->($self, $event, @args);
   $cb = $self->can ("on_$event") and $cb->($self, $event, @args);
   $cb = $self->    {"on_$event"} and $cb->($self, $event, @args);
}

# predefined events

sub on_notify_thread_group_added {
   my ($self, undef, $r) = @_;

   $self->{thread_group}{$r->{id}} = $r;
}

sub on_notify_thread_group_removed {
   my ($self, undef, $r) = @_;

   delete $self->{thread_group}{$r->{id}};
}

sub on_notify_thread_group_started {
   my ($self, undef, $r) = @_;

   delete $self->{thread_group}{exit_code};
   $self->{thread_group}{$r->{id}}{pid} = $r->{pid};
}

sub on_notify_thread_group_exited {
   my ($self, undef, $r) = @_;

   delete $self->{thread_group}{pid};
   $self->{thread_group}{$r->{id}}{exit_code} = $r->{exit_code};
}

sub on_notify_record_started {
   my ($self, undef, $r) = @_;

   $self->{thread_group}{$r->{id}}{recording} = 1;
}

sub on_notify_record_stopped {
   my ($self, undef, $r) = @_;

   $self->{thread_group}{$r->{id}}{recording} = 0;
}

sub on_notify_thread_created {
   my ($self, undef, $r) = @_;

   $self->{thread}{$r->{id}} = $r;
}

sub on_notify_thread_exited {
   my ($self, undef, $r) = @_;

   delete $self->{thread}{$r->{id}};
}

sub _threads {
   my ($self, $id) = @_;

   ref $id
      ? @{ $self->{thread} }{@$id}
      : $id eq "all"
         ? values %{ $self->{thread} }
         : $self->{thread}{$id}
}

sub on_exec_running {
   my ($self, undef, $r) = @_;

   for ($self->_threads ($r->{thread_id})) {
      delete $_->{stopped};
      $_->{running} = 1;
   }
}

sub on_exec_stopped {
   my ($self, undef, $r) = @_;

   for ($self->_threads ($r->{stopped_threads})) {
      delete $_->{running};
      $_->{stopped} = $r;
   }

#   $self->event ("thread_$r->{reason}" => $r, [map $_->{id}, $self->_threads ($r)]);
}

sub _thread_groups {
   my ($self, $r) = @_;

   exists $r->{thread_group}
      ? $self->{thread_group}{$r->{thread_group}}
      : values %{ $self->{thread_group} }
}

sub on_notify_library_loaded {
   my ($self, undef, $r) = @_;

   $_->{library}{$r->{id}} = $r
      for $self->_thread_groups ($r);
}

sub on_notify_library_unloaded {
   my ($self, undef, $r) = @_;

   delete $_->{library}{$r->{id}}
      for $self->_thread_groups ($r);
}

=back

=head2 EVENTS

AnyEvent::GDB is asynchronous in nature, as the goal of the MI interface
is to be fully asynchronous. Due to this, a user of this interface must
be prepared to handle various events.

When an event is produced, the GDB object will look for the following four
handlers and, if found, will call each one in order with the GDB object
and event name (without C<on_>) as the first two arguments, followed by
any event-specific arguments:

=over 4

=item on_event method on the GDB object

Useful when subclassing.

=item on_event constructor parameter/object member

The callback specified as C<on_event> parameter to the constructor.

=item on_EVENTNAME method on the GDB object

Again, mainly useful when subclassing.

=item on_EVENTNAME constructor parameter/object member

Any callback specified as C<on_EVENTNAME> parameter to the constructor.

=back

You can change callbacks dynamically by simply replacing the corresponding
C<on_XXX> member in the C<$gdb> object:

   $gdb->{on_event} = sub {
      # new event handler
   };

Here's the list of events with a description of their arguments.

=over 4

=item on_eof => $cb->($gdb, "eof")

Called whenever GDB closes the connection. After this event, the object is
partially destroyed and must not be accessed again.

=item on_target => $cb->($gdb, "target", $string)

Output received from the target. Normally, this is sent directly to STDOUT
by GDB, but remote targets use this hook.

=item on_log => $cb->($gdb, "log", $string)

Log output from GDB. Best printed to STDOUT in interactive sessions.

=item on_TYPE => $cb->($gdb, "TYPE", $class, $results)

Called for GDB C<exec>, C<status> and C<notify> event (TYPE is one of
these three strings). C<$class> is the class of the event, with C<->
replaced by C<_> everywhere.

For each of these, the GDB object will create I<two> events: one for TYPE,
and one for TYPE_CLASS. Usuaully you should provide the more specific
event (TYPE_CLASS).

=item on_TYPE_CLASS => $cb->($gdb, "TYPE_CLASS", $results)

Called for GDB C<exec>, C<status> and C<notify> event: TYPE is one
of these three strings, the class of the event (with C<-> replaced b
C<_>s) is appended to it to form the TYPE_CLASS (e.g. C<exec_stopped> or
C<notify_library_loaded>).

=back

=head2 STATUS STORAGE

The default implementations of the event method store the thread,
thread_group, recording, library and running status insid ethe C<$gdb>
object.

You can access these at any time. Specifically, the following information
is available:

=over 4

=item C<< $gdb->{thread_group}{I<id>} >>

The C<thread_group> member stores a hash for each existing thread
group. The hash always contains the C<id> member, but might also contain
other members.

=item C<< $gdb->{thread_group}{I<id>}{pid} >>

The C<pid> member only exists while the thread group is running a program,
and contaisn the PID of the program.

=item C<< $gdb->{thread_group}{I<id>}{exit_code} >>

The C<exit_code> member only exists after a program has finished
executing, and before it is started again, and contains the exit code of
the program.

=item C<< $gdb->{thread_group}{I<id>}{recording} >>

The C<recording> member only exists if recording has been previously
started, and is C<1> if recoridng is currently active, and C<0> if it has
been stopped again.

=item C<< $gdb->{thread}{I<id>} >>

The C<thread> member stores a hash for each existing thread. The hash
always contains the C<id> member with the thread id, and the C<group_id>
member with the corresponding thread group id.

=item C<< $gdb->{thread}{I<id>}{running} >>

The C<running> member is C<1> while the thread is, well, running, and is
missing otherwise.

=item C<< $gdb->{thread}{I<id>}{stopped} >>

The C<stopped> member contains the result list from the C<on_exec_stopped>
notification that caused the thread to stop, and only exists when the
thread is topped.

=item C<< $gdb->{library}{I<id>} >>

The C<library> member contains all results from the C<on_library_loaded>
event (such as C<id>, C<target_name>, C<host_name> and potentially a
C<thread_group>.

=back

=head1 SEE ALSO

L<AnyEvent>, L<http://sourceware.org/gdb/current/onlinedocs/gdb/GDB_002fMI.html#GDB_002fMI>.

=head1 AUTHOR

   Marc Lehmann <schmorp@schmorp.de>
   http://home.schmorp.de/

=cut

1
