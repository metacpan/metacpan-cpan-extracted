=head1 NAME

AnyEvent::Fork::Remote - remote processes with AnyEvent::Fork interface

THE API IS NOT FINISHED, CONSIDER THIS A BETA RELEASE

=head1 SYNOPSIS

   use AnyEvent;
   use AnyEvent::Fork::Remote;

   my $rpc = AnyEvent::Fork::Remote
      ->new_execp ("ssh", "ssh", "othermachine", "perl")
      ->require ("MyModule")
      ->run ("MyModule::run", my $cv = AE::cv);

   my $fh = $cv->recv;

=head1 DESCRIPTION

Despite what the name of this module might suggest, it doesn't actually
create remote processes for you. But it does make it easy to use them,
once you have started them.

This module implements a very similar API as L<AnyEvent::Fork>. In fact,
similar enough to require at most minor modifications to support both
at the same time. For example, it works with L<AnyEvent::Fork::RPC> and
L<AnyEvent::Fork::Pool>.

The documentation for this module will therefore only document the parts
of the API that differ between the two modules.

=head2 SUMMARY OF DIFFERENCES

Here is a short summary of the main differences between L<AnyEvent::Fork>
and this module:

=over 4

=item * C<send_fh> is not implemented and will fail

=item * the child-side C<run> function must read from STDIN and write to STDOUT

=item * C<fork> does not actually fork, but will create a new process

=back

=head1 EXAMPLE

This example uses a local perl (because that is likely going to work
without further setup) and the L<AnyEvent::Fork::RPC> to create simple
worker process.

First load the modules we are going to use:

   use AnyEvent;
   use AnyEvent::Fork::Remote;
   use AnyEvent::Fork::RPC;

