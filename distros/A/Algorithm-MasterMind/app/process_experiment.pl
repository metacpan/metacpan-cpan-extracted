#!/usr/bin/perl

use strict;
use warnings;

use IO::YAML;
use YAML qw(Load);

my $yaml_file = shift || die "I need an experiment file, no defaults\n";
my $results_io = IO::YAML->new($yaml_file, '<') || die "Can't open $yaml_file: $@\n";

print "Evaluations, Played\n";
while(defined(my $yaml = <$results_io>)) {
    next if $yaml !~ /evaluations/;
    my $these_results = YAML::Load($yaml);
    print $these_results->{'evaluations'}, ", ",  
    @{$these_results->{'combinations'}}+1, "\n";
}

  
