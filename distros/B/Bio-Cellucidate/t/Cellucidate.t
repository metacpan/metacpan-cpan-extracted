#!/usr/bin/env perl

use t::TestHelper;

my @modules = qw/
    Bio::Cellucidate
    Bio::Cellucidate::Request
    Bio::Cellucidate::Bookshelf
    Bio::Cellucidate::Book
    Bio::Cellucidate::Agent
    Bio::Cellucidate::Rule
    Bio::Cellucidate::Model
    Bio::Cellucidate::ModelRule
    Bio::Cellucidate::RuleObservable
    Bio::Cellucidate::SolutionObservable
    Bio::Cellucidate::InitialCondition
    Bio::Cellucidate::SimulationRun
    Bio::Cellucidate::Plot
    Bio::Cellucidate::Series
    Bio::Cellucidate::KappaImportJob
/;

plan tests => scalar(@modules);

foreach my $module (@modules) { use_ok($module); }
