#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

my @packages = qw(
  Catmandu::Importer::Activiti::RuntimeTask
  Catmandu::Importer::Activiti::HistoricTask
  Catmandu::Importer::Activiti::RuntimeProcessInstance
  Catmandu::Importer::Activiti::HistoricProcessInstance
);
require_ok $_ for @packages;

done_testing scalar(@packages);
