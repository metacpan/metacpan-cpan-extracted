package BPM::Engine::Store::ResultBase::Activity;
BEGIN {
    $BPM::Engine::Store::ResultBase::Activity::VERSION   = '0.01';
    $BPM::Engine::Store::ResultBase::Activity::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;
with qw/
    Class::Workflow::State
    Class::Workflow::State::TransitionHash
    Class::Workflow::State::AcceptHooks
    Class::Workflow::State::AutoApply
    /;

sub new_instance {
    my ($self, $args) = @_;
    
    my $guard = $self->result_source->schema->txn_scope_guard;
    
    my $ai = $self->add_to_instances($args);
    if($self->is_split) {
        $ai->create_related('split', { states => {} });
        }
    
    $guard->commit;
    
    #$ai->discard_changes;
    return $ai;
    }

no Moose::Role;

1;
__END__