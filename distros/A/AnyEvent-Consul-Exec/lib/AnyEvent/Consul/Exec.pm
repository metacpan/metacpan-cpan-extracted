package AnyEvent::Consul::Exec;
$AnyEvent::Consul::Exec::VERSION = '0.003';
# ABSTRACT: Execute a remote command across a Consul cluster

use 5.020;
use warnings;
use strict;
use experimental qw(postderef);

use Consul 0.022;
use AnyEvent;
use AnyEvent::Consul;
use JSON::MaybeXS;
use Type::Params qw(compile);
use Types::Standard qw(ClassName Dict Str Optional CodeRef ArrayRef Int slurpy);

my @callbacks = map { "on_$_" } qw(submit ack output exit done error);

sub new {
  state $check = compile(
    ClassName,
    slurpy Dict[
      command => Str,
      wait    => Optional[Int],
      dc      => Optional[Str],
      node    => Optional[Str],
      service => Optional[Str],
      tag     => Optional[Str],
      consul_args => Optional[ArrayRef],
      map { $_ => Optional[CodeRef] } @callbacks,
    ],
  );
  my ($class, $self) = $check->(@_);
  map { $self->{$_} //= sub {} } @callbacks;
  $self->{wait} //= 2;
  $self->{consul_args} //= [];
  $self->{dc_args} = $self->{dc} ? [dc => $self->{dc}] : [];
  return bless $self, $class;
}

sub _wait_responses {
  my ($self, $index) = @_;

  $self->{_c}->kv->get_all(
    "_rexec/$self->{_sid}",
    index => $index,
    $self->{dc_args}->@*,
    cb => sub {
      my ($kv, $meta) = @_;
      my @changed = grep { $_->modify_index > $index } $kv->@*;

      for my $kv (@changed) {
        my ($key) = $kv->key =~ m{^_rexec/$self->{_sid}/(.+)};
        unless ($key) {
          warn "W: consul told us '".$kv->key."' changed, but we aren't interested in it, consul bug?\n";
          next;
        }

        if ($key eq 'job') {
          $self->{on_submit}->();
          next;
        }

        my ($node, $act, $id) = split '/', $key, 3;
        unless ($act) {
          warn "W: malformed rexec response: $key\n";
        }

        if ($act eq 'ack') {
          $self->{_nack}++;
          $self->{on_ack}->($node);
          next;
        }

        if ($act eq 'out') {
          $self->{on_output}->($node, $kv->value);
          next;
        }

        if ($act eq 'exit') {
          $self->{_nexit}++;
          $self->{on_exit}->($node, $kv->value);
          if ($self->{_nack} == $self->{_nexit}) {
            # XXX super naive. there might be some that haven't acked yet
            #     should schedule done for a lil bit in the future
            $self->{_done} = 1;
            $self->_cleanup(sub { $self->{on_done}->() });
          }
          next;
        }

        warn "W: $node: unknown action: $act\n";
      }

      $self->_wait_responses($meta->index) unless $self->{_done};
    },
  );
}

sub _fire_event {
  my ($self) = @_;
  my $payload = {
    Prefix  => "_rexec",
    Session => $self->{_sid},
  };
  $self->{_c}->event->fire(
    "_rexec",
    payload => encode_json($payload),
    $self->{dc_args}->@*,
    $self->{node}    ? (node    => $self->{node})    : (),
    $self->{service} ? (service => $self->{service}) : (),
    $self->{tag}     ? (tag     => $self->{tag})     : (),
    cb => sub { $self->_wait_responses(0) },
  );
}

sub _setup_job {
  my ($self) = @_;
  my $job = {
    Command => $self->{command},
    Wait    => $self->{wait} * 1_000_000_000, # nanoseconds
  };
  $self->{_c}->kv->put(
    "_rexec/$self->{_sid}/job",
    encode_json($job),
    acquire => $self->{_sid},
    $self->{dc_args}->@*,
    cb => sub { $self->_fire_event },
  );
}

sub _start_session {
  my ($self) = @_;

  my $session_started_cb = sub {
    $self->{_sid} = shift;
    $self->{_refresh_guard} = AnyEvent->timer(after => "5s", interval => "5s", cb => sub {
      $self->{_c}->session->renew(
        $self->{_sid},
        $self->{dc_args}->@*,
      );
    });
    $self->_setup_job;
  };

  if ($self->{dc}) {
    $self->{_c}->health->service(
      "consul",
      $self->{dc_args}->@*,
      cb => sub {
        my ($services) = @_;
        my $service = shift $services->@*;
        unless ($service) {
          # XXX no consuls at remote DC
          ...
        }
        my $node = $service->node->name;
        $self->{_c}->session->create(
          Consul::Session->new(
            name     => 'Remote exec via ...', # XXX local node name
            behavior => 'delete',
            ttl      => "15s",
            node     => $node,
          ),
          $self->{dc_args}->@*,
          cb => $session_started_cb,
        );
      },
      error_cb => sub {
        my ($err) = @_;
        $self->_cleanup(sub { $self->{on_error}->($err) });
      },
    );
  }

  else {
    $self->{_c}->session->create(
      Consul::Session->new(
        name     => 'Remote exec',
        behavior => 'delete',
        ttl      => "15s",
      ),
      cb => $session_started_cb,
    );
  }
}

sub _cleanup {
  my ($self, $cb) = @_;
  delete $self->{_refresh_guard};
  if ($self->{_sid}) {
    $self->{_c}->session->destroy(
      $self->{_sid},
      $self->{dc_args}->@*,
      cb => sub {
      $self->{_c}->kv->delete(
        "_rexec/$self->{_sid}",
        recurse => 1,
        $self->{dc_args}->@*,
        cb => sub {
          delete $self->{_sid};
          delete $self->{_c};
          $cb->();
        },
      );
    });
  }
  else {
    delete $self->{_sid};
    delete $self->{_c};
    $cb->();
  }
}

sub start {
  my ($self) = @_;
  $self->{_c} = AnyEvent::Consul->new($self->{consul_args}->@*, error_cb => sub {
    my ($err) = @_;
    $self->_cleanup(sub { $self->{on_error}->($err) });
  });
  $self->_start_session;
  return;
}

1;

=pod

=encoding UTF-8

=for markdown [![Build Status](https://secure.travis-ci.org/robn/AnyEvent-Consul-Exec.png)](http://travis-ci.org/robn/AnyEvent-Consul-Exec)

=head1 NAME

AnyEvent::Consul::Exec - Execute a remote command across a Consul cluster

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::Consul::Exec;
    
    my $cv = AE::cv;
    
    my $e = AnyEvent::Consul::Exec->new(
        
        # command to run
        command => 'uptime',

        # number of seconds target will wait for command, without sending
        # output, before terminating it
        wait => 2,
        
        # called once job is submitted to Consul
        on_submit => sub {
            say "job submitted";
        },
        
        # called as each target node starts to process the job
        # multiple calls, once per node
        on_ack => sub {
            my ($node) = @_;
            say "$node: ack";
        },
        
        # called when a node has output from the job
        # can be called zero or more times per node, as more output
        # becomes available
        on_output => sub {
            my ($node, $output) = @_;
            say "$node: output:";
            say "$node> $_" for split("\n", $output);
        },
        
        # called when the node completes a job
        # multiple calls, one per node
        on_exit => sub {
            my ($node, $rc) = @_;
            say "$node: exit: $rc";
        },
        
        # called once all nodes have reported completion
        # object is unusable past this point
        on_done => sub {
            say "job done";
            $cv->send;
        },
        
        # called if an error occurs anywhere during processing (not command errors)
        # typically called if Consul is unable to service requests
        # object is unusable past this point
        on_error => sub {
            my ($err) = @_;
            say "error: $err";
            $cv->send;
        },
    );
    
    # begin execution
    $e->start;

    $cv->recv;

=head1 DESCRIPTION

AnyEvent::Consul::Exec is an interface to Consul's "exec" agent function. This
is the same thing you get when you run L<consul exec|https://www.consul.io/docs/commands/exec.html>.

C<consul exec> is great, but its output is text-based, making it awkward to
parse to determine what happened on each node that ran the command.
C<AnyEvent::Consul::Exec> replaces the client portion with a library you can
use to get info about what is happening on each node as it happens.

As the name implies, it expects to be run inside an L<AnyEvent> event loop.

=head1 BASICS

Start off by instantiating a C<AnyEvent::Consul::Exec> object with the command
you want to run:

    my $e = AnyEvent::Consul::Exec->new(
        command => 'uptime',
    );

Then call C<start> to kick it off:

    $e->start;

As the C<AnyEvent> event loop progresses, the command will be executed on
remote nodes. Output and results of that command on each node will be posted to
callbacks you can optionally provide to the constructor.

When calling the constructor, you can include the C<consul_args> option with an
arrayref as a value. Anything in that arrayref will be passed as-is to the
C<AnyEvent::Consul> constructor. Use this to set the various client options
documented in L<AnyEvent::Consul> and L<Consul>.

The C<wait> option will tell the target agent how long to wait, without
receiving output, before killing the command. This does the same thing as the
C<-wait> option to C<consul exec>.

The C<node>, C<service> and C<tag> each take basic regexes that will be used to
match nodes to run the command on. See the corresponding options to C<consul exec>
for more info.

The C<dc> option can take the name of the datacenter to run the command in. The
exec mechanism is limited to a single datacentre. This option will cause
L<AnyEvent::Consul::Exec> to find a Consul agent in the named datacenter and
execute the command there (without it, the local node is used).

=head1 CALLBACKS

C<AnyEvent::Consul::Exec> will arrange for various callbacks to be called as
the command is run on each node and its output and exit code returned. Set this
up by passing code refs to the constructor:

=over 4

=item * C<on_submit>

Called when the command is fully accepted by Consul (ie in the KV store, ready
for nodes to find).

=item * C<on_ack($node)>

Called for each node as they notice the command has been entered into the KV
store and start running it.

=item * C<on_output($node, $output)>

Called when a command emits some output. May be called multiple times per node,
or not at all if the command has no output.

=item * C<on_exit($node, $rc)>

Called when a command completes.

=item * C<on_done>

Called when all remote commands have completed. After this call, the object is
no longer useful.

=item * C<on_error($err)>

Called if an error occurs while communicating with Consul (local agent
unavailable, quorum loss, etc). After this call, the object is no longer
useful.

=back

=head1 CAVEATS

Consul's remote execution protocol is internal to Consul itself and is not
documented. This module has been confirmed to work in Consul 0.9.0 (the latest
release at the time of writing). The Consul authors L<may change the underlying
mechanism|https://github.com/hashicorp/consul/issues/1120> in the future, but
this module should continue to work.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/AnyEvent-Consul-Exec/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/AnyEvent-Consul-Exec>

  git clone https://github.com/robn/AnyEvent-Consul-Exec.git

=head1 AUTHORS

=over 4

=item *

Rob N ★ <robn@robn.io>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Rob N ★ and was supported by FastMail
Pty Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
