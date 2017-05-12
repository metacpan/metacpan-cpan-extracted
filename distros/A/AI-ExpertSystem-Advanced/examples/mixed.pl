#!/usr/bin/perl
# 
# forward.pl
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
        initial_facts => ['I'],
        verbose => 1);
$ai->mixed();
$ai->summary();



