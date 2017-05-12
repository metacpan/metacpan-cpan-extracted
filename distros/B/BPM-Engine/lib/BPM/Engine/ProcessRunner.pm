package BPM::Engine::ProcessRunner;
BEGIN {
    $BPM::Engine::ProcessRunner::VERSION   = '0.01';
    $BPM::Engine::ProcessRunner::AUTHORITY = 'cpan:SITETECH';
    }

use Moose;
use MooseX::StrictConstructor;
use DateTime;
use BPM::Engine::Types qw/Bool ArrayRef HashRef CodeRef Exception Row/;
use BPM::Engine::Exceptions qw/throw_model throw_abstract throw_runner/;
use BPM::Engine::Util::ExpressionEvaluator;
use namespace::autoclean;    # -also => [qr/^_/];

with qw/
    MooseX::Traits
    BPM::Engine::Role::WithLogger
    BPM::Engine::Role::WithCallback
    /;

BEGIN {
    for my $event (qw/start continue complete execute/) {
        for my $entity (qw/process activity transition task/) {
            __PACKAGE__->meta->add_method(
                "cb_$event\_$entity" => sub {
                    my $self = shift;
                    return 1 unless $self->has_callback;
                    return $self->call_callback($self, $entity, $event, @_);
                    }
                    );
            }
        }
    }

has '+_trait_namespace' => (default => 'BPM::Engine::Plugin');

# DEPRECATED
#has 'engine' => (
#    is       => 'ro',
#    isa      => 'BPM::Engine',
#    weak_ref => 1,
#    );

has 'process' => (
    is         => 'ro',
    isa        => Row['Process'],
    lazy_build => 1,
    );

has 'process_instance' => (
    is       => 'ro',
    isa      => Row['ProcessInstance'],
    required => 1,
    );

has 'graph' => (
    is         => 'rw',
    lazy_build => 1,
    );

has 'stash' => ( # heap
    is      => 'rw',
    isa     => HashRef,
    default => sub { {} },
    #traits => [qw(MergeHashRef)],
    );

has 'dryrun' => ( # simulate
    is            => 'ro',
    isa           => Bool,
    default       => 0,
    #documentation => 'Make a dry-run and do not execute any tasks [Default: False]',
    );

has 'evaluator' => (
    is         => 'rw',
    lazy_build => 1,
    );
    
sub _build_evaluator {
    my $self = shift;
    return BPM::Engine::Util::ExpressionEvaluator->load(
        process          => $self->process,
        process_instance => $self->process_instance,
        );
    }

with qw/
    BPM::Engine::Role::HandlesIO
    BPM::Engine::Role::HandlesTaskdata
    BPM::Engine::Role::HandlesAssignments
    /;
with 'BPM::Engine::Role::RunnerAPI';

sub _build_process {
    shift->process_instance->process;
    }

sub _build_graph {
    shift->process->graph;
    }

has '_is_running' => (
    is  => 'rw',
    isa => Bool
    );

has '_activity_stack' => (    # not a stack but a queue, actually
    isa     => ArrayRef,
    is      => 'rw',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        '_queue_count' => 'count',
        '_queue_next'  => 'shift',
        '_queue_push'  => 'push',
        '_queue_clear' => 'clear',
        }
        );

has '_deferred_stack' => (    # not a stack but a queue, actually
    isa     => ArrayRef,
    is      => 'rw',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        '_defer_count' => 'count',
        '_defer_next'  => 'shift',
        '_defer_push'  => 'push',
        '_defer_clear' => 'clear',
        },
        );

sub start_process {
    my $self = shift;

    $self->cb_start_process($self->process, $self->process_instance);

    eval { $self->process_instance->apply_transition('start'); };
    if ($@) {
        throw_runner error => "Could not start process: $@";
        }

    my @start = @{ $self->process->start_activities } or do {
        $self->complete_process;
        return;
        };

    foreach my $activity (@start) {
        $activity->is_start_activity
            or throw_model error => 'Not a start event';

        if ($activity->is_auto_start) {
            my $ai = $activity->new_instance(
                { process_instance_id => $self->process_instance->id });
            $self->start_activity($activity, $ai, 0);
            }
        }

    $self->_run;

    return;
    }

sub start_activity {
    my ($self, $activity, $instance, $run) = @_;

    $self->cb_start_activity($activity, $instance);

    $instance->apply_transition('assign');

    $self->_queue_push([$activity, $instance]);
    $self->_run if $run;
    }

