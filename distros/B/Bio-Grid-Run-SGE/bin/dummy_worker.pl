#!/usr/bin/env perl

use warnings;
use strict;

use Carp;

use Bio::Grid::Run::SGE::Util qw/my_glob my_sys INFO run_job/;
use Data::Dumper;
use Bio::Grid::Run::SGE::Master;
die "not updated yet";
my %c = (   input_files  => ['~/blast/result/*'],
    job_name    => 'dummy',
    tmp_dir    => '~/blast/tmp',
    result_dir => '~/blast/result',
    stderr_dir => '~/blast/tmp/error',
    stdout_dir => '~/blast/tmp/output',
    num_slots   => 30,
    idx_format => 'FileList',
);

run_job( { pre_task => \&master, task => \&worker, config=>\%c } );

sub master {
    my ($c) = @_;

    return Bio::Grid::Run::SGE::Master->new($c);
}

sub worker {
    my ( $c, $result_file,$input_file ) = @_;

    open my $fh, '>', $result_file or confess "Can't open filehandle: $!";
    print $fh "$input_file -> $result_file\n";
    $fh->close;
}
