package Bio::Cellucidate::Model;

use base Bio::Cellucidate::Base;

sub route { '/models'; }
sub element { 'model'; }

# Bio::Cellucidate::Book->models_rules($model_id);
sub model_rules {
    my $self = shift;
    my $id = shift;
    my $format = shift;

    $self->rest('GET', $self->route . "/$id" . Bio::Cellucidate::ModelRule->route, $format)->processResponseAsArray(Bio::Cellucidate::ModelRule->element);
} 

# Bio::Cellucidate::Book->initial_conditions($model_id);
sub initial_conditions {
    my $self = shift;
    my $id = shift;
    my $format = shift;

    $self->rest('GET', $self->route . "/$id" . Bio::Cellucidate::InitialCondition->route, $format)->processResponseAsArray(Bio::Cellucidate::InitialCondition->element);
}

# Bio::Cellucidate::Book->simulation_runs($model_id);
sub simulation_runs {
    my $self = shift;
    my $id = shift;
    my $format = shift;
    
    $self->rest('GET', $self->route . "/$id" . Bio::Cellucidate::SimulationRun->route, $format)->processResponseAsArray(Bio::Cellucidate::SimulationRun->element);
}

1;
