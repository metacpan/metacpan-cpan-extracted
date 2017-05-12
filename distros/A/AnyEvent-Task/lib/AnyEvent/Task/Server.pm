package AnyEvent::Task::Server;

use common::sense;

use AnyEvent;
use AnyEvent::Util;
use AnyEvent::Socket;

use AnyEvent::Task::Util;
use AnyEvent::Task::Server::Worker;


sub new {
  my ($class, %arg) = @_;
  my $self = {};
  bless $self, $class;


  $self->{all_done_cv} = AE::cv;
  $self->{children} = {};
  $self->{curr_worker_id} = 0;


  $self->{name} = $arg{name};
  $self->{setup} = $arg{setup} || sub {};
  $self->{checkout_done} = $arg{checkout_done} || sub {};
  $self->{hung_worker_timeout} = exists $arg{hung_worker_timeout} ? $arg{hung_worker_timeout} : (60*5);


  if (defined $self->{name}) {
    $0 = "AET-Server:$self->{name}";
  }


  if ($arg{listen}) {
    $self->{listen} = $arg{listen};

    my $host = $self->{listen}->[0];
    my $service = $self->{listen}->[1];

    $self->{server_guard} = tcp_server $host, $service, sub {
      my ($fh) = @_;
      $self->handle_new_connection($fh);
    };
  } else {
    die "unspecified listen path";
  }


  if (exists $arg{interface}) {
    my $interface = $arg{interface};

    if (ref $interface eq 'CODE') {
      $self->{interface} = $interface;
    } elsif (ref $interface eq 'HASH') {
      $self->{interface} = sub {
        my $method = shift;
        $interface->{$method}->(@_);
      };
    } else {
      die "interface must be a sub or a hash";
    }
  } else {
    die "unspecified interface";
  }


  return $self;
}


sub fork_task_server {
  my (@args) = @_;

  if (wantarray) {
    return AnyEvent::Task::Util::fork_anyevent_subprocess(sub {
             AnyEvent::Task::Server->new(@args)->run;
           });
  } else {
    AnyEvent::Task::Util::fork_anyevent_subprocess(sub {
      AnyEvent::Task::Server->new(@args)->run;
      return undef;
    });

    return undef;
  }
}




sub handle_new_connection {
  my ($self, $fh) = @_;

  my ($monitor_fh1, $monitor_fh2) = AnyEvent::Util::portable_socketpair;

  $self->{curr_worker_id}++;

  my $rv = fork;

  if ($rv) {
    close($fh);
    close($monitor_fh2);

    $self->{children}->{$rv} = {
      monitor_fh => $monitor_fh1,
    };
  } elsif ($rv == 0) {
    close($monitor_fh1);

    ## Don't want keep-alive pipes of other workers open in this worker
    foreach my $child (keys %{$self->{children}}) {
      close($self->{children}->{$child}->{monitor_fh});
    }

    if (defined $self->{name}) {
      $0 = "AET-Worker:$self->{name}($self->{curr_worker_id})";
    }

    AnyEvent::Task::Server::Worker::handle_worker($self, $fh, $monitor_fh2);
    die "handle_worker should never return";
  } else {
    close($fh);
    close($monitor_fh1);
    close($monitor_fh2);
    die "fork failed: $!";
  }
}


sub run {
  my ($self) = @_;

  $self->{all_done_cv}->recv;
}


1;
