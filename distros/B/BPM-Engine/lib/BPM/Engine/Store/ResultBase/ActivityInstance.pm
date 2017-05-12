package BPM::Engine::Store::ResultBase::ActivityInstance;
BEGIN {
    $BPM::Engine::Store::ResultBase::ActivityInstance::VERSION   = '0.01';
    $BPM::Engine::Store::ResultBase::ActivityInstance::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;
use BPM::Engine::Util::YAMLWorkflowLoader qw/load_workflow_from_yaml/;
with 'BPM::Engine::Store::ResultRole::WithWorkflow';

my $W = undef;

sub get_workflow {
    unless($W) {
        my $yaml = do { local $/ = undef; <DATA> };
        $W = load_workflow_from_yaml($yaml);
        $W->instance_class('BPM::Engine::Store::Result::ActivityInstanceState');
        }
    return $W;
    }

no Moose::Role;

1;
__DATA__
workflow:
    initial_state: open.not_running.ready
    states:
    - name: open.not_running.ready
      transitions:
        - name    : start
          to_state: open.running.not_assigned
        - name    : assign
          to_state: open.running.assigned
        - name    : abort
          to_state: closed.cancelled.aborted
        - name    : finish
          to_state: closed.completed
    - name: open.running.not_assigned
      transitions:
        - name    : assign
          to_state: open.running.assigned
    - name: open.running.assigned
      transitions:
        - name    : reassign
          to_state: open.running.assigned
        - name    : unassign
          to_state: open.running.not_assigned        
        - name    : suspend
          to_state: open.not_running.suspended
        - name    : abort
          to_state: closed.cancelled.aborted
        - name    : finish
          to_state: closed.completed
    - name: open.not_running.suspended
      transitions:
        - name    : resume
          to_state: open.running.assigned
    - name: closed.cancelled.aborted
    - name: closed.completed