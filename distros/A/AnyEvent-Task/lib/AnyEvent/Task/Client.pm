package AnyEvent::Task::Client;

use common::sense;

use Scalar::Util;

use AnyEvent;
use AnyEvent::Util;
use AnyEvent::Handle;
use AnyEvent::Socket;

use AnyEvent::Task::Client::Checkout;


sub new {
  my ($class, %arg) = @_;
  my $self = {};
  bless $self, $class;

  $self->{connect} = $arg{connect} || die "need connect";
  $self->{name} = $arg{name};

  $self->{min_workers} = defined $arg{min_workers} ? $arg{min_workers} : 2;
  $self->{max_workers} = defined $arg{max_workers} ? $arg{max_workers} : 20;
  $self->{min_workers} = $self->{max_workers} if $self->{min_workers} > $self->{max_workers};
  $self->{timeout} = $arg{timeout} if exists $arg{timeout};
  $self->{max_checkouts} = $arg{max_checkouts} if exists $arg{max_checkouts};
  $self->{dont_refork_after_error} = 1 if $arg{dont_refork_after_error};

  $self->{total_workers} = 0;
  $self->{connecting_workers} = {};
  $self->{available_workers} = {};
  $self->{occupied_workers} = {};
  $self->{workers_to_checkouts} = {}; # used to map errors detected on worker connection to checkout callbacks
  $self->{worker_checkout_counts} = {}; # used for max_checkouts "memory leak protection"

  $self->{pending_checkouts} = [];

  $self->populate_workers;

  return $self;
}



sub populate_workers {
  my ($self) = @_;

  Scalar::Util::weaken($self);

  return if $self->{total_workers} >= $self->{max_workers};

  my $workers_to_create = $self->{min_workers} - $self->{total_workers};
  if ($workers_to_create <= 0) {
    $workers_to_create = 0;
    $workers_to_create = 1 unless keys %{$self->{available_workers}} || keys %{$self->{connecting_workers}};
  }

  for (1 .. $workers_to_create) {
    $self->{total_workers}++;

    my $host = $self->{connect}->[0];
    my $service = $self->{connect}->[1];

    my $worker_guard;
    $self->{connecting_workers}->{0 + $worker_guard} = $worker_guard = tcp_connect $host, $service, sub {
      my $fh = shift;

      delete $self->{connecting_workers}->{0 + $worker_guard};

      if (!$fh) {
        $self->{total_workers}--;
        $self->install_populate_workers_timer;
        return;
      }

      delete $self->{populate_workers_timer};

      my $worker; $worker = new AnyEvent::Handle
                              fh => $fh,
                              on_read => sub { }, ## So we always have a read watcher and can instantly detect worker deaths
                              on_error => sub {
                                my ($worker, $fatal, $message) = @_;

                                my $checkout = $self->{workers_to_checkouts}->{0 + $worker};

                                $checkout->{timeout_timer} = undef; ## timer keeps a circular reference

                                $checkout->throw_fatal_error('worker connection suddenly died') if $checkout;

                                $self->destroy_worker($worker);
                                $self->populate_workers;
                              };

      $self->{worker_checkout_counts}->{0 + $worker} = 0;

      $self->make_worker_available($worker);

      $self->try_to_fill_pending_checkouts;
    };
  }

}


sub install_populate_workers_timer {
  my ($self) = @_;

  return if exists $self->{populate_workers_timer};

  $self->{populate_workers_timer} = AE::timer 0.2, 1, sub {
    $self->populate_workers;
  };
}


sub try_to_fill_pending_checkouts {
  my ($self) = @_;

  return unless @{$self->{pending_checkouts}};

  if (keys %{$self->{available_workers}}) {
    my @available_workers = values %{$self->{available_workers}};
    my $worker = shift @available_workers;
    $self->make_worker_occupied($worker);

    my $checkout = shift @{$self->{pending_checkouts}};
    $checkout->{worker} = $worker;

    $self->{workers_to_checkouts}->{0 + $worker} = $checkout;
    Scalar::Util::weaken($self->{workers_to_checkouts}->{0 + $worker});

    $checkout->_try_to_fill_requests;
    return $self->try_to_fill_pending_checkouts;
  }

  $self->populate_workers;
}



sub make_worker_occupied {
  my ($self, $worker) = @_;

  delete $self->{available_workers}->{0 + $worker};
  $self->{occupied_workers}->{0 + $worker} = $worker;

  $self->{worker_checkout_counts}->{0 + $worker}++;
}


sub make_worker_available {
  my ($self, $worker) = @_;

  if (exists $self->{max_checkouts}) {
    if ($self->{worker_checkout_counts}->{0 + $worker} >= $self->{max_checkouts}) {
      $self->destroy_worker($worker);
      return;
    }
  }

  ## Cancel any push_read callbacks installed while worker was occupied
  $worker->{_queue} = [];

  delete $self->{occupied_workers}->{0 + $worker};
  $self->{available_workers}->{0 + $worker} = $worker;
}


sub destroy_worker {
  my ($self, $worker) = @_;

  $worker->destroy;

  $self->{total_workers}--;
  delete $self->{available_workers}->{0 + $worker};
  delete $self->{occupied_workers}->{0 + $worker};
  delete $self->{worker_checkout_counts}->{0 + $worker};
}


sub checkout {
  my ($self, @args) = @_;

  my $checkout = AnyEvent::Task::Client::Checkout->_new( client => $self, @args, );

  push @{$self->{pending_checkouts}}, $checkout;

  $self->try_to_fill_pending_checkouts;

  return $checkout;
}

sub remove_pending_checkout {
  my ($self, $checkout) = @_;

  $self->{pending_checkouts} = [ grep { $_ != $checkout } @{$self->{pending_checkouts}} ];
}

1;
