#!/usr/bin/perl
use strict;
use warnings;

use YAML::Syck;
use AlignDB::DeltaG;

my $dG = AlignDB::DeltaG->new;
YAML::Syck::DumpFile( "dG.yml", $dG);
