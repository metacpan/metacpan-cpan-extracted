package Bio::Cellucidate;

use 5.008009;
use Bio::Cellucidate::Request;
use Bio::Cellucidate::Bookshelf;
use Bio::Cellucidate::Book;
use Bio::Cellucidate::Rule;
use Bio::Cellucidate::Agent;
use Bio::Cellucidate::Model;
use Bio::Cellucidate::ModelRule;
use Bio::Cellucidate::RuleObservable;
use Bio::Cellucidate::SolutionObservable;
use Bio::Cellucidate::InitialCondition;
use Bio::Cellucidate::SimulationRun;
use Bio::Cellucidate::Plot;
use Bio::Cellucidate::Series;
use Bio::Cellucidate::KappaImportJob;

use strict;
use warnings;

our $VERSION = '0.03';

our $CONFIG = {
    host => 'http://api.cellucidate.com'
};

our $AUTH = {
    'login' => 'user@host.com',
    'api_key' => '111111'
};


1;

__END__

=head1 NAME

Bio::Cellucidate - Perl library for cellucidate.com

=head1 SYNOPSIS

  use Cellucidate;

  # Search for a bookshelf, returns an array of bookshelf hashes
  $bookshelves = Bio::Cellucidate::Bookshelf->find();
  $bookshelves = Bio::Cellucidate::Bookshelf->find( { name => 'Reference 10' });

  # Single bookshelf
  $bookshelf = Bio::Cellucidate::Bookshelf->show(102);

  # Bookshelf properties
  $bookshelf->{id}   # => 102
  $bookshelf->{name} # => 'Reference 10'


  # All books on a bookshelf
  $books = $bookshelf->books();

  # Search for a book
  $books = Bio::Cellucidate::Book->find( ... );

  # Search for models..
  $models = Bio::Cellucidate::Model->find( ... );

  # Single model
  $model = Bio::Cellucidate::Model->show( id );

  # All models in a book
  $model = Bio::Cellucidate::Book->models( book_id );

  # All model rules in a model
  $model_rules = Bio::Cellucidate::Model->model_rules( model_id );

  # All initial conditions in a model
  $initial_conditions = Bio::Cellucidate::Model->initial_conditions( model_id );

  # All simulation runs in a model
  $simulation_runs = Bio::Cellucidate::Model->simulation_runs( model_id );

  # Create a simulation run for a model
  $simulation_run_params = { "model_id" => $model_id  };
  $simulation_run = Bio::Cellucidate::SimulationRun->create($simulation_run_params);

  $csv_data = Bio::Cellucidate::SimulationRun->get($simulation_run_id, 'csv');

  $plots = Bio::Cellucidate::SimulationRun->plots($simulation_run_id);

  $plots = $simulation_run->plots();  # Bio::Cellucidate::Plot->find( { simulation_run_id => $id } );

=head1 DESCRIPTION

Cellucidate is a tool for computation biologists to run simulations.  It is
based on the Kappa language.

The various objects in Cellucidate are arranged into a book metaphor.  The basic
hierarchy is:

  Bookshelves
  `-> Books
      `-> Agents
      `-> Rules
      `-> Models
          `-> Model Rules
          `-> Initial Conditions
          `-> Rule Observables
          `-> Solution Observables
          `-> Simulation Runs
              `-> Ode Results
              `-> Plots
                  `-> Series

Additionally, there are a few resources for auxiliary tasks, like importing
data and running various jobs L<Cellucidate::KappaImportJob>.

=head2 REST

Cellucidate has a RESTful interface.  So this library is built upon the 
L<REST::Client> library.  At the core, there are 4 operations over HTTP,
including: GET, POST, PUT and DELETE.  The encoding is primarily XML, but
certain resource can be returned in CSV and Kappa (application/x-kappa).

=head2 COMMON METHODS / PATTERN

Around each resource, there are convience methods -

    find( { params }, format)
    get(id, format)
    update(id, { data }, format)
    create({ data }, format)

See each subclass for a list of specific methods and examples

=head1 CONFIGURATION

There are two variables that should be set.  These are used by all
subclasses.

=over 4

=item $Bio::Cellucidate::CONFIG

This is a hash of configuration options for the underling REST client.
See L<REST::Client> for more information.

    $Bio::Cellucidate::CONFIG = { host => 'http://api.cellucidate.com' };

=item $Bio::Cellucidate::AUTH

This is a hash of your authentication information from cellucidate.com.
It includes your email address as your login and API Key.

    $Bio::Cellucidate::AUTH = { login => 'email@host.com', api_key => '111111' };

=head1 SUBCLASSES

=over 4

=item L<Bio::Cellucidate::Base> 

Base class for each resource.

=item L<Bio::Cellucidate::Bookshelf> 

Represents a Bookshelf in Cellucidate.  This is pretty much the top tier
of cellucidate resources.

=item L<Bio::Cellucidate::Book>

Represents a Book in Cellucidate.  This is where Models live.  A book
can be placed on a Bookshelf and has many Models.

=item L<Bio::Cellucidate::Agent>

Represents an agent in Cellucidate.  Agents are used by rules and initial
conditions and solution observables.  Books have zero, one or many agents
and an agent belongs to a book.

=item L<Bio::Cellucidate::Rule>

Represents a rule in Cellucidate. Books have zero, one or many rules
and a rule belongs to a book.  Models have Rules through the ModelRule
resource.

=item L<Bio::Cellucidate::Model> 

Represents a biological model in Cellucidate.  The model belongs to a book
and contains a number of Model Rules and Initial Conditions.  A number of
simulations can be run from a Model, each having a number of settings.

=item L<Bio::Cellucidate::ModelRule> 

Represents a Rule that is used my a model.  Model rules belong to a model and
models have one or more typically many model rules.  ModelRules have an
association to Rules.

=item L<Bio::Cellucidate::SolutionObservable>

Represents an Agent or set of Agents that you want to observe and plot the 
concentration of when the simulation is run.

=item L<Bio::Cellucidate::RuleObservable>

Represents a ModelRule that you want to observe the activity of when the
simulation is run.

=item L<Bio::Cellucidate::InitialCondition>

This is an initial condition in a model.  Models have one by more typically
many initial conditions and an initial condition belongs to a model.

=item L<Bio::Cellucidate::SimulationRun>

A simulation run represents an execution of the Cellucidate simulator and contains
child result resources.  Simulation runs define various settings.
A Model has one or many simulation runs and a simulation run belongs to
a model.

=item L<Bio::Cellucidate::OdeResult>

Represents the set of ODE formulas generated when running a simulation in ODE-mode.
The results can be used directly in MATLAB.

=item L<Bio::Cellucidate::Plot>

A plot contains a single time series and a number of data series representing the
rule and solution observables.  A simulation run has one or many plots (one for
each iteration).

=item L<Bio::Cellucidate::Series>

A collection of datapoints.  A series belongs to a plot and represents an observable
or time.

=item L<Bio::Cellucidate::KappaImportJob>

This is a resource that represents an import job.  This allows the creation
of a Book, including Model Rules and Initial Conditions, from a Kappa 
string.

=item L<Bio::Cellucidate::Request>

This is the request client, a subclass of L<REST::Client>.  This isn't a 
cellucidate resource.

=back

=head1 SEE ALSO

L<http://cellucidate.com>, L<REST::Client>

=head1 AUTHOR

Brian Kaney, E<lt>brian@vermonster.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Plectix BioSystems Inc 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut
