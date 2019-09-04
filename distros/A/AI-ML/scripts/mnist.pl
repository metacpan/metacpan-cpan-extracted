#!/usr/bin/env perl

use warnings;
use strict;

use HTTP::Tiny;
use Data::Dumper;
use File::Fetch;

use Math::Lapack;
use Math::Lapack::Matrix;

use AI::ML;
use AI::ML::NeuralNetwork;
    
my %opt = (
        "train-images" => "train-images-idx3-ubyte",
        "train-labels" => "train-labels-idx1-ubyte",
        "test-images"  => "t10k-images-idx3-ubyte",
        "test-labels"  => "t10k-labels-idx1-ubyte"
    );


_load_data();


sub _load_data {
    _download_data();
    # compile c file
    system("gcc load_data.c -o load");

    my @matrices;
    
    for my $key ( keys %opt ) {
        my (undef, $type) = split /-/, $key;
        system("gunzip $opt{$key}.gz");
        system("./load $type $opt{$key} $key.csv");
    }
}

sub _download_data{
    my $http = HTTP::Tiny->new();

    my $url = "http://yann.lecun.com/exdb/mnist";

    my $res;
    for my $key ( keys %opt ) {
        my $file = "$url/$opt{$key}.gz";
        my $ff = File::Fetch->new(uri => $file);
        my $aux = $ff->fetch() or die $ff->error;
        #print "$file\n";
        #$res = $http->get("$file");
        #my $content = $res->{content};
#       # $res = $http->get("$route/".$opt{$key});
        #print STDERR Dumper $content;
    } 
}
    