sub continue_activity {
    my ($self, $activity, $instance, $run) = @_;

    $self->cb_continue_activity($activity, $instance);

    $self->_queue_push([$activity, $instance]);
    $self->_run if $run;
    }

sub _run {
    my $self = shift;

    throw_runner error => "runner: ALREADY RUNNING" if $self->_is_running;

    $self->_is_running(1);

    $self->debug("=========== START_run =================");

    my $did_something = 0;
    while (my $act_ctx = $self->_queue_next) {
        $did_something++;
        eval {
            $self->_execute_activity_instance($act_ctx->[0], $act_ctx->[1]);
            };
        if (my $err = $@) {
            throw_runner error => "Could not execute activity: $err";
            }

        my %acted = ();
        $acted{ $act_ctx->[0]->id }++;
        $self->debug("runner: _run DrainInner " . $act_ctx->[0]->activity_uid);
        # drain deferred queue
        my %seen = ();
        while (my $def_ctx = $self->_defer_next) {
            my ($activity, $instance) = ($def_ctx->[0], $def_ctx->[1]);
            last if $seen{ $instance->id }++; # full circle on current deferreds
            next if $acted{ $activity->id }++;
            $instance->discard_changes;
            next unless $instance->is_deferred;
            $instance->update({ deferred => undef });
            $self->debug("runner: _run draininner " . $activity->activity_uid);
            $self->_enqueue_ai($activity, $instance, 1);
            }
        }

    $self->debug("=========== /STOP _run =================");

    die("Inconclusive process state") if $self->_queue_count();

    if ($did_something) {
        die("Inconclusive processdb state") if $self->_defer_count();
        $self->_defer_clear();
        $self->_is_running(0);
        }
    elsif ($self->_defer_count) {
        $self->debug("runner: DrainAfter");
        my %seen = ();
        while (my $def_ctx = $self->_defer_next) {
            my ($activity, $instance) = ($def_ctx->[0], $def_ctx->[1]);
            last if $seen{ $instance->id }++; # full circle on current deferreds
            #next if $acted{$activity->id}++;
            $instance->discard_changes;
            next unless $instance->is_deferred;
            $instance->update({ deferred => undef });
            $self->debug("runner: _run drainafter " . $activity->activity_uid);
            $self->_enqueue_ai($activity, $instance, 1);
            }

        $self->_is_running(0);

        if ($self->_queue_count) {
            $self->warning("runner: SecondRun by DrainAfter");
            $self->_run;
            }
        }
    else {
        $self->_is_running(0);
        }

    return;
    }

## no critic (ProhibitCascadingIfElse)

sub _execute_activity_instance {
    my ($self, $activity, $instance) = @_;

    return unless $self->cb_execute_activity($activity, $instance);

    my $completed = 0;
    
    # Route
    if ($activity->is_route_type) {
        #$self->debug("runner: route type " . $activity->activity_uid);
        $completed = 1;
        }
    
    # Implementations are No, Task, SubFlow or Reference
    elsif ($activity->is_implementation_type) {
        $self->debug("runner: executing implementation activity '"
                . $activity->activity_uid
                . "'");
        $completed = $self->_execute_implementation($activity, $instance);
        }
    
    # BlockActivity executes an ActivitySet
    elsif ($activity->is_block_type) {
        $self->error("runner: BlockActivity not implemented yet ...");
        throw_abstract error => 'BlockActivity not implemented yet';
        }
    
    # Events just complete, for now
    elsif ($activity->is_event_type) {
        #$self->notice("runner: Events not implemented yet ...");
        #throw_abstract error => 'Events not implemented yet';
        $completed++;
        }
    else {
        throw_model error => "Unsupported activity type "
            . $activity->activity_type;
        }

    if ($completed && $activity->is_auto_finish) {
        $self->complete_activity($activity, $instance, 0);
        }
    }

sub _execute_implementation {
    my ($self, $activity, $instance) = @_;

    my $completed = 0;

    if ($activity->is_impl_subflow) {
        $self->error("runner: subflows not implemented yet ...");
        throw_abstract error => 'Subflows not implemented yet';
        }
    elsif ($activity->is_impl_reference) {
        $self->error("runner: reference not implemented yet ...");
        throw_abstract error => 'Reference not implemented yet';
        }
    elsif ($activity->is_impl_task) {
        my ($i, $j) = (0, 0);
        foreach my $task ($activity->tasks->all) {
            # inject into sync/async event engine
            $i++ if ($self->dryrun || $self->execute_task($task, $instance));
            $j++;
            }
        $completed = $i == $j ? 1 : 0;
        }
    elsif ($activity->is_impl_no) {
        # 'No' implementation completes immediately
        $completed = 1;
        }
    else {
        throw_model error => "Invalid activity implementation definition";
        }

    return $completed;
    }