Then create, configure and run the process:

   my $rpc = AnyEvent::Fork::Remote
      ->new_execp ("perl", "perl")
      ->eval ('
           sub myrun {
              "this is process $$, and you passed <@_>"
           }
        ')
      ->AnyEvent::Fork::RPC::run ("myrun");

We use C<new_execp> to execute the first F<perl> found in the PATH. You'll
have to make sure there is one for this to work. The perl does not
actually have to be the same perl as the one running the example, and it
doesn't need to have any modules installed.

The reason we have to specify C<perl> twice is that the first argument to
C<new_execp> (and also C<new_exec>) is the program name or path, while
the remaining ones are the arguments, and the first argument passed to a
program is the program name, so it has to be specified twice.

Finally, the standard example, send some numbers to the remote function,
and print whatever it returns:

   my $cv = AE::cv;

   for (1..10) {
      $cv->begin;
      $rpc->($_, sub {
         print "remote function returned: $_[0]\n";
         $cv->end;
      });
   }

   $cv->recv;

Now, executing F<perl> in the PATH isn't very interesting - you could have
done the same with L<AnyEvent::Fork>, and it might even be more efficient.

The power of this module is that the F<perl> doesn't need to run on the
local box, you could simply substitute another command, such as F<ssh
remotebox perl>:

   my $rpc = AnyEvent::Fork::Remote
      ->new_execp ("ssh", "ssh", "remotebox", "perl")

And if you want to use a specific path for ssh, use C<new_exec>:

   my $rpc = AnyEvent::Fork::Remote
      ->new_exec ("/usr/bin/ssh", "ssh", "remotebox", "perl")

Of course, it doesn't really matter to this module how you construct your
perl processes, what matters is that somehow, you give it a file handle
connected to the new perls STDIN and STDOUT.

=head1 PARENT PROCESS USAGE

=over 4

=cut

package AnyEvent::Fork::Remote;

use common::sense;

use Carp ();
use Errno ();

use AnyEvent ();

our $VERSION = '1.0';

# xored together must start and and with \n
my $magic0 = "Pdk{6y[_zZ";
my $magic1 = "Z^yZ7~i=oP";

=item my $proc = new_exec AnyEvent::Fork::Remote $path, @args...

Creates a new C<AnyEvent::Fork::Remote> object. Unlike L<AnyEvent::Fork>,
processes are only created when C<run> is called, every other method call
is is simply recorded until then.

Each time a new process is needed, it executes C<$path> with the given
arguments (the first array member must be the program name, as with
the C<exec> function with explicit PROGRAM argument) and both C<STDIN>
and C<STDOUT> connected to a communications socket. No input must be
consumed by the command before F<perl> is started, and no output should be
generated.

The program I<must> invoke F<perl> somehow, with STDIN and STDOUT intact,
without specifying anything to execute (no script file name, no C<-e>
switch etc.).

Here are some examples to give you an idea:

   # just "perl"
   $proc = new_exec AnyEvent::Fork::Remote
      "/usr/bin/perl", "perl";

   # rsh othernode exec perl
   $proc = new_exec AnyEvent::Fork::Remote
      "/usr/bin/rsh", "rsh", "othernode", "exec perl";

   # a complicated ssh command
   $proc = new_exec AnyEvent::Fork::Remote
      "/usr/bin/ssh",
      qw(ssh -q
         -oCheckHostIP=no -oTCPKeepAlive=yes -oStrictHostKeyChecking=no
         -oGlobalKnownHostsFile=/dev/null -oUserKnownHostsFile=/dev/null
         otherhost
         exec perl);

=item my $proc = new_execp AnyEvent::Fork::Remote $file, @args...

Just like C<new_exec>, except that the program is searched in the
C<$ENV{PATH}> first, similarly to how the shell does it. This makes it easier
to find e.g. C<ssh>:

   $proc = new_execp AnyEvent::Fork::Remote "ssh", "ssh", "otherhost", "perl";

=item my $proc = new AnyEvent::Fork::Remote $create_callback

Basically the same as C<new_exec>, but instead of a command to execute,
it expects a callback which is invoked each time a process needs to be
created.

The C<$create_callback> is called with another callback as argument,
and should call this callback with the file handle that is connected
to a F<perl> process. This callback can be invoked even after the
C<$create_callback> returns.

Example: emulate C<new_exec> using C<new>.

   use AnyEvent::Util;
   use Proc::FastSpawn;

   $proc = new AnyEvent::Fork::Remote sub {
      my $done = shift;

      my ($a, $b) = AnyEvent::Util::portable_socketpair
         or die;

      open my $oldin , "<&0" or die;
      open my $oldout, ">&1" or die;

      open STDIN , "<&" . fileno $b or die;
      open STDOUT, ">&" . fileno $b or die;

      spawn "/usr/bin/rsh", ["rsh", "othernode", "perl"];

      open STDIN , "<&" . fileno $oldin ;
      open STDOUT, ">&" . fileno $oldout;

      $done->($a);
   };

=item my $proc = new_from_fh $fh

Creates an C<AnyEvent::Fork::Remote> object from a file handle. This file
handle must be connected to both STDIN and STDOUT of a F<perl> process.

This form might be more convenient than C<new> or C<new_exec> when
creating an C<AnyEvent::Fork::Remote> object, but the resulting object
does not support C<fork>.

=cut

sub new {
   my ($class, $create) = @_;

   bless [
      $create,
      "",
      [],
   ], $class
}

sub new_from_fh {
   my ($class, @fh) = @_;

   $class->new (sub {
      my $fh = shift @fh
         or Carp::croak "AnyEvent::Fork::Remote::new_from_fh does not support fork";

      $_[0]($fh);
   });
}

sub _new_exec {
   my $p = pop;

   my ($class, $program, @argv) = @_;

   require AnyEvent::Util;
   require Proc::FastSpawn;

   $class->new (sub {
      my $done = shift;

      my ($a, $b) = AnyEvent::Util::portable_socketpair ()
         or die;

      open my $oldin , "<&0" or die;
      open my $oldout, ">&1" or die;

      open STDIN , "<&" . fileno $b or die;
      open STDOUT, ">&" . fileno $b or die;

      $p ? Proc::FastSpawn::spawnp ($program, \@argv)
         : Proc::FastSpawn::spawn  ($program, \@argv);

      open STDIN , "<&" . fileno $oldin ;
      open STDOUT, ">&" . fileno $oldout;

      $done->($a);
   })
}

sub new_exec {
   push @_, 0;
   &_new_exec
}

sub new_execp {
   push @_, 1;
   &_new_exec
}

=item $new_proc = $proc->fork

Quite the same as the same method of L<AnyEvent::Fork>, except that it
simply clones the object without creating an actual process.

=cut

sub fork {
   my $self = shift;

   bless [
      $self->[0],
      $self->[1],
      [@{ $self->[2] }],
   ], ref $self
}

=item undef = $proc->pid

The C<pid> method always returns C<undef> and only exists for
compatibility with L<AnyEvent::Fork>.

=cut

sub pid {
   undef
}

=item $proc = $proc->send_fh (...)

Not supported and always croaks.

=cut

sub send_fh {
   Carp::croak "send_fh is not supported on AnyEvent::Fork::Remote objects";
}

=item $proc = $proc->eval ($perlcode, @args)

Quite the same as the same method of L<AnyEvent::Fork>.

=cut

# quote a binary string as a perl scalar
sub sq($) {
   my $s = shift;

   $s =~ /'/
      or return "'$s'";

   $s =~ s/(\x10+)/\x10.'$1'.q\x10/g;
   "q\x10$s\x10"
}

# quote a list of strings
sub aq(@) {
   "(" . (join ",", map sq $_, @_) . ")"
}

sub eval {
   my ($self, $perlcode, @args) = @_;

   my $linecode = $perlcode;
   $linecode =~ s/\s+/ /g; # takes care of \n
   $linecode =~ s/"/''/g;
   substr $linecode, 70, length $linecode, "..." if length $linecode > 70;

   $self->[1] .= '{ local @_ = ' . (aq @args) . ";\n#line 1 \"'$linecode'\"\n$perlcode;\n}\n";

   $self
}

=item $proc = $proc->require ($module, ...)

Quite the same as the same method of L<AnyEvent::Fork>.

=cut

sub require {
   my ($self, @modules) = @_;

   $self->eval ("require $_")
      for @modules;

   $self
}

=item $proc = $proc->send_arg ($string, ...)

Quite the same as the same method of L<AnyEvent::Fork>.

=cut

sub send_arg {
   my ($self, @arg) = @_;

   push @{ $self->[2] }, @arg;

   $self
}

=item $proc->run ($func, $cb->($fh))

Very similar to the run method of L<AnyEvent::Fork>.

On the parent side, the API is identical, except that a C<$cb> argument of
C<undef> instead of a valid file handle signals an error.

On the child side, the "communications socket" is in fact just C<*STDIN>,
and typically can only be read from (this highly depends on how the
program is created - if you just run F<perl> locally, it will work for
both reading and writing, but commands such as F<rsh> or F<ssh> typically
only provide read-only handles for STDIN).

To be portable, if the run function wants to read data that is written to
C<$fh> in the parent, then it should read from STDIN. If the run function
wants to provide data that can later be read from C<$fh>, then it should
write them to STDOUT.

You can write a run function that works with both L<AnyEvent::Fork>
and this module by checking C<fileno $fh>. If it is C<0> (meaning
it is STDIN), then you should use it for reading, and STDOUT for
writing. Otherwise, you should use the file handle for both:

   sub run {
      my ($rfh, ...) = @_;
      my $wfh = fileno $rfh ? $rfh : *STDOUT;

      # now use $rfh for reading and $wfh for writing
   }

=cut

sub run {
   my ($self, $func, $cb) = @_;

   $self->[0](sub {
      my $fh = shift
         or die "AnyEvent::Fork::Remote: create callback failed";

      my $owner = length $ENV{HOSTNAME} ? "$ENV{HOSTNAME}:$$" : "*:$$";

      my $code = 'BEGIN { $0 = ' . (sq "$owner $func") . '; ' . $self->[1] . "}\n"
               . 'syswrite STDOUT, ' . (sq $magic0) . '^' . (sq $magic1) . ';'
               . '{ sysread STDIN, my $dummy, 1 }'
               . "\n$func*STDIN," . (aq @{ $self->[2] }) . ';'
               . "\n__END__\n";

      AnyEvent::Util::fh_nonblocking $fh, 1;

      my ($rw, $ww);

      my $ofs;

      $ww = AE::io $fh, 1, sub {
         my $len = syswrite $fh, $code, 1<<20, $ofs;

         if ($len || $! == Errno::EAGAIN || $! == Errno::EWOULDBLOCK) {
            $ofs += $len;
            undef $ww if $ofs >= length $code;
         } else {
            # error
            ($ww, $rw) = (); $cb->(undef);
         }
      };

      my $rbuf;

      $rw = AE::io $fh, 0, sub {
         my $len = sysread $fh, $rbuf, 1<<10;

         if ($len || $! == Errno::EAGAIN || $! == Errno::EWOULDBLOCK) {
            $rbuf = substr $rbuf, -length $magic0 if length $rbuf > length $magic0;

            if ($rbuf eq ($magic0 ^ $magic1)) {
               # all data was sent, magic was received - both
               # directions should be "empty", and therefore
               # the socket must accept at least a single octet,
               # to signal the "child" to go on.
               undef $rw;
               die if $ww; # uh-oh

               syswrite $fh, "\n";
               $cb->($fh);
            }
         } else {
            # error
            ($ww, $rw) = (); $cb->(undef);
         }
      };
   });
}

=back

=head1 SEE ALSO

L<AnyEvent::Fork>, the same as this module, for local processes.

L<AnyEvent::Fork::RPC>, to talk to the created processes.

L<AnyEvent::Fork::Pool>, to manage whole pools of processes.

=head1 AUTHOR AND CONTACT INFORMATION

 Marc Lehmann <schmorp@schmorp.de>
 http://software.schmorp.de/pkg/AnyEvent-Fork-Remote

=cut

1

