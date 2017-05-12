#!/usr/bin/perl
use strict;
use warnings;
use blib;
use Config::Merge();
use File::Spec();

eval        { require YAML::Syck; YAML::Syck->import(); 1 }
    or eval { require YAML;       YAML->import();       1 }
    or die "ERROR: "
    . "YAML::Syck or YAML needs to be installed to use this example\n\n";

my $config = Config::Merge->new( get_path('config_dev') );
my $path = shift @ARGV || '';

my $data = $config->($path);

print Dump($data);

#===================================
sub get_path {
#===================================
    my ($vol,$path) = File::Spec->splitpath(
                   File::Spec->rel2abs($0)
            );
    $path = File::Spec->catdir(
        File::Spec->splitdir($path),
        ,@_
    );
    return File::Spec->catpath($vol,$path,'');
}
