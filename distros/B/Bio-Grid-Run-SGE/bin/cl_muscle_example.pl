#!/usr/bin/env perl

use warnings;
use strict;

use Carp;

use Bio::Grid::Run::SGE::Util qw/my_glob my_sys INFO run_job/;
use Bio::Grid::Run::SGE::Master;

run_job( { pre_task => \&do_master_stuff, task => \&do_worker_stuff } );
1;

sub do_master_stuff {
    my ($c) = @_;

    #WICHTIG: return statements in every function
    return Bio::Grid::Run::SGE::Master->new($c);
}

sub do_worker_stuff {
    my ( $c, $result_file,$input_file ) = @_;

    my $cmd = "$ENV{HOME}/bin/muscle -in $input_file -out $result_file -maxiters $c->{max_iters}";
    INFO "Running muscle: $cmd";
    
    my_sys($cmd);
    #WICHTIG: return statements in every function
    return;
}