## use critic (ProhibitCascadingIfElse)

sub execute_task {
    my ($self, $task, $instance) = @_;

    if ($self->cb_execute_task($task, $instance)) {
        return 1;
        }

    return 0;
    }

sub complete_activity {
    my ($self, $activity, $instance, $run) = @_;

    $self->cb_complete_activity($activity, $instance);
    
    $instance->apply_transition('finish');
    $instance->fire_join if $activity->is_join;    
    $instance->update({ completed => DateTime->now() });

    if ($activity->is_end_activity()) {
        unless ($self->process_instance->activity_instances_rs->active->count) {
            $self->complete_process();
            return;
            }
        }
    else {
        $self->_execute_transitions($activity, $instance);
        }

    $self->_run if $run;
    }

sub complete_process {
    my $self = shift;

    my $pi = $self->process_instance;
    return unless $self->cb_complete_process($self->process, $pi);

    $pi->apply_transition('finish');
    $pi->update({ completed => DateTime->now() });

    $self->_queue_clear();
    $self->_defer_clear();

    if ($pi->parent_ai_id) {
        my $pai = $pi->parent_activity_instance;
        $self->_complete_parent_activity($pai->activity, $pai);
        }
    }

sub _complete_parent_activity {
    my ($self, $activity, $instance) = @_;

    $self->error('runner: subflows not implemented');
    throw_abstract error => 'Subflows not implemented';
    }

sub _execute_transitions {
    my ($self, $activity, $instance) = @_;

    my $pref = { prefetch => ['from_activity', 'to_activity'] };
    my @transitions =
          $activity->is_split
        ? $activity->transitions_by_ref({}, $pref)->all
        : $activity->transitions({}, $pref)->all;
    unless (@transitions) {
        my $act_id =
               $activity->activity_name
            || $activity->activity_uid
            || $activity->id;
        throw_model error =>
            "Model error: no outgoing transitions for activity '$act_id'";
        }

    my (@instances) = ();
    my (@blocked)   = ();
    my ($stop_following, $fired_count) = (0, 0);
    my ($otherwise, $exception) = ();

    # evaluate efferent transitions
    foreach my $transition (@transitions) {
        if (   $transition->condition_type eq 'NONE'
            || $transition->condition_type eq 'CONDITION') {
            my $t_instance;
            unless ($stop_following) {
                $t_instance =
                    $self->_execute_transition($transition, $instance, 0);
                }
            if ($t_instance) {
                push(@instances, [$transition, $t_instance]);
                $fired_count++;
                # only one transition in an XOR split can fire.
                $stop_following++ if $activity->is_xor_split;
                }
            elsif ($activity->is_split) {
                my $split = $instance->split
                    or die("No split for " . $activity->activity_uid);
                $split->set_transition($transition->id, 'blocked');
                push(@blocked, [$transition, $instance]);
                }
            }
        elsif ($transition->condition_type eq 'OTHERWISE') {
            $otherwise = $transition;
            }
        elsif ($transition->condition_type eq 'DEFAULTEXCEPTION'
            || $transition->condition_type eq 'EXCEPTION') {
            $exception = $transition;
            }

        }

    if ($fired_count == 0) {
        unless ($otherwise) {
            throw_model(
                error => "Deadlock: OTHERWISE transition missing on activity '"
                    . $activity->activity_uid
                    . "'");
            }
        my $t_instance = $self->_execute_transition($otherwise, $instance, 0);
        if ($t_instance) {
            push(@instances, [$otherwise, $t_instance]);
            }
        else {
            throw_runner error =>
                "Execution of transition with 'Otherwise' condition failed";
            }
        }
    elsif ($otherwise && $activity->is_split) {
        my $split = $instance->split
            or die("No join found for split " . $activity->activity_uid);
        $split->set_transition($otherwise->id, 'blocked');
        }

    # activate successor activities
    my $followed_back = 0;
    foreach my $inst (@instances) {
        $followed_back++ if $inst->[0]->is_back_edge;
        my $r_instance = $inst->[1];
        my $r_activity = $r_instance->activity;
        $self->_enqueue_ai($r_activity, $r_instance);
        }

    # blocked paths may trigger downstream deferred activities which must now be
    # resolved; signal deferred activity instances on other branches in the
    # wf-net when paths were blocked and any transition downstream was followed
    if (scalar(@blocked) && $followed_back != scalar @instances) {
        $self->_signal_upstream_orjoins_if_in_split_branch(@blocked);
        }

    return;
    }

