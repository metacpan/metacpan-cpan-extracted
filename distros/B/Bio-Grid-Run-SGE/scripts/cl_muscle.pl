#!/usr/bin/env perl
#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

use warnings;
use strict;

use Carp;
use Data::Dumper;

use Bio::Grid::Run::SGE;

run_job(
    {
        task => sub {
            my ( $c, $result_file, $seq_file ) = @_;

            my $cmd = "$ENV{HOME}/bin/muscle -in $seq_file -out $result_file -maxiters $c->{extra}{max_iters}";
            INFO "Running muscle: $cmd";

            return my_sys_non_fatal($cmd);
        },
    }
);

=head1 NAME

cl_muscle.pl - show your muscles on the cluster.

=head1 SYNOPSIS

=head1 EXTRA OPTIONS

=over 4

=item max_iters

Corresponds to the C<-maxiters> option in muscle.

=back

=cut
