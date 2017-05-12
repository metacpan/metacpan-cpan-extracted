#!/usr/bin/env perl

use warnings;
use strict;

use Carp;

use Bio::Grid::Run::SGE;
use Bio::Grid::Run::SGE::Util qw/my_glob expand_path concat_files faiterate/;

run_job(
    {   task => \&do_worker_stuff,
        config => {
            idx_format => 'General',
            record_sep => '^\s+\d+\s+\d+$',
        },
    }
);

sub do_worker_stuff {
    my ( $c, $result_prefix, $seq_file ) = @_;

    my $cmd = "$ENV{HOME}/usr/bin/fprotdist -sequence $seq_file -outfile $result_prefix";
    
    INFO "Running fprotdist $cmd";

    return my_sys_non_fatal($cmd);
}