sub _execute_transition {
    my ($self, $transition, $from_instance, $run) = @_;

    #XXX mitigate expensive debugging
    my $tid = $transition->transition_uid || $transition->id || 'noid';
    $self->debug("runner: executing transition $tid from "
            . $transition->from_activity->activity_uid . ' to '
            . $transition->to_activity->activity_uid);

    $self->cb_execute_transition($transition, $from_instance);

    my $to_instance = eval { $transition->apply($from_instance); };

    my $err = $@;
    if ($err) {
        $self->debug("runner: transition '"
                . $transition->transition_uid
                . "' did not result in a new activity_instance : $err");
        if (is_Exception($err)) {
            # condition false
            return if $err->isa('BPM::Engine::Exception::Condition');
            #warn $err->trace->as_string;
            $err->rethrow;
            }
        else {
            $err =~ s/\n//;
            $self->error("Error applying transition: $err");
            throw_model error => $err;
            }
        }
    elsif (!$to_instance) {
        $self->error("Applying transition did not result in an instance");
        throw_runner error => "Applying transition did not return an instance";
        }

    $self->_run if $run;

    return $to_instance;
    }

sub _enqueue_ai {
    my ($self, $activity, $instance, $deferred) = @_;

    $self->debug("runner: _enqueue activity " . $activity->activity_uid);
    my $should_fire = $activity->is_join ? $instance->is_enabled() : 1;
    if ($should_fire) {
        if ($instance->is_deferred) {
            #$instance->update({ deferred => \'NULL' });
            $instance->update({ deferred => undef })->discard_changes;
            }
        #$instance->fire_join if $activity->is_join;

        if ($activity->is_auto_start) {
            $self->debug("runner: _enqueue Pushing instance "
                    . $activity->activity_uid
                    . " to active queue");
            $self->start_activity($activity, $instance, 0);
            }
        }
    else {
        $instance->update({ deferred => DateTime->now });

        $self->debug("runner: _enqueue Pushing instance "
                . $activity->activity_uid
                . " to deferred queue");

        $self->_defer_push([$activity, $instance]) unless $deferred;
        }
    }

sub _signal_upstream_orjoins_if_in_split_branch {
    my ($self, @blocked) = @_;

    my @deferred = $self->process_instance->activity_instances->deferred->all;

    foreach my $instance (@deferred) {

        $self->debug("runner: _run Pushing db instance "
                . $instance->activity->activity_uid
                . " to deferred queue");

        my $graph = $self->graph;

        foreach my $block (@blocked) {
            my $tr   = $block->[0];
            my $ai   = $block->[1];
            my $a_to = $tr->to_activity;
            if ($graph->is_reachable($a_to->id, $instance->activity->id)) {
                $self->_defer_push([$instance->activity, $instance]);
                }
            }

        }
    }

__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=encoding utf-8

=head1 NAME

BPM::Engine::ProcessRunner - Runs workflow processes

=head1 VERSION

0.01

=head1 SYNOPSIS

    use BPM::Engine::ProcessRunner;

    my $callback = sub {
        my($runner, $entity, $action, $node, $instance) = @_;
        ...        
        return 1;
        };

    my $runner = BPM::Engine::ProcessRunner->new(
        process_instance => $instance,
        callback         => $callback,
        );
  
    $runner->start_process();

    # somewhere else, after completing a task, 
    # from an asynchronous task handler...
  
    $runner->complete_activity($activity, $instance, 1);

=head1 DESCRIPTION

Implements the workflow enactment logic.

=head1 CALLBACKS

The methods in this package emit callback events to a callback handler that may 
be passed to the constructor. If no callback handler is specified, the default 
return values are applied for these event calls.

The following callback actions are emitted for a process event:

=over 4

=item I<start_process>

Arguments: $process, $process_instance

=item I<start_activity>

Arguments: $activity, $instance

=item I<continue_activity>

Arguments: $activity, $instance

=item I<execute_activity>

Argments: $activity, $instance

On this event, the callback should return false if the workflow process should
be interrupted, true (default) if otherwise, which executes the activity and
progresses the workflow.

=item I<execute_task>

Argments: $task, $activity_instance

