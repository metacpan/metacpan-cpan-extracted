#!/usr/bin/env perl
 
use Dancer;
use Catmandu;
use Dancer::Plugin::Catmandu::SRU;
 
Catmandu->load;
Catmandu->config;
 
my $options = {};

sru_provider '/sru', %$options;
 
dance;
