package Daje::Workflow::Enqueue;
use v5.40;
use Mojo::Base -base;

has 'context';
has 'minion';
has 'error';
has 'model';


sub enqueue_activity($self, $workflow, $activity_name, $workflow_fkey = 0) {

    $self->model->insert_history(
        "Enqueue activity",
        "Daje::Workflow::Enqueue::enqueue_activity $workflow, $activity_name, $workflow_fkey",
        1
    );
    try {
        my $context->{context} = $self->context->{context};
        $context->{context}->{workflow}->{workflow} = $workflow;
        $context->{context}->{workflow}->{activity} = $activity_name;
        $context->{context}->{workflow}->{workflow_fkey} = $workflow_fkey;

        $self->minion->enqueue(
            execute_workflow => [ $context ],
                {
                    queue => "workflow"
                }
        );
    } catch ($e) {
        $self->error->add_error($e);
    }
}
1;