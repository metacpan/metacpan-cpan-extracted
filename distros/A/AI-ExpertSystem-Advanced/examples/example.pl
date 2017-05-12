#!/usr/bin/perl
# 
# example.pl
# 
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 12/13/2009 15:20:43 PST 15:20:43

use strict;
use warnings;
use Data::Dumper;
use AI::ExpertSystem::Advanced;
use AI::ExpertSystem::Advanced::KnowledgeDB::Factory;

my $yaml_kdb = AI::ExpertSystem::Advanced::KnowledgeDB::Factory->new('yaml',
        {
            filename => 'examples/knowledge_db_one.yaml'
            });

my $ai = AI::ExpertSystem::Advanced->new(
        viewer_class => 'terminal',
        knowledge_db => $yaml_kdb,
        goals_to_check => ['H']);
$ai->backward();
$ai->summary();



