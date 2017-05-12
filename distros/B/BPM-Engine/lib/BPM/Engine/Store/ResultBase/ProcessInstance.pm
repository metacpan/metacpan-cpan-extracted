package BPM::Engine::Store::ResultBase::ProcessInstance;
BEGIN {
    $BPM::Engine::Store::ResultBase::ProcessInstance::VERSION   = '0.01';
    $BPM::Engine::Store::ResultBase::ProcessInstance::AUTHORITY = 'cpan:SITETECH';
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
        $W->instance_class('BPM::Engine::Store::Result::ProcessInstanceState');
        }
    return $W;
    }

no Moose::Role;

1;
__DATA__
workflow:
    initial_state: open.not_running.ready
    states:
    # initial state - the workflow is active, but has not been started yet
    - name: open.not_running.ready
      transitions:
        - name    : start
          to_state: open.running
        - name    : terminate
          to_state: closed.cancelled.terminated
        - name    : abort
          to_state: closed.cancelled.aborted
    # the workflow is executing
    - name: open.running
      transitions:
        - name    : suspend
          to_state: open.not_running.suspended
        - name    : terminate
          to_state: closed.cancelled.terminated
        - name    : abort
          to_state: closed.cancelled.aborted
        - name    : finish
          to_state: closed.completed
    # execution was temporarily suspended
    - name: open.not_running.suspended
      transitions:
        - name    : resume
          to_state: open.running
        - name    : terminate
          to_state: closed.cancelled.terminated
        - name    : abort
          to_state: closed.cancelled.aborted
    - name: closed.cancelled.aborted
    - name: closed.cancelled.terminated
    - name: closed.completed