#!/usr/bin/env perl

use warnings;
use strict;

use Carp;
use Data::Dumper;

use Bio::Grid::Run::SGE;

run_job(
    {
        task => \&do_worker_stuff
    }
);

sub do_worker_stuff {
    my ( $c, $result_prefix, $file ) = @_;

    INFO "Running $file -> $result_prefix";
    open my $file_fh, '<', $file or confess "Can't open filehandle: $!";
    die "geil" if($ENV{SGE_TASK_ID} % 2 == 0);

    open my $result_fh, '>', $result_prefix or confess "Can't open filehandle: $!";
    while(<$file_fh>) {
        print $result_fh lc($_)
    }
    $result_fh->close;
    $file_fh->close;
    sleep 10;

    return 1;
}

1;
