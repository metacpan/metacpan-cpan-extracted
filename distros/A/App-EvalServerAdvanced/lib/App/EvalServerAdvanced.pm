package App::EvalServerAdvanced;

use strict;
our $VERSION = '0.020';

use App::EvalServerAdvanced::Sandbox;
use IO::Async::Loop;
use IO::Async::Function;
use App::EvalServerAdvanced::Config;
use App::EvalServerAdvanced::Sandbox;
use App::EvalServerAdvanced::JobManager;
use Function::Parameters;
use App::EvalServerAdvanced::Protocol;
use App::EvalServerAdvanced::Log;
use Syntax::Keyword::Try;

use Data::Dumper;
use POSIX qw/_exit/;

use Moo;
use IPC::Run qw/harness/;

has loop => (is => 'ro', lazy => 1, default => sub {IO::Async::Loop->new()});
has _inited => (is => 'rw', default => 0);
has jobman => (is => 'ro', default => sub {App::EvalServerAdvanced::JobManager->new(loop => $_[0]->loop)});
has listener => (is => 'rw');

has session_counter => (is => 'rw', default => 0);
has sessions => (is => 'ro', default => sub {+{}});

method new_session_id() {
  my $c = $self->session_counter + 1;
  $self->session_counter($c);

  return $c;
}