Returning true (default) will assume the task completed and call
C<complete_activity()> within ProcessRunner. Return false to halt the process
thread.

=item I<complete_activity>

Arguments: $activity, $instance

=item I<execute_transition>

Arguments: $transition, $from_instance

=item I<complete_process>

Arguments: $process, $process_instance

Returning true (default) will set the process state to C<closed.comleted>.

=back

Callback methods are directly available under its name prefixed by C<cb_>, for
example

    $runner->cb_start_process($process, $process_instance);
 
The callback handler receives the following options:

=over 4

=item * C<$runner>

This ProcessRunner instance.

=item * C<$entity>

Type of entity the node represents. This is either I<process>, I<activity>,
I<transition> or I<task>.

=item * C<$action>

The event action called on the entity. This is either I<start>, I<continue>,
I<complete> or I<execute>.

=item * C<$node>

The first argument passed to the C<cb_*> callback method, the respective entity
node in the process that this callback is emitted for. On activity callbacks,
this is the activity object, the task object on task callbacks, the process
object for process entities, and transition for transition calls.

=item * C<$instance>

The second argument passed to the C<cb_*> callback method, being the instance
for the node called on. In case of a transition callback, this is the activity
instance the transition originated from (the activity being executed).

=back

The callback should return true on succesful/normal processing of events, and
false if something stalled or went wrong. Example:

    my $callback = sub {
        my($runner, $entity, $action, $node, $instance) = @_;
            
        ## call your task execution sub when tasks need executing:
        if ($entity eq 'task' && $action eq 'execute') {
            return &execute_task($node, $instance); 
            }

        return 1;
        };

    my $runner = BPM::Engine::ProcessRunner->new(
        callback => $callback,
        process_instance => $pi
        );



=head1 CONSTRUCTOR

=head2 new

Returns a new BPM::Engine::ProcessRunner instance. Optional arguments are:

=over 4

=item C<< process_instance => $process_instance >>

The process instance to run. Required.

=item C<< callback => \&cb >>

Optional callback I<&cb> which is called on all process instance events.

=item C<< dryrun => 0 | 1 >>

Boolean indicating whether or not the execute_task phase should be skipped.
Defaults to 0.

=back

=head1 ATTRIBUTE METHODS

=head2 process_instance

The L<BPM::Engine::Store::Result::ProcessInstance> to run.

=head2 process

The L<BPM::Engine::Store::Result::Process> of the process instance.

=head2 graph

The directed graph (an instance of L<Graph::Directed>) for the process.

=head2 stash

Returns a hash reference stored as a heap, that is local to this
runner object that lets you store any information you want.

=head2 dryrun

Returns the C<dryrun> flag

=head2 evaluator

Returns the L<BPM::Engine::Util::ExpressionEvaluator> object attached to this 
instance.

=head1 METHODS

=head2 start_process

    $runner->start_process;

Call the 'start_process' callback, set the process instance to the 'started' 
state, and call start_activity() with an activity instance created for each of 
the auto_start start activities.

=head2 start_activity

    $runner->start_activity($activity, $instance, $run);

C<start_activity()> takes an activity, an activity instance and an optional 'run' flag.
It calls the 'start_activity' callback, sets the activity instance state to 'assigned',
enqueues the activity instance to be executed, and optionally runs all queued activity instances

=head2 continue_activity

    $runner->continue_activity($activity, $instance, $run);

Call the 'continue_activity' callback, enqueue the activity instance to be executed,
and optionally run all queued activity instances.

=head2 execute_task

    $runner->execute_task($task, $instance);

Call the 'execute_task' callback, and returns 1 or 0 depending on the existance
of a callback return value. This method is called on activity implementation
when the activity instance is executed, and is meant to be used in Traits, not
to be called directly.

=head2 complete_activity

    $runner->complete_activity($activity, $instance, $run);

Call the 'complete_activity' callback, sets the activity instance state to 'closed.completed',
and sets the completion datetime.  and either calls complete_process()
Outgoing transitions, if any, are followed. If it's an end activity and there are no
active activity instances left, complete_process() is called, otherwise
it optionally runs all enqueued activity instances.

=head2 complete_process

    $runner->complete_process;

Return unless the 'complete_process' returns true. Set the process instance state to 'closed.completed',
set the completion datetime, and clear the activity instance execution queues.

=head1 LOGGING METHODS

    $runner->debug('Something happened');

log, debug, info, notice, warning, error, critical, alert, emergency

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
