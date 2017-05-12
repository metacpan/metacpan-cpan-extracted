#!/usr/bin/env perl -w
use Bio::Cellucidate;
use Data::Dumper;
use strict;


# Setup my login information.
$Bio::Cellucidate::CONFIG = { host => 'http://api.cellucidate.com'  };

die "Set your AUTH up here to run this script (remove/comment out this line)";
$Bio::Cellucidate::AUTH = { login => '<login>', api_key => '<key>' };



# Here are all my Bookshelves
my $bookshelves = Bio::Cellucidate::Bookshelf->find;
print "\nMy Bookshelves:\n";
print Dumper $bookshelves;


# Import a new book from kappa (bottom of this file)
my $kappa_import_job = Bio::Cellucidate::KappaImportJob->create( { kappa => join("",<DATA>), book_name => 'New Book from Kappa' });
print "\nImport Job:\n";
print Dumper $kappa_import_job;


# Wait until that job is done...
while ($kappa_import_job->{status} ne 'succeeded') {
    # Wait a few seconds..
    sleep(2);
    
    # Requery job
    $kappa_import_job = Bio::Cellucidate::KappaImportJob->get($kappa_import_job->{id});

    printf "Job status is %s.  %.2f %% complete...\n",
       $kappa_import_job->{status}, 
       $kappa_import_job->{progress}; 
}


# The job is complete, see what the result is...
my $result = Bio::Cellucidate::KappaImportJob->result($kappa_import_job->{id});
print "\nResult of the import job:\n";
print Dumper $result;


# We should have a book, so let's get it by it's id
my $book = Bio::Cellucidate::Book->get($result->{id});
print "\nNewly created Book\n";
print Dumper $book;


# Let's examine the agents, rules and models in my book
my $agents = Bio::Cellucidate::Book->agents($result->{id});
print "\nImported Agents:\n";
print Dumper $agents;


# Here is a detail of the first agent
my $agent = Bio::Cellucidate::Agent->get($agents->[0]->{id});
print "\nFirst Agent Detail:\n";
print Dumper $agent;


my $rules = Bio::Cellucidate::Book->rules($result->{id});
print "\nImported Rules:\n";
print Dumper $rules;

# Here is a detail of the first rule
my $rule = Bio::Cellucidate::Rule->get($rules->[0]->{id});
print "\nFirst Rule Detail:\n";
print Dumper $rule;


my $models = Bio::Cellucidate::Book->models($result->{id});
print "\nImported Models:\n";
print Dumper $models;

# Here is a detail of the first model
my $model = Bio::Cellucidate::Model->get($models->[0]->{id});
print "\nFirst Model Detail:\n";
print Dumper $model;


# Lets look at the initial conditions of our model. 
my $ics = Bio::Cellucidate::Model->initial_conditions($model->{id});
print "\nInitial Conditions:\n";
print Dumper $ics;

# Here are the details of the first initial condition
my $ic = Bio::Cellucidate::InitialCondition->get($ics->[0]->{id});
print "\nFirst Initial Condition Detail:\n";
print Dumper $ic;


# Here are the model rules.
my $model_rules = Bio::Cellucidate::Model->model_rules($model->{id});
print "\nModel Rules for model:\n";
print Dumper $model_rules;

# Here is the detail of the first model rule
my $model_rule = Bio::Cellucidate::ModelRule->get($model_rules->[0]->{id});
print "\nModel Rule Detail:\n";
print Dumper $model_rule;


# There shouldn't be any simulation runs yet, but let's check
my $simulation_runs = Bio::Cellucidate::Model->simulation_runs($model->{id});
print "\nSimulation Runs for model:\n";
print Dumper $simulation_runs;

# Let's create a simulation run (2 iterations)!
my $simulation_run = Bio::Cellucidate::SimulationRun->create({ model_id => $model->{id}, num_iterations => 2 }); #, simulation_method => 'ODE' });
print "\nNewly created Simulation Run:\n";
print Dumper $simulation_run;

# Same pattern as import, poll and see when my run is complete...
while ($simulation_run->{state} ne 'succeeded') {
    # Wait a few seconds..
    sleep(2);
    
    # Requery simulation
    $simulation_run = Bio::Cellucidate::SimulationRun->get($simulation_run->{id});

    printf "Simulation run state is %s.  %.2f %% complete...\n",
       $simulation_run->{state}, 
       $simulation_run->{progress};
}


