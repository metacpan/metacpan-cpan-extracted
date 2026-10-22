=head1 NAME

AnyEvent::MCP::Client::JSONL - MCP byte streams and stdio subprocesses

=head1 SYNOPSIS

   use AnyEvent::MCP::Client::JSONL;

   my $client = AnyEvent::MCP::Client::JSONL->new (
      command => [$program, @args],
      env => { PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio" },
   );

=head1 DESCRIPTION

Use this transport when the MCP server is a subprocess or an already
connected byte stream. It reads one JSON-RPC message per line, so stdout
on a conventional stdio transport must contain protocol messages only.
The C<command> mode here connects the child's stdin and stdout to a
socketpair; diagnostic output belongs on stderr. A stray banner or log
message on the protocol stream can break the connection.

An argument array executes the program directly; a command string runs
through a shell. Prefer the array form when no shell syntax is needed.
The process starts on the first connection, not when the client object
is constructed.

=head1 FIRST CALL

To invoke a bundled server as a subprocess:

   use AnyEvent;
   use AnyEvent::MCP::Client::JSONL;

   my $client = AnyEvent::MCP::Client::JSONL->new (
      command => ["mcp-fs", "--stdio", "/home/alice/src/project"],
   );
   my $cv = AE::cv;
   $client->call (workdirs => {}, sub { $cv->send (@_) });
   my ($success, $result) = $cv->recv;
   $success or die "$result->{message}\n";
   !$result->{isError} or die "$result->{content}[0]{text}\n";

This assumes the project exists and C<mcp-fs> is installed on C<PATH>.
The subprocess is created on first use and reaped when it exits.
The caller owns the client and its event loop; callbacks also distinguish
protocol success from tool errors. See
L<AnyEvent::MCP::Server::Simple/TUTORIAL> for a complete echo server
and a matching client example.

=head1 METHODS

=over

=item $client = AnyEvent::MCP::Client::JSONL->new (%config)

Accepts the common L<AnyEvent::MCP::Client> options and these transport
options:

=over

=item command => [$program, $arg...]

=item command => $shell_command

Argument array for direct execution, or a string run through C</bin/sh -c>.
The child inherits stderr. No command runs until connecting.
Omit this option when using C<attach> instead.

=item env => { %environment }

Child environment overrides. Unspecified variables are inherited from
the parent; the parent environment is unchanged.

=item handle => { %handle }

L<AnyEvent::Handle> options. The filehandle and read/error/EOF callbacks
are managed by this transport.

=item max_size => $bytes

Bounds a buffered incoming JSON line, defaulting to 16 MiB.

=back

C<name> does not load transport defaults. The library does not infer a
subprocess command or environment.

=item $client->attach ($fh_in, $fh_out)

Uses existing handles instead of a command. C<$fh_in> may also be an
L<AnyEvent::Handle>, whose buffered input is preserved. C<$fh_out> defaults to C<$fh_in>
for a bidirectional socket. The client takes ownership. Attach before sending
requests. Closing an attached connection requires attaching new handles before
reconnecting.

Closing a subprocess connection sends SIGTERM and keeps its child watcher
alive until the child has been reaped. It does not restart an outstanding call.
An accepted multibroker idle shutdown is the exception: its child can exit
and perform cleanup without receiving SIGTERM.

=back

=cut

package AnyEvent::MCP::Client::JSONL;

use common::sense;
use parent "AnyEvent::MCP::Client";
use AnyEvent::Handle ();
use AnyEvent::Util ();
use JSON::XS ();
use Scalar::Util qw(weaken blessed);

sub attach {
   my ($self, $fh_in, $fh_out) = @_;

   $self->close if $self->{read_handle};
   weaken $self;
   $self->{read_handle} = blessed $fh_in && $fh_in->isa ("AnyEvent::Handle")
      ? $fh_in : AnyEvent::Handle->new (%{$self->{handle} || {}}, fh => $fh_in);
   $self->{read_handle}{rbuf_max} = $self->{max_size} || 16 * 1024 * 1024;
   $self->{read_handle}->on_read (undef);
   $self->{read_handle}->on_error (sub { $self->close ($_[2]) if $self });
   $self->{read_handle}->on_eof (sub { $self->close ("MCP stream closed") if $self });
   $self->{write_handle} = $fh_out ? AnyEvent::Handle->new (
      %{$self->{handle} || {}},
      fh       => $fh_out,
      on_read  => undef,
      on_error => sub { $self->close ($_[2]) if $self },
      on_eof   => sub { $self->close ("MCP output closed") if $self },
   ) : $self->{read_handle};
   $self->_read;
}

sub _open {
   my ($self, $done) = @_;

   return $done->(1, undef) if $self->{read_handle};
   return $done->(0, { transport => 1, message => "No command or attached stream" })
      unless $self->{command};

   my $ok = eval {
      local %ENV = (%ENV, %{$self->{env} || {}});
      my ($parent, $child) = AnyEvent::Util::portable_socketpair;
      die "Cannot create MCP socketpair: $!\n" unless defined $parent && defined $child;

      my $pid;
      my $cv = AnyEvent::Util::run_cmd (
         ref $self->{command} eq "ARRAY" ? $self->{command} : ["/bin/sh", "-c", $self->{command}],
         "<" => $child, ">" => $child, '$$' => \$pid, close_all => 1,
      );
      close $child;
      $self->{pid} = $pid;
      $self->attach ($parent);

      weaken $self;
      $cv->cb (sub {
         my $status = $_[0]->recv;
         if ($self && $self->{pid} == $pid) {
            delete $self->{pid};
            delete $self->{child};
            $self->close ("MCP child exited (status $status)");
         }
      });
      $self->{child} = $cv;
      1
   };
   $done->($ok ? (1, undef) : (0, { transport => 1, message => "$@" }));
}

sub _read {
   my ($self) = @_;

   weaken $self;

   $self->{read_handle}->push_read (line => sub {
      my ($handle, $line) = @_;

      return unless $self;
      my $ok = eval {
         $self->_receive (JSON::XS::decode_json $line);
         1
      };
      return $self->close ("$@") unless $ok;
      $self->_read if $self->{read_handle} && !$handle->destroyed;
   });
}

sub _send {
   my ($self, $message, $done) = @_;

   my $ok = eval {
      my $handle = $self->{write_handle} or die "MCP stream is not connected\n";
      $handle->push_write (JSON::XS::encode_json ($message) . "\n");
      1
   };
   $done->($ok ? (1, undef) : (0, { transport => 1, message => "$@" }));
}

sub _shutdown {
   my ($self) = @_;

   my $read = delete $self->{read_handle};
   my $write = delete $self->{write_handle};
   $read->destroy if $read;
   $write->destroy if $write && $write != $read;
   if (my $pid = delete $self->{pid}) {
      kill TERM => $pid unless $self->{idle_shutdown_expected};
   }
   delete $self->{child};
}

1
