use v5.40;
no warnings 'experimental::class';
use feature 'class';
#
# A named, per-fiber value slot. Each Local object is one logical variable that reads
# differently depending on which fiber asks; fibers never see each other's values, and a
# completed fiber's values vanish when its fiber object is destroyed (DESTROY prunes
# %FIBER_LOCALS, the same place fids are released).
#
# Keys are a monotonic process-wide id, never a refaddr: a recycled memory address must not
# alias a newer Local's slot.
class Acme::Parataxis::Local v0.1.1 {
    use Acme::Parataxis;
    use Carp qw[croak];
    my $NEXT_ID = 0;
    field $id = $NEXT_ID++;           # process-wide unique slot key
    field $default : param = undef;
    field $inherit : param = 0;       # opt-in: spawn copies this slot's value from parent fiber to child (trace propagation)
    ADJUST {
        # register with spawn's trace-propagation hook: a fiber that spawns a child with a value in this slot
        # seeds it into the child's stash before the child body runs (see Acme::Parataxis::spawn)
        push @Acme::Parataxis::INHERIT_LOCAL_IDS, $id if $inherit;
    }

    method get () {
        my $fid = Acme::Parataxis->current_fid;
        croak 'Local->get must be called from inside a scheduled fiber' if $fid < 0;
        my $stash = Acme::Parataxis::_fiber_locals( Acme::Parataxis->by_id($fid) );
        return $default unless exists $stash->{$id};
        return $stash->{$id};
    }

    method set ($value) {
        my $fid = Acme::Parataxis->current_fid;
        croak 'Local->set must be called from inside a scheduled fiber' if $fid < 0;
        Acme::Parataxis::_fiber_locals( Acme::Parataxis->by_id($fid) )->{$id} = $value;
        return $value;
    }

    method DESTROY {
        return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
        @Acme::Parataxis::INHERIT_LOCAL_IDS = grep { $_ != $id } @Acme::Parataxis::INHERIT_LOCAL_IDS;
    }
};
#
1;