# Simulation is done, check it out
print "\nCompleted Simulation Run:\n";
print Dumper $simulation_run;


# Let's see all the data in CSV format for the simulation
my $simulation_csv =  Bio::Cellucidate::SimulationRun->get($simulation_run->{id}, 'CSV');
print "\nSimluation Run CSV:\n";
print Dumper $simulation_csv;


# We can get the Plots
my $plots = Bio::Cellucidate::SimulationRun->plots($simulation_run->{id});
print "\nAll Plots from Simulation:\n";
print Dumper $plots;


# Detail for first plot
my $plot = Bio::Cellucidate::Plot->get($plots->[0]->{id});
print "\nFirst Plot Detail:\n";
print Dumper $plot;

# Get the plot in CSV
my $plot_csv = Bio::Cellucidate::Plot->get($plot->{id}, 'CSV');
print "\nFirst Plot in CSV:\n";
print Dumper $plot_csv;


__DATA__
'RBS transcription{58497}' DNA(binding!1,downstream!2,type~BBaB0000), RNAP(dna!1,rna!3), DNA(upstream!2,binding), RNA(downstream!3) -> DNA(binding,downstream!2,type~BBaB0000), RNAP(dna!1,rna!3), DNA(upstream!2,binding!1), RNA(downstream!4), RNA(binding,upstream!4,downstream!3,type~BBaB0000) @ 10.0
'Coding sequence translation{77005}' RNA(binding!1,type~BBaC0000), Ribosome(rna!1) -> RNA(binding,type~BBaC0000), Ribosome(rna), Repressor(dna) @ 10.0
'Transcription initiation of R0051{77270}' DNA(binding!1,type~BBaR0051p4,downstream!2), RNAP(dna!1,rna), DNA(upstream!2,binding) -> DNA(binding,type~BBaR0051p4,downstream!3), RNAP(dna!1,rna!2), DNA(upstream!3,binding!1), RNA(binding,upstream,downstream!2,type~BBaR0051) @ 10.0
'LacI binding to R0010p3 (no LacI){77309}' DNA(binding,type~BBaR0010p3,upstream!2), LacI(dna,lactose), DNA(downstream!2,binding,type~BBaR0010p2) <-> DNA(binding!1,type~BBaR0010p3,upstream!3), LacI(dna!1,lactose), DNA(downstream!3,binding,type~BBaR0010p2) @ 0.00996323269897635,2.24
'TetR translation initiation{77281}' RNA(binding!2,downstream!1), RNA(binding,upstream!1,type~BBaC0040), Ribosome(rna!2) -> RNA(binding,downstream!1), RNA(binding!2,upstream!1,type~BBaC0040), Ribosome(rna!2) @ 0.167
'IPTG addition{77331}'  -> IPTG(laci) @ 0.0
'C0040 transcription{77278}' DNA(binding!1,downstream!2,type~BBaC0040), RNAP(dna!1,rna!3), DNA(upstream!2,binding), RNA(downstream!3) -> DNA(binding,downstream!2,type~BBaC0040), RNAP(dna!1,rna!3), DNA(upstream!2,binding!1), RNA(downstream!4), RNA(binding,upstream!4,downstream!3,type~BBaC0040) @ 10.0
'Transcription of R0051 (readthrough){77271}' DNA(binding,type~BBaR0051p3,downstream!2,upstream!3), RNAP(dna!1,rna!5), DNA(upstream!6,binding), DNA(upstream!4,downstream!3,binding,type~BBaR0051p2), DNA(downstream!4,binding!1,type~BBaR0051p1), RNA(downstream!5), DNA(upstream!2,downstream!6,binding,type~BBaR0051p4) -> DNA(binding,type~BBaR0051p3,downstream!3,upstream!5), RNAP(dna!1,rna!6), DNA(upstream!7,binding!1), DNA(upstream!4,downstream!5,binding,type~BBaR0051p2), DNA(downstream!4,binding,type~BBaR0051p1), RNA(downstream!2), DNA(upstream!3,downstream!7,binding,type~BBaR0051p4), RNA(binding,upstream!2,downstream!6,type~BBaR0051) @ 10.0
'Repressor binding (no RNAP){76995}' DNA(downstream!1,binding,type~BBaR0000p2), DNA(upstream!1,binding,type~BBaR0000p3), Repressor(dna) <-> DNA(downstream!1,binding!2,type~BBaR0000p2), DNA(upstream!1,binding,type~BBaR0000p3), Repressor(dna!2) @ 0.0166053878316273,1.0
'Transcription of R0010 (readthrough){77317}' DNA(binding,type~BBaR0010p3,downstream!2,upstream!3), RNAP(dna!1,rna!5), DNA(upstream!6,binding), DNA(upstream!4,downstream!3,binding,type~BBaR0010p2), DNA(downstream!4,binding!1,type~BBaR0010p1), RNA(downstream!5), DNA(upstream!2,downstream!6,binding,type~BBaR0010p4) -> DNA(binding,type~BBaR0010p3,downstream!3,upstream!5), RNAP(dna!1,rna!6), DNA(upstream!7,binding!1), DNA(upstream!4,downstream!5,binding,type~BBaR0010p2), DNA(downstream!4,binding,type~BBaR0010p1), RNA(downstream!2), DNA(upstream!3,downstream!7,binding,type~BBaR0010p4), RNA(binding,upstream!2,downstream!6,type~BBaR0010) @ 10.0
'Transcription of R0040 (readthrough){77306}' DNA(binding,type~BBaR0040p3,downstream!2,upstream!3), RNAP(dna!1,rna!5), DNA(upstream!6,binding), DNA(upstream!4,downstream!3,binding,type~BBaR0040p2), DNA(downstream!4,binding!1,type~BBaR0040p1), RNA(downstream!5), DNA(upstream!2,downstream!6,binding,type~BBaR0040p4) -> DNA(binding,type~BBaR0040p3,downstream!3,upstream!5), RNAP(dna!1,rna!6), DNA(upstream!7,binding!1), DNA(upstream!4,downstream!5,binding,type~BBaR0040p2), DNA(downstream!4,binding,type~BBaR0040p1), RNA(downstream!2), DNA(upstream!3,downstream!7,binding,type~BBaR0040p4), RNA(binding,upstream!2,downstream!6,type~BBaR0040) @ 10.0
'Ribosome falloff{76777}' Ribosome(rna!1), RNA(binding!1) -> Ribosome(rna), RNA(binding) @ 0.01
'Transcription initiation{58498}' DNA(binding!1,type~BBaR0000p3,downstream!2), RNAP(dna!1,rna), DNA(upstream!2,binding) -> DNA(binding,type~BBaR0000p3,downstream!3), RNAP(dna!1,rna!2), DNA(upstream!3,binding!1), RNA(binding,upstream,downstream!2,type~BBaR0000) @ 10.0
'RNAP falloff{76542}' DNA(binding!1,downstream!3), RNAP(dna!1,rna!2), RNA(downstream!2), DNA(upstream!3,binding!_) -> DNA(binding,downstream!1), RNAP(dna,rna), RNA(downstream), DNA(upstream!1,binding!_) @ 1.0
'Promoter transcription (readthrough){77000}' DNA(binding,type~BBaR0000p3,downstream!2,upstream!3), RNAP(dna!1,rna!5), DNA(upstream!2,binding), DNA(upstream!4,downstream!3,binding,type~BBaR0000p2), DNA(downstream!4,binding!1,type~BBaR0000p1), RNA(downstream!5) -> DNA(binding,type~BBaR0000p3,downstream!3,upstream!5), RNAP(dna!1,rna!6), DNA(upstream!3,binding!1), DNA(upstream!4,downstream!5,binding,type~BBaR0000p2), DNA(downstream!4,binding,type~BBaR0000p1), RNA(downstream!2), RNA(binding,upstream!2,downstream!6,type~BBaR0000) @ 10.0
'LacI degradation{77288}' LacI(dna) ->  @ 0.00115
'IPTG washout{77329}' IPTG(laci) ->  @ 0.0
'ATC addition{77334}'  -> ATC(tetr) @ 0.0
'RNAP binding (with repressor){76997}' DNA(downstream!1,binding!3,type~BBaR0000p2), DNA(upstream!1,binding,type~BBaR0000p3), Repressor(dna!3), RNAP(dna,rna) -> DNA(downstream!1,binding!2,type~BBaR0000p2), DNA(upstream!1,binding!3,type~BBaR0000p3), Repressor(dna!2), RNAP(dna!3,rna) @ 8.30269391581363e-07
'RNAP binding (no repressor){76998}' DNA(downstream!1,binding,type~BBaR0000p2), DNA(upstream!1,binding,type~BBaR0000p3), RNAP(dna,rna) -> DNA(downstream!1,binding,type~BBaR0000p2), DNA(upstream!1,binding!3,type~BBaR0000p3), RNAP(dna!3,rna) @ 0.000830269391581363
'cI binding to R0051p3 (cI bound){77261}' DNA(binding,type~BBaR0051p3,upstream!2), cI(dna!1), cI(dna), DNA(downstream!2,binding!1,type~BBaR0051p2) <-> DNA(binding!1,type~BBaR0051p3,upstream!3), cI(dna!2), cI(dna!1), DNA(downstream!3,binding!2,type~BBaR0051p2) @ 0.00996323269897635,0.09
'Binding of IPTG to LacI{77327}' IPTG(laci), LacI(dna,lactose) <-> IPTG(laci!1), LacI(dna,lactose!1) @ 0.00166053878316273,0.02
'cI degradation{77286}' cI(dna) ->  @ 0.00115
'RNAP binding to R0051 (cI on p2 and p3){77269}' DNA(binding!3,type~BBaR0051p3,upstream!2,downstream!1), DNA(upstream!1,binding,type~BBaR0051p4), RNAP(dna,rna), DNA(downstream!2,binding!4,type~BBaR0051p2), cI(dna!3), cI(dna!4) -> DNA(binding!4,type~BBaR0051p3,upstream!3,downstream!1), DNA(upstream!1,binding!2,type~BBaR0051p4), RNAP(dna!2,rna), DNA(downstream!3,binding!5,type~BBaR0051p2), cI(dna!4), cI(dna!5) @ 7.14031676759972e-07
'RNAP binding to R0010 (LacI on p3){77314}' DNA(binding!3,type~BBaR0010p3,upstream!2,downstream!1), DNA(upstream!1,binding,type~BBaR0010p4), RNAP(dna,rna), DNA(downstream!2,binding,type~BBaR0010p2), LacI(dna!3) -> DNA(binding!4,type~BBaR0010p3,upstream!3,downstream!1), DNA(upstream!1,binding!2,type~BBaR0010p4), RNAP(dna!2,rna), DNA(downstream!3,binding,type~BBaR0010p2), LacI(dna!4) @ 7.14031676759972e-07
'TetR binding to R0040p3 (no TetR){77297}' DNA(binding,type~BBaR0040p3,upstream!2), TetR(dna,atc), DNA(downstream!2,binding,type~BBaR0040p2) <-> DNA(binding!1,type~BBaR0040p3,upstream!3), TetR(dna!1,atc), DNA(downstream!3,binding,type~BBaR0040p2) @ 0.00996323269897635,2.24
'cI binding to R0051p2 (no cI){77258}' DNA(binding,type~BBaR0051p3,upstream!2), cI(dna), DNA(downstream!2,binding,type~BBaR0051p2) <-> DNA(binding,type~BBaR0051p3,upstream!3), cI(dna!1), DNA(downstream!3,binding!1,type~BBaR0051p2) @ 0.00996323269897635,2.24
'Translation initiation{77010}' RNA(binding!2,downstream!1), RNA(binding,upstream!1,type~BBaC0000), Ribosome(rna!2) -> RNA(binding,downstream!1), RNA(binding!2,upstream!1,type~BBaC0000), Ribosome(rna!2) @ 0.167
'TetR binding to R0040p2 (no TetR){77296}' DNA(binding,type~BBaR0040p3,upstream!2), TetR(dna,atc), DNA(downstream!2,binding,type~BBaR0040p2) <-> DNA(binding,type~BBaR0040p3,upstream!3), TetR(dna!1,atc), DNA(downstream!3,binding!1,type~BBaR0040p2) @ 0.00996323269897635,2.24
'RNAP binding to R0040 (TetR on p2 and p3){77304}' DNA(binding!3,type~BBaR0040p3,upstream!2,downstream!1), DNA(upstream!1,binding,type~BBaR0040p4), RNAP(dna,rna), DNA(downstream!2,binding!4,type~BBaR0040p2), TetR(dna!3), TetR(dna!4) -> DNA(binding!4,type~BBaR0040p3,upstream!3,downstream!1), DNA(upstream!1,binding!2,type~BBaR0040p4), RNAP(dna!2,rna), DNA(downstream!3,binding!5,type~BBaR0040p2), TetR(dna!4), TetR(dna!5) @ 7.14031676759972e-07
'cI translation{77283}' RNA(binding!1,type~BBaC0051), Ribosome(rna!1) -> RNA(binding,type~BBaC0051), Ribosome(rna), cI(dna) @ 10.0
'Coding sequence transcription{77009}' DNA(binding!1,downstream!2,type~BBaC0000), RNAP(dna!1,rna!3), DNA(upstream!2,binding), RNA(downstream!3) -> DNA(binding,downstream!2,type~BBaC0000), RNAP(dna!1,rna!3), DNA(upstream!2,binding!1), RNA(downstream!4), RNA(binding,upstream!4,downstream!3,type~BBaC0000) @ 10.0
'Ribosome binding{77002}' RNA(binding,type~BBaB0000), Ribosome(rna) -> RNA(binding!1,type~BBaB0000), Ribosome(rna!1) @ 0.000166053878316273
'LacI translation initiation{77282}' RNA(binding!2,downstream!1), RNA(binding,upstream!1,type~BBaC0012), Ribosome(rna!2) -> RNA(binding,downstream!1), RNA(binding!2,upstream!1,type~BBaC0012), Ribosome(rna!2) @ 0.167
'RBS BBa_B0034 Ribosome binding{77254}' RNA(binding,type~BBaB0034), Ribosome(rna) -> RNA(binding!1,type~BBaB0034), Ribosome(rna!1) @ 0.000166053878316273
'Termination{77013}' DNA(binding!1,type~BBaK0000), RNAP(dna!1,rna!2), RNA(downstream!2) -> DNA(binding,type~BBaK0000), RNAP(dna,rna), RNA(downstream) @ 10.0
'Terminator transcription (readthrough){77015}' DNA(binding!1,downstream!2,type~BBaK0000), RNAP(dna!1,rna!3), DNA(upstream!2,binding), RNA(downstream!3) -> DNA(binding,downstream!2,type~BBaK0000), RNAP(dna!1,rna!3), DNA(upstream!2,binding!1), RNA(downstream!4), RNA(binding,upstream!4,downstream!3,type~BBaK0000) @ 1.0
'RBS BBa_B0034 transcription{77253}' DNA(binding!1,downstream!2,type~BBaB0034), RNAP(dna!1,rna!3), DNA(upstream!2,binding), RNA(downstream!3) -> DNA(binding,downstream!2,type~BBaB0034), RNAP(dna!1,rna!3), DNA(upstream!2,binding!1), RNA(downstream!4), RNA(binding,upstream!4,downstream!3,type~BBaB0034) @ 10.0
'cI binding to R0051p2 (cI bound){77260}' DNA(binding!1,type~BBaR0051p3,upstream!2), cI(dna), cI(dna!1), DNA(downstream!2,binding,type~BBaR0051p2) <-> DNA(binding!2,type~BBaR0051p3,upstream!3), cI(dna!1), cI(dna!2), DNA(downstream!3,binding!1,type~BBaR0051p2) @ 0.00996323269897635,0.09
'TetR binding to R0040p3 (TetR bound){77300}' DNA(binding,type~BBaR0040p3,upstream!2), TetR(dna,atc), TetR(dna!1), DNA(downstream!2,binding!1,type~BBaR0040p2) <-> DNA(binding!2,type~BBaR0040p3,upstream!3), TetR(dna!2,atc), TetR(dna!1), DNA(downstream!3,binding!1,type~BBaR0040p2) @ 0.00996323269897635,0.09
'RNAP binding to R0040 (TetR on p2){77302}' DNA(binding,type~BBaR0040p3,upstream!2,downstream!1), DNA(upstream!1,binding,type~BBaR0040p4), RNAP(dna,rna), DNA(downstream!2,binding!3,type~BBaR0040p2), TetR(dna!3) -> DNA(binding,type~BBaR0040p3,upstream!3,downstream!1), DNA(upstream!1,binding!2,type~BBaR0040p4), RNAP(dna!2,rna), DNA(downstream!3,binding!4,type~BBaR0040p2), TetR(dna!4) @ 7.14031676759972e-07
'Repressor binding (with RNAP){76996}' DNA(downstream!1,binding,type~BBaR0000p2), DNA(upstream!1,binding!2,type~BBaR0000p3), Repressor(dna), RNAP(dna!2) <-> DNA(downstream!1,binding!2,type~BBaR0000p2), DNA(upstream!1,binding!3,type~BBaR0000p3), Repressor(dna!2), RNAP(dna!3) @ 1.66053878316273e-05,1.0
'TetR binding to R0040p2 (TetR bound){77299}' DNA(binding!1,type~BBaR0040p3,upstream!2), TetR(dna!1), TetR(dna,atc), DNA(downstream!2,binding,type~BBaR0040p2) <-> DNA(binding!2,type~BBaR0040p3,upstream!3), TetR(dna!2), TetR(dna!1,atc), DNA(downstream!3,binding!1,type~BBaR0040p2) @ 0.00996323269897635,0.09
'B0011 terminator transcription (readthrough){77291}' DNA(binding!1,downstream!2,type~BBaB0011), RNAP(dna!1,rna!3), DNA(upstream!2,binding), RNA(downstream!3) -> DNA(binding,downstream!2,type~BBaR0011), RNAP(dna!1,rna!3), DNA(upstream!2,binding!1), RNA(downstream!4), RNA(binding,upstream!4,downstream!3,type~BBaR0011) @ 0.5
'LacI translation{77285}' RNA(binding!1,type~BBaC0012), Ribosome(rna!1) -> RNA(binding,type~BBaC0012), Ribosome(rna), LacI(dna,lactose) @ 10.0
'Binding of ATC to TetR{77325}' TetR(dna,atc), ATC(tetr) <-> TetR(dna,atc!1), ATC(tetr!1) @ 1.66053878316273,0.001
'RNAP binding to R0010 (LacI on p2 and p3){77315}' DNA(binding!3,type~BBaR0010p3,upstream!2,downstream!1), DNA(upstream!1,binding,type~BBaR0010p4), RNAP(dna,rna), DNA(downstream!2,binding!4,type~BBaR0010p2), LacI(dna!3), LacI(dna!4) -> DNA(binding!4,type~BBaR0010p3,upstream!3,downstream!1), DNA(upstream!1,binding!2,type~BBaR0010p4), RNAP(dna!2,rna), DNA(downstream!3,binding!5,type~BBaR0010p2), LacI(dna!4), LacI(dna!5) @ 7.14031676759972e-07
'TetR translation{77284}' RNA(binding!1,type~BBaC0040), Ribosome(rna!1) -> RNA(binding,type~BBaC0040), Ribosome(rna), TetR(dna,atc) @ 10.0
'TetR degradation{77287}' TetR(dna) ->  @ 0.00115
'RNAP binding to R0051 (cI on p3){77268}' DNA(binding!3,type~BBaR0051p3,upstream!2,downstream!1), DNA(upstream!1,binding,type~BBaR0051p4), RNAP(dna,rna), DNA(downstream!2,binding,type~BBaR0051p2), cI(dna!3) -> DNA(binding!4,type~BBaR0051p3,upstream!3,downstream!1), DNA(upstream!1,binding!2,type~BBaR0051p4), RNAP(dna!2,rna), DNA(downstream!3,binding,type~BBaR0051p2), cI(dna!4) @ 7.14031676759972e-07
'Transcription initiation of R0040{77305}' DNA(binding!1,type~BBaR0040p4,downstream!2), RNAP(dna!1,rna), DNA(upstream!2,binding) -> DNA(binding,type~BBaR0040p4,downstream!3), RNAP(dna!1,rna!2), DNA(upstream!3,binding!1), RNA(binding,upstream,downstream!2,type~BBaR0040) @ 10.0
'LacI binding to R0010p2 (no LacI){77308}' DNA(binding,type~BBaR0010p3,upstream!2), LacI(dna,lactose), DNA(downstream!2,binding,type~BBaR0010p2) <-> DNA(binding,type~BBaR0010p3,upstream!3), LacI(dna!1,lactose), DNA(downstream!3,binding!1,type~BBaR0010p2) @ 0.00996323269897635,2.24
'LacI binding to R0010p3 (LacI bound){77311}' DNA(binding,type~BBaR0010p3,upstream!2), LacI(dna!1), DNA(downstream!2,binding!1,type~BBaR0010p2), LacI(dna,lactose) <-> DNA(binding!1,type~BBaR0010p3,upstream!3), LacI(dna!2), DNA(downstream!3,binding!2,type~BBaR0010p2), LacI(dna!1,lactose) @ 0.00996323269897635,0.09
'LacI binding to R0010p2 (LacI bound){77310}' DNA(binding!1,type~BBaR0010p3,upstream!2), LacI(dna!1), DNA(downstream!2,binding,type~BBaR0010p2), LacI(dna,lactose) <-> DNA(binding!2,type~BBaR0010p3,upstream!3), LacI(dna!2), DNA(downstream!3,binding!1,type~BBaR0010p2), LacI(dna!1,lactose) @ 0.00996323269897635,0.09
'Transcription initiation of R0010{77316}' DNA(binding!1,type~BBaR0010p4,downstream!2), RNAP(dna!1,rna), DNA(upstream!2,binding) -> DNA(binding,type~BBaR0010p4,downstream!3), RNAP(dna!1,rna!2), DNA(upstream!3,binding!1), RNA(binding,upstream,downstream!2,type~BBaR0010) @ 10.0
'Termination - B0011{77290}' DNA(binding!1,type~BBaB0011), RNAP(dna!1,rna!2), RNA(downstream!2) -> DNA(binding,type~BBaB0011), RNAP(dna,rna), RNA(downstream) @ 10.0
'Repressor degradation{77212}' Repressor(dna) ->  @ 0.00115
'RNAP binding to R0040 (no TetR){77301}' DNA(binding,type~BBaR0040p3,upstream!2,downstream!1), DNA(upstream!1,binding,type~BBaR0040p4), RNAP(dna,rna), DNA(downstream!2,binding,type~BBaR0040p2) -> DNA(binding,type~BBaR0040p3,upstream!3,downstream!1), DNA(upstream!1,binding!2,type~BBaR0040p4), RNAP(dna!2,rna), DNA(downstream!3,binding,type~BBaR0040p2) @ 0.000714031676759972
'RNAP binding to R0040 (TetR on p3){77303}' DNA(binding!3,type~BBaR0040p3,upstream!2,downstream!1), DNA(upstream!1,binding,type~BBaR0040p4), RNAP(dna,rna), DNA(downstream!2,binding,type~BBaR0040p2), TetR(dna!3) -> DNA(binding!4,type~BBaR0040p3,upstream!3,downstream!1), DNA(upstream!1,binding!2,type~BBaR0040p4), RNAP(dna!2,rna), DNA(downstream!3,binding,type~BBaR0040p2), TetR(dna!4) @ 7.14031676759972e-07
'ATC washout{77333}' ATC(tetr) ->  @ 0.0
'cI translation initiation{77280}' RNA(binding!2,downstream!1), RNA(binding,upstream!1,type~BBaC0051), Ribosome(rna!2) -> RNA(binding,downstream!1), RNA(binding!2,upstream!1,type~BBaC0051), Ribosome(rna!2) @ 0.167
'C0012 transcription{77279}' DNA(binding!1,downstream!2,type~BBaC0012), RNAP(dna!1,rna!3), DNA(upstream!2,binding), RNA(downstream!3) -> DNA(binding,downstream!2,type~BBaC0012), RNAP(dna!1,rna!3), DNA(upstream!2,binding!1), RNA(downstream!4), RNA(binding,upstream!4,downstream!3,type~BBaC0012) @ 10.0
'RNA degradation{76543}' RNA(binding,downstream) ->  @ 0.0058
'cI binding to R0051p3 (no cI){77259}' DNA(binding,type~BBaR0051p3,upstream!2), cI(dna), DNA(downstream!2,binding,type~BBaR0051p2) <-> DNA(binding!1,type~BBaR0051p3,upstream!3), cI(dna!1), DNA(downstream!3,binding,type~BBaR0051p2) @ 0.00996323269897635,2.24
'RNAP binding to R0051 (no cI){77266}' DNA(binding,type~BBaR0051p3,upstream!2,downstream!1), DNA(upstream!1,binding,type~BBaR0051p4), RNAP(dna,rna), DNA(downstream!2,binding,type~BBaR0051p2) -> DNA(binding,type~BBaR0051p3,upstream!3,downstream!1), DNA(upstream!1,binding!2,type~BBaR0051p4), RNAP(dna!2,rna), DNA(downstream!3,binding,type~BBaR0051p2) @ 0.000714031676759972
'RNAP binding to R0051 (cI on p2){77267}' DNA(binding,type~BBaR0051p3,upstream!2,downstream!1), DNA(upstream!1,binding,type~BBaR0051p4), RNAP(dna,rna), DNA(downstream!2,binding!3,type~BBaR0051p2), cI(dna!3) -> DNA(binding,type~BBaR0051p3,upstream!3,downstream!1), DNA(upstream!1,binding!2,type~BBaR0051p4), RNAP(dna!2,rna), DNA(downstream!3,binding!4,type~BBaR0051p2), cI(dna!4) @ 7.14031676759972e-07
'C0051 transcription{77272}' DNA(binding!1,downstream!2,type~BBaC0051), RNAP(dna!1,rna!3), DNA(upstream!2,binding), RNA(downstream!3) -> DNA(binding,downstream!2,type~BBaC0051), RNAP(dna!1,rna!3), DNA(upstream!2,binding!1), RNA(downstream!4), RNA(binding,upstream!4,downstream!3,type~BBaC0051) @ 10.0
'RNAP binding to R0010 (no LacI){77312}' DNA(binding,type~BBaR0010p3,upstream!2,downstream!1), DNA(upstream!1,binding,type~BBaR0010p4), RNAP(dna,rna), DNA(downstream!2,binding,type~BBaR0010p2) -> DNA(binding,type~BBaR0010p3,upstream!3,downstream!1), DNA(upstream!1,binding!2,type~BBaR0010p4), RNAP(dna!2,rna), DNA(downstream!3,binding,type~BBaR0010p2) @ 0.000714031676759972
'RNAP binding to R0010 (LacI on p2){77313}' DNA(binding,type~BBaR0010p3,upstream!2,downstream!1), DNA(upstream!1,binding,type~BBaR0010p4), RNAP(dna,rna), DNA(downstream!2,binding!3,type~BBaR0010p2), LacI(dna!3) -> DNA(binding,type~BBaR0010p3,upstream!3,downstream!1), DNA(upstream!1,binding!2,type~BBaR0010p4), RNAP(dna!2,rna), DNA(downstream!3,binding!4,type~BBaR0010p2), LacI(dna!4) @ 7.14031676759972e-07
%init: 700 * (RNAP(dna,rna))
%init: 18000 * (Ribosome(rna))
%init: 1 * (DNA(upstream,downstream!1,binding,type~BBaR0051p1), DNA(upstream!1,downstream!2,binding,type~BBaR0051p2), DNA(upstream!2,downstream!3,binding,type~BBaR0051p3), DNA(upstream!3,downstream!4,binding,type~BBaR0051p4), DNA(upstream!4,downstream!5,binding,type~BBaB0034), DNA(upstream!5,downstream!6,binding,type~BBaC0012), DNA(upstream!6,downstream,binding,type~BBaB0011))
%init: 1 * (DNA(upstream,downstream!1,binding,type~BBaR0010p1), DNA(upstream!1,downstream!2,binding,type~BBaR0010p2), DNA(upstream!2,downstream!3,binding,type~BBaR0010p3), DNA(upstream!3,downstream!4,binding,type~BBaR0010p4), DNA(upstream!4,downstream!5,binding,type~BBaB0034), DNA(upstream!5,downstream!6,binding,type~BBaC0040), DNA(upstream!6,downstream,binding,type~BBaB0011))
%init: 1 * (DNA(upstream,downstream!1,binding,type~BBaR0040p1), DNA(upstream!1,downstream!2,binding,type~BBaR0040p2), DNA(upstream!2,downstream!3,binding,type~BBaR0040p3), DNA(upstream!3,downstream!4,binding,type~BBaR0040p4), DNA(upstream!4,downstream!5,binding,type~BBaB0034), DNA(upstream!5,downstream!6,binding,type~BBaC0051), DNA(upstream!6,downstream,binding,type~BBaB0011))

