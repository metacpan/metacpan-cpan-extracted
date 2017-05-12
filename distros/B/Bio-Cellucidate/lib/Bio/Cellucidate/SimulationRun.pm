package Bio::Cellucidate::SimulationRun;

=pod

=head1 NAME

Bio::Cellucidate::SimulationRun

=head1 SYNOPSIS

    # Set your authentication, see L<http://cellucidate.com/api> for more info.
    $Bio::Cellucidate::AUTH = { login => 'email@server', api_key => '12334567890' };

    $params = { 
        model_id           => 1,           # : valid id of a model
        rescale            => 1.0,         # : multiplier of each initial 
                                           #   condition (typ. 1)
        event_time_length  => 10000,       # : number of events that will 
                                           #   occur before simulation 
                                           #   ends (only if mode = 'EVENT')
        bio_time_length    => 100,         # : simulation time length before 
                                           #   simulation ends (only if 
                                           #   mode = 'TIME')
        event_num_points   => 1000,        # : number of points to collect 
                                           #   (if mode = 'EVENT')
        bio_num_points     => 1000,        # : number of data points to 
                                           #   collect (if model = 'TIME')
        mode               => 'EVENT',     # : either 'EVENT' or 'MODE'
        num_iterations     => 1,           # : number of plots to create
        simulation_method  => 'STOCHASTIC' # : either 'STOCAHASTIC' or 'ODE'
    };

    $simulation_run = Bio::Cellucidate::SimulationRun->create($params);

    $id = $simulation_run->{id};

    while ($simulation_run->{state} ne 'success') {
        $simulation_run = Bio::Cellucidate::SimulationRun->get($simulation_run->{id});
        print "Simulation Running: " . Bio::Cellucidate::SimulationRun->progress($id) . "% complete";
        sleep(5);
    }

    print "Simulation Complete, CSV data\n";

    # This is the CSV data for all series and plots.
    if (Bio::Cellucidate::SimulationRun->get($id)->{state} eq 'succeeded') {
        print Bio::Cellucidate::SimulationRun->get($id, 'csv');
    }

    # The metadata for the plots
    $plots = Bio::Cellucidate::SimulationRun->plots($id);


=head1 SEE ALSO

L<http://cellucidate.com>

=head1 AUTHOR

Brian Kaney, E<lt>brian@vermonster.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Plectix BioSystems Inc 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut

use base Bio::Cellucidate::Base;

sub route { '/simulation_runs'; }
sub element { 'simulation-run'; }


sub plots {
    my $self = shift;
    my $id = shift;
    my $format = shift;
    $self->rest('GET', $self->route . "/$id" . Bio::Cellucidate::Plot->route, $format)->processResponseAsArray(Bio::Cellucidate::Plot->element);
}

sub progress {
    my $self = shift;
    my $id = shift;
    Bio::Cellucidate::SimulationRun->get($id)->{progress};
}

sub complete {
    my $self = shift;
    my $id = shift;
    my $state = Bio::Cellucidate::SimulationRun->get($id)->{state};
    return ( ($state eq 'failed') || ($state eq 'succeeded') || ($state eq 'aborted') );
}

1;
