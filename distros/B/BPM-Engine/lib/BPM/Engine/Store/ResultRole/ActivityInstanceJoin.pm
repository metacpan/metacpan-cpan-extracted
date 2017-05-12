package BPM::Engine::Store::ResultRole::ActivityInstanceJoin;
BEGIN {
    $BPM::Engine::Store::ResultRole::ActivityInstanceJoin::VERSION   = '0.01';
    $BPM::Engine::Store::ResultRole::ActivityInstanceJoin::AUTHORITY = 'cpan:SITETECH';
    }
## no critic (ProhibitCascadingIfElse)
use namespace::autoclean;
use Moose::Role;
use BPM::Engine::Exceptions qw/throw_abstract/;

sub is_enabled {
    my $self = shift;

    #warn("Not an active instance") unless $self->is_active;    
    
    my $activity = $self->activity;
    if(!$activity->is_join) {
        die("Not a join " . $activity->activity_uid);
        }
    elsif($activity->is_and_join) {
        return $self->_and_join_should_fire;
        }
    elsif($activity->is_or_join) {
        return $self->_or_join_should_fire;
        }
    elsif($activity->is_xor_join) {
        return 1;
        }
    elsif($activity->is_complex_join) {
        throw_abstract error => "Complex joins not implemented";
        }
    else {
        die("Not a valid join type " . $self->activity->join_type);
        }
    }

## use critic (ProhibitCascadingIfElse)

sub _and_join_should_fire {
    my $self = shift;

    my $activity = $self->activity;
    my $deferred_states = $self->result_source->schema
        ->resultset('ActivityInstance')->deferred({
            process_instance_id => $self->process_instance_id,
            activity_id         => $activity->id,
            tokenset            => $self->tokenset,
        });

    my %deferred_trans = map { $_->transition_id => 1 } $deferred_states->all;
    $deferred_trans{$self->transition_id} = 1;

    my @transa = $activity->transitions_in->all;
    my @transd = grep { $deferred_trans{$_->id} } @transa;

    return scalar @transa == @transd ? 1 : 0;
    }

sub _or_join_should_fire {
    my $self = shift;

    my $deferred_states = $self->result_source->schema
        ->resultset('ActivityInstance')->deferred({
          activity_id         => $self->activity->id,
          process_instance_id => $self->process_instance_id,
          tokenset            => $self->tokenset,
        });

    my %deferred_trans = map { $_->transition_id => 1 } $deferred_states->all;
    $deferred_trans{$self->transition_id} = 1;
    
    # Each transition corresponds to either waiting for upstream,
    # executed+deferred, blocked, the start of a new cycle or this ai's
    # transition itself. Join should fire if there's no upstream activity left.
    foreach my $transition($self->activity->transitions_in->all) {
        next if($deferred_trans{$transition->id});
        next if($transition->is_back_edge);
        return 0 unless $self->_upstream_blocked($transition);
        }
    
    return 1;
    }

