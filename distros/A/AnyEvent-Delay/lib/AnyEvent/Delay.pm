package AnyEvent::Delay;
use Moo;
use EV;

our $VERSION = 0.01;

has on_error => (
    is => 'rw',
    isa => sub {
        return 2 if ref $_[0] eq 'CODE';
    },
    default => sub {  sub { 1 } },
);

has on_finish => (
    is => 'rw',
    isa => sub {
        return 2 if ref $_[0] eq 'CODE';
    }
);

sub begin {
    my $self = shift;
    my @callar = caller;
    my @mark = @_;
    $self->{pending}++;
    my $id = $self->{_ae_counter}++;
    return sub { 
        $self->_step($id, @_, @mark) 
    };
}

sub steps {
  my $self = shift;
  $self->{steps} = [@_];

  $self->begin->();
  #$self->{timers}{-1} =  EV::timer 0, 0,  $self->begin; 
  return $self;
}

sub _step {
    my ($self, $id) = (shift, shift);
    
    push @{ $self->{args}[$id] }, [@_];
    return if $self->{fail} || --$self->{pending} || $self->{lock};

    local $self->{lock} = 1;
    my @args = map {@$_} @{delete $self->{args}};
    $self->{_ae_counter} = 0;
    if (my $cb = shift @{$self->{steps} ||= []}) {
      eval { $self->$cb(@args); 1 } or return $self->on_error->($@) and $self->{fail}++;
    }

    if (! $self->{_ae_counter}) {
         return $self->on_finish->( @args ); 
    }

    if (! $self->{pending}) {
      $self->{timers}{$id} =  EV::timer 0, 0,  $self->begin 
    }
}

1;

=encoding utf8

=head1 NAME

AnyEvent::Delay - Manage AnyEvent callbacks and control the flow of events

=head1 SYNOPSIS

    # Synchronize multiple events
    my $cv = AE::cv;
    my $delay = AnyEvent::Delay->new();
    $delay->on_finish(sub { say 'BOOM!'; $cv->send });
    for my $i (1 .. 10) {
      my $end = $delay->begin;
      Mojo::IOLoop->timer($i => sub {
        say 10 - $i;
        $end->();
      });
    }
    $cv->recv;

    # Sequentialize multiple events
    my $cv = AE::cv;
    my $delay = AnyEvent::Delay->new();
    $delay->steps(
    
        # First step (parallel events)
        sub {
          my $delay = shift;
          Mojo::IOLoop->timer(2 => $delay->begin);
          http_get( 'http://www.yinyuetai.com' => $delay->begin );
          say 'Second step in 2 seconds.';
        },
    
        # Second step (parallel timers)
        sub {
          my ($delay, @args) = @_;
          say "This http response is $args[1]->[1]{Status}";
          Mojo::IOLoop->timer(1 => $delay->begin);
          Mojo::IOLoop->timer(3 => $delay->begin);
          say 'Third step in 3 seconds.';
        },
    
        # Third step (the end)
        sub {
          my ($delay, @args) = @_;
          say 'And done after 5 seconds total.';
          $cv->send;
        }
    );
    $cv->recv;

=head1 DESCRIPTION

L<AnyEvent::Delay> manages callbacks and controls the flow of events for L<AnyEvent>. This module is L<Mojo::IOLoop::Delay> version of AnyEvent. 

=head1 EVENTS

L<AnyEvent::Delay> have method the following.

=head2 on_error

  $delay->on_error(sub {
    my ($delay, $err) = @_;
    ...
  });

if an error occurs in one of the steps, breaking the chain.

=head2 on_finish

  $delay->on_finish(sub {
    my ($delay, @args) = @_;
    ...
  });

the active event _ae_counter reaches zero and there are no more steps.

=head1 METHODS

=head2 begin

  my $without_first_arg_arrayref = $delay->begin;
  my $with_first_arg_arrayref    = $delay->begin(0);

Increment active event _ae_counter, the returned callback can be used to decrement
the active event _ae_counter again. Arguments passed to the callback are queued in
the right order for the next step or C<on_finish> event method, the argument will be 
array references for each begin callback.


=head2 steps

  $delay = $delay->steps(sub {...}, sub {...});

Sequentialize multiple events, the first callback will run right away, and the
next one once the active event _ae_counter reaches zero. This chain will continue
until there are no more callbacks, a callback does not increment the active
event _ae_counter or an error occurs in a callback.

=head1 SEE ALSO

L<Mojo::IOLoop::Delay>.

=cut
