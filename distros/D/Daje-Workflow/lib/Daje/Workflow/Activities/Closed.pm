package Daje::Workflow::Activities::Closed;
use Mojo::Base 'Daje::Workflow::Common::Activity::Base', -base, -signatures;
use v5.40;


sub closed($self) {

    $self->error->add_error("This workflow is closed");
}
1;