# Search the transition's upstream subnet for active or blocked activity 
# instances. Transition has not been applied yet, so either
# - still activity further upstream (last ai in process thread=active), or
# - split.path blocked for last completed ai in process thread
sub _upstream_blocked {
    my ($self, $transition) = @_;
    
    my $rs = $self->process_instance->activity_instances_rs({
        tokenset => $self->tokenset,
        })->active_or_completed;
    
    my $split_blocked = sub {    
        my ($ai, $trans) = @_;
        my $split = $ai->split || die("Inclusive split has no join attached");
        $split->discard_changes;
        if(   $split->states->{$trans->id} 
           && $split->states->{$trans->id} eq 'blocked') {
            # no blocking if followed a backedge upstream (cyclic wf)
            my @tids = 
                map { $_->id } 
                $ai->activity->transitions({ is_back_edge => 1 })->all;
            if(scalar @tids) {
                return 0 if $ai->next({ transition_id => [@tids] })->count;
                }
            return 1;
            }
        else {
            return 0;
            }
        };
    
    my $seen  = 0;
    my $block = 0;
    
    my(@act) = ([$transition->from_activity, $transition]);
    while(my $next = shift(@act)) {
        my ($upstream_act, $down_trans) = ($next->[0], $next->[1]);
        my @ai = $rs->search({'activity_id' => $upstream_act->id})->all;
        
        # no activity instances, traverse further upstream
        if(!scalar @ai) {
            foreach my $trans($upstream_act->transitions_in) {
                next if $trans->is_back_edge;
                my $src = $trans->from_activity;
                unless($src->id == $self->activity->id) {
                    push(@act, [$src, $trans]);
                    }
                }
            }
        # active or completed+blocked instances
        else {
            $seen++;
            my %status = ();
            foreach(@ai) { 
                $status{
                    $_->is_deferred ?  'deferred' : 
                    ($_->is_completed ? 'completed' : 'active') 
                    }++; 
                }

            die("Invalid db state for instances " . $upstream_act->activity_uid)
                if($status{deferred} && ($status{active} || $status{completed}));
            die("Invalid db state for instances " . $upstream_act->activity_uid)
                if($status{active} && $status{active} > 1);

            # active ai, may have come from split upstream
            if($status{active}) {
                return 0;
                }
            # completed, is_split, blocked transition path
            elsif($status{completed} && scalar(keys %status) == 1) {
                # OR-split should be blocked, XOR split missed this transition by definition
                if($upstream_act->is_or_split) {
                    my $blocked = 0;                    
                    foreach my $ai(@ai) {
                        $blocked++ if &$split_blocked($ai, $down_trans);
                        }
                    die("OR split " . $upstream_act->activity_uid . " completed but not blocked") 
                        unless $blocked;
                    }
                elsif(!$upstream_act->is_xor_split) {
                    die("Not an OR/XOR split " . $upstream_act->activity_uid);
                    }
                $block++;
                }
            else {
                die("Wrong status");
                }
            }
        }
    die("Invalid transition " . $transition->transition_uid) unless $block == $seen;
    return 1;
    }

sub fire_join {
    my $self = shift;
    
    die("Not a join") unless $self->activity->is_join;
    die("Not active") unless $self->is_active;

    $self->_mark_upstream_joined();

    # make all deferreds completed
    $self->result_source->schema
        ->resultset('ActivityInstance')->deferred({
          activity_id         => $self->activity->id,
          process_instance_id => $self->process_instance_id,
          tokenset            => $self->tokenset,
        })->update({ deferred => \'NULL', completed => DateTime->now() });
    }


# follow upstream up to root, stopping only after all 'takens' have been set to
# 'joineds' OR stop when first 'joined' found  (meaning previously traversed
# upwards when this was previously set from 'taken')
sub _mark_upstream_joined {
    my ($self, $open_reach) = @_;
    $open_reach ||= {};

    # verify paths against local joins
    my $upstream_ai = undef;
    my $transition  = $self->transition or die("Transition not found");
    my $is_parent   = 1;

    # traverse upstream
    while($upstream_ai = $self->prev) {
        delete $open_reach->{$upstream_ai->activity->id};
        
        if($upstream_ai->activity->is_or_split) {
            if($upstream_ai->activity->id != $transition->from_activity->id) {
                die("ShouldFire: Illegal transition for JoinActivity '" .
                    $upstream_ai->activity->activity_uid .
                    "' doesn't match transition " . $transition->transition_uid .
                    " activity '" . $transition->from_activity->activity_uid . "'");
                }

            my $split = $upstream_ai->split 
                || die("Inclusive split has no join attached");
            $split->discard_changes;
            
            # mark transition from split as 'fired' in join from this downstream branch
            my $should_fire = $split->should_fire($transition);
            
            return 0 unless($is_parent || $should_fire);
            }
        
        $is_parent  = 0;
        $self       = $upstream_ai;
        $transition = $upstream_ai->transition;
        last unless $transition;
        }

    return 1;
    }

no Moose::Role;

1;
__END__

# ABSTRACT: role for Activity Instances with joins