package Bot::Cobalt::Core::Role::Timers;
$Bot::Cobalt::Core::Role::Timers::VERSION = '0.021003';
use 5.10.1;
use strictures 2;

use Bot::Cobalt::Timer;

use Scalar::Util qw/blessed/;

use List::Objects::WithUtils;

use Moo::Role;

requires qw/
  log
  debug
  send_event
/;


## FIXME tests are nonexistant

has TimerPool => ( 
  is        => 'rw', 
  builder   => sub { hash },
);


sub timer_gen_unique_id {
  my ($self) = @_;
  my @p = ( 'a'..'f', 1..9 );
  my $id = join '', map { $p[rand@p] } 1 .. 4;
  $id .= $p[rand@p] while $self->TimerPool->exists($id);
  $id
}

sub timer_set {
  my ($self, $item) = @_;
  
  my ($caller_pkg, $caller_line) = (caller)[0,2];
  my $d_line = "$caller_pkg line $caller_line";
  
  my $timer = $item;
  unless (blessed $item && $item->isa('Bot::Cobalt::Timer') ) {
    ## hashref-style (we hope)
    $timer = $self->timer_set_hashref( $item, @_[2 .. $#_] );
  }

  unless ($timer->has_id) {
    $timer->id( $self->timer_gen_unique_id );
  }
  
  ## Add to our TimerPool.
  $self->TimerPool->set($timer->id => $timer);
  $self->send_event( new_timer => $timer->id );

  $self->log->debug(
    "timer_set; ".join ' ', $timer->id, $timer->delay, $timer->event
  ) if $self->debug > 1;

  $timer->id
}

sub timer_set_hashref {
  my ($self, $delay, $ev, $id) = @_;

  my ($caller_pkg, $caller_line) = (caller)[0,2];
  my $d_line = "$caller_pkg line $caller_line";
  
  unless (ref $ev eq 'HASH') {
    if (ref $ev) {
      $self->log->warn(
        "timer_set_hashref expected HASH but got $ev; $d_line"
      );
      return
    } else {
      ## Assume we were passed a simple string.
      $ev = { Event => $ev };
    }
  }
  
  my $timer = Bot::Cobalt::Timer->new;

  $timer->id($id) if $id;

  ## Try to guess type, or default to 'event'
  my $type = $ev->{Type};
  unless ($type) {
    if (defined $ev->{Text} && defined $ev->{Context}) {
      $type = 'msg'
    } else {
      $type = 'event'
    }
  }
  
  my($event_name, @event_args);
  
  TYPE: {
    if ($type eq "event") {
      unless (defined $ev->{Event}) {
        $self->log->warn(
          "timer_set_hashref no Event specified; $d_line"
        );
        return
      }

      $timer->event( $ev->{Event} );
      $timer->args( $ev->{Args}//[] );
    
      last TYPE
    }
    
    if (grep { $type eq $_ } qw/msg message privmsg action/) {
      unless (defined $ev->{Text} && defined $ev->{Target}) {
        $self->log->warn(
          "timer_set_hashref; $type needs Text and Target; $d_line"
        );

        return
      }

      $timer->context( $ev->{Context} ) if defined $ev->{Context};
      $timer->target( $ev->{Target} );
      $timer->text( $ev->{Text} );
      $timer->type( $type );

      last TYPE
    }
    
    $self->log->error("Unknown type $type passed to timer_set_hashref");
    return
  }

  ## Tag w/ __PACKAGE__ if no alias is specified
  $timer->alias( $ev->{Alias} // scalar caller );
  
  ## Start ticking.
  $timer->delay( $delay );

  $timer
}

sub timer_get {
  my ($self, $id) = @_;
  return unless $id and $self->TimerPool->exists($id);

  $self->log->debug("timer retrieved; $id")
    if $self->debug > 1;

  $self->TimerPool->get($id)
}

sub timer_get_alias {
  ## get all timerIDs for this alias
  my ($self, $alias) = @_;
  return unless $alias;

  my @timers;
  $self->TimerPool->kv->visit(sub {
    my ($id, $entry) = @$_;
    push @timers, $id if $entry->alias eq $alias
  });

  wantarray ? @timers : \@timers
}

sub timer_del {
  ## delete a timer by its ID
  ## doesn't care if the timerID actually exists or not.
  my ($self, $id) = @_;
  return unless $id;

  $self->log->debug("timer del; $id")
    if $self->debug > 1;

  return unless $self->TimerPool->exists($id);

  my $deleted = $self->TimerPool->delete($id);
  $self->send_event( 'deleted_timer', $id, $deleted->all );
  
  $deleted->all
}

sub timer_del_alias {
  my ($self, $alias) = @_;
  return unless $alias;

  my @deleted;
  $self->TimerPool->kv->visit(sub {
    my ($id, $entry) = @$_;
    if ($entry->alias eq $alias) {
      push @deleted, $id;
      my $removed = $self->TimerPool->delete($id);
      $self->send_event( deleted_timer => $id, $removed );
    }
  });

  wantarray ? @deleted : scalar @deleted 
}


1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Core::Role::Timers

=head1 SYNOPSIS

  ## From a Cobalt plugin:
  my $new_id = $core->timer_set( 60,
    {
      Event => 'my_timed_event',
      Args  => [ $one, $two ],
      Alias => $core->get_plugin_alias($self),
    }
  );
  
  $core->timer_set( 60,
    {
      Event => 'my_timed_event',
      Args  => [ $one, $two ],
    },
    'MY_NAMED_TIMER'
  );
  
  $core->timer_del( $timer_id );
  $core->timer_del_alias( $core->get_plugin_alias($self) );
  
  my $timer_item = $core->timer_get( $timer_id );
  my @active = $core->timer_get_alias( $core->get_plugin_alias($self) );
    

=head1 DESCRIPTION

L<Bot::Cobalt> core interface role for managing a pool of timers living in a
TimerPool hash.

This is consumed by L<Bot::Cobalt::Core> to provide timer manipulation 
methods to the plugin pipeline.

=head1 METHODS

=head2 timer_set

The B<timer_set> method adds a new timer to the hashref 
provided by B<TimerPool> in the consuming class (usually 
L<Bot::Cobalt::Core>).

  ## Supply a Bot::Cobalt::Timer object:
  $core->timer_set( $timer_obj );
  
  ## Supply a hashref containing options:
  $core->timer_set( $secs, $opts_ref );
  $core->timer_set( $secs, $opts_ref, $timer_id );

An already-constructed L<Bot::Cobalt::Timer> object can be passed in; see the 
L<Bot::Cobalt::Timer> documentation for details on constructing a timer 
object.

More frequently, plugins pass in a hash reference containing event 
options and let B<timer_set> construct a L<Bot::Cobalt::Timer> on its own. 
This is the interface documented here.

B<timer_set> will return the new timer's ID on success; a B<send_event> 
will be called for event L</new_timer>.

=head3 Basic timers

The most basic timer is fire-and-forget with no alias tag and no 
preservation of timer ID:

  ## From a Cobalt plugin
  ## Trigger Bot_myplugin_timed_ev with no args in 30 seconds
  $core->timer_set( 30, 'myplugin_timed_ev' );
  ## Same as:
  $core->timer_set( 30, { Event => 'myplugin_timed_ev'  } );

A more sophisticated timer will probably have some arguments specified:

  $core->timer_set( 30,
    {
      Event => 'myplugin_timed_ev',
      Args  => [ $one, $two ],
    },
  );

If this is not a named timer, a unique timer ID will be created:

  my $new_id = $core->timer_set(30, { Event => 'myplugin_timed_ev' });

When used from Cobalt plugins, a timer should usually have an alias 
specified; this makes it easier to clear your pending timers from a 
B<Cobalt_unregister> event using L</timer_del_alias>, for example.

  ## From a Cobalt plugin
  ## Tag w/ our current plugin alias from Bot::Cobalt::Core
  my $new_id = $core->timer_set( 30,
    {
      Event => 'myplugin_timed_ev',
      Args  => [ $one, $two ],
      Alias => $core->get_plugin_alias($self),
    }
  );

=head3 Named timers

If a timer is intended to be globally unique within this TimerPool or 
the timer ID is generated by some other method, it can be specified in 
B<timer_set>. Existing timers with the same ID will be replaced.

  $core->timer_set( 30, 
    { 
      Event => 'myplugin_timed_ev',
      Args  => [ ],
    },
    'MY_NAMED_TIMER',
  );

(This, of course, makes life difficult if your plugin is intended to be 
instanced more than once.)

=head3 Message timers

If a timer is simply intended to send some message or action to an IRC 
context, the B<msg> and B<action> types can be used for convenience:

  $core->timer_set( 30,
    {
      Alias   => $core->get_plugin_alias($self),
      Type    => 'msg',
      Context => $context,
      Target  => $channel,
      Text    => $string,
    },
  );

=head2 timer_set_hashref

timer_set_hashref is the method called by L</timer_set> when it is not 
passed a preexisting L<Bot::Cobalt::Timer> object; you would not normally use 
this method directly.

=head2 timer_del

Deletes a timer by timer ID.

Returns the deleted timer item on success.

Calls a B<send_event> for event L</deleted_timer>.

=head2 timer_del_alias

Deletes a timer by tagged alias.

Returns the list of deleted timer IDs in list context or the number of 
deleted timers in scalar context.

A B<send_event> is called for L</deleted_timer> events for every 
removed timer.

=head2 timer_get

Retrieves the L<Bot::Cobalt::Timer> object for the specified timer ID.

This can be useful for tweaking active timers.

=head2 timer_get_alias

Returns all timer IDs in the pool belonging to the specified alias tag.

Returns a list of timer IDs. In scalar context, returns an array 
reference.

=head2 timer_gen_unique_id

Generates a unique (guaranteed not to exist in the consumer's 
TimerPool) randomized ID for a timer.

You would not normally call this method directly.

=head1 EVENTS

=head2 new_timer

Issued when a timer is set.

Only argument provided is the timer ID.

=head2 deleted_timer

Issued when a timer is deleted.

Arguments are the timer ID and the deleted item object, respectively.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>


=cut