method init() {
  return if $self->_inited();
  my $es_self = $self;

  my $listener = $self->loop->listen(
    service => config->evalserver->port,
    host => config->evalserver->host,
    socktype => 'stream',
    on_stream => fun ($stream) {
      my $session_id = $self->new_session_id;
      $self->sessions->{$session_id} = {}; # init the session

      my $close_session = sub {
        debug "Closing session $session_id! ";
        for my $sequence (keys $self->sessions->{$session_id}{jobs}->%*) {
          my $job = $self->sessions->{$session_id}{jobs}{$sequence};
          
          $job->{future}->fail("Session ended") unless $job->{future}->is_ready;
          $job->{canceled} = 1; # Mark them as canceled
        }

        delete $self->sessions->{$session_id}; # delete the session references
      };

      $stream->configure(
        on_read_eof => sub {debug "read_eof"; $close_session->()},
        on_write_eof => sub {debug "write_eof"; $close_session->()},

        on_read => method ($buffref, $eof) {
          my ($res, $message, $newbuf); 
          do { # decode as many packets as we can
            ($res, $message, $newbuf) = eval{decode_message($$buffref)};
            debug sprintf("packet decode %d %d %d: %d", $res, length($message//''), length($newbuf//''), $eof);

            # We had an error when decoding the incoming packets, tell them and close the connection.
            if ($@) {
              debug "Session error, decoding packet. $@";
              my $message = encode_message(warning => {message => $@});
              $stream->write($message);
              $close_session->();
              $stream->close_when_empty();
            }

            if ($res) {
              $$buffref = $newbuf;

              if ($message->isa("App::EvalServerAdvanced::Protocol::Eval")) {
                my $sequence = $message->sequence;
                my $out_encoding = eval {$message->encoding} // "utf8";
                try {  
                  my $prio = ($message->prio->has_pr_deadline ? "deadline" :
                             ($message->prio->has_pr_batch    ? "batch" : "realtime"));

                  my $evalobj = {
                    files => $message->{files},
                    priority => $prio,
                    language => $message->language,
                  };

                  debug Dumper($evalobj);

                  if ($prio eq 'deadline') {
                    $evalobj->{priority_deadline} = $message->prio->pr_deadline->milliseconds;  
                  };

                  my $job = $es_self->jobman->add_job($evalobj);
                  my $future = $job->{future};
                  debug "Got job and future";

                  # Log the job for the session. Cancel any in progress with the same sequence.
                  if ($es_self->sessions->{$session_id}{jobs}{$sequence}) {
                    my $job = $self->sessions->{$session_id}{jobs}{$sequence};
                    
                    $job->{future}->fail("Session ended") unless $job->{future}->is_ready;
                    $job->{canceled} = 1; # Mark them as canceled

                    delete $es_self->sessions->{$session_id}{jobs}{$sequence};
                  }
                  $es_self->sessions->{$session_id}{jobs}{$sequence} = $job;
                  
                  $future->on_ready(fun ($future) {
                    my $output = eval {$future->get()};
                    if ($@) {
                      my $response = encode_message(warning => {message => "$@", sequence => $sequence, encoding => $out_encoding });
                      $stream->write($response);
                    } else {
                      my $response = encode_message(response => {sequence => $sequence, contents => $output, encoding => $out_encoding});
                      $stream->write($response);
                    }

                    delete $es_self->sessions->{$session_id}{jobs}{$sequence}; # get rid of the references, so we don't leak
                  });
                } catch {
                  my $response = encode_message(warning => {message => "Something went wrong during decoding: $@", encoding => $out_encoding, sequence => $sequence});
                  $stream->write($response);
                }
              } else {
                my $response = encode_message(warning => {message => "Got unhandled packet type, ". ref($message), encoding => "utf8"});
                $stream->write($response);
              }
            }
          } while($res);
          
          return 0;
        }
      );

      $self->loop->add($stream);
    },

    on_resolve_error => sub {die "Cannot resolve - $_[1]\n"},
    on_listen_error => sub {die "Cannot listen - $_[1]\n"},

    on_listen => method() {
        print "listening on: " . $self->sockhost . ':' . $self->sockport . "\n";
    },
  );

  $self->_inited(1);
}

method run() {
  $self->init();
  $self->loop->run();

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::EvalServerAdvanced - A more featured update to App::EvalServer

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This is a complete redesign and rewrite of the original code behind App::EvalServer.

This code is only BETA quality at best.  See the USE section below for more information.

=head1 FEATURES

Features over App::EvalServer

=over 1

=item Use of Linux namespaces.

The chroot is accompanied by a private mounted tmpfs filesystem.  This allows a safe writable /tmp that won't be seen by anyone else.
The evaluated code is placed in it's own PID space.  This helps prevent it from sending signals to anything else that might be running.

=item Use of Seccomp

More featureful sandboxing with Seccomp rules.  This helps prevent anything running from issuing any potentially dangerous system calls.

=item Formal network protocol.

You can send multiple requests per connection, and wait on them asynchronously.  
This helps enable better scheduling and handling of batch actions, and allows you to cancel inflight requests.
This also allows the cancelling, by the client, of a long running job while it's running.

=back

=head1 USE

You're going to want to review at least the source of L<App::EvalServerAdvanced::Sandbox> and L<App::EvalServerAdvanced::Seccomp>.
These two modules are responsible for most of the security features of the whole system.  Familiarity with them is HIGHLY recommended.

Included in this dist is a command L<esa-makesandbox> that will create a skeleton for a sandbox for you with my opinionated recommendations.

=head1 SECURITY

This system exercises a series of defense in depth measures.  However they are not perfect.  
If a kernel level exploit exists to get higher privileges (Dirty COW is a good example), it could be used to write to any bind mounted directory.

My recommendations for extra protection are to use a copy of a running system in the sandbox, and not actually use the /lib64 directories from the existing system.
This wouldn't prevent someone from leaving something behind, but would prevent it from being accessed accidentally from the original system.

Take a look at something like C<debootstrap> to create a skeleton debian based system to use in the sandbox.

=head1 WARRANTY

There is none.  You use this at your own risk.  It is opinionated 
about what is secure, but it probably isn't secure.  This software 
will result in the hacking of everyone around you.

=head1 TODO

=over 1

=item Create some kind of pluggable system for specifiying additional Seccomp rules

=item Create another pluggable system for extending App::EvalServer::Sandbox::Internal with additional subs

=item Finish enabling full configuration of the sandbox without having to edit any code

=back

=head1 SEE ALSO

L<App::EvalServerAdvanced::REPL>, L<App::EvalServerAdvanced::Protocol>

=head1 AUTHOR

Ryan Voots <simcop@cpan.org>

=cut
