#!/usr/bin/env perl

use warnings;
use strict;

use Carp;

use Bio::Grid::Run::SGE;

run_job(
    {
        task => \&do_worker_stuff
    }
);

sub do_worker_stuff {
    my ( $c, $result_prefix, $seq_file ) = @_;

    INFO "Running $seq_file -> $result_prefix";
    open my $seq_file_fh, '<', $seq_file or confess "Can't open filehandle: $!";

    open my $result_fh, '>', $result_prefix or confess "Can't open filehandle: $!";
    while(<$seq_file_fh>) {
        print $result_fh lc($_)


    }
    $result_fh->close;
    $seq_file_fh->close;
}